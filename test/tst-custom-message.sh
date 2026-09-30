test_run() {
    test_setup
    test_create_tags v1.0.0

    test_run_release_script -l -m "shouldn't be visible" major
    test_run_release_script -m "minor release" minor
    test_run_release_script -p 'debian/' --message "Debian release {}" patch
    test_run_release_script -m $'foo\n\nbar' patch

    test_validate_tags debian/0.0.1,v1.0.0,v2.0.0,v2.1.0,v2.1.1
    test_validate_tags debian/0.0.1,v1.0.0,v2.1.0,v2.1.1 annotated
    test_validate_tags v2.0.0 lightweight

    test_validate_tag_message v2.1.0 'minor release'
    test_validate_tag_message debian/0.0.1 'Debian release debian/0.0.1'
    test_validate_tag_message v2.1.1 $'foo\n\nbar'
}
