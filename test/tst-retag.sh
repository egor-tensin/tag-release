test_run() {
    test_setup

    test_make_commit
    test_create_tags v1
    test_make_commit
    test_run_release_script minor
    test_make_commit
    test_run_release_script patch

    test_validate_tags v1,v1.1.0,v1.1.1

    test_make_commit
    test_run_release_script -r patch

    test_validate_tags v1,v1.1,v1.1.0,v1.1.1,v1.1.2

    test_validate_tags_same_rev v1 v1.1 v1.1.2
    test_validate_tag_message v1 v1
    test_validate_tag_message v1.1 v1.1
    test_validate_tag_message v1.1.2 v1.1.2
}
