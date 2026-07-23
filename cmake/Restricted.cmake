#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

#! o3de_pal_path: Resolves Platform Abstraction Layer (PAL) directory paths for O3DE objects from where
# the platform file should be to where it really is
#
# This function handles the resolution of PAL-specific file paths by checking if a platform-specific
# version of a file exists in the restricted overlay structure. If the input path doesn't exist,
# it attempts to construct a PAL path by looking for "Platform" directories in the path hierarchy
# and checking for platform-specific versions in restricted directories.
#
# The function supports the O3DE PAL structure where platform-specific files are organized as:
# <object_path>/Platform/<platform_name>/<relative_path>
# or in restricted overlay paths:
# <restricted_path>/<platform_name>/<relative_path>/<pre_platform_path>
#
# \arg:path_to_where_the_platform_file_should_be - Input path to resolve (may not exist, triggering PAL resolution)
# \arg:path_to_where_the_platform_file_really_is - Output variable name to store the resolved absolute path
#
# \return: Sets path_to_where_the_platform_file_really_is to the resolved absolute path.
#
# Note: If PAL resolution fails or input exists, returns the original input path made absolute.
#
# Example call to resolve where jasper.cpp:
# object_json_path = C:/github/byrcolin/o3de/AutomatedTesting/project.json
# path_to_where_the_platform_file_should_be = C:/github/byrcolin/o3de/AutomatedTesting/Platform/Jasper/jasper.cpp
# 1. C:/github/byrcolin/o3de/AutomatedTesting/Platform/Jasper/jasper.cpp doesn't exist, so it will try to resolve the PAL path
# 2. we start at the restricted_path_to_where_the_platform_file_should_be and find the closest object path. We do that
# by removing the last component of the path and trying the different object types until we find one that exists.
# object_path = C:/github/byrcolin/o3de/AutomatedTesting
# 3. call o3de_pal_path_object_json to find the PAL path
function(o3de_pal_path path_to_where_the_platform_file_should_be path_to_where_the_platform_file_really_is)
    # 1. if the path_to_where_the_platform_file_should_be exists, then we use it
    if (EXISTS ${path_to_where_the_platform_file_should_be})
        set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
        return()
    endif()

    #2. find the closest object_path starting at the restricted_path_to_where_the_platform_file_should_be and find the
    cmake_path(GET path_to_where_the_platform_file_should_be PARENT_PATH candidate_path)

    #set the list of types to try on the candidate_path
    set(candidate_types "engine.json" "project.json" "gem.json" "template.json" "repo.json")

    #while the candidate_path is not empty
    set(found_object_json FALSE)
    while(NOT candidate_path STREQUAL "" AND NOT found_object_json)
        # loop through the candidate_types and check if the file exists
        foreach(candidate_type ${candidate_types})
            # append the candidate_type to the candidate_path
            cmake_path(APPEND candidate_path ${candidate_type} OUTPUT_VARIABLE test_json_path)
            if (EXISTS ${test_json_path})
                # if we found an object_json_path, we break out of the loop
                set(object_json_path ${test_json_path})
                set(found_object_json TRUE)
                break()
            endif()
        endforeach()
        # try the parent path (only if we haven't found the object json);
        # stop at the filesystem root where parent equals current
        if(NOT found_object_json)
            cmake_path(GET candidate_path PARENT_PATH parent_path)
            if(parent_path STREQUAL candidate_path)
                break()
            endif()
            set(candidate_path ${parent_path})
        endif()
    endwhile()

    # 3. If we don't find one then we just return the original path
    if(NOT object_json_path)
        # If no candidate path was found, we just return the original path and let it fail
        set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
        return()
    endif()

    o3de_pal_path_object_json(${object_json_path} ${path_to_where_the_platform_file_should_be} pal_path)
    set(${path_to_where_the_platform_file_really_is} ${pal_path} PARENT_SCOPE)
endfunction()

