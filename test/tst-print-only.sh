test_run() {
    test_setup
    test_make_commit
    test_create_tags v1.0.0
    local output
    output="$( test_run_release_script --print-only patch )"

    if [ "$output" != 'v1.0.1' ]; then
        fail "Invalid output: $output"
        return 1
    fi

    test_validate_tags v1.0.0
}
