test_run() {
    test_setup

    test_make_commit
    test_run_release_script patch
    test_validate_tags v0.0.1 annotated
    test_validate_remote_tags ''

    test_make_commit
    test_run_release_script --push patch
    test_validate_tags v0.0.1,v0.0.2 annotated
    test_validate_remote_tags v0.0.2
}
