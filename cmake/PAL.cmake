#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# PAL allows us to deal with platforms in a flexible way. In order to do that, we need
# to be able to refer to the current platform in a generic way.
# This cmake file provides variables and configurations for the current platform

# Initialize O3DE platform mappings
# These can be extended by restricted.json files or other configuration

#! o3de_add_pal_platform_name: Add a platform name to the global list of supported platforms
#
# \arg:platform_name - The platform name to add to the global list
#
function(o3de_add_pal_platform_name platform_name)
    get_property(current_platforms GLOBAL PROPERTY O3DE_ALL_PAL_PLATFORM_NAMES)
    list(APPEND current_platforms "${platform_name}")
    list(REMOVE_DUPLICATES current_platforms)
    set_property(GLOBAL PROPERTY O3DE_ALL_PAL_PLATFORM_NAMES "${current_platforms}")
endfunction()

#! o3de_add_pal_platform_mapping: Add a new platform mapping to the system
#
# This function allows adding new platform mappings at runtime. This is useful for
# adding support for new platforms or aliases without modifying the core function.
#
# \arg:mapping_string - Single string containing "input_name:output_name"
#                      where input_name is the platform name (case-insensitive) and 
#                      output_name is the CMake platform name
#
# Example usage:
#   o3de_add_pal_platform_mapping("steamdeck:Lancaster")
#   o3de_add_pal_platform_mapping("ps5:Paris")
#
function(o3de_add_pal_platform_mapping mapping_string)
    # Check if this mapping already exists to avoid duplicates
    get_property(current_mappings GLOBAL PROPERTY O3DE_PLATFORM_MAP)
    foreach(mapping ${current_mappings})
        if(mapping_string STREQUAL mapping)
            # Mapping already exists, skip adding
            return()
        endif()
    endforeach()
    
    # Parse the mapping string - only match colon format
    if(NOT mapping_string MATCHES "^([^:]+):([^:]+)$")
        message(WARNING "o3de_add_platform_mapping: Invalid mapping format '${mapping_string}'. Expected 'input:output'")
        return()
    endif()
    
    list(APPEND current_mappings "${mapping_string}")
    set_property(GLOBAL PROPERTY O3DE_PLATFORM_MAP "${current_mappings}")
endfunction()

#! o3de_add_pal_platform_wart_mapping: Add a new platform wart mapping to the system
#
# This function allows adding new platform wart mappings at runtime. This is useful for
# adding support for new platforms or aliases without modifying the core function.
#
# \arg:mapping_string - Single string containing "input_name:wart_name"
#                      where input_name is the platform name (case-insensitive) and 
#                      wart_name is the lowercase platform wart
#
# Example usage:
#   o3de_add_pal_platform_wart_mapping("steamdeck:lancaster")
#   o3de_add_pal_platform_wart_mapping("ps5:paris")
#   o3de_add_pal_platform_wart_mapping("xboxseriesx:durango")
#
function(o3de_add_pal_platform_wart_mapping mapping_string)
    # Check if this mapping already exists to avoid duplicates
    get_property(current_mappings GLOBAL PROPERTY O3DE_PLATFORM_WART_MAP)
    foreach(mapping ${current_mappings})
        if(mapping_string STREQUAL mapping)
            # Mapping already exists, skip adding
            return()
        endif()
    endforeach()

    # Parse the mapping string - only match colon format
    if(NOT mapping_string MATCHES "^([^:]+):([^:]+)$")
        message(WARNING "o3de_add_platform_wart_mapping: Invalid mapping format '${mapping_string}'. Expected 'input:wart'")
        return()
    endif()
    
    list(APPEND current_mappings "${mapping_string}")
    set_property(GLOBAL PROPERTY O3DE_PLATFORM_WART_MAP "${current_mappings}")
endfunction()

#! o3de_pal_platform_name_to_cmake_platform_name: Converts O3DE platform names to standardized CMake platform names
#
# This function provides a mapping layer between O3DE's platform naming conventions and CMake's
# standardized platform names. It handles various aliases and naming variations to ensure consistent
# platform identification across the build system. Note that cmake does not have official platform names
# for all O3DE platforms, so this function provides a custom mapping.
#
# The function supports multiple input formats for each platform:
# - Full platform names (e.g., "Windows", "Mac", "PlayStation4")
# - Short aliases (e.g., "Win", "Mac")
# - Internal codenames (e.g., "Jasper" -> XboxOne, "Paris" -> PlayStation5, "Salem" -> NintendoSwitch)
# - Case-insensitive input (automatically converts to lowercase for comparison)
#
# \arg:o3de_platform_name - Input platform name in any supported format (case-insensitive)
# \arg:cmake_platform_name - Output variable name to store the standardized CMake platform name
#
# \return: Sets cmake_platform_name to the standardized platform name in the parent scope
#
function(o3de_pal_platform_name_to_cmake_platform_name o3de_platform_name cmake_platform_name)
    string(TOLOWER "${o3de_platform_name}" o3de_platform_name_lower)

    get_property(current_mappings GLOBAL PROPERTY O3DE_PLATFORM_MAP)

    # Search through the platform map
    foreach(mapping ${current_mappings})
        if(mapping MATCHES "^([^:]+):([^:]+)$")
            set(input_platform "${CMAKE_MATCH_1}")
            set(output_platform "${CMAKE_MATCH_2}")
            if(o3de_platform_name_lower STREQUAL input_platform)
                set(${cmake_platform_name} "${output_platform}" PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()
    
    # If no mapping found, return empty or original value
    set(${cmake_platform_name} "" PARENT_SCOPE)
endfunction()


#! o3de_pal_platform_name_wart: Converts O3DE platform names to lowercase platform wart used in files
#
# This function provides a mapping layer between O3DE's platform naming conventions and the lowercase 
# platform "wart" (suffix) used in platform-specific file naming throughout the codebase. Platform warts
# are short, lowercase identifiers appended to filenames to indicate platform-specific implementations.
#
# The function handles various aliases and naming variations to ensure consistent platform identification
# across the build system. It supports both official CMake platform names and O3DE's custom platform
# codenames for gaming consoles and specialized platforms.
#
# Platform warts are used in contexts such as:
# - Source files: "Achievements_jasper.cpp", "NetworkManager_mac.cpp"  
# - Header files: "Platform_windows.h", "Audio_ios.h"
#
# \arg:o3de_platform_name - Input platform name in any supported format (case-insensitive)
# \arg:wart - Output variable name to store the lowercase platform wart
#
# \return: Sets wart to the lowercase platform wart in the parent scope
#
# Example usage:
#   o3de_pal_platform_name_wart("XboxOne" wart)
#   # wart will be set to "jasper"
#   o3de_pal_platform_name_wart("Darwin" wart)
#   # wart will be set to "mac"
#
function(o3de_pal_platform_name_wart o3de_platform_name wart)
    string(TOLOWER "${o3de_platform_name}" o3de_platform_name_lower)

    get_property(current_wart_mappings GLOBAL PROPERTY O3DE_PLATFORM_WART_MAP)

    # Search through the platform wart map
    foreach(mapping ${current_wart_mappings})
        if(mapping MATCHES "^([^:]+):([^:]+)$")
            set(input_platform "${CMAKE_MATCH_1}")
            set(output_wart "${CMAKE_MATCH_2}")
            if(o3de_platform_name_lower STREQUAL input_platform)
                set(${wart} "${output_wart}" PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()
    
    # If no mapping found, return empty or original value
    set(${wart} "" PARENT_SCOPE)
endfunction()


