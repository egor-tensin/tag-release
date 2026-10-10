# Copyright (c) 2026 Egor Tensin <egor@tensin.name>
# This file is part of the "tag-release" project.
# For details, see https://github.com/egor-tensin/tag-release
# Distributed under the MIT License.

export GIT_CONFIG_NOSYSTEM=true
export GIT_CONFIG_GLOBAL=/dev/null

test_should_fail=
test_root_dir=

test_repo_upstream=
test_repo_workdir=

test_setup() {
    test_root_dir="$( mktemp -d )"

    test_repo_upstream="$test_root_dir/upstream"
    mkdir -- "$test_repo_upstream"
    git -C "$test_repo_upstream" init -q --bare

    test_repo_workdir="$test_root_dir/workdir"
    git clone -q "$test_repo_upstream" "$test_repo_workdir"

    log "Root directory: $test_root_dir"
    log "Upstream directory: $test_repo_upstream"
    log "Working directory: $test_repo_workdir"

    git -C "$test_repo_workdir" init -q
    git -C "$test_repo_workdir" config user.name 'Test user'
    git -C "$test_repo_workdir" config user.email 'test@example.com'
}

test_cleanup_default() {
    if [ -n "$test_root_dir" ]; then
        log "Removing test's root directory: $test_root_dir"
        rm -rf -- "$test_root_dir"
    fi
}

test_make_commit() {
    local file
    file="$( mktemp "--tmpdir=$test_repo_workdir" )"

    log "Commiting file $file in $test_repo_workdir..."
    touch -- "$file"
    git -C "$test_repo_workdir" add "$file"
    git -C "$test_repo_workdir" commit -q -m "$file"
    git -C "$test_repo_workdir" push -q -u
}

_validate_tag_kind() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} {lightweight|annotated}"
        return 1
    fi

    case "$1" in
        lightweight|annotated)
            echo "$1"
            ;;
        *)
            log "${FUNCNAME[1]}: invalid tag type: $kind"
            return 1
            ;;
    esac
}

test_get_tags() {
    if [ "$#" -gt 1 ]; then
        log "usage: ${FUNCNAME[0]} [{lightweight|annotated}]"
        return 1
    fi

    local kind=
    [ "$#" -gt 0 ] && kind="$( _validate_tag_kind "$1" )"

    log "Reading tags in $test_repo_workdir..."

    local objecttype
    local refname

    git -C "$test_repo_workdir" for-each-ref refs/tags/ \
        '--format=%(objecttype)%0a%(refname:short)' |
    while IFS= read -r objecttype; do
        IFS= read -r refname

        case "$kind-$objecttype" in
            lightweight-commit|annotated-tag|-*)
                echo "$refname"
                ;;
        esac
    done | sort -V
}

test_get_remote_tags() {
    if [ "$#" -gt 1 ]; then
        log "usage: ${FUNCNAME[0]} [REMOTE]"
        return 1
    fi

    local remote=
    [ "$#" -gt 0 ] && remote="$1"

    log "Fetching remote tags in $test_repo_workdir..."

    git -C "$test_repo_workdir" ls-remote -q --tags --refs $remote \
        | cut -f 2 -d $'\t' \
        | sed -e 's/refs\/tags\///' \
        | sort -V
}

test_get_tag_message() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} TAG"
        return 1
    fi

    local tag="$1"

    git -C "$test_repo_workdir" for-each-ref "refs/tags/$tag" '--format=%(contents)'
}

test_get_tag_commit() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} TAG"
        return 1
    fi

    local tag="$1"

    git -C "$test_repo_workdir" rev-list -n 1 "$tag" --
}

test_create_tags() {
    local tag
    for tag; do
        log "Creating simple tag: $tag"
        touch -- "$test_repo_workdir/$tag"
        git -C "$test_repo_workdir" add "$test_repo_workdir/$tag"
        git -C "$test_repo_workdir" commit -q -m "$tag"
        git -C "$test_repo_workdir" tag -a -m "$tag" "$tag"
    done
}

test_validate_tags() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        log "usage: ${FUNCNAME[0]} EXPECTED_TAGS [{lightweight,annotated}]"
        return 1
    fi

    local expected="$1"

    local kind=
    [ "$#" -gt 1 ] && kind="$( _validate_tag_kind "$2" )"

    local actual
    actual="$( test_get_tags $kind | paste -s -d ',' )"

    log "Validating tags in $test_repo_workdir..."

    [ "$actual" == "$expected" ] && return 0

    fail "Unexpected tags"
    fail_details "Expected tags: $expected"
    fail_details "Actual tags:   $actual"
    return 1
}

test_validate_remote_tags() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        log "usage: ${FUNCNAME[0]} EXPECTED_TAGS [REMOTE]"
        return 1
    fi

    local expected="$1"
    shift

    local remote=
    [ "$#" -gt 0 ] && remote="$1"

    local actual
    actual="$( test_get_remote_tags $remote | paste -s -d ',' )"

    log "Validating remote tags in $test_repo_workdir..."

    [ "$actual" == "$expected" ] && return 0

    fail "Unexpected remote tags"
    fail_details "Expected tags: $expected"
    fail_details "Actual tags:   $actual"
    return 1
}

test_validate_tag_message() {
    if [ "$#" -ne 2 ]; then
        log "usage: ${FUNCNAME[0]} TAG EXPECTED_MSG"
        return 1
    fi

    local tag="$1"
    local expected="$2"

    log "Validating tag message for tag: $tag"

    local actual
    actual="$( test_get_tag_message "$tag" )"

    [ "$actual" == "$expected" ] && return 0

    fail "Unexpected message for tag $tag:"
    fail_details "Expected: $expected"
    fail_details "Actual: $actual"
    return 1
}

test_validate_tags_same_target() {
    if [ "$#" -lt 2 ]; then
        log "usage: ${FUNCNAME[0]} TAG1 TAG2 [TAG...]"
        return 1
    fi

    local tgt=

    local tag
    for tag; do
        log "Validating tag target for tag: $tag"

        local output
        output="$( test_get_tag_commit "$tag" )"

        if [ -z "$tgt" ]; then
            tgt="$output"
            continue
        fi

        if [ "$tgt" != "$output" ]; then
            fail "Tag '$tag' doesn't point to the expected revision"
            fail_details "Expected: $tgt"
            fail_details "Actual: $output"
            return 1
        fi
    done
}

test_run_release_script() {
    local cmd=("$script_dir/../src/release.py" --verbose "$@" "$test_repo_workdir")
    log_run "${cmd[@]}"
    "${cmd[@]}"
}
