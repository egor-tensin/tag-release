test_run() {
    # Similar to the lightweight2 test, but now both the major and minor
    # version tags are lightweight.

    test_setup

    test_make_commit
    # Make lightweight tags:
    git -C "$test_repo_workdir" tag v1
    git -C "$test_repo_workdir" tag v1.1

    test_make_commit
    test_run_release_script -r patch

    test_validate_tags v1,v1.1,v1.1.1
    # The lightweight parent tags should still be lightweight; the others -
    # annotated.
    test_validate_tags v1,v1.1 lightweight
    test_validate_tags v1.1.1 annotated

    test_validate_tags_same_target v1 v1.1 v1.1.1
}
