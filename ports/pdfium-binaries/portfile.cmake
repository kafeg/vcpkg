vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO bblanchon/pdfium-binaries
    REF chromium/${VERSION}
    SHA512 256280362354296d9698364ee656c31192f1d52961180a35bebcea00cbe91c81e622b5dd2c4296257c23c9b66eba42de9f1e73ecc857e2a1f09b6111db69429b
    HEAD_REF master
)

# params
if(CMAKE_HOST_WIN32)
	#vcpkg_acquire_msys(MSYS_ROOT PACKAGES make)
	#set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)
    set(BASH C:/PROGRA~1/Git/bin/bash.exe) # MSYS version is not supported
    set(OS "win")
    set(CPU "x64")
elseif(CMAKE_HOST_APPLE)
    set(BASH /bin/bash)
    set(OS "mac")
    set(CPU "x64")
elseif(CMAKE_HOST_LINUX)
	set(BASH /bin/bash)
    set(OS "linux")
    set(CPU "x64")
else()
    message(FATAL_ERROR "Unable to detect OS")
endif()

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

# vcpkg specific params
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    set(SUFFIX "dbg")
    set(ENV{PDFium_IS_DEBUG} "true")
endif()
if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    set(SUFFIX "rel")
    set(ENV{PDFium_IS_DEBUG} "false")
endif()

# env params
set(ENV{PDFium_SOURCE_DIR} "${SOURCE_PATH}/pdfium")
set(ENV{PDFium_BUILD_DIR} "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SUFFIX}")
set(ENV{PDFium_TARGET_OS} "${OS}")
set(ENV{PDFium_TARGET_CPU} "${CPU}")
set(ENV{PDFium_BRANCH} "chromium/${VERSION}")
set(ENV{DEPOT_TOOLS_WIN_TOOLCHAIN} "0")

message(STATUS $ENV{INCLUDE})

# setup PATH
get_filename_component(GIT_PATH ${GIT} DIRECTORY)
vcpkg_add_to_path(PREPEND "${GIT_PATH}")
vcpkg_add_to_path(PREPEND "${WindowsSDK_DIR}/${CPU}")
#vcpkg_add_to_path(PREPEND "${MSYS_ROOT}/usr/bin")

# do other stuff
file(MAKE_DIRECTORY "$ENV{PDFium_BUILD_DIR}")

# run build steps
message(STATUS "Save environment")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc -c "/usr/bin/env"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 00-env-${TARGET_TRIPLET}-${SUFFIX}
)

# prepare sources to use correct environment on Windows
message("Use SDK version $ENV{UCRTVersion} for steps/01-install.sh")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc -c "sed -i 's/10.0.19041.0/$ENV{UCRTVersion}/g' steps/01-install.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 00-sed-${TARGET_TRIPLET}-${SUFFIX}
)
#set(CHANGE_FILE_PATH "${SOURCE_PATH}/steps/01-install.sh")
#file(READ ${CHANGE_FILE_PATH} FILE_CONTENTS)
#string(REPLACE "10.0.19041.0" "$ENV{UCRTVersion}" FILE_CONTENTS ${FILE_CONTENTS})
#file(WRITE ${CHANGE_FILE_PATH} ${FILE_CONTENTS})

message(STATUS "Run '01-install.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/01-install.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 01-install-${TARGET_TRIPLET}-${SUFFIX}
)
set(ENV{DepotTools_DIR} "${SOURCE_PATH}/depot_tools")
vcpkg_add_to_path(PREPEND "$ENV{DepotTools_DIR}")

message(STATUS "Run '02-checkout.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/02-checkout.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 02-checkout-${TARGET_TRIPLET}-${SUFFIX}
)

# prepare sources to use correct environment on Windows
message("Use SDK version $ENV{UCRTVersion} for pdfium/build/toolchain/win/setup_toolchain.py")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc -c "sed -i 's/10.0.22621.0/$ENV{UCRTVersion}/g' pdfium/build/toolchain/win/setup_toolchain.py"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 02-sed-${TARGET_TRIPLET}-${SUFFIX}
)
#set(CHANGE_FILE_PATH "${SOURCE_PATH}/pdfium/build/toolchain/win/setup_toolchain.py")
#file(READ ${CHANGE_FILE_PATH} FILE_CONTENTS)
#string(REPLACE "10.0.22621.0" "$ENV{UCRTVersion}" FILE_CONTENTS ${FILE_CONTENTS})
#file(WRITE ${CHANGE_FILE_PATH} ${FILE_CONTENTS})

message(STATUS "Run '03-patch.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/03-patch.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 03-patch-${TARGET_TRIPLET}-${SUFFIX}
)

message(STATUS "Run '04-install-extras.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/04-install-extras.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 04-install-extras-${TARGET_TRIPLET}-${SUFFIX}
)

message(STATUS "Run '05-configure.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/05-configure.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 05-configure-${TARGET_TRIPLET}-${SUFFIX}
)

message(STATUS "Run '06-build.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/06-build.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 06-build-${TARGET_TRIPLET}-${SUFFIX}
)

message(STATUS "Run '07-stage.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/07-stage.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 07-stage-${TARGET_TRIPLET}-${SUFFIX}
)

message(STATUS "Run '08-test.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/08-test.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 08-test-${TARGET_TRIPLET}-${SUFFIX}
)

message(STATUS "Run '09-pack.sh'")
vcpkg_execute_build_process(
    COMMAND ${BASH} --noprofile --norc "${SOURCE_PATH}/steps/09-pack.sh"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME 09-pack-${TARGET_TRIPLET}-${SUFFIX}
)


