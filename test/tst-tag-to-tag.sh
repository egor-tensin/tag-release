test_run() {
    # This test is for understanding how git works; specifically, its "nested"
    # tags feature.

    test_setup

    # Git warns about creating nested tags by default.
    _git config set advice.nestedTag false || true

    test_make_commit
    _git tag -a -m v1-tgt v1-tgt
    _git tag -a -m v1 v1 v1-tgt
    # ^^^ This is a nested tag. Git itself warns against creating them, so I'm
    # avoiding them in the script.
    test_validate_tags_same_rev v1 v1-tgt
    test_validate_tags_different_object v1 v1-tgt

    test_make_commit
    _git tag -a -m v2-tgt v2-tgt
    _git tag -a -m v2 v2 'v2-tgt^{}'
    # ^^^ Tags-to-tags should be created like so, then they're pointing to the
    # same thing.
    test_validate_tags_same_rev v2 v2-tgt
    test_validate_tags_same_object v2 v2-tgt

    # Lightweight tags are "just references" or whatever, I don't care enough
    # to delve to deeply into this. In practice, I think, it means that all
    # attempts at dereferencing them will return just the commit object.
    test_make_commit
    _git tag v3-tgt
    _git tag v3 v3-tgt
    test_validate_tags_same_rev v3 v3-tgt
    test_validate_tags_same_object v3 v3-tgt

    test_make_commit
    # A lightweight tag pointing to an annotated tag.
    _git tag -a -m v4-tgt v4-tgt
    _git tag v4 v4-tgt
    test_validate_tags_same_rev v4 v4-tgt
    # The lightweight tag is "just a reference", so its object's contents is
    # the same as the annotated tag's.
    test_validate_tags_same_object v4 v4-tgt

    test_make_commit
    # An annotated tag pointing to a lightweight tag.
    _git tag v5-tgt
    _git tag -a -m v5 v5 v5-tgt
    test_validate_tags_same_rev v5 v5-tgt
    # The lightweight tag's contents is the commit object's contents; git
    # cat-file -p will show different things for the two tags.
    test_validate_tags_different_object v5 v5-tgt

    # Lightweight tags using the ^{} syntax.
    test_make_commit
    _git tag v6-tgt
    _git tag v6 'v6-tgt^{}'
    test_validate_tags_same_rev v6 v6-tgt
    test_validate_tags_same_object v6 v6-tgt

    # Lightweight-to-annotated using the ^{} syntax. Notice how it's different
    # from the v4 case. The lightweight tag points to the commit now, not the
    # tag.
    test_make_commit
    _git tag -a -m v7-tgt v7-tgt
    _git tag v7 'v7-tgt^{}'
    test_validate_tags_same_rev v7 v7-tgt
    test_validate_tags_different_object v7 v7-tgt

    # Annotated-to-lightweight using the ^{} syntax. As in the v5 case, the
    # annotated tag points to the commit pointed to by the lightweight tag.
    test_make_commit
    _git tag v8-tgt
    _git tag -a -m v8 v8 'v8-tgt^{}'
    test_validate_tags_same_rev v8 v8-tgt
    test_validate_tags_different_object v8 v8-tgt
}

test_get_tag_object() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} TAG"
        return 1
    fi

    local tag="$1"
    local output
    if ! output="$( _git cat-file -p "$tag" | grep -P '^object ' )"; then
        # Assuming it's a lightweight tag:
        log "No output from git cat-file for tag: $tag"
        return 0
    fi

    echo "$output"
}

test_validate_tags_same_object() {
    if [ "$#" -lt 2 ]; then
        log "usage: ${FUNCNAME[0]} TAG1 TAG2 [TAG...]"
        return 1
    fi

    local tgt_set=
    local tgt=

    local tag
    for tag; do
        log "Validating tag object for: $tag"

        local output
        output="$( test_get_tag_object "$tag" )"

        if [ -z "$tgt_set" ]; then
            tgt="$output"
            tgt_set=1
            continue
        fi

        if [ "$tgt" != "$output" ]; then
            fail "Tag '$tag' doesn't point to the expected object"
            fail_details "Expected: $tgt"
            fail_details "Actual: $output"
            return 1
        fi
    done
}

test_validate_tags_different_object() {
    if [ "$#" -ne 2 ]; then
        log "usage: ${FUNCNAME[0]} TAG1 TAG2"
        return 1
    fi

    local tgt_set=
    local tgt=

    local tag
    for tag; do
        log "Validating tag object for: $tag"

        local output
        output="$( test_get_tag_object "$tag" )"

        if [ -z "$tgt_set" ]; then
            tgt="$output"
            tgt_set=1
            continue
        fi

        if [ "$tgt" == "$output" ]; then
            fail "Tag '$tag' points to the same object: $tgt"
            return 1
        fi
    done
}
