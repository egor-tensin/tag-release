#!/usr/bin/env python3

# Copyright (c) 2026 Egor Tensin <egor@tensin.name>
# This file is part of the "tag-release" project.
# For details, see https://github.com/egor-tensin/tag-release
# Distributed under the MIT License.

R"""
This script automates the creation of git tags in accordance with the semantic
versioning policy. It follows the convention of tags being in the MAJOR.MINOR.PATCH
format (with an optional prefix - "v" by default). You can then use it to bump
either of the major/minor/patch version numbers, and it will take care of
creating the proper tag for you.
"""

import argparse
from contextlib import contextmanager
from dataclasses import dataclass
from enum import Enum
import logging
import os
import re
import shlex
import subprocess
import sys


@contextmanager
def setup_logging(verbose=False):
    level_names = {
        logging.DEBUG: "DBG",
        logging.INFO: "INFO",
        logging.WARNING: "WARN",
        logging.ERROR: "ERR",
        logging.CRITICAL: "CRIT",
    }
    for lvl, name in level_names.items():
        logging.addLevelName(lvl, name)

    logging.basicConfig(
        datefmt="%Y-%m-%d %H:%M:%S%z",
        format="%(asctime)s | %(levelname)4s | %(message)s",
        level=logging.DEBUG if verbose else logging.INFO,
        stream=sys.stdout,
    )
    try:
        yield
    except Exception as e:
        logging.exception(e)
        sys.exit(1)


def _run_log_output(level, output):
    if not output:
        logging.log(level, "... No output")
        return
    logging.log(level, "Output (%d characters):", len(output))
    for line in output.splitlines():
        logging.log(level, "    %s", line)


def run(cmd, **kwargs):
    stdout = subprocess.PIPE
    stderr = subprocess.STDOUT

    logging.info("Running: %s", shlex.join(cmd))
    try:
        result = subprocess.run(
            cmd, check=True, stdout=stdout, stderr=stderr, encoding="utf-8", **kwargs
        )
    except subprocess.CalledProcessError as e:
        logging.error("... Returned exit code %d", e.returncode)
        _run_log_output(logging.ERROR, e.output)
        raise

    _run_log_output(logging.DEBUG, result.stdout)
    return result.stdout


@contextmanager
def cd(path):
    cwd = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(cwd)


class Repo:
    DEFAULT_REMOTE = "origin"

    @staticmethod
    @contextmanager
    def setup(path=None):
        if path is None:
            path = os.getcwd()
        with cd(path):
            yield Repo(path)

    def __init__(self, path):
        self.path = path
        self._validate_git_workdir(path)
        self._branch = self._get_current_branch(path)
        if self._branch is None:
            self._remote = None
        else:
            self._remote = self._get_target_remote(path, self._branch)
        self._remote = self._remote or Repo.DEFAULT_REMOTE

    @staticmethod
    def _validate_git_workdir(path):
        try:
            run(["git", "-C", path, "rev-parse", "--is-inside-work-tree"])
        except subprocess.CalledProcessError as e:
            raise RuntimeError(
                f"Doesn't seem to be a git working directory: {path}"
            ) from e

    @staticmethod
    def _get_current_branch(path):
        output = run(["git", "-C", path, "rev-parse", "--abbrev-ref", "HEAD"])
        parts = output.splitlines()
        if len(parts) > 1:
            raise RuntimeError(f"Invalid `git rev-parse` output: {output}")
        if not parts:
            logging.warning("Our HEAD seems to be detached here: %s", path)
            return None
        result = parts[0]
        logging.info("Working on branch '%s' here: %s", result, path)
        return result

    @staticmethod
    def _get_target_remote(path, branch):
        try:
            cmd = [
                "git",
                "-C",
                path,
                "rev-parse",
                "--abbrev-ref",
                branch + "@{upstream}",
            ]
            output = run(cmd)
        except subprocess.CalledProcessError:
            logging.warning("Branch '%s' doesn't seem to have a target branch", branch)
            return None
        parts = output.splitlines()
        if len(parts) != 1:
            raise RuntimeError(f"Invalid `git rev-parse` output: {output}")
        parts = parts[0]
        parts = parts.split("/", maxsplit=1)
        if len(parts) != 2:
            raise RuntimeError(f"Unexpected `git rev-parse` output: {output}")
        result = parts[0]
        logging.info("Detected remote '%s' for branch '%s'", result, branch)
        return result

    def push(self, tag, force=False, remote=None):
        if remote is None:
            remote = self._remote
        cmd = ["git", "-C", self.path, "push"]
        if force:
            cmd.append("-f")
        cmd += [remote, tag.name]
        try:
            run(cmd)
        except subprocess.CalledProcessError as e:
            raise RuntimeError(
                f"Failed to push tag {tag.name} to remote {remote}"
            ) from e


