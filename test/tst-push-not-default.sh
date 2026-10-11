test_run() {
    # Check that --push isn't enabled by default.

    test_setup

    test_make_commit
    test_run_release_script patch
    test_validate_tags v0.0.1
    test_validate_remote_tags ''

    test_make_commit
    test_run_release_script --push patch
    test_validate_tags v0.0.1,v0.0.2
    test_validate_remote_tags v0.0.2
}
