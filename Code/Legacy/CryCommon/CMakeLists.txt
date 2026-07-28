#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_legacy_crycommon_path ${O3DE_ENGINE_PATH}/Code/Legacy/CryCommon/Platform/${O3DE_PAL_PLATFORM_NAME})
#set(common_code_legacy_crycommon_path ${O3DE_ENGINE_PATH}/Code/Legacy/CryCommon/Platform/Common)

o3de_add_target(
    NAME CryCommon STATIC
    NAMESPACE Legacy
    FILES_CMAKE
        crycommon_files.cmake
        ${pal_code_legacy_crycommon_path}/crycommon_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_legacy_crycommon_path}/crycommon_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .         # Lots of code without CryCommon/
            ..        # Dangerous since exports Legacy's path (client code can do CrySystem/ without depending on that target)
            ${pal_code_legacy_crycommon_path}
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
)

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME CryCommonMocks HEADERONLY
        NAMESPACE Legacy
        FILES_CMAKE
            crycommon_testing_files.cmake
        INCLUDE_DIRECTORIES
            INTERFACE
                Mocks
    )

endif()
