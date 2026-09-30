test_run() {
    test_setup
    test_make_commit
    test_run_release_script patch
    test_validate_tags v0.0.1
}
