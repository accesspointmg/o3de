#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

#! o3de_append_cmake_file_list_to_ALLFILES: includes a cmake file list
#
# Includes a .cmake file that contains a variable "FILE" with the list of files
# The function appends the list of files to the variable ALLFILES. Callers of this
# function can include multiple cmake file list files and then use ALLFILES as the
# source for libraries/binaries/etc. Files that need to be excluded from unity builds
# due to possible ODR violations will need to be set in the variable 'SKIP_UNITY_BUILD_INCLUSION_FILES'
# in the same .cmake file (regardless of whether unity builds are enabled or not)
#
# The function takes care of appending the path relative to the cmake list file
#
# \arg:file cmake file list to include
#
function(o3de_append_cmake_file_list_to_ALLFILES file)
    set(UNITY_AUTO_EXCLUSIONS)

    include(${file})
    get_filename_component(file_path "${file}" PATH)
    if(file_path)
        foreach(f ${FILES})
            cmake_path(IS_RELATIVE f is_relative)
            if(is_relative)
                string(PREPEND f ${file_path}/)
                cmake_path(NORMAL_PATH f OUTPUT_VARIABLE f)
            endif()
            list(APPEND TRANSFORMED_FILES ${f})
        endforeach()
        set(FILES ${TRANSFORMED_FILES})
    endif()

    foreach(f ${FILES})
        get_filename_component(absolute_path ${f} ABSOLUTE)
        if(NOT EXISTS ${absolute_path})
            message(SEND_ERROR "File ${absolute_path} referenced in ${file} not found")
        endif()

        # Automatically exclude any extensions marked for the current platform
        if (O3DE_PAL_TRAIT_BUILD_UNITY_EXCLUDE_EXTENSIONS)
            get_filename_component(file_extension ${f} LAST_EXT)
            if (${file_extension} IN_LIST O3DE_PAL_TRAIT_BUILD_UNITY_EXCLUDE_EXTENSIONS)
                list(APPEND UNITY_AUTO_EXCLUSIONS ${f})
            endif()
        endif()
    endforeach()

    list(APPEND FILES ${file}) # Add the _files.cmake to the list so it shows in the IDE

    if(file_path)
        foreach(f ${SKIP_UNITY_BUILD_INCLUSION_FILES})
            cmake_path(IS_RELATIVE f is_relative)
            if(is_relative)
                string(PREPEND f ${file_path}/)
                cmake_path(NORMAL_PATH f OUTPUT_VARIABLE f)
            endif()
            list(APPEND SKIP_UNITY_BUILD_INCLUSION_TRANSFORMED_FILES ${f})
        endforeach()
        set(SKIP_UNITY_BUILD_INCLUSION_FILES ${SKIP_UNITY_BUILD_INCLUSION_TRANSFORMED_FILES})
    endif()

    # Check if there are any files to exclude from unity groupings
    foreach(f ${SKIP_UNITY_BUILD_INCLUSION_FILES})
        get_filename_component(absolute_path ${f} ABSOLUTE)
        if(NOT EXISTS ${absolute_path})
            message(FATAL_ERROR "File ${absolute_path} for SKIP_UNITY_BUILD_INCLUSION_FILES referenced in ${file} not found")
        endif()
        if(NOT f IN_LIST FILES)
            list(APPEND FILES ${f})
        endif()
    endforeach()

    # Mark files tagged for unity build group exclusions for unity builds
    if (O3DE_UNITY_BUILD)
        set_source_files_properties(
            ${UNITY_AUTO_EXCLUSIONS}
            ${SKIP_UNITY_BUILD_INCLUSION_FILES}
            PROPERTIES 
                SKIP_UNITY_BUILD_INCLUSION ON
        )
    endif()

    set(ALLFILES ${ALLFILES} ${FILES} PARENT_SCOPE)
endfunction()

function(ly_include_cmake_file_list file)
    # Add a deprecation warning using this macro
    message(WARNING "ly_include_cmake_file_list is deprecated, use o3de_append_cmake_file_list_to_ALLFILES instead")
    o3de_append_cmake_file_list_to_ALLFILES(${file})
    # The o3de_append_cmake_file_list_to_ALLFILES function already sets ALLFILES in PARENT_SCOPE,
    # so we need to propagate it up one more level to the caller of this deprecated function
    set(ALLFILES ${ALLFILES} PARENT_SCOPE)
endfunction()

