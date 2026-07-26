#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include_guard()

#! o3de_get_user_home_path: returns the home path
#
# \arg:o3de_manifest_path returns the path of the manifest
function(o3de_get_user_home_path o3de_home_path)
    # The o3de_manifest.json is in the home directory / .o3de folder
    file(TO_CMAKE_PATH "$ENV{USERPROFILE}" home_path) # Windows
    if(NOT EXISTS ${home_path})
        file(TO_CMAKE_PATH "$ENV{HOME}" home_path) # Unix
        if (NOT EXISTS ${home_path})
            message(FATAL_ERROR "o3de Home path not found")
        endif()
    endif()
    set(${o3de_home_path} ${home_path} PARENT_SCOPE)
endfunction()

#! o3de_get_manifest_path: returns the path to the manifest
# \arg:o3de_manifest_path returns the path of the manifest
function(o3de_get_manifest_path o3de_manifest_path)
    # The o3de_manifest.json is in the home directory / .o3de folder
    o3de_get_user_home_path(o3de_home_path)
    set(${o3de_manifest_path} ${o3de_home_path}/.o3de/o3de_manifest.json PARENT_SCOPE)
endfunction()

#! o3de_get_resolved_manifest_path: returns the path to the resolved manifest
# \arg:o3de_manifest_path returns the path of the manifest
#
# Resolution order:
# 1. O3DE_RESOLVED_MANIFEST cache/normal variable (set by workspace builds —
#    the workspace carries its own compose-time resolved manifest)
# 2. A resolved_o3de_manifest.json found walking up from CMAKE_SOURCE_DIR
#    (source dir inside a composed workspace)
# 3. The user-level ~/.o3de/resolved_o3de_manifest.json
function(o3de_get_resolved_manifest_path resolved_o3de_manifest_path)
    if(O3DE_RESOLVED_MANIFEST)
        set(${resolved_o3de_manifest_path} ${O3DE_RESOLVED_MANIFEST} PARENT_SCOPE)
        return()
    endif()

    # Walk up from the source dir looking for a workspace-scoped manifest
    set(search_dir ${CMAKE_SOURCE_DIR})
    while(NOT search_dir STREQUAL "")
        set(candidate ${search_dir}/resolved_o3de_manifest.json)
        if(EXISTS ${candidate} AND EXISTS ${search_dir}/workspace.json)
            set(${resolved_o3de_manifest_path} ${candidate} PARENT_SCOPE)
            return()
        endif()
        cmake_path(GET search_dir PARENT_PATH parent_dir)
        if(parent_dir STREQUAL search_dir)
            break()
        endif()
        set(search_dir ${parent_dir})
    endwhile()

    # The resolved_o3de_manifest.json is in the home directory / .o3de folder
    o3de_get_user_home_path(o3de_home_path)
    set(${resolved_o3de_manifest_path} ${o3de_home_path}/.o3de/resolved_o3de_manifest.json PARENT_SCOPE)
endfunction()

#! o3de_read_manifest: returns the contents of the manifest
# \arg:o3de_manifest_json_data returns the contents of the manifest as a json string
function(o3de_read_manifest o3de_manifest_json_data)
    #get the manifest path
    o3de_get_manifest_path(o3de_manifest_path)
    if(EXISTS ${o3de_manifest_path})
        o3de_file_read(${o3de_manifest_path} json_data)
        set(${o3de_manifest_json_data} ${json_data} PARENT_SCOPE)
    endif()
endfunction()

#! o3de_get_upgraded_file_path
#  Gets the upgraded file path in x.2-0-0.y format
#
#  \arg:input_path - the original file path
#  \arg:output_path - name of output variable to store the alternate path
#  \return: the alternate file path with .2-0-0 inserted before the extension
#
#  Example:
#  # For input "c:/engine.json", returns "c:/engine.2-0-0.json"
#  o3de_get_upgraded_file_path("c:/engine.json" alt_path)
function(o3de_get_upgraded_file_path input_path output_path)
    cmake_path(GET input_path STEM name_without_ext)
    cmake_path(GET input_path EXTENSION last_ext)
    cmake_path(GET input_path PARENT_PATH parent_path)
    
    set(alt_filename "${name_without_ext}.2-0-0${last_ext}")
    if(parent_path)
        cmake_path(SET alt_path "${parent_path}/${alt_filename}")
    else()
        set(alt_path "${alt_filename}")
    endif()
    
    set(${output_path} "${alt_path}" PARENT_SCOPE)
