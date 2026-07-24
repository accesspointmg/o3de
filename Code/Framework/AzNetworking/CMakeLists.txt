#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path(${O3DE_ENGINE_PATH}/Code/Framework/AzNetworking/Platform/${O3DE_PAL_PLATFORM_NAME} pal_core_framework_aznetworking_path)
set(common_core_framework_aznetworking_path ${O3DE_ENGINE_PATH}/Code/Framework/AzNetworking/Platform/Common)

o3de_add_target(
    NAME AzNetworking STATIC
    NAMESPACE AZ
    FILES_CMAKE
        AzNetworking/aznetworking_files.cmake
        ${pal_core_framework_aznetworking_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_core_framework_aznetworking_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
            ${common_core_framework_aznetworking_path}
            ${pal_core_framework_aznetworking_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            3rdParty::zstd
            3rdParty::OpenSSL
        PUBLIC
            3rdParty::RapidJSON
            3rdParty::RapidXML
    AUTOGEN_RULES
        *.AutoPackets.xml,AutoPackets_Header.jinja,$path/$fileprefix.AutoPackets.h
        *.AutoPackets.xml,AutoPackets_Inline.jinja,$path/$fileprefix.AutoPackets.inl
        *.AutoPackets.xml,AutoPackets_Source.jinja,$path/$fileprefix.AutoPackets.cpp
)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME AzNetworking.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            Tests/aznetworkingtests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        COMPILE_DEFINITIONS
            PRIVATE
                AZ_NUMERICCAST_ENABLED
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzFramework
                AZ::AzNetworking
                AZ::AzTestShared
                AZ::AzTest
    )

    o3de_add_googletest(
        NAME AZ::AzNetworking.Tests
        LABELS REQUIRES_tiaf
    )

    o3de_add_googletest(
        NAME AZ::AzNetworking.Tests.Sandbox
        TARGET AZ::AzNetworking.Tests
        TEST_SUITE sandbox
    )
    
endif()
