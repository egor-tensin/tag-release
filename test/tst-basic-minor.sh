test_run() {
    test_setup
    test_create_tags v1
    test_run_release_script minor
    test_validate_tags v1,v1.1.0
}