class ReleaseScope(Enum):
    MAJOR = "major"
    MINOR = "minor"
    PATCH = "patch"

    def __str__(self):
        return self.value

    def next_version(self, version):
        version = version.extend(len(ReleaseScope))
        version = version.upgrade(self._index)
        return version

    @property
    def _index(self):
        if self is ReleaseScope.MAJOR:
            return 0
        if self is ReleaseScope.MINOR:
            return 1
        if self is ReleaseScope.PATCH:
            return 2
        raise NotImplementedError(f"Unknown release scope: {self}")


class Version:
    def __init__(self, nums):
        nums = list(nums)
        if len(nums) > len(ReleaseScope):
            raise ValueError(f"Too many version components: {nums}")

        while nums and nums[-1] is None:
            nums.pop()
        if not nums:
            raise ValueError("Must provide at least the major version number")
        if any((n is None for n in nums)):
            raise ValueError(f"Some version components are invalid: {nums}")

        self._nums = tuple(nums)

    @staticmethod
    def parse(src, strict=False):
        invalid_msg = f"Invalid version: {src}"

        match = re.fullmatch(r"(\d+)(?:\.(\d+)(?:\.(\d+))?)?", src)
        if not match:
            if strict:
                raise ValueError(invalid_msg)
            logging.warning("%s", invalid_msg)
            return None
        assert len(match.groups()) == 3

        nums = [int(n) if n is not None else None for n in match.groups()]
        return Version(nums)

    def __str__(self):
        return ".".join(map(str, self._nums))

    def __eq__(self, other):
        return self._nums == other._nums

    def __lt__(self, other):
        # Attempting to sort the way `sort -V` does it (so v1 < v1.0 for example).
        for a, b in zip(self._nums, other._nums):
            if a > b:
                return False
            if a < b:
                return True
        return len(self._nums) < len(other._nums)

    def __hash__(self):
        return hash(self._nums)

    def extend(self, new_len):
        if new_len < 1 or new_len > len(ReleaseScope):
            raise ValueError(f"Invalid version length {new_len}")
        if len(self._nums) >= new_len:
            return Version(self._nums)
        nums = list(self._nums)
        nums.extend([0 for i in range(new_len - len(self._nums))])
        return Version(nums)

    def upgrade(self, idx):
        assert idx < len(ReleaseScope)
        if idx < 0 or len(self._nums) < idx + 1:
            raise ValueError(
                f"Can't increment version number at index {idx} for version {self}"
            )
        nums = list(self._nums[:idx])
        nums.append(self._nums[idx] + 1)
        nums.extend([0 for i in range(len(self._nums) - idx - 1)])
        return Version(nums)

    @property
    def has_parent(self):
        return len(self._nums) > 1

    def get_parent(self):
        return Version(self._nums[:-1])


@dataclass
class Tag:
    name: str
    version: Version
    lightweight: bool

    def git_cmd_create(self, message=None, target=None):
        cmd = ["git", "tag"]
        if self.lightweight:
            return cmd + [self.name]
        if message is None:
            raise ValueError("Must provide a tag message for annotated tags")
        cmd += ["-a", "-m", message, self.name]
        if target is not None:
            cmd.append(target.name + "^{}")
            # ^^^ Avoid tags-to-tags, which is somehow bad, idk.
        return cmd

    def git_cmd_update(self, target):
        cmd = ["git", "tag"]
        if self.lightweight:
            return cmd + ["-f", self.name, target.name]
        cmd += ["-a", "-f", self.name]
        cmd.append(target.name + "^{}")
        # ^^^ Avoid tags-to-tags, which is somehow bad, idk.
        return cmd


