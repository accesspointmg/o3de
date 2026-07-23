#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_Mac_O3deWrappers_mac_cmake ${CMAKE_CURRENT_LIST_DIR})
include(${_cmake_Platform_Mac_O3deWrappers_mac_cmake}/../Common/O3deWrappers_default.cmake)

set(O3DE_ENABLE_HARDENED_RUNTIME OFF CACHE BOOL "Enable hardened runtime capability for Mac builds. This should be ON when building the engine for notarization/distribution.")

define_property(TARGET PROPERTY ENTITLEMENT_FILE_PATH
    BRIEF_DOCS "Path to the entitlement file"
    FULL_DOCS [[
        On Mac, entitlements are used to grant certain privileges
        to applications at runtime. Use this property to specify the
        path to a .plist file containing entitlements.
    ]]
)

function(o3de_apply_platform_properties target)

    set_target_properties(${target} PROPERTIES
        BUILD_RPATH "@executable_path;@executable_path/../Frameworks"
        INSTALL_RPATH "@executable_path;@executable_path/../Frameworks"
    )

    get_property(is_imported TARGET ${target} PROPERTY IMPORTED)
    if((NOT is_imported) AND (O3DE_ENABLE_HARDENED_RUNTIME))
        get_property(target_type TARGET ${target} PROPERTY TYPE)
        set(runtime_types_list "MODULE_LIBRARY" "SHARED_LIBRARY" "EXECUTABLE")
        if (target_type IN_LIST runtime_types_list)
            set_target_properties(${target} PROPERTIES
                XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
                XCODE_ATTRIBUTE_CODE_SIGN_INJECT_BASE_ENTITLEMENTS NO
            )
        endif()
    endif()

endfunction()

function(o3de_apply_platform_properties target)
    message(WARNING "o3de_apply_platform_properties is deprecated, use o3de_apply_platform_properties instead")
    o3de_apply_platform_properties(${target})
endfunction()

function(o3de_handle_custom_output_directory target output_subdirectory)

    if(output_subdirectory)
        set_target_properties(${target} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${output_subdirectory}
            LIBRARY_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${output_subdirectory}
        )

        foreach(conf ${CMAKE_CONFIGURATION_TYPES})
            string(TOUPPER ${conf} UCONF)
            set_target_properties(${target} PROPERTIES
                RUNTIME_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${UCONF}}/${output_subdirectory}
                LIBRARY_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${UCONF}}/${output_subdirectory}
            )
        endforeach()

    endif()

endfunction()

function(o3de_handle_custom_output_directory target output_subdirectory)
    message(WARNING "o3de_handle_custom_output_directory is deprecated, use o3de_handle_custom_output_directory instead")
    o3de_handle_custom_output_directory(${target} ${output_subdirectory})
endfunction()

#! o3de_add_bundle_resources: add resource files to the current bundle application (if any) in the bundle's resource folder
#  if a bundle is specified for the supporting platform.
#
# \arg:FILES files to copy to the resources
#
function(o3de_add_bundle_resources)

    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs FILES)

    cmake_parse_arguments(o3de_add_bundle_resources "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input arguments
    if(NOT o3de_add_bundle_resources_TARGET)
        message(FATAL_ERROR "You must provide a TARGET")
    endif()

    if(NOT o3de_add_bundle_resources_FILES)
        message(FATAL_ERROR "You must provide at least a file to copy")
    endif()

    if (TARGET ${o3de_add_bundle_resources_TARGET})

        set(destination_location $<TARGET_BUNDLE_CONTENT_DIR:${o3de_add_bundle_resources_TARGET}>/Resources)

        foreach(file ${o3de_add_bundle_resources_FILES})

            get_filename_component(filename ${file} NAME)
            add_custom_command(
                TARGET ${o3de_add_bundle_resources_TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${destination_location}
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${file} ${destination_location}
                DEPENDS ${file}
                VERBATIM
                COMMENT "Copying ${file} to Resources..."
            )

        endforeach()

    endif()

endfunction()

function(o3de_add_bundle_resources)
    message(WARNING "o3de_add_bundle_resources is deprecated, use o3de_add_bundle_resources instead")
    o3de_add_bundle_resources(${ARGN})
endfunction()
