test_should_fail=Yes

test_run() {
    test_setup
    test_create_tags v1 vinvalid v2
    test_run_release_script --strict patch
    test_validate_tags vinvalid,v1,v2,v2.0.1
}
