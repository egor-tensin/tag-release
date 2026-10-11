test_should_fail=Yes

test_run() {
    # Should fail on tag name parsing ("test_tag" not starting with "v").
    test_setup
    test_make_commit
    test_create_tags v1
    test_make_commit
    test_create_tags v2 test_tag
    test_run_release_script --strict patch
}
