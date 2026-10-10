test_run() {
    test_setup
    test_make_commit
    test_run_release_script --push patch
    test_validate_tags v0.0.1
    test_validate_remote_tags v0.0.1

    git -C "$test_repo_workdir" remote remove origin
    git -C "$test_repo_workdir" remote add foobar "$test_repo_upstream"
    test_validate_remote_tags v0.0.1 foobar

    test_run_release_script --push --remote foobar patch

    test_validate_tags v0.0.1,v0.0.2
    test_validate_remote_tags v0.0.1,v0.0.2 foobar
}
