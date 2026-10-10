tag-release
===========

[![CI](https://github.com/egor-tensin/tag-release/actions/workflows/ci.yml/badge.svg)](https://github.com/egor-tensin/tag-release/actions/workflows/ci.yml)
[![Packages (Debian)](https://github.com/egor-tensin/tag-release/actions/workflows/debian.yml/badge.svg)](https://github.com/egor-tensin/tag-release/actions/workflows/debian.yml)
[![Publish (Launchpad)](https://github.com/egor-tensin/tag-release/actions/workflows/ppa.yml/badge.svg)](https://github.com/egor-tensin/tag-release/actions/workflows/ppa.yml)

I'm tired of looking up the correct tag name to use, hence this script.
It follows the semantic versioning rules.
Should work with any semi-recent Python version.

Installation
------------

* Python: [PyPI](https://pypi.org/project/git-tag-release/)
* Arch Linux: [AUR](https://aur.archlinux.org/packages/tag-release)
* Ubuntu: [PPA](https://launchpad.net/~egor-tensin/+archive/ubuntu/tag-release)
* Alternatively, just clone this repo and run `src/release.py` instead of
`tag-release`.

Usage
-----

* View usage info:

      tag-release -h

* Make a new patch version release in the current repo.
Tries to parse the latest tag (say, v2.1.3) and will add a new tag (in this
case, v2.1.4).

      tag-release patch

* Make a new minor version release in the current repo (v2.1.3 -> v2.2.0):

      tag-release minor

* Similar for major versions (v2.1.3 -> v3.0.0):

      tag-release major

* Accepts path to repository as an optional argument:

      tag-release patch path/to/your/repo

* You can customize the version prefix ("v" by default).
It will search for the latest tag with the given prefix then.
For example, this command, given that tag "2.1.3" exists, will create tag
"2.1.4":

      tag-release -p '' patch

* A prefix can be anything, basically; this will create tag "release/v2.2.0"
if the latest tag is "release/v2.1.3":

      tag-release -p 'release/v' minor

* If no tags were found, the implicit version 0.0.0 is assumed.
In a repository with no matching tags, this will create tag "v1.0.0":

      tag-release major

* Customize the tag message:

      tag-release -m 'Release: version {}' patch

* You can "retag" parent versions.
For example, given that the latest tag is "v1.1.3", this will create/update
tags "v1" & "v1.1" to point to the new tag "v1.1.4":

      tag-release -r patch

* Push new/updated tags automatically using `--push` (retagged tags are pushed
forcefully):

      tag-release -u patch

* Create lightweight tags, if you wish (using annotated tags, which is the
default, is almost always the preferred option):

      tag-release -l patch

License
-------

Distributed under the MIT License.
See [LICENSE.txt] for details.

[LICENSE.txt]: LICENSE.txt
