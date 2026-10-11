test_run() {
    test_setup
    test_make_commit
    test_create_tags release/1
    test_make_commit
    test_create_tags release/2
    test_make_commit
    test_create_tags release/2.1
    test_make_commit
    test_run_release_script -p 'release/' major
    test_validate_tags release/1,release/2,release/2.1,release/3.0.0
}