#! o3de_append_cmake_file_to_ALLFILES: appends a single file to ALLFILES
#
# Appends a single file to the ALLFILES variable with path normalization and validation.
# This is a simplified version of o3de_append_cmake_file_list_to_ALLFILES for single files.
# Unity build exclusions are handled automatically based on file extensions.
#
# The function takes care of normalizing the path and checking file existence.
#
# \arg:file single file path to append to ALLFILES
#
function(o3de_append_cmake_file_to_ALLFILES file)
    set(UNITY_AUTO_EXCLUSIONS)
    set(TRANSFORMED_FILE ${file})

    # Normalize relative paths to absolute paths based on current source directory
    cmake_path(IS_RELATIVE file is_relative)
    if(is_relative)
        cmake_path(ABSOLUTE_PATH file BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE TRANSFORMED_FILE)
        cmake_path(NORMAL_PATH TRANSFORMED_FILE)
    endif()

    # Validate file exists
    if(NOT EXISTS ${TRANSFORMED_FILE})
        message(FATAL_ERROR "File ${TRANSFORMED_FILE} not found")
    endif()

    # Check if file should be automatically excluded from unity builds based on extension
    if (O3DE_PAL_TRAIT_BUILD_UNITY_EXCLUDE_EXTENSIONS)
        get_filename_component(file_extension ${TRANSFORMED_FILE} LAST_EXT)
        if (${file_extension} IN_LIST O3DE_PAL_TRAIT_BUILD_UNITY_EXCLUDE_EXTENSIONS)
            list(APPEND UNITY_AUTO_EXCLUSIONS ${TRANSFORMED_FILE})
        endif()
    endif()

    # Mark file for unity build exclusion if automatically determined
    if (O3DE_UNITY_BUILD AND UNITY_AUTO_EXCLUSIONS)
        set_source_files_properties(
            ${TRANSFORMED_FILE}
            PROPERTIES 
                SKIP_UNITY_BUILD_INCLUSION ON
        )
    endif()

    # Append the normalized file to ALLFILES in parent scope
    set(ALLFILES ${ALLFILES} ${TRANSFORMED_FILE} PARENT_SCOPE)
endfunction()


#! o3de_source_groups_from_folders: creates source_group for files
#
# Uses the path to the files being passed to create source_groups for them.
#
# \arg:files list of files to create source_group for
#
function(o3de_source_groups_from_folders files)
    foreach(file IN LISTS files)
        if(IS_ABSOLUTE ${file})
            file(RELATIVE_PATH file ${CMAKE_CURRENT_SOURCE_DIR} ${file})
        endif()
        get_filename_component(file_path "${file}" PATH)
        string(REPLACE "/" "\\" file_filters "${file_path}")
        source_group("${file_filters}" FILES "${file}")
    endforeach()
endfunction()

function(ly_source_groups_from_folders files)
    # Add a deprecation warning using this macro
    message(WARNING "ly_source_groups_from_folders is deprecated, use o3de_source_groups_from_folders instead")
    o3de_source_groups_from_folders(${files})
endfunction()

#! o3de_update_platform_settings: Function to generate a config-parsable file for cmake-project generation settings
#
# This generate a platform-specific, parsable config file that will live in the build directory specified during
# the cmake project generation. This will provide a bridge to non-cmake tools to read the platform-specific cmake
# project generation settings.
#
get_property(O3DE_PROJECTS_NAME GLOBAL PROPERTY O3DE_PROJECTS_NAME)
function(o3de_update_platform_settings)
    # Update the <platform>.last file to keep track of the recent build_dir
    set(o3de_platform_last_path "${CMAKE_BINARY_DIR}/platform.settings")
    string(TIMESTAMP o3de_last_generation_timestamp "%Y-%m-%dT%H:%M:%S")

    file(WRITE ${o3de_platform_last_path} "# Auto Generated from last cmake project generation (${o3de_last_generation_timestamp})

[settings]
platform=${O3DE_PAL_PLATFORM_NAME}
game_projects=${O3DE_PROJECTS_NAME}
asset_deploy_mode=${O3DE_ASSET_DEPLOY_MODE}
asset_deploy_type=${O3DE_ASSET_DEPLOY_ASSET_TYPE}
override_pak_root=${O3DE_ASSET_OVERRIDE_PAK_FOLDER_ROOT}
")
endfunction()

function(ly_update_platform_settings)
    # Add a deprecation warning using this macro
    message(WARNING "ly_update_platform_settings is deprecated, use o3de_update_platform_settings instead")
    o3de_update_platform_settings()
endfunction()


#! o3de_file_read: wrap to file(READ) that adds the file to configuration tracking
#
# file(READ) does not add file tracking. So changes to the file being read will not cause a cmake regeneration
#
function(o3de_file_read path content)
    unset(file_content)
    file(READ ${path} file_content)
    set(${content} ${file_content} PARENT_SCOPE)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${path})
endfunction()

function(ly_file_read path content)
    # Add a deprecation warning using this macro
    message(WARNING "ly_file_read is deprecated, use o3de_file_read instead")
    o3de_file_read(${path} ${content})
endfunction()

#! o3de_get_last_path_segment_concat_sha256 : Concatenates the last path segment of the absolute path
# with the first 8 characters of the absolute path SHA256 hash to make a unique relative path segment
function(o3de_get_last_path_segment_concat_sha256 absolute_path output_path)
    string(SHA256 target_source_hash ${absolute_path})
    string(SUBSTRING ${target_source_hash} 0 8 target_source_hash)
    cmake_path(GET absolute_path FILENAME last_path_segment)
    cmake_path(SET last_path_segment_sha256_path "${last_path_segment}-${target_source_hash}")

    set(${output_path} ${last_path_segment_sha256_path} PARENT_SCOPE)
endfunction()

