test_run() {
    # This was a bug (or a feature mayhaps)? With a lightweight parent tag,
    # it'd get remade into an annotated tag.

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
}