endfunction()

#! o3de_file_read_cache
#  Wraps o3de_file_read but stores the file in a cache to avoid extra reads
#  Also checks for an alternate version of the file first (x.2-0-0.y format)
#  and falls back to the original file if the alternate does not exist
#
#  \arg:path - path to the json file to read
#  \arg:content - name of output variable to store the file content
#  \return: the content of the file (either alternate or original version)
#
#  Example:
#  # For "c:/engine.json", checks "c:/engine.2-0-0.json" first
#  o3de_file_read_cache("c:/engine.json" file_content)
function(o3de_file_read_cache path content)
    cmake_path(SET orig_path "${path}")
    cmake_path(NORMAL_PATH orig_path)

    set(file_cache_var_name "O3DE_FILE_CACHE_${orig_path}")
    get_property(file_content GLOBAL PROPERTY ${file_cache_var_name})
    
    if(NOT file_content)
        # Check for alternate file version first (x.2-0-0.y)
        o3de_get_upgraded_file_path("${orig_path}" alt_path)
        
        if(EXISTS "${alt_path}")
            message(VERBOSE "Using alternate file: ${alt_path} instead of ${orig_path}")
            set(final_path "${alt_path}")
        else()
            set(final_path "${orig_path}")
        endif()
        
        o3de_file_read(${final_path} file_content)
        set_property(GLOBAL PROPERTY ${file_cache_var_name} ${file_content})
    endif()
    
    set(${content} ${file_content} PARENT_SCOPE)
endfunction()

#! o3de_build_keys_list
#  Builds a list of keys from function arguments
#
#  \arg:output_list - name of output variable to store the keys list
#  \arg:first_key - the first key
#  \args:additional_keys - additional keys to append to the list
#  \return: a list containing all the provided keys
#
#  Example:
#  # Creates a list ["engine", "name"] from arguments
#  o3de_build_keys_list(keys_list "engine" "name")  
function(o3de_build_keys_list output_list first_key)
    set(keys_list ${first_key})
    foreach(additional_key IN LISTS ARGN)
        list(APPEND keys_list ${additional_key})
    endforeach()
    set(${output_list} ${keys_list} PARENT_SCOPE)
endfunction()

#! o3de_navigate_json_path
#  Navigates through a JSON path and returns the final object/value or array
#
#  \arg:output_value - name of output variable to store the result
#  \arg:json_data - the json data to navigate
#  \arg:keys_list - list of keys defining the path to navigate
#  \arg:context_info - context information for error messages
#  \arg:is_array - TRUE if extracting an array, FALSE if extracting a property value
#  \return: the value or array at the specified path in the json data
#
#  Example:
#  # Navigate to {"engine": {"name": "value"}} and extract "value"
#  o3de_navigate_json_path(result ${json_data} "engine;name" "in test" FALSE)
function(o3de_navigate_json_path output_value json_data keys_list context_info is_array)
    set(current_json ${json_data})
    set(current_path "")
    list(LENGTH keys_list keys_count)
    math(EXPR last_key_index "${keys_count} - 1")
    
    # Navigate through all keys
    foreach(key_index RANGE ${last_key_index})
        list(GET keys_list ${key_index} current_key)
        
        # Build path for error messages
        if(current_path STREQUAL "")
            set(current_path ${current_key})
        else()
            string(APPEND current_path ".${current_key}")
        endif()
        
        # If this is the last key
        if(key_index EQUAL ${last_key_index})
            if(is_array)
                # Extract array
                string(JSON array_count ERROR_VARIABLE json_error LENGTH ${current_json} ${current_key})
                if(json_error)
                    message(VERBOSE "No array found at key '${current_key}' in path '${current_path}' ${context_info}")
                    return()
                endif()
                
                set(array_elements "")
                if(array_count GREATER 0)
                    math(EXPR array_range "${array_count} - 1")
                    foreach(array_index RANGE ${array_range})
                        string(JSON array_element ERROR_VARIABLE json_error GET ${current_json} ${current_key} ${array_index})
                        if(json_error)
                            message(WARNING "Error reading element at index ${array_index} in array '${current_key}' at path '${current_path}' ${context_info}: ${json_error}")
                            return()
                        endif()
                        list(APPEND array_elements ${array_element})
                    endforeach()
                endif()
                set(${output_value} ${array_elements} PARENT_SCOPE)
            else()
                # Extract property value
                string(JSON property_value ERROR_VARIABLE json_error GET ${current_json} ${current_key})
                if(json_error)
                    message(WARNING "Error reading property '${current_key}' at path '${current_path}' ${context_info}: ${json_error}")
                    return()
                endif()
                set(${output_value} ${property_value} PARENT_SCOPE)
            endif()
        else()
            # Navigate to next object
            string(JSON next_object ERROR_VARIABLE json_error GET ${current_json} ${current_key})
            if(json_error)
                message(VERBOSE "No object found at key '${current_key}' in path '${current_path}' ${context_info}")
                return()
            endif()
            set(current_json ${next_object})
        endif()
    endforeach()
