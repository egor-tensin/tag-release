test_should_fail=Yes

test_run() {
    test_setup
    test_create_tags v1 test_tag v2
    test_run_release_script --strict patch
}
