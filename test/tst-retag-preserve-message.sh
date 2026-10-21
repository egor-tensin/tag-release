test_run() {
    # Check that when retagging, the original tag message is preserved.

    test_setup

    test_make_commit
    test_create_tags v1 v1.0.0

    test_validate_tags v1,v1.0.0
    test_validate_tags_same_rev v1 v1.0.0
    test_validate_tag_message v1 v1
    test_validate_tag_message v1.0.0 v1.0.0

    test_make_commit
    test_run_release_script -r patch

    test_validate_tags v1,v1.0,v1.0.0,v1.0.1

    test_validate_tags_same_rev v1 v1.0 v1.0.1
    test_validate_tag_message v1 v1
    test_validate_tag_message v1.0 v1.0
    test_validate_tag_message v1.0.1 v1.0.1
}
