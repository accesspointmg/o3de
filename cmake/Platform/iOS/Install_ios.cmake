#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_iOS_Install_ios_cmake ${CMAKE_CURRENT_LIST_DIR})
include(${_cmake_Platform_iOS_Install_ios_cmake}/../Common/Install_common.cmake)

#! o3de_setup_target_install_targets_override: iOS specific target installation
function(o3de_setup_target_install_targets_override)

    set(options)
    set(oneValueArgs TARGET ARCHIVE_DIR LIBRARY_DIR RUNTIME_DIR LIBRARY_SUBDIR RUNTIME_SUBDIR)
    set(multiValueArgs)
    cmake_parse_arguments(o3de_platform_install_target "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # For bundles on iOS(/Mac), we set the icons by passing in a path to the Images.xcassets directory.
    # However, the CMake install command expects paths to files for the the RESOURCE property.
    # More details can be found in the CMake issue: https://gitlab.kitware.com/cmake/cmake/-/issues/22409
    get_target_property(is_bundle ${o3de_platform_install_target_TARGET} MACOSX_BUNDLE)
    if (${is_bundle})
        get_target_property(cached_resources_dir ${o3de_platform_install_target_TARGET} RESOURCE)
        set_property(TARGET ${o3de_platform_install_target_TARGET} PROPERTY RESOURCE "")
    endif()
    
    foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
        string(TOUPPER ${conf} UCONF)
        o3de_install(TARGETS ${TARGET_NAME}
            ARCHIVE
                DESTINATION ${o3de_platform_install_target_ARCHIVE_DIR}
                COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                CONFIGURATIONS ${conf}
            LIBRARY
                DESTINATION ${o3de_platform_install_target_LIBRARY_DIR}/${o3de_platform_install_target_LIBRARY_SUBDIR}
                COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                CONFIGURATIONS ${conf}
            RUNTIME
                DESTINATION ${o3de_platform_install_target_RUNTIME_DIR}/${o3de_platform_install_target_RUNTIME_SUBDIR}
                COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                CONFIGURATIONS ${conf}
            BUNDLE
                DESTINATION ${o3de_platform_install_target_RUNTIME_DIR}/${o3de_platform_install_target_RUNTIME_SUBDIR}
                COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                CONFIGURATIONS ${conf}
            RESOURCE
                DESTINATION ${o3de_platform_install_target_RUNTIME_DIR}/${o3de_platform_install_target_RUNTIME_SUBDIR}
                COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                CONFIGURATIONS ${conf}
            FRAMEWORK
                DESTINATION ${o3de_platform_install_target_RUNTIME_DIR}/${o3de_platform_install_target_RUNTIME_SUBDIR}
                COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                CONFIGURATIONS ${conf}
        )
    endforeach()

    if (${is_bundle})
        set_property(TARGET ${o3de_platform_install_target_TARGET} PROPERTY RESOURCE ${cached_resources_dir})
    endif()
    
endfunction()

function(o3de_setup_target_install_targets_override)
    # This function is deprecated, use o3de_setup_target_install_targets_override instead
    message(WARNING "o3de_setup_target_install_targets_override is deprecated, use o3de_setup_target_install_targets_override instead")
    o3de_setup_target_install_targets_override(${ARGN})
endfunction()