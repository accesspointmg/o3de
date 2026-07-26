#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_iOS_O3deWrappers_ios_cmake ${CMAKE_CURRENT_LIST_DIR})
include(${_cmake_Platform_iOS_O3deWrappers_ios_cmake}/../Common/O3deWrappers_default.cmake)

function(o3de_apply_platform_properties target)
    get_target_property(target_type ${target} TYPE)

    if(${target_type} STREQUAL "SHARED_LIBRARY")
        # Some projects use an "_" in their target name which is not allowed in a bundle identifier
        get_target_property(target_name ${target} NAME)
        string(REPLACE "_" "." target_name ${target_name})
        
        set_target_properties(${target}
            PROPERTIES
            FRAMEWORK TRUE
            MACOSX_FRAMEWORK_IDENTIFIER "org.o3de.lib.${target_name}"
            XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "org.o3de.lib.${target_name}"
            XCODE_ATTRIBUTE_SKIP_INSTALL "YES"
        )
    endif()

    if(${target_type} STREQUAL "EXECUTABLE")
        set_target_properties(${target}
            PROPERTIES
            XCODE_ATTRIBUTE_SKIP_INSTALL "NO"
            XCODE_ATTRIBUTE_INSTALL_PATH "$(LOCAL_APPS_DIR)"
            XCODE_ATTRIBUTE_COPY_PHASE_STRIP "NO"
        )
    endif()
endfunction()

function(o3de_apply_platform_properties target)
    # This function is deprecated, use o3de_apply_platform_properties instead
    message(WARNING "o3de_apply_platform_properties is deprecated, use o3de_apply_platform_properties instead")
    o3de_apply_platform_properties(${target})
endfunction()