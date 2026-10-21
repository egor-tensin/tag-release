test_run() {
    # Check that --push & --retag work together.

    test_setup
    test_make_commit
    test_run_release_script --push major
    test_validate_tags v1.0.0
    test_validate_remote_tags v1.0.0

    test_make_commit
    test_run_release_script --push minor
    test_make_commit
    test_run_release_script --push patch
    test_make_commit
    test_run_release_script --push --retag patch

    test_validate_tags v1,v1.0.0,v1.1,v1.1.0,v1.1.1,v1.1.2
    test_validate_remote_tags v1,v1.0.0,v1.1,v1.1.0,v1.1.1,v1.1.2
    test_validate_tags_same_rev v1 v1.1 v1.1.2

    # Make a new version and retag it again!
    test_make_commit
    test_run_release_script --push --retag patch

    test_validate_tags v1,v1.0.0,v1.1,v1.1.0,v1.1.1,v1.1.2,v1.1.3
    test_validate_remote_tags v1,v1.0.0,v1.1,v1.1.0,v1.1.1,v1.1.2,v1.1.3
    test_validate_tags_same_rev v1 v1.1 v1.1.3
}