function(ly_get_last_path_segment_concat_sha256 absolute_path output_path)
    # Add a deprecation warning using this macro
    message(WARNING "ly_get_last_path_segment_concat_sha256 is deprecated, use o3de_get_last_path_segment_concat_sha256 instead")
    o3de_get_last_path_segment_concat_sha256(${absolute_path} ${output_path})
endfunction()

#! o3de_get_root_subdirectory_which_is_parent: Locates the root source directory added the input directory
#  as a subdirectory of the build, which an actual prefix of the input directory
#  This is done by recursing through the PARENT_DIRECTORY "DIRECTORY" property
#  The use for this is to locate the top most directory which called add_subdirectory from any input path
#  i.e Given an
#  O3DE_ENGINE_PATH = D:\o3de
#  EXTERNAL_SUBDIRS = [D:\TestGem, D:\o3de\Gems\MyGem]
#  The O3DE_ENGINE_PATH is responsible for invoking add_subdirectory on the external subdirectories
#  so it in the PARENT_DIRECTORY property, of the subdirectory, though it might not be an actual "parent"
#  If the input path to this function is D:\TestGem\Code, then the return value is D:\TestGem
#  If the input path to this function is D:\o3de\Gems\MyGem, then the return value is D:\o3de

# \arg:absolute_path - directory to locate top most parent "subdirectory", which is an "parent" of the input
# \return:output_path- top most parent subdirectory, which is actual parent(i.e a prefix)
function(o3de_get_root_subdirectory_which_is_parent absolute_path output_path)
    # Walk up the parent add_subdirectory calls until a parent directory which is not a prefix of the target directory
    # is found
    cmake_path(SET candidate_path ${absolute_path})
    get_property(parent_subdir DIRECTORY ${candidate_path} PROPERTY PARENT_DIRECTORY)
    cmake_path(IS_PREFIX parent_subdir ${candidate_path} is_parent_subdir)
    while(parent_subdir AND is_parent_subdir)
        cmake_path(SET candidate_path "${parent_subdir}")
        get_property(parent_subdir DIRECTORY ${candidate_path} PROPERTY PARENT_DIRECTORY)
        cmake_path(IS_PREFIX parent_subdir ${candidate_path} is_parent_subdir)
    endwhile()

    message(DEBUG "Root subdirectory of path \"${absolute_path}\" is \"${candidate_path}\"")
    set(${output_path} ${candidate_path} PARENT_SCOPE)
endfunction()

function(ly_get_root_subdirectory_which_is_parent absolute_path output_path)
    # Add a deprecation warning using this macro
    message(WARNING "ly_get_root_subdirectory_which_is_parent is deprecated, use o3de_get_root_subdirectory_which_is_parent instead")
    o3de_get_root_subdirectory_which_is_parent(${absolute_path} ${output_path})
endfunction()

#! o3de_get_engine_relative_source_dir: Attempts to form a path relative to the BASE_DIRECTORY.
#  If that fails the last path segment of the absolute_target_source_dir concatenated with a SHA256 hash to form a target directory
# \arg:BASE_DIRECTORY - Directory to base relative path against. Defaults to O3DE_ENGINE_PATH
function(o3de_get_engine_relative_source_dir absolute_target_source_dir output_source_dir)
    set(options)
    set(oneValueArgs BASE_DIRECTORY)
    set(multiValueArgs)
    cmake_parse_arguments(o3de_get_engine_relative_source_dir "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    if(NOT o3de_get_engine_relative_source_dir_BASE_DIRECTORY)
        set(o3de_get_engine_relative_source_dir_BASE_DIRECTORY ${O3DE_ENGINE_PATH})
    endif()

    # Get a relative target source directory to the O3DE root folder if possible
    # Otherwise use the top most source directory which led to calling add_subdirectory on the input directory
    o3de_get_root_subdirectory_which_is_parent(${absolute_target_source_dir} root_subdir_of_target)
    cmake_path(RELATIVE_PATH absolute_target_source_dir BASE_DIRECTORY ${root_subdir_of_target} OUTPUT_VARIABLE relative_target_source_dir)

    cmake_path(IS_PREFIX O3DE_ENGINE_PATH ${absolute_target_source_dir} is_target_source_dir_subdirectory_of_engine)
    if(NOT is_target_source_dir_subdirectory_of_engine)
        cmake_path(GET root_subdir_of_target FILENAME root_subdir_dirname)
        set(relative_subdir ${relative_target_source_dir})
        unset(relative_target_source_dir)
        cmake_path(APPEND relative_target_source_dir "External" ${root_subdir_dirname} ${relative_subdir})
    endif()

    set(${output_source_dir} ${relative_target_source_dir} PARENT_SCOPE)
endfunction()

function(ly_get_engine_relative_source_dir absolute_target_source_dir output_source_dir)
    # Add a deprecation warning using this macro
    message(WARNING "ly_get_engine_relative_source_dir is deprecated, use o3de_get_engine_relative_source_dir instead")
    o3de_get_engine_relative_source_dir(${absolute_target_source_dir} ${output_source_dir} ${ARGN})
endfunction()