class TagManager:
    DEFAULT_PREFIX = "v"
    DEFAULT_VERSION = Version((0 for _ in range(len(ReleaseScope))))
    DEFAULT_MESSAGE_FMT = "{}"

    def __init__(self, prefix=None, strict=False, lightweight=False, message_fmt=None):
        if prefix is None:
            prefix = TagManager.DEFAULT_PREFIX
        self._prefix = prefix
        self._strict = strict
        self._lightweight = lightweight
        if message_fmt is None:
            message_fmt = TagManager.DEFAULT_MESSAGE_FMT
        self._message_fmt = message_fmt

        tags = self._git_query_tags()
        tags = self._git_filter_tags(tags)
        tags = self._git_parse_tags(tags)
        tags = list(tags)
        if not tags:
            version = TagManager.DEFAULT_VERSION
            tags = [Tag(self._format_tag_name(version), version, lightweight)]

        self._tag_lst = sorted(tags, key=lambda tag: tag.version)
        self._tag_map = {tag.version: tag for tag in tags}

    def _format_tag_name(self, version):
        return f"{self._prefix}{version}"

    @staticmethod
    def _git_query_tags():
        cmd = [
            "git",
            "for-each-ref",
            "--format=%(refname:short) %(objecttype)",
            "refs/tags/",
        ]

        output = run(cmd)
        lines = output.splitlines()

        for line in lines:
            line = line.split()
            assert len(line) == 2
            yield line

    def _git_filter_tags(self, tags):
        for refname, objecttype in tags:
            if not refname.startswith(self._prefix):
                msg = f"Unexpected tag name: {refname}"
                if self._strict:
                    raise RuntimeError(msg)
                logging.warning("%s", msg)
                continue
            yield refname[len(self._prefix) :], objecttype
            # ^^^ .removeprefix for Python 3.9+

    @staticmethod
    def _is_tag_lightweight(objecttype):
        if objecttype == "commit":
            return True
        if objecttype == "tag":
            return False
        raise ValueError(f"Unexpected %(objecttype) value: {objecttype}")

    def _git_parse_tags(self, tags):
        for refname, objecttype in tags:
            version = Version.parse(refname, strict=self._strict)
            if version is None:
                continue
            lightweight = self._is_tag_lightweight(objecttype)
            yield Tag(self._format_tag_name(version), version, lightweight)

    def __len__(self):
        return len(self._tag_lst)

    @property
    def latest(self):
        if not self:
            raise RuntimeError("No tags, can't get the latest")
        return self._tag_lst[-1]

    def create(self, tag, target=None):
        if tag.version in self._tag_map:
            raise RuntimeError(f"Tag {tag.name} already exists")

        cmd = tag.git_cmd_create(
            message=self._message_fmt.format(tag.name), target=target
        )
        run(cmd)

        self._tag_lst.append(tag)
        self._tag_lst.sort(key=lambda tag: tag.version)
        self._tag_map[tag.version] = tag

    def update(self, parent, child):
        if parent.version not in self._tag_map:
            raise RuntimeError(f"Tag {parent.name} doesn't exist")
        if child.version not in self._tag_map:
            raise RuntimeError(f"Tag {child.name} doesn't exist")

        cmd = parent.git_cmd_update(child)
        env = os.environ.copy()
        env["GIT_EDITOR"] = "true"
        run(cmd, env=env)

    def release_next(self, scope):
        version = scope.next_version(self.latest.version)
        tag = Tag(f"{self._prefix}{version}", version, self._lightweight)
        self.create(tag)
        return tag

    def retag_parents(self, child):
        updated = []
        while child.version.has_parent:
            parent_version = child.version.get_parent()
            if parent_version in self._tag_map:
                parent = self._tag_map[parent_version]
                self.update(parent, child)
            else:
                parent = Tag(
                    self._format_tag_name(parent_version),
                    parent_version,
                    self._lightweight,
                )
                self.create(parent, target=child)
            updated.append(parent)
            child = parent
        return updated


def parse_args(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    epilog = R"""
The tag message (--message) can include Python's str.format() placeholders.
It will be format()ted with a single argument: the full tag name (for example,
v1.2.3).
"""

    parser = argparse.ArgumentParser(description=__doc__, epilog=epilog)

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="verbose output",
    )
    parser.add_argument(
        "-p",
        "--prefix",
        default=TagManager.DEFAULT_PREFIX,
        metavar="STR",
        help=f"""tag prefix ("{TagManager.DEFAULT_PREFIX}" by default)""",
    )
    parser.add_argument(
        "-s",
        "--strict",
        action="store_true",
        help="error out on discovering malformed tags",
    )
    parser.add_argument(
        "-l",
        "--lightweight",
        action="store_true",
        help="create lightweight tags (annotated by default)",
    )
    parser.add_argument(
        "-m",
        "--message",
        metavar="FMT",
        dest="message_fmt",
        default=TagManager.DEFAULT_MESSAGE_FMT,
        help="tag message format string",
    )
    parser.add_argument(
        "-u",
        "--push",
        action="store_true",
        help="push new tags",
    )
    parser.add_argument(
        "--remote",
        help='name of the remote to push to; unless specified or detected, defaults to "origin"',
    )
    parser.add_argument(
        "-r",
        "--retag",
        action="store_true",
        help="update parent version tags (i.e. for tag v2.1.1, update tags v2 & v2.1 to the same commit); if --push is used, the updated tags are pushed w/ --force",
    )
    parser.add_argument(
        "release_scope",
        choices=ReleaseScope,
        type=ReleaseScope,
        help="release scope",
    )
    parser.add_argument(
        "repo_dir",
        metavar="DIR",
        nargs="?",
        help="path to repository (working directory by default)",
    )

    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    with setup_logging(args.verbose):
        with Repo.setup(args.repo_dir) as repo:
            tags = TagManager(
                prefix=args.prefix,
                strict=args.strict,
                lightweight=args.lightweight,
                message_fmt=args.message_fmt,
            )
            new = tags.release_next(args.release_scope)
            updated = tags.retag_parents(new) if args.retag else []
            if args.push:
                repo.push(new, remote=args.remote)
                for tag in updated:
                    repo.push(tag, force=True, remote=args.remote)


if __name__ == "__main__":
    main()
