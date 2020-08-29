vcpkg_fail_port_install(ON_TARGET "OSX" "Windows" "UWP")

set(TARGET_VERSION 5.5.3)
vcpkg_download_distfile(ARCHIVE
    URLS "https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-${TARGET_VERSION}.tar.xz"
    FILENAME "linux-headers-${TARGET_VERSION}.tar.xz"
    SHA512 ffc4f5605b6f9278030146d8ed8f1c3341bb588f6a96400ff5466daf0d74e95e94bc47f22308ef917adff3de211385e959de583b91523a1ab1e0e93b4326e3c3
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${TARGET_VERSION}
)

# Make sure we start from a clean slate
vcpkg_execute_build_process(
    COMMAND make headers
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME build-${TARGET_TRIPLET}-dbg
)

vcpkg_execute_build_process(
    COMMAND make headers
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME build-${TARGET_TRIPLET}-rel
)

file(INSTALL
    ${SOURCE_PATH}/usr/include/
    DESTINATION ${CURRENT_PACKAGES_DIR}/include
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

