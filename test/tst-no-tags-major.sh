test_run() {
    test_setup
    test_make_commit
    test_run_release_script major
    test_validate_tags v1.0.0
}
