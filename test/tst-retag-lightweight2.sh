test_run() {
    # This was a bug. With a lightweight parent tag, it would become a
    # tag-to-tag, which is bad somehow.

    test_setup

    test_make_commit
    # Make a lightweight tag:
    git -C "$test_repo_workdir" tag v1

    test_make_commit
    test_run_release_script -r minor

    test_validate_tags v1,v1.1,v1.1.0
    # The lightweight parent tag should still be lightweight; the others -
    # annotated.
    test_validate_tags v1 lightweight
    test_validate_tags v1.1,v1.1.0 annotated

    test_validate_tags_same_target v1 v1.1 v1.1.0
}