endfunction()

#! o3de_read_json_array
#  Reads a json array field into a cmake list variable
#  Assumes all keys except the last one are objects, and the last key is an array
#
#  \arg:read_output_array - name of output variable to store the array elements into
#  \arg:input_json_path - path to the json file to read
#  \arg:first_key - the first object key in the path
#  \args:additional_keys - additional object keys with the last one being the array name
#  \return: the elements of the array in the json file as a cmake list variable
#
#  Example:
#  # Access { "children": { "gems": ["Gem1", "Gem2"] } }
#  o3de_read_json_array(gems path/to/engine.json "children" "gems")
function(o3de_read_json_array read_output_array input_json_path first_key)
    o3de_file_read_cache(${input_json_path} json_data)
    o3de_build_keys_list(keys_list ${first_key} ${ARGN})
    o3de_navigate_json_path(result_array ${json_data} "${keys_list}" "in file \"${input_json_path}\"" TRUE)
    set(${read_output_array} ${result_array} PARENT_SCOPE)
endfunction()

#! o3de_get_json_array
#  Reads a json array field from json data into a cmake list variable
#  Assumes all keys except the last one are objects, and the last key is an array
#
#  \arg:read_output_array - name of output variable to store the array elements into
#  \arg:input_json_data - json data
#  \arg:first_key - the first object key in the path
#  \args:additional_keys - additional object keys with the last one being the array name
#  \return: the elements of the array in the json data as a cmake list variable
#
#  Example:
#  # Access { "children": { "gems": ["Gem1", "Gem2"] } }
#  o3de_get_json_array(gems ${json_data} "children" "gems")
function(o3de_get_json_array read_output_array json_data first_key)
    o3de_build_keys_list(keys_list ${first_key} ${ARGN})
    o3de_navigate_json_path(result_array ${json_data} "${keys_list}" "in json data" TRUE)
    set(${read_output_array} ${result_array} PARENT_SCOPE)
endfunction()


#! o3de_read_json_key
#  Reads a JSON value from a file and sets it to the output variable
#  Assumes all keys except the last one are objects, and the last key is a property
#
#  \arg:output_value - name of output variable to store the value into
#  \arg:input_json_path - path to the json file to read
#  \arg:first_key - the first object key in the path
#  \args:additional_keys - additional object keys with the last one being the property name
#  \return: the value at the specified path in the json file
#  
#  Example:
#  # Access { "engine": { "name": "org.o3de.engine.o3de" } }
#  o3de_read_json_key(engine_name path/to/engine.json "engine" "name")
function(o3de_read_json_key output_value input_json_path first_key)
    o3de_file_read_cache(${input_json_path} json_data)
    o3de_build_keys_list(keys_list ${first_key} ${ARGN})
    o3de_navigate_json_path(result_value ${json_data} "${keys_list}" "in file \"${input_json_path}\"" FALSE)
    set(${output_value} ${result_value} PARENT_SCOPE)
endfunction()

#! o3de_get_json_key
#  Reads a JSON value from json data and sets it to the output variable
#  Assumes all keys except the last one are objects, and the last key is a property
#
#  \arg:output_value - name of output variable to store the value into
#  \arg:input_json_data - json data
#  \arg:first_key - the first object key in the path
#  \args:additional_keys - additional object keys with the last one being the property name
#  \return: the value at the specified path in the json data
#  
#  Example:
#  # Access { "engine": { "name": "org.o3de.engine.o3de" } }
#  o3de_get_json_key(engine_name ${json_data} "engine" "name")
function(o3de_get_json_key output_value json_data first_key)
    o3de_build_keys_list(keys_list ${first_key} ${ARGN})
    o3de_navigate_json_path(result_value ${json_data} "${keys_list}" "in json data" FALSE)
    set(${output_value} ${result_value} PARENT_SCOPE)
