test_run() {
    test_setup
    test_create_tags v1 test_tag v2
    test_run_release_script patch
    test_validate_tags test_tag,v1,v2,v2.0.1
}
