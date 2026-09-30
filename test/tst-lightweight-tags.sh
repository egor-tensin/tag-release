test_run() {
    test_setup
    test_create_tags v1.0.0

    test_run_release_script --lightweight major
    test_run_release_script minor
    test_run_release_script --l patch

    test_validate_tags v1.0.0,v2.0.0,v2.1.0,v2.1.1
    test_validate_tags v1.0.0,v2.1.0 annotated
    test_validate_tags v2.0.0,v2.1.1 lightweight
}