endfunction()

#! o3de_read_optional_json_key
#  Reads a single key from a json file and sets it to the output variable
#  If the key does not exist, it does not set the output variable
#
#  \arg:output_value - name of output variable to store the value into
#  \arg:input_json_path - path to the json file to read
#  \arg:key - the key to read from the json file
#  \return: the value of the key in the json file, or does not set the output variable if the key does not exist
#
#  Example:
#  # Read optional "version" key from engine.json
#  o3de_read_optional_json_key(version_value path/to/engine.json "version")
function(o3de_read_optional_json_key output_value input_json_path key)
    o3de_file_read_cache(${input_json_path} json_data)
    o3de_get_optional_json_key(${output_value} ${json_data} ${key})
    if(DEFINED ${output_value})
        set(${output_value} ${${output_value}} PARENT_SCOPE)
    endif()
endfunction()

#! o3de_get_optional_json_key
#  Reads a single key from json data and sets it to the output variable
#  If the key does not exist, it does not set the output variable
#
#  \arg:output_value - name of output variable to store the value into
#  \arg:json_data - json data
#  \arg:key - the key to read from the json data
#  \return: the value of the key in the json data, or does not set the output variable if the key does not exist
#
#  Example:
#  # Read optional "version" key from json data
#  o3de_get_optional_json_key(version_value ${json_data} "version")
function(o3de_get_optional_json_key output_value json_data key)
    string(JSON value ERROR_VARIABLE json_error GET ${json_data} ${key})
    if(NOT json_error)
        set(${output_value} ${value} PARENT_SCOPE)
    endif()
endfunction()

#! o3de_read_json_keys
#  Reads multiple json keys at once from a file
#  More efficient than using o3de_read_json_key multiple times
#
#  \arg:input_json_path - the path to the json file 
#  \args:key_output_pairs - pairs of 'key' and 'output_value'
#  \return: sets multiple output variables with their corresponding key values
#
#  Example:
#  # Read key1 and key2 values from myfile.json
#  o3de_read_json_keys(c:/myfile.json 'key1' out_key1_value 'key2' out_key2_value)
function(o3de_read_json_keys input_json_path)
    o3de_file_read_cache(${input_json_path} json_data)
    o3de_get_json_keys(${json_data} ${ARGN})
    
    # Forward all output variables to parent scope
    list(LENGTH ARGN arg_count)
    math(EXPR max_index "${arg_count} - 1")
    foreach(i RANGE 1 ${max_index} 2)  # Step by 2, starting at 1 (output vars)
        list(GET ARGN ${i} output_var)
        if(DEFINED ${output_var})
            set(${output_var} ${${output_var}} PARENT_SCOPE)
        endif()
    endforeach()
endfunction()

#! o3de_get_json_keys
#  Reads multiple json keys at once from json data
#  More efficient than using o3de_get_json_key multiple times
#
#  \arg:json_data - the json data 
#  \args:key_output_pairs - pairs of 'key' and 'output_value'
#  \return: sets multiple output variables with their corresponding key values
#
#  Example:
#  # Read key1 and key2 values from json data
#  o3de_get_json_keys(${json_data} 'key1' out_key1_value 'key2' out_key2_value)
function(o3de_get_json_keys json_data)
    list(LENGTH ARGN arg_count)
    if(arg_count LESS 2)
        return()
    endif()
    
    # Process pairs of (key, output_variable)
    math(EXPR max_index "${arg_count} - 1")
    foreach(i RANGE 0 ${max_index} 2)  # Step by 2, starting at 0 (keys)
        math(EXPR output_index "${i} + 1")
        if(output_index LESS ${arg_count})
            list(GET ARGN ${i} key)
            list(GET ARGN ${output_index} output_var)
            
            string(JSON value ERROR_VARIABLE json_error GET ${json_data} ${key})
            if(json_error)
                message(WARNING "Error reading field at key ${key} in json data: ${json_error}")
            else()
                set(${output_var} ${value} PARENT_SCOPE)
            endif()
        endif()
    endforeach()
endfunction()

