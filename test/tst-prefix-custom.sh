test_run() {
    test_setup
    test_create_tags V1 V2 V2.1
    test_run_release_script -p V major
    test_validate_tags V1,V2,V2.1,V3.0.0
}
