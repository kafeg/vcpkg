vcpkg_fail_port_install(ON_TARGET "OSX" "Windows" "UWP")

if(EXISTS "${CURRENT_INSTALLED_DIR}/include/stdio.h")
    message(FATAL_ERROR "Can't build ${PORT} if another 'libc'-like port is installed. Please remove another libc (glibc, musl, uclibs, ...), and try to install ${PORT} again if you need it.")
endif()

set(VCPKG_POLICY_ALLOW_RESTRICTED_HEADERS enabled)

set(TARGET_VERSION 1.2.1)
vcpkg_download_distfile(ARCHIVE
    URLS "https://musl.libc.org/releases/musl-${TARGET_VERSION}.tar.gz"
    FILENAME "musl-${TARGET_VERSION}.tar.gz"
    SHA512 455464ef47108a78457291bda2b1ea574987a1787f6001e9376956f20521593a4816bc215dab41c1a80292ae7ebd315accb4d4fa6a1210ff77d9a4d68239e960
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${TARGET_VERSION}
)

set(ENV{C_INCLUDE_PATH} "/")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

vcpkg_configure_make(
    #AUTOCONFIG
    SOURCE_PATH ${SOURCE_PATH}
)

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYRIGHT DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