#! o3de_pal_dir: upstream-compatible PAL directory resolution.
#
# Object CMakeLists (gems/projects) call
#   o3de_pal_dir(out_dir <dir> "${restricted_path}" "${object_path}" "${parent_relative_path}")
# The restricted/object/parent args are optional legacy parameters —
# restricted objects are superseded by overlays (applied at workspace
# compose time), so this simply resolves through o3de_pal_path.
function(o3de_pal_dir out_dir in_dir)
    o3de_pal_path(${in_dir} resolved_dir)
    set(${out_dir} ${resolved_dir} PARENT_SCOPE)
endfunction()

#! o3de_pal_path_object_json: Resolves Platform Abstraction Layer (PAL) directory paths for O3DE objects given a object JSON path
#
# This function handles the resolution of PAL-specific file paths by checking if a platform-specific
# version of a file exists in the restricted overlay structure. If the input path doesn't exist,
# it attempts to construct a PAL path by looking for "Platform" directories in the path hierarchy
# and checking for platform-specific versions in restricted directories.
#
# The function supports the O3DE PAL structure where platform-specific files are organized as:
# <object_path>/Platform/<platform_name>/<relative_path>
# or in restricted overlay paths:
# <restricted_path>/<platform_name>/<relative_path>/<pre_platform_path>
#
# \arg:object_json_path - The path to the object JSON file (e.g., a project.json or engine.json, etc)
# \arg:path_to_where_the_platform_file_should_be - Input path to resolve (may not exist, triggering PAL resolution)
# \arg:path_to_where_the_platform_file_really_is - Output variable name to store the resolved absolute path
#
# \return: Sets path_to_where_the_platform_file_really_is to the resolved absolute path.
#
# Note: If PAL resolution fails or input exists, returns the original input path made absolute.
#
# Example call to resolve where jasper.cpp:
# object_json_path = C:/github/byrcolin/o3de/AutomatedTesting/project.json
# path_to_where_the_platform_file_should_be = C:/github/byrcolin/o3de/AutomatedTesting/Platform/Jasper/jasper.cpp
# 1. C:/github/byrcolin/o3de/AutomatedTesting/Platform/Jasper/jasper.cpp doesn't exist, so it will try to resolve the PAL path
# 2. we start at the restricted_path_to_where_the_platform_file_should_be and find the closest object path. We do that
# by removing the last component of the path and trying the different object types until we find one that exists.
# object_path = C:/github/byrcolin/o3de/AutomatedTesting
# 3. if we don't find the object_path, then we just return the original path and let it fail.
# 4. get this objects 'restricteds' json data from the global property O3DE_PATH_C:/github/byrcolin/o3de/AutomatedTesting/project.json_RESTRICTEDS =
#[
#    {
#        "restricted_precedence": 20,
#        "restricted_object_json_path": "F:/github/byrcolin/o3de/engine.json",
#        "restricted_json_path": "C:/Users/colin/O3DE/Restricteds/Engines/org.o3de.restricted.o3de2/restricted.json"
#    },
#    {
#        "restricted_precedence": 10,
#        "restricted_object_json_path": "F:/github/byrcolin/o3de/AutomatedTesting/project.json",
#        "restricted_json_path": "C:/Users/colin/O3DE/Restricteds/Projects/org.o3de.restricted.automatedtesting/restricted.json"
#    },
#    {
#        "restricted_precedence": 10,
#        "restricted_object_json_path": "F:/github/byrcolin/o3de/engine.json",
#        "restricted_json_path": "C:/Users/colin/O3DE/Restricteds/Engines/org.o3de.restricted.o3de/restricted.json"
#    }
#]
# which is an array of restricted objects that COULD have the file we are looking for.
# Note that a parent object can have a restricted object that applies to all its children.
# So in this case we see that there are 3 restricted objects, 1 that applies directly to this project and 2 that apply to its
# parent the engine object.
# Note that restricted_object_json_path is the object the restricted object is applied to,
# and restricted_json_path is the restricted json file that is being applied.
# This is important because all files in the restricted objects are relative to the object they are applied to's root.
# Also note that the list is sorted in precedence order, and will be searched in descending order and the first match wins.
# So even if a match would occur in lower precedence objects, a later restricted object will not be used if a match occurs
# in an earlier restricted object.
# Now that we know that, we loop over the restricteds:
# 5. we extract the restricted_object_json_path and restricted_json_path from each restricted entry
# "restricted_object_json_path": "C:/github/byrcolin/o3de/engine.json",
# "restricted_json_path": "C:/Users/colin/O3DE/Restricteds/Engines/org.o3de.restricted.o3de2/restricted.json"
# we check if this restricted_json_path exists, if it does not so we continue to the next restricted object.
# we cut off the file portion of the restricted_json_path to get the restricted_path
# we cut off the file portion of the restricted_object_json_path to get the restricted_object_path
# "restricted_object_path": "C:/github/byrcolin/o3de",
# "restricted_path": "C:/Users/colin/O3DE/Restricteds/Engines/org.o3de.restricted.o3de2"
# 6. we need to get the relative portion of the path to the file they asked us to look for, so that means we need to remove
# the restricted_object_path from the requested path
# restricted_object_path =                      C:/github/byrcolin/o3de
# path_to_where_the_platform_file_should_be =   C:/github/byrcolin/o3de/AutomatedTesting/Platform/Jasper/jasper.cpp
# relative_path = AutomatedTesting/Platform/Jasper/jasper.cpp
# 7. This relative_path string should ALWAYS have a 'Platform' component in it and we want to find that and split there
# to get the pre_platform_path and post_platform_path
# pre_platform_path = AutomatedTesting
# post_platform_path = Jasper/jasper.cpp
# 8. The first component of post_platform_path should be the platform name, so we can split that out platform
# 9. we now have all the possible components to construct the PAL path
# restricted_path = C:/github/byrcolin/restricted/engine/o3de    this should be the root path to where the PAL files are located for this object so
# pal_path = C:/github/byrcolin/restricted/engine/o3de
# then we need to add the platform name
# pal_path = C:/github/byrcolin/restricted/engine/o3de/Jasper
# and then the pre_platform_path
# pal_path = C:/github/byrcolin/restricted/engine/o3de/Jasper/AutomatedTesting
# and finally the post_platform_path
# pal_path = C:/github/byrcolin/restricted/engine/o3de/Jasper/AutomatedTesting/Jasper/jasper.cpp
# if that pal_path exists, then we set the path_to_where_the_platform_file_really_is in the parent scope to that path
# else loop to the next restricted object
# if we run out of restricteds, then we just return the original path_to_where_the_platform_file_should_be which will
# certainly fail to exist, but it will be the path that the user asked for. 
function(o3de_pal_path_object_json object_json_path path_to_where_the_platform_file_should_be path_to_where_the_platform_file_really_is)
    # 1. if the path_to_where_the_platform_file_should_be exists, then we use it
    if (EXISTS ${path_to_where_the_platform_file_should_be})
        set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
        return()
    endif()

    #2. make sure the object_path is prefix of the path_to_where_the_platform_file_should_be
    cmake_path(GET object_json_path PARENT_PATH object_path)
    cmake_path(IS_PREFIX object_path ${path_to_where_the_platform_file_should_be} is_prefix)
    if(NOT is_prefix)
        # If the object_path is not a prefix, we just return the original path
        set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
        return()
    endif()

    # 3. Get the objects restricted_json_paths
    get_property(restricteds GLOBAL PROPERTY O3DE_PATH_${object_json_path}_RESTRICTEDS)

    # loop through the restricteds and find the first one that exists
    foreach(restricted ${restricteds})
        # 5. extract the "restricted_object_json_path" and "restricted_json_path"
        string(JSON restricted_object_json_path GET ${restricted} "restricted_object_json_path")
        string(JSON restricted_json_path GET ${restricted} "restricted_json_path")

        # if either restricted_json_path or restricted_object_json_path doesn't exist, we skip it
        if(NOT EXISTS ${restricted_json_path} OR NOT EXISTS ${restricted_object_json_path})
            continue()
        endif()

        # remove the file portion of the restricted_json_path to get the restricted_path
        cmake_path(GET restricted_json_path PARENT_PATH restricted_path)
        # remove the file portion of the restricted_object_json_path to get the restricted_object_path
        cmake_path(GET restricted_object_json_path PARENT_PATH restricted_object_path)

        # 6. Set the relative_path to the relative object path = path_to_where_the_platform_file_should_be - restricted_path
        cmake_path(RELATIVE_PATH path_to_where_the_platform_file_should_be BASE_DIRECTORY "${restricted_object_path}" OUTPUT_VARIABLE relative_path)

        # 7. Find the "Platform" component and split there
        cmake_path(NORMAL_PATH relative_path OUTPUT_VARIABLE normalized_path)
        string(FIND "${normalized_path}" "Platform/" platform_pos)
        if (platform_pos EQUAL -1)
            continue()
        else()
            # Extract the Path Before "Platform" which starts at platform_pos 
            string(SUBSTRING "${normalized_path}" 0 "${platform_pos}" pre_platform_path)

            # Remove trailing slash from pre_platform_path if it exists
            string(LENGTH "${pre_platform_path}" pre_platform_path_length)
            if(pre_platform_path_length GREATER 0)
                math(EXPR last_char_pos "${pre_platform_path_length} - 1")
                string(SUBSTRING "${pre_platform_path}" ${last_char_pos} 1 last_char)
                if(last_char STREQUAL "/")
                    string(SUBSTRING "${pre_platform_path}" 0 ${last_char_pos} pre_platform_path)
                endif()
            endif()            

            # Extract the Path After "Platform/"
            math(EXPR start_after_platform "${platform_pos} + 9") # 9 is length of "Platform/"
            string(SUBSTRING "${normalized_path}" "${start_after_platform}" -1 post_platform_path)
        endif()

        # 8. The first component of post_platform_path should be the platform name,
        # so we can split that out to platform and remove the platform name from post_platform_path
        string(FIND "${post_platform_path}" "/" first_separator_pos)
        if (first_separator_pos EQUAL -1)
            set(platform ${post_platform_path})
            set(post_platform_path_without_first_component "")
        else()
            # Extract the first component (platform name)
            string(SUBSTRING "${post_platform_path}" 0 ${first_separator_pos} platform)
            
            # Extract the remaining path
            # If the path starts with '/', the second '/' needs to be found
            if (first_separator_pos EQUAL 0)
                string(SUBSTRING "${post_platform_path}" 1 -1 temp_path) # Remove the leading '/'
                string(FIND "${temp_path}" "/" second_separator_pos)
                if (second_separator_pos EQUAL -1)
                    # Only one component after the root slash (e.g., "/dir")
                    set(platform ${temp_path})
                    set(post_platform_path_without_first_component "")
                else()
                    string(SUBSTRING "${temp_path}" 0 ${second_separator_pos} platform)
                    math(EXPR start_pos "${second_separator_pos} + 1")
                    string(SUBSTRING "${temp_path}" "${start_pos}" -1 post_platform_path_without_first_component)
                endif()
            else()
                # Path does not start with '/', so the first separator is between components
                math(EXPR start_pos "${first_separator_pos} + 1")
                string(SUBSTRING "${post_platform_path}" "${start_pos}" -1 post_platform_path_without_first_component)
            endif()
        endif()

        # 9. Compose the pal_path using list append and then join
        set(pal_path_components ${restricted_path})
        if(platform AND NOT platform STREQUAL "")
            list(APPEND pal_path_components ${platform})
        endif()
        if(pre_platform_path AND NOT pre_platform_path STREQUAL "")
            list(APPEND pal_path_components ${pre_platform_path})
        endif()
        if(post_platform_path_without_first_component AND NOT post_platform_path_without_first_component STREQUAL "")
            list(APPEND pal_path_components ${post_platform_path_without_first_component})
        endif()
        string(JOIN "/" pal_path ${pal_path_components})
        
        if(EXISTS ${pal_path})
            # If the PAL path exists, set the output variable to this path
            # This is the path where the platform-specific file really is
            set(${path_to_where_the_platform_file_really_is} ${pal_path} PARENT_SCOPE)
            return()
        endif()
    endforeach()

    #if we get here, then we didn't find a PAL path that exists
    # so we just return the original path_to_where_the_platform_file_should_be
    set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
endfunction()
