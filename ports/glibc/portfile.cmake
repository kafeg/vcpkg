vcpkg_fail_port_install(ON_TARGET "OSX" "Windows" "UWP")

if(EXISTS "${CURRENT_INSTALLED_DIR}/include/stdio.h")
    message(FATAL_ERROR "Can't build ${PORT} if another 'libc'-like port is installed. Please remove another libc (glibc, musl, uclibs, ...), and try to install ${PORT} again if you need it.")
endif()

set(VCPKG_POLICY_ALLOW_RESTRICTED_HEADERS enabled)

execute_process(COMMAND ${SOURCE_PATH}/scripts/config.guess OUTPUT_VARIABLE MACHINE_HOST)
set(TARGET_MACHINE "")
if ("${VCPKG_TARGET_ARCHITECTURE}" STREQUAL "x64" AND "${VCPKG_CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set(MACHINE_TARGET x86_64-pc-linux-gnu)
else()
    #for future cross-build
    message(FATAL_ERROR "Unsupported target architecture for ${PORT}: ${VCPKG_TARGET_ARCHITECTURE} / ${VCPKG_CMAKE_SYSTEM_NAME}")
endif()

set(TARGET_VERSION 2.31)
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnu.org/gnu/glibc/glibc-${TARGET_VERSION}.tar.xz"
    FILENAME "glibc-${TARGET_VERSION}.tar.xz"
    SHA512 735e4c0ef10418b6ea945ad3906585e5bbd8b282d76f2131309dce4cec6b15066a5e4a3731773ce428a819b542579c9957867bb0abf05ed2030983fca4412306
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${TARGET_VERSION}
    PATCHES
        glibc-2.31-fhs-1.patch
)

set(CORES_COUNT 16)
#set(ENV{CFLAGS} "-static -static-libgcc -fno-stack-protector -u_fortify_source")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

#unset(ENV{CFLAGS})
#unset(ENV{C_INCLUDE_PATH})
#unset(ENV{CPLUS_INCLUDE_PATH})
#unset(ENV{CPPFLAGS})
#unset(ENV{CXXFLAGS})
#unset(ENV{INCLUDE})
#unset(ENV{LDFLAGS})
#unset(ENV{PKG_CONFIG})

set(OPTIONS --with-headers=${CURRENT_INSTALLED_DIR}/include --enable-kernel=3.2 --disable-werror --with-binutils=${CURRENT_INSTALLED_DIR}/tools/binutils/bin --enable-static --disable-profile --enable-static-nss --enable-add-ons --host=${MACHINE_TARGET} --build=${MACHINE_HOST}) #--disable-shared

message("Configuring debug...")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
file(TOUCH ${CURRENT_BUILDTREES_DIR}/config-${TARGET_TRIPLET}-dbg)
vcpkg_execute_build_process(
    COMMAND ${SOURCE_PATH}/configure ${OPTIONS} --enable-debug --prefix=${CURRENT_PACKAGES_DIR}/debug
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME config-${TARGET_TRIPLET}-dbg
)

message("Configuring release...")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
file(TOUCH ${CURRENT_BUILDTREES_DIR}/config-${TARGET_TRIPLET}-rel)
vcpkg_execute_build_process(
    COMMAND ${SOURCE_PATH}/configure ${OPTIONS} --disable-debug --prefix=${CURRENT_PACKAGES_DIR}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME config-${TARGET_TRIPLET}-rel
)

message("Building debug...")
file(TOUCH ${CURRENT_BUILDTREES_DIR}/build-${TARGET_TRIPLET}-dbg)
vcpkg_execute_build_process(
    COMMAND make -j ${CORES_COUNT}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME build-${TARGET_TRIPLET}-dbg
)

message("Building release...")
file(TOUCH ${CURRENT_BUILDTREES_DIR}/build-${TARGET_TRIPLET}-rel)
vcpkg_execute_build_process(
    COMMAND make -j ${CORES_COUNT}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME build-${TARGET_TRIPLET}-rel
)

message("Installing debug...")
file(TOUCH ${CURRENT_BUILDTREES_DIR}/install-${TARGET_TRIPLET}-dbg)
vcpkg_execute_build_process(
    COMMAND make install
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME install-${TARGET_TRIPLET}-dbg
)

message("Installing release...")
file(TOUCH ${CURRENT_BUILDTREES_DIR}/install-${TARGET_TRIPLET}-rel)
vcpkg_execute_build_process(
    COMMAND make install
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME install-${TARGET_TRIPLET}-rel
)

#vcpkg_install_make()

file(INSTALL ${CURRENT_PACKAGES_DIR}/debug/bin DESTINATION ${CURRENT_PACKAGES_DIR}/tools/glibc/debug)
file(INSTALL ${CURRENT_PACKAGES_DIR}/debug/sbin DESTINATION ${CURRENT_PACKAGES_DIR}/tools/glibc/debug)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin" "${CURRENT_PACKAGES_DIR}/debug/sbin")

file(INSTALL ${CURRENT_PACKAGES_DIR}/bin DESTINATION ${CURRENT_PACKAGES_DIR}/tools/glibc)
file(INSTALL ${CURRENT_PACKAGES_DIR}/sbin DESTINATION ${CURRENT_PACKAGES_DIR}/tools/glibc)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/sbin")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share" "${CURRENT_PACKAGES_DIR}/debug/var" "${CURRENT_PACKAGES_DIR}/var" "${CURRENT_PACKAGES_DIR}/debug/include")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

