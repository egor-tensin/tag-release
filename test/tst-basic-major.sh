test_run() {
    test_setup
    test_create_tags v1
    test_run_release_script major
    test_validate_tags v1,v2.0.0
}
