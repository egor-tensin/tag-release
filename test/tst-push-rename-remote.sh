test_run() {
    test_setup
    test_make_commit
    test_run_release_script --push patch
    test_validate_tags v0.0.1 annotated

    git -C "$test_repo_workdir" remote rename origin foobar
    test_run_release_script --push patch
    test_validate_tags v0.0.1,v0.0.2 annotated
}
