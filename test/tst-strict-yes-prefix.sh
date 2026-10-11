test_should_fail=Yes

test_run() {
    # Should fail on version parsing ("invalid" not being a valid version).
    test_setup
    test_make_commit
    test_create_tags v1
    test_make_commit
    test_create_tags v2 vinvalid
    test_run_release_script --strict patch
}
