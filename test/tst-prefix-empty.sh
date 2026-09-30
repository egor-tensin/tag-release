test_run() {
    test_setup
    test_create_tags 1 2 2.1
    test_run_release_script -p '' major
    test_validate_tags 1,2,2.1,3.0.0
}
