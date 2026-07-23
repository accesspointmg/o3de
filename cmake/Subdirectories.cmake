#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include_guard()

set(O3DE_DISABLE_GEM_DEPENDENCY_RESOLUTION FALSE CACHE BOOL "Option to forcibly disable the resolution of gem dependencies")

################################################################################
# External Subdirectory processing
################################################################################

# Add a GLOBAL property which can be used to quickly determine if a directory is an external subdirectory
get_property(cache_external_subdirectories CACHE O3DE_EXTERNAL_SUBDIRECTORIES PROPERTY VALUE)
foreach(cache_external_subdirectory IN LISTS cache_external_subdirectories)
    file(REAL_PATH ${cache_external_subdirectory} real_external_subdirectory)
    set_property(GLOBAL PROPERTY "O3DE_EXTERNAL_SUBDIRECTORY_${real_external_subdirectory}" TRUE)
endforeach()

# The visited_object_name_set is used to append the external_subdirectories found
# within descendant objects to the parents to the global O3DE_EXTERNAL_SUBDIRECTORIES_<object_type>_<object_name> property
function(add_o3de_object_external_subdirectories object_type object_name object_path visited_object_name_set_ref)

    #lower the object_type to match the property names
    string(TOLOWER ${object_type} object_type_lower)
    string(TOUPPER ${object_type} object_type_upper)
    set(object_json_path ${object_path}/${object_type_lower}.json)
    if(EXISTS ${object_json_path})
        o3de_read_json_array(object_external_subdirectories ${object_json_path} "external_subdirectories")

        # Read the object_name from the object.json and map it to the object path
        o3de_read_json_key(object_name "${object_json_path}" "${object_type_lower}_name")
        if(NOT object_name)
            o3de_read_json_key(object_name "${object_json_path}" "${object_type_lower}" "name")
        endif()
        if(NOT object_name)
            MESSAGE(FATAL_ERROR "Failed to read the ${object_type_lower} name from '${object_json_path}' or the ${object_type_lower} name is empty.")
            return()
        endif()

        set_property(GLOBAL PROPERTY "@{object_type_upper}ROOT:${object_name}@" "${object_json_path}")

        # Push the object name onto the visited set
        list(APPEND ${visited_object_name_set_ref} ${object_name})
        foreach(object_external_subdirectory IN LISTS object_external_subdirectories)
            file(REAL_PATH ${object_external_subdir} real_external_subdirectory BASE_DIRECTORY ${object_path})

            if(NOT object_name STREQUAL "")
                # Append external subdirectory to the O3DE_EXTERNAL_SUBDIRECTORIES_${object_type}_${object_name} PROPERTY
                set(object_external_subdirectory_property_name O3DE_EXTERNAL_SUBDIRECTORIES_${object_type}_${object_name})
            else()
                # Append external subdirectory to the O3DE_EXTERNAL_SUBDIRECTORIES_${object_type} PROPERTY
                set(object_external_subdirectory_property_name O3DE_EXTERNAL_SUBDIRECTORIES_${object_type})
            endif()

            get_property(current_external_subdirectories GLOBAL PROPERTY ${object_external_subdirectory_property_name})
            if(NOT real_external_subdirectory IN_LIST current_external_subdirectories)
                set_property(GLOBAL APPEND PROPERTY ${object_external_subdirectory_property_name} "${real_external_subdirectory}")
                set_property(GLOBAL PROPERTY "O3DE_SUBDIRECTORY_${real_external_subdirectory}" TRUE)
                foreach(visited_object_name IN LISTS ${visited_object_name_set_ref})
                    # Append the external subdirectories that come with the object to
                    # the visited_object_set O3DE_EXTERNAL_SUBDIRECTORIES_OBJECT_<object-name> properties as well
                    set_property(GLOBAL APPEND PROPERTY O3DE_EXTERNAL_SUBDIRECTORIES_OBJECT_${visited_object_name} ${real_external_subdirectory})
                endforeach()
                add_o3de_object_external_subdirectories("${object_type}" "${object_name}" "${real_external_subdirectory}" "${visited_object_name_set_ref}")
            endif()
        endforeach()
        # Pop the object name from the visited set
        list(POP_BACK ${visited_object_name_set_ref})
    endif()
endfunction()

#! add_o3de_object_json_external_subdirectories:
#! Returns the external_subdirectories referenced by the supplied <o3de_object>.json
#! This will recurse through to check for gem.json external_subdirectories
#! via calling the *_gem_json_external_subdirectories variant of this function
function(add_o3de_object_json_external_subdirectories object_type object_name object_path object_json_filename)
    set(object_json_path ${object_path}/${object_json_filename})
    if(EXISTS ${object_json_path})
        o3de_read_json_array(object_external_subdirectories ${object_json_path} "external_subdirectories")    
        foreach(object_external_subdirectory IN LISTS object_external_subdirectories)
            file(REAL_PATH ${object_external_subdir} real_external_subdirectory BASE_DIRECTORY ${object_path})

            # Append external subdirectory ONLY to O3DE_EXTERNAL_SUBDIRECTORIES_PROJECT_${project_name} PROPERTY
            if(NOT object_name STREQUAL "")
                # Append external subdirectory to the O3DE_EXTERNAL_SUBDIRECTORIES_${object_type}_${object_name} PROPERTY
                set(object_external_subdirectory_property_name O3DE_EXTERNAL_SUBDIRECTORIES_${object_type}_${object_name})
            else()
                # Append external subdirectory to the O3DE_EXTERNAL_SUBDIRECTORIES_${object_type} PROPERTY
                set(object_external_subdirectory_property_name O3DE_EXTERNAL_SUBDIRECTORIES_${object_type})
            endif()

            get_property(current_external_subdirectories GLOBAL PROPERTY ${object_external_subdirectory_property_name})
            if(NOT real_external_subdirectory IN_LIST current_external_subdirectories)
                set_property(GLOBAL APPEND PROPERTY ${object_external_subdirectory_property_name} "${real_external_subdirectory}")
                set_property(GLOBAL PROPERTY "O3DE_SUBDIRECTORY_${real_external_subdirectory}" TRUE)
                set(visited_object_name_set)
                add_o3de_object_json_external_subdirectories("${object_type}" "${object_name}" "${real_external_subdirectory}" visited_object_name_set)
            endif()
        endforeach()
    endif()
endfunction()


#! Gather unique_list of all external subdirectories that is union
#! of the engine.json, project.json, and any gem.json files found visiting
function(get_all_external_subdirectories output_subdirectories)
    # Gather user supplied external subdirectories via the Cache Variable
    get_property(o3de_external_subdirectories CACHE O3DE_EXTERNAL_SUBDIRECTORIES PROPERTY VALUE)
    list(APPEND all_external_subdirectories ${o3de_external_subdirectories})

    get_property(engine_external_subdirectories GLOBAL PROPERTY O3DE_EXTERNAL_SUBDIRECTORIES_ENGINE)
    list(APPEND all_external_subdirectories ${engine_external_subdirectories})

    # Gather the list of every configured project external subdirectory
    # and and append them to the list of external subdirectories
    get_property(project_names GLOBAL PROPERTY O3DE_PROJECTS_NAME)
    foreach(project_name IN LISTS project_names)
        get_property(project_external_subdirectories GLOBAL PROPERTY O3DE_EXTERNAL_SUBDIRECTORIES_PROJECT_${project_name})
        list(APPEND all_external_subdirectories ${project_external_subdirectories})
    endforeach()

    list(REMOVE_DUPLICATES all_external_subdirectories)
    set(${output_subdirectories} ${all_external_subdirectories} PARENT_SCOPE)
endfunction()


#! Use cmake.py to get a resolved list of gem names and paths for this object (engine or project)
#! If dependencies are resolved successfully, save each gem's resolved path in a global property
#! named "@GEMROOT:${gem_name}@"
function(resolve_gem_dependencies object_type object_path)

    # Avoid resolving dependencies for the same object type and path multiple times
    get_property(resolved_dependencies GLOBAL PROPERTY "O3DE_RESOLVED_GEM_DEPENDENCIES_${object_type}_${object_path}")
    if(resolved_dependencies)
        return()
    endif()

    set(ENV{PYTHONNOUSERSITE} 1)
    string(TOLOWER ${object_type} object_type_lower)
    get_property(user_external_subdirectories CACHE O3DE_EXTERNAL_SUBDIRECTORIES PROPERTY VALUE)
    if(user_external_subdirectories)
        set(user_external_subdir_option -ed "${user_external_subdirectories}")
    endif()
    execute_process(COMMAND 
        ${O3DE_PYTHON_CMD} "${O3DE_ENGINE_PATH}/scripts/o3de/o3de/cmake.py" "resolve-gem-dependencies" --${object_type_lower}-path "${object_path}" --engine-path "${O3DE_ENGINE_PATH}" ${user_external_subdir_option}
        WORKING_DIRECTORY ${O3DE_ENGINE_PATH}
        RESULT_VARIABLE O3DE_CLI_RESULT
        OUTPUT_VARIABLE resolved_gem_dependency_output 
        ERROR_VARIABLE O3DE_CLI_OUT
        )

    if(O3DE_CLI_RESULT)
        message(WARNING "Dependency resolution failed.\n  If needed, set the O3DE_DISABLE_GEM_DEPENDENCY_RESOLUTION variable to bypass dependency resolution.\n  Error: ${O3DE_CLI_OUT}")
        return()
    endif()

    # Strip any whitespace which might be included in the first or last elements of the list
    string(STRIP "${resolved_gem_dependency_output}" resolved_gem_dependency_output)

    unset(gem_name)
    foreach(entry IN LISTS resolved_gem_dependency_output)
        if(NOT DEFINED gem_name)
            # The first entry is the gem name
            set(gem_name ${entry})
        else()
            # The next entry after every gem name is the gem path
            cmake_path(SET gem_path "${entry}")

            get_property(current_gem_path GLOBAL PROPERTY "@GEMROOT:${gem_name}@")
            if(current_gem_path)
                cmake_path(SET current_gem_path "${current_gem_path}")
                cmake_path(COMPARE "${gem_path}" NOT_EQUAL "${current_gem_path}" paths_are_different)
                if (paths_are_different)

                    if (O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE STREQUAL "windows")
                        # Changing the case can cause problems on Windows where the drive
                        # letter can be upper or lower case in CMake 
                        string(TOLOWER "${current_gem_path}" current_gem_path_lower)
                        string(TOLOWER "${gem_path}" gem_path_lower)

                        if(current_gem_path_lower STREQUAL gem_path_lower)
                            message(VERBOSE "Not replacing existing path '${current_gem_path}' with different case '${gem_path}'")
                            unset(gem_name)
                            continue()
                        endif()
                    endif()

                    message(VERBOSE "Multiple paths were found for the same gem '${gem_name}'.\n  Current:'${current_gem_path}'\n  New:'${gem_path}'")
                endif()
            else()
                message(VERBOSE "New path found for gem '${gem_name}' ${current_gem_path}")
            endif()

            set_property(GLOBAL PROPERTY "@GEMROOT:${gem_name}@" "${gem_path}")
            unset(gem_name)
        endif()
    endforeach()

    set_property(GLOBAL PROPERTY "O3DE_RESOLVED_GEM_DEPENDENCIES_${object_type}_${object_path}" TRUE)
endfunction()

#! Queries the list of gem names against the list of ALL registered external subdirectories
#! in order to determine the paths corresponding to the gem names
function(add_registered_gems_to_external_subdirectories output_gem_dirs gem_names)
    get_all_external_subdirectories(registered_external_subdirectories)
    query_gem_paths_from_external_subdirectories(gem_dirs "${gem_names}" "${registered_external_subdirectories}")
    set(${output_gem_dirs} ${gem_dirs} PARENT_SCOPE)
endfunction()

#! Gather unique_list of all external subdirectories that the o3de object provides or uses
#! The list is made up of the following
#! - The list of external_subdirectories found by recursively visiting the <o3de_object>.json "external_subdirectories"
function(get_all_external_subdirectories_for_o3de_object output_subdirectories object_type object_name object_path object_json_filename)

    # Append the list of external_subdirectories that come with the object
    if(NOT object_name STREQUAL "")
        # query the O3DE_EXTERNAL_SUBDIRECTORIES_${object_type}_${object_name} PROPERTY
        set(object_external_subdirectory_property_name O3DE_EXTERNAL_SUBDIRECTORIES_${object_type}_${object_name})
    else()
        # query the O3DE_EXTERNAL_SUBDIRECTORIES_${object_type} PROPERTY
        set(object_external_subdirectory_property_name O3DE_EXTERNAL_SUBDIRECTORIES_${object_type})
    endif()

    get_property(object_external_subdirectories GLOBAL PROPERTY ${object_external_subdirectory_property_name})
    list(APPEND subdirectories_for_object ${object_external_subdirectories})

    list(REMOVE_DUPLICATES subdirectories_for_object)
    set(${output_subdirectories} ${subdirectories_for_object} PARENT_SCOPE)
endfunction()








# Add a GLOBAL property which can be used to quickly determine if a directory is an gem
get_property(cache_gems CACHE O3DE_GEMS PROPERTY VALUE)
foreach(cache_gem IN LISTS cache_gems)
    file(REAL_PATH ${cache_gem} real_gem)
    set_property(GLOBAL PROPERTY "O3DE_GEMS_${real_gem}" TRUE)
endforeach()

# The visited_gem_name_set is used to append the gems found
# within descendant gems to the parents to the global O3DE_GEM_<gem_name> property
# i.e If `GemA` "gems" points to `GemB` and `GemB` gems
# points to `GemC`.
# Then O3DE_GEM_GemA = [<AbsPath GemB>, <AbsPath GemC>]
# And O3DE_GEM_GemB = [<AbsPath GemC>]
#! add_o3de_object_gem_json_gems : Recurses
#! originally found in the add_*_json_gems command
function(add_o3de_object_gem_json_gems object_type object_name gem_path visited_gem_name_set_ref)
    set(gem_json_path ${gem_path}/gem.json)
    if(EXISTS ${gem_json_path})
        o3de_read_json_array(gem_gems ${gem_path}/gem.json "gems")

        # Read the gem_name from the gem.json and map it to the gem path
        o3de_read_json_key(gem_name_with_version_specifier "${gem_path}/gem.json" "gem_name")
        if(NOT gem_name_with_version_specifier)
            o3de_read_json_key(gem_name_with_version_specifier "${gem_path}/gem.json" "gem" "name")
        endif()
        if(NOT gem_name_with_version_specifier)
            MESSAGE(FATAL_ERROR "Failed to read the gem name from '${gem_path/gem.json}' or the gem name is empty.")
            return()
        endif()

        # Remove any version specifier
        o3de_get_name_and_version_specifier(${gem_name_with_version_specifier} gem_name spec_op spec_version)
        set_property(GLOBAL PROPERTY "@GEMROOT:${gem_name}@" "${gem_path}")

        # Push the gem name onto the visited set
        list(APPEND ${visited_gem_name_set_ref} ${gem_name})
        foreach(gem_gem IN LISTS gem_gems)
            file(REAL_PATH ${gem_gem} real_gem BASE_DIRECTORY ${gem_path})

            if(NOT object_name STREQUAL "")
                # Append gem to the O3DE_GEM_${object_type}_${object_name} PROPERTY
                set(object_gem_property_name O3DE_GEM_${object_type}_${object_name})
            else()
                # Append gem to the O3DE_GEM_${object_type} PROPERTY
                set(object_gem_property_name O3DE_GEM_${object_type})
            endif()

            get_property(current_gems GLOBAL PROPERTY ${object_gem_property_name})
            if(NOT real_gem IN_LIST current_gems)
                set_property(GLOBAL APPEND PROPERTY ${object_gem_property_name} "${real_gem}")
                set_property(GLOBAL PROPERTY "O3DE_GEM_${real_gem}" TRUE)
                foreach(visited_gem_name IN LISTS ${visited_gem_name_set_ref})
                    # Append the external subdirectories that come with the gem to
                    # the visited_gem_set O3DE_GEM_<gem-name> properties as well
                    set_property(GLOBAL APPEND PROPERTY O3DE_GEM_${visited_gem_name} ${real_gem})
                endforeach()
                add_o3de_object_gem_json_gems("${object_type}" "${object_name}" "${real_gem}" "${visited_gem_name_set_ref}")
            endif()
        endforeach()
        # Pop the gem name from the visited set
        list(POP_BACK ${visited_gem_name_set_ref})
    endif()
endfunction()

#! add_o3de_object_json_gems:
#! Returns the gems referenced by the supplied <o3de_object>.json
#! This will recurse through to check for gem.json gems
#! via calling the *_gem_json_gems variant of this function
function(add_o3de_object_json_gems object_type object_name object_path object_json_filename)
    set(object_json_path ${object_path}/${object_json_filename})
    if(EXISTS ${object_json_path})
        o3de_read_json_array(object_gems ${object_json_path} "children" "gems")    
        foreach(object_gem IN LISTS object_gems)
            file(REAL_PATH ${object_gem} real_gem BASE_DIRECTORY ${object_path})

            # Append gem ONLY to O3DE_GEM_PROJECT_${project_name} PROPERTY
            if(NOT object_name STREQUAL "")
                # Append gem to the O3DE_GEM_${object_type}_${object_name} PROPERTY
                set(object_gem_property_name O3DE_GEM_${object_type}_${object_name})
            else()
                # Append gem to the O3DE_GEM_subdirectories_${object_type} PROPERTY
                set(object_gem_property_name O3DE_GEM_${object_type})
            endif()

            get_property(current_gems GLOBAL PROPERTY ${object_gem_property_name})
            if(NOT real_gem IN_LIST current_gems)
                set_property(GLOBAL APPEND PROPERTY ${object_gem_property_name} "${real_gem}")
                set_property(GLOBAL PROPERTY "O3DE_GEM_${real_gem}" TRUE)
                set(visited_gem_name_set)
                add_o3de_object_gem_json_gems("${object_type}" "${object_name}" "${real_gem}" visited_gem_name_set)
            endif()
        endforeach()
    endif()
endfunction()

# The following functions is for gathering the list of external subdirectories
# provided by the engine.json
function(add_engine_json_gems)
    add_o3de_object_json_gems("ENGINE" "" "${O3DE_ENGINE_PATH}" "engine.json")
endfunction()

# The following functions is for gathering the list of external subdirectories
# provided by the project.json
function(add_project_json_gems project_path project_name)
    add_o3de_object_json_gems("PROJECT" "${project_name}" "${project_path}" "project.json")
endfunction()

#! add_o3de_manifest_json_gems : Adds the list of gems
#! in the user o3de_manifest.json to the O3DE_GEM_O3DE_MANIFEST property
function(add_o3de_manifest_json_gems)
    # Retrieves the path to the o3de_manifest.json(includes the name)
    o3de_get_manifest_path(manifest_path)
    # Separate the o3de_manifest.json from the path to it
    cmake_path(GET manifest_path FILENAME manifest_json_name)
    cmake_path(GET manifest_path PARENT_PATH manifest_path)

    add_o3de_object_json_gems("O3DE_MANIFEST" "" "${manifest_path}" "${manifest_json_name}")
endfunction()

#! Gather unique_list of all external subdirectories that is union
#! of the engine.json, project.json, o3de_manifest.json and any gem.json files found visiting
function(get_all_gems output_subdirectories)
    # Gather user supplied external subdirectories via the Cache Variable
    get_property(o3de_gems CACHE O3DE_GEMS PROPERTY VALUE)
    list(APPEND all_gems ${o3de_gems})

    get_property(manifest_gems GLOBAL PROPERTY O3DE_GEMS_O3DE_MANIFEST)
    list(APPEND all_gems ${manifest_gems})
    
    get_property(engine_gems GLOBAL PROPERTY O3DE_GEMS_ENGINE)
    list(APPEND all_gems ${engine_gems})

    # Gather the list of every configured project gem
    # and and append them to the list of external subdirectories
    get_property(project_names GLOBAL PROPERTY O3DE_PROJECTS_NAME)
    foreach(project_name IN LISTS project_names)
        get_property(project_gems GLOBAL PROPERTY O3DE_GEMS_PROJECT_${project_name})
        list(APPEND all_gems ${project_gems})
    endforeach()

    list(REMOVE_DUPLICATES all_gems)
    set(${output_subdirectories} ${all_gems} PARENT_SCOPE)
endfunction()


#! Accepts a list of gem names (which can be read from the project.json, gem.json or engine.json)
#! and a list of ALL registered external subdirectories across all manifest
#! and cross checks them against union of all external subdirectories to determine the gem path.
#! If that gem path exist it is appended to the output parameter output gem directories parameter
#! A fatal error is logged indicating that is not gem could not be found in the list of external subdirectories
function(query_gem_paths_from_gems output_gem_dirs gem_names registered_gems)
    if (gem_names)
        foreach(gem_name_with_version_specifier IN LISTS gem_names)
            unset(gem_path)

            # Remove the version specifier from the gem name before fetching properties
            o3de_get_name_and_version_specifier(${gem_name_with_version_specifier} gem_name spec_op spec_version)

            get_property(gem_optional GLOBAL PROPERTY ${gem_name}_OPTIONAL)
            get_property(gem_path GLOBAL PROPERTY "@GEMROOT:${gem_name}@")

            if (gem_path)
                list(APPEND gem_dirs ${gem_path})
            elseif(NOT gem_optional)
                # Sort the list so it is easier to search visually
                list(SORT registered_gems COMPARE NATURAL CASE INSENSITIVE ORDER ASCENDING)
                # Indent the text to be easier to read. If the indent is removed CMake will add an
                # additional newline automatically because "non-indented text is formatted in 
                # line-wrapped paragraphs delimited by newlines"
                list(JOIN registered_gems "\n  " gems_formatted)
                message(SEND_ERROR "The gem \"${gem_name}\""
                " could not be found in any gem.json from the following list of registered external subdirectories:"
                "\n  ${gems_formatted}")
                break()
            endif()
        endforeach()
    endif()
    set(${output_gem_dirs} ${gem_dirs} PARENT_SCOPE)
endfunction()

#! Use cmake.py to get a resolved list of gem names and paths for this object (engine or project)
#! If dependencies are resolved successfully, save each gem's resolved path in a global property
#! named "@GEMROOT:${gem_name}@"
function(resolve_gem_dependencies object_type object_path)

    # Avoid resolving dependencies for the same object type and path multiple times
    get_property(resolved_dependencies GLOBAL PROPERTY "O3DE_RESOLVED_GEM_DEPENDENCIES_${object_type}_${object_path}")
    if(resolved_dependencies)
        return()
    endif()

    set(ENV{PYTHONNOUSERSITE} 1)
    string(TOLOWER ${object_type} object_type_lower)
    get_property(user_gems CACHE O3DE_GEM_subdirectories PROPERTY VALUE)
    if(user_gems)
        set(user_gem_option -ed "${user_gems}")
    endif()
    execute_process(COMMAND 
        ${O3DE_PYTHON_CMD} "${O3DE_ENGINE_PATH}/scripts/o3de/o3de/cmake.py" "resolve-gem-dependencies" --${object_type_lower}-path "${object_path}" --engine-path "${O3DE_ENGINE_PATH}" ${user_gem_option}
        WORKING_DIRECTORY ${O3DE_ENGINE_PATH}
        RESULT_VARIABLE O3DE_CLI_RESULT
        OUTPUT_VARIABLE resolved_gem_dependency_output 
        ERROR_VARIABLE O3DE_CLI_OUT
        )

    if(O3DE_CLI_RESULT)
        message(WARNING "Dependency resolution failed.\n  If needed, set the O3DE_DISABLE_GEM_DEPENDENCY_RESOLUTION variable to bypass dependency resolution.\n  Error: ${O3DE_CLI_OUT}")
        return()
    endif()

    # Strip any whitespace which might be included in the first or last elements of the list
    string(STRIP "${resolved_gem_dependency_output}" resolved_gem_dependency_output)

    unset(gem_name)
    foreach(entry IN LISTS resolved_gem_dependency_output)
        if(NOT DEFINED gem_name)
            # The first entry is the gem name
            set(gem_name ${entry})
        else()
            # The next entry after every gem name is the gem path
            cmake_path(SET gem_path "${entry}")

            get_property(current_gem_path GLOBAL PROPERTY "@GEMROOT:${gem_name}@")
            if(current_gem_path)
                cmake_path(SET current_gem_path "${current_gem_path}")
                cmake_path(COMPARE "${gem_path}" NOT_EQUAL "${current_gem_path}" paths_are_different)
                if (paths_are_different)

                    if (O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE STREQUAL "windows")
                        # Changing the case can cause problems on Windows where the drive
                        # letter can be upper or lower case in CMake 
                        string(TOLOWER "${current_gem_path}" current_gem_path_lower)
                        string(TOLOWER "${gem_path}" gem_path_lower)

                        if(current_gem_path_lower STREQUAL gem_path_lower)
                            message(VERBOSE "Not replacing existing path '${current_gem_path}' with different case '${gem_path}'")
                            unset(gem_name)
                            continue()
                        endif()
                    endif()

                    message(VERBOSE "Multiple paths were found for the same gem '${gem_name}'.\n  Current:'${current_gem_path}'\n  New:'${gem_path}'")
                endif()
            else()
                message(VERBOSE "New path found for gem '${gem_name}' ${current_gem_path}")
            endif()

            set_property(GLOBAL PROPERTY "@GEMROOT:${gem_name}@" "${gem_path}")
            unset(gem_name)
        endif()
    endforeach()

    set_property(GLOBAL PROPERTY "O3DE_RESOLVED_GEM_DEPENDENCIES_${object_type}_${object_path}" TRUE)
endfunction()

#! Queries the list of gem names against the list of ALL registered external subdirectories
#! in order to determine the paths corresponding to the gem names
function(add_registered_gems_to_gems output_gem_dirs gem_names)
    get_all_gems(registered_gems)
    query_gem_paths_from_gems(gem_dirs "${gem_names}" "${registered_gems}")
    set(${output_gem_dirs} ${gem_dirs} PARENT_SCOPE)
endfunction()

#! Recurses "dependencies" array if the gem is a gem(contains a gem.json)
#! for each subdirectory in use.
#! This function looks up the each dependent gem path from the registered gem set
#! That list of resolved gem paths then have this function invoked on it to perform the same behavior
#! When every descendent gem referenced from the "dependencies" field of the current subdirectory is visited
#! it is then appended to a list of output external subdirectories
#! NOTE: This must be invoked after all the add_*_json_gems function
function(reorder_dependent_gems_with_cycle_detection _output_external_dirs subdirectories_in_use registered_gems cycle_detection_set)
    # output_external_dirs is a variable whose value is the name of a variable to set in the parent scope
    # So double resolve the variable to retrieve its value
    set(current_external_dirs "${${_output_external_dirs}}")

    foreach(gem IN LISTS subdirectories_in_use)
        # If a cycle is detected, fatal error and output the list of subdirectories that led to the outcome
        if (gem IN_LIST cycle_detection_set)
            message(FATAL_ERROR "While visiting \"${gem}\", a cycle was detected in the \"dependencies\""
            " array of the following gem.json files in the directories: ${cycle_detection_set}")
        endif()
        # This subdirectory has already been processed so skip to the next one
        if(gem IN_LIST current_external_dirs)
            continue()
        endif()

        get_property(ordered_dependent_subdirectories GLOBAL PROPERTY "Dependent:${gem}")
        if(ordered_dependent_subdirectories)
            # Re-use the cached list of dependent subdirectories if available
            list(APPEND current_external_dirs "${ordered_dependent_subdirectories}")
        else()
            cmake_path(SET gem_manifest_path "${gem}/gem.json")
            if(EXISTS ${gem_manifest_path})
                # Read the "dependencies" array from gem.json
                o3de_read_json_array(dependencies_array "${gem_manifest_path}" "dependencies")
                # Lookup the paths using the dependent gem names
                unset(reference_external_dirs)
                query_gem_paths_from_gems(reference_external_dirs "${dependencies_array}" "${registered_gems}")

                # Append the gem into the children cycle_detection_set
                set(child_cycle_detection_set ${cycle_detection_set} ${gem})

                # Recursively visit the list of gem dependencies for the current external subdir
                reorder_dependent_gems_with_cycle_detection(current_external_dirs "${reference_external_dirs}"
                    "${registered_gems}" "${child_cycle_detection_set}")
                # Append the referenced gem directories before the current external subdir so that they are visited first
                list(APPEND current_external_dirs "${reference_external_dirs}")

                # Cache the list of external subdirectories so that it can be reused in subsequent calls
                set_property(GLOBAL PROPERTY "Dependent:${gem}" "${reference_external_dirs}")
            endif()
        endif()

        # Now append the external subdirectories
        list(APPEND current_external_dirs ${gem})
    endforeach()

    set(${_output_external_dirs} ${current_external_dirs} PARENT_SCOPE)
endfunction()

function(reorder_dependent_gems_before_gems output_gem_subdirectories subdirectories_in_use)
    # Lookup the registered external subdirectories once and re-use it for each call
    get_all_gems(registered_gems)
    # Supply an empty visited set and cycle_detection_set argument
    reorder_dependent_gems_with_cycle_detection(output_external_dirs "${subdirectories_in_use}" "${registered_gems}" "")
    set(${output_gem_subdirectories} ${output_external_dirs} PARENT_SCOPE)
endfunction()

#! Gather unique_list of all gems that the o3de object provides or uses
#! The list is made up of the following
#! - The paths of gems referenced in the <o3de_object>.json "gem_names" key.
#! Those paths are queried from the gems in o3de_manifest.json
#! - The <o3de_object> path
#! - The list of gems found by recursively visiting the <o3de_object>.json
function(get_all_gems_for_o3de_object output_subdirectories object_type object_name object_path object_json_filename)
    # Append the gems referenced by name from "gem_names" field in the <object>.json
    # These gems are registered in the users o3de_manifest.json
    o3de_read_json_array(initial_gem_names ${object_path}/${object_json_filename} "gem_names")
    set(gem_names "")

    # Gem dependency resolution can be disabled to speed up configuration 
    # for projects where it is not needed
    if(initial_gem_names AND NOT O3DE_DISABLE_GEM_DEPENDENCY_RESOLUTION)
        # Resolve gem dependency names to gem paths before adding them to external subdirectories 
        resolve_gem_dependencies(${object_type} "${object_path}")
    endif()

    # Cache the "gem_names" field entries as read from the <o3de_object>.json file
    # This will be used in the Install code to generate an "engine.json" with the same
    # set of active gems into its "gem_names" field
    get_property(explicit_active_gems GLOBAL PROPERTY "O3DE_EXPLICIT_ACTIVE_GEMS_${object_type}")
    # Append to any existing active gems mapped using the ${object_type} key
    list(APPEND explicit_active_gems ${initial_gem_names})
    # Make the list of active gems unique
    list(REMOVE_DUPLICATES explicit_active_gems)
    # Update the ${object_type} -> active gem GLOBAL property
    set_property(GLOBAL PROPERTY "O3DE_EXPLICIT_ACTIVE_GEMS_${object_type}" "${explicit_active_gems}")

    foreach(gem_name_with_version_specifier IN LISTS initial_gem_names)
        # Use the ERROR_VARIABLE to catch the common case when it's a simple string and not a json type.
        string(JSON json_type ERROR_VARIABLE json_error TYPE ${gem_name_with_version_specifier})
        set(gem_optional FALSE)
        if(${json_type} STREQUAL "OBJECT")
            string(JSON gem_optional GET ${gem_name_with_version_specifier} "optional")
            string(JSON gem_name_with_version_specifier GET ${gem_name_with_version_specifier} "name")
        endif()

        # Remove any version specifier from the gem name
        o3de_get_name_and_version_specifier(${gem_name_with_version_specifier} gem_name spec_op spec_version)

        # Set a global "optional" property on the gem name
        set_property(GLOBAL PROPERTY "${gem_name}_OPTIONAL" ${gem_optional})

        # Build the gem_names list with extracted names
        list(APPEND gem_names ${gem_name_with_version_specifier})
    endforeach()

    # Ensure all gems from "gem_names" are included in the settings registry 
    # file used to load runtime gems libraries
    if(gem_names)
        o3de_enable_gems(GEMS ${gem_names} PROJECT_NAME ${object_name})

        add_registered_gems_to_gems(object_gem_reference_dirs "${gem_names}")
        list(APPEND subdirectories_for_object ${object_gem_reference_dirs})

        # Also append the array the "gems" from each gem referenced through the "gem_names"
        # field
        foreach(gem_name_with_version_specifier IN LISTS gem_names)
            # Remove any version specifier from the gem name e.g. 'atom>=1.2.3' becomes 'atom'
            o3de_get_name_and_version_specifier(${gem_name_with_version_specifier} gem_name spec_op spec_version)
            get_property(gem_real_gems GLOBAL PROPERTY O3DE_GEM_${gem_name})
            list(APPEND subdirectories_for_object ${gem_real_gems})
        endforeach()
    endif()

    # Append the list of gems that come with the object
    if(NOT object_name STREQUAL "")
        # query the O3DE_GEM_${object_type}_${object_name} PROPERTY
        set(object_gem_property_name O3DE_GEMS_${object_type}_${object_name})
    else()
        # query the O3DE_GEM_${object_type} PROPERTY
        set(object_gem_property_name O3DE_GEMS_${object_type})
    endif()

    get_property(object_gems GLOBAL PROPERTY ${object_gem_property_name})
    list(APPEND subdirectories_for_object ${object_gems})

    list(REMOVE_DUPLICATES subdirectories_for_object)
    set(${output_subdirectories} ${subdirectories_for_object} PARENT_SCOPE)
endfunction()

#! Gather the unique list of all gems that the engine provides
#! plus all gems that every active project provides
#! or references in gem_names
function(get_gems_in_use output_subdirectories)
    get_property(all_gems GLOBAL PROPERTY O3DE_ALL_GEMS)
    if(all_gems)
        # This function has already run, use the calculated list of gems
        set(${output_subdirectories} ${all_gems} PARENT_SCOPE)
        return()
    endif()

    # Gather the list of gems set through the O3DE_GEMS Cache Variable
    get_property(all_gems CACHE O3DE_GEMS PROPERTY VALUE)

    # Append the list of external subdirectories from the engine.json
    get_all_gems_for_o3de_object(engine_gems "ENGINE" "" ${O3DE_ENGINE_PATH} "engine.json")
    list(APPEND all_gems ${engine_gems})

    # Visit each O3DE_PROJECTS_PATHS entry and append the external subdirectories
    # the project provides and references
    get_property(O3DE_PROJECTS_NAME GLOBAL PROPERTY O3DE_PROJECTS_NAME)
    get_property(O3DE_PROJECTS_PATHS GLOBAL PROPERTY O3DE_PROJECTS_PATHS)
    foreach(project_name project_path IN ZIP_LISTS O3DE_PROJECTS_NAME O3DE_PROJECTS_PATHS)
        # Append the project root path to the list of external subdirectories so that it is visited
        list(APPEND all_gems ${project_path})
        get_all_gems_for_o3de_object(gems "PROJECT" "${project_name}" "${project_path}" "project.json")
        list(APPEND all_gems ${gems})
    endforeach()

    # Make sure any gems in the "dependencies" field of a gem.json
    # are ordered before that gem, so they are parsed first.
    reorder_dependent_gems_before_gems(all_gems "${all_gems}")
    list(REMOVE_DUPLICATES all_gems)

    # Store in a global property so we don't re-calculate this list again
    set_property(GLOBAL PROPERTY O3DE_ALL_GEMS "${all_gems}")

    set(${output_subdirectories} ${all_gems} PARENT_SCOPE)
endfunction()

#! Visit all gems that are in use by the engine and each project
#! This visits gems listed in the engine.json,
#! the gems listed in the each O3DE_PROJECTS project.json,
#! and the gems listed o3de_manifest.json in which the engine.json/project.json
#! references in their gem_names key.
function(call_add_subdirectory_on_gems)
    # Query the list of gems in use by the engine and any projects
    get_gems_in_use(all_gems)

    # Log the gem visit order
    message(VERBOSE "add_subdirectory will be called on the following gems in order:")
    foreach(gem IN LISTS all_gems)
        message(VERBOSE "${gem}")
    endforeach()

    # Loop over the additional gems and invoke add_subdirectory on them
    foreach(gem IN LISTS all_gems)
        # Hash the gem name and append it to the Binary Directory section of add_subdirectory
        # This is to deal with potential situations where multiple gems has the same last directory name
        # For example if D:/Company1/RayTracingGem and F:/Company2/Path/RayTracingGem were both added as a subdirectory
        file(REAL_PATH ${gem} full_directory_path)
        string(SHA256 full_directory_hash ${full_directory_path})
        # Truncate the full_directory_hash down to 8 characters to avoid hitting the Windows 260 character path limit
        # when the gem contains relative paths of significant length
        string(SUBSTRING ${full_directory_hash} 0 8 full_directory_hash)
        # Use the last directory as the suffix path to use for the Binary Directory
        cmake_path(GET gem FILENAME directory_name)
        add_subdirectory(${gem} ${CMAKE_BINARY_DIR}/Gem/${directory_name}-${full_directory_hash})
    endforeach()
endfunction()

#! o3de_add_manifest_gem_subdirectories: add_subdirectory() every top-level
#  gem indexed in the resolved manifest.
#
#  The resolved manifest (user-level for source builds, workspace-scoped
#  for workspace builds) is the single source of gem paths � no re-solve
#  happens here.  Nested gems (a gem rooted inside another gem) are
#  skipped: their parent gem's CMakeLists is responsible for them.
#
# \arg:exclude_prefix directory tree to skip (e.g. the project source
#      dir whose own gem is added natively by the project CMakeLists)
function(o3de_add_manifest_gem_subdirectories exclude_prefix)
    get_property(all_gem_paths GLOBAL PROPERTY O3DE_MANIFEST_ALL_GEM_PATHS)

    # collect gem roots
    set(gem_roots "")
    foreach(gem_json_path IN LISTS all_gem_paths)
        get_filename_component(gem_root "${gem_json_path}" DIRECTORY)
        list(APPEND gem_roots ${gem_root})
    endforeach()
    list(REMOVE_DUPLICATES gem_roots)

    foreach(gem_root IN LISTS gem_roots)
        # skip gems inside the excluded tree
        if(exclude_prefix)
            cmake_path(IS_PREFIX exclude_prefix ${gem_root} NORMALIZE inside_excluded)
            if(inside_excluded)
                continue()
            endif()
        endif()

        # skip nested gems � their parent adds them
        set(is_nested FALSE)
        foreach(other_root IN LISTS gem_roots)
            if(NOT other_root STREQUAL gem_root)
                cmake_path(IS_PREFIX other_root ${gem_root} NORMALIZE is_nested_in_other)
                if(is_nested_in_other)
                    set(is_nested TRUE)
                    break()
                endif()
            endif()
        endforeach()
        if(is_nested)
            continue()
        endif()

        # skip gems without a build script (asset-only gems)
        if(NOT EXISTS ${gem_root}/CMakeLists.txt)
            continue()
        endif()

        # idempotence guard
        get_property(already_added GLOBAL PROPERTY "O3DE_GEM_SUBDIR_ADDED_${gem_root}")
        if(already_added)
            continue()
        endif()
        set_property(GLOBAL PROPERTY "O3DE_GEM_SUBDIR_ADDED_${gem_root}" TRUE)

        # unique binary dir from the gem's canonical name
        get_property(gem_canonical_name GLOBAL PROPERTY O3DE_PATH_${gem_root}/gem.json_NAME)
        if(NOT gem_canonical_name)
            get_filename_component(gem_canonical_name "${gem_root}" NAME)
        endif()

        # PREBUILT gems: when the resolved manifest marks this gem's
        # artifact form as a binary package (workspace override), skip
        # building from source and import targets from the package's
        # config instead.
        get_property(gem_artifact GLOBAL PROPERTY O3DE_PATH_${gem_root}/gem.json_ARTIFACT)
        if(gem_artifact AND NOT gem_artifact STREQUAL "source")
            get_property(gem_binary_config_path GLOBAL PROPERTY O3DE_PATH_${gem_root}/gem.json_BINARY_CONFIG_PATH)
            set(gem_binary_config "${gem_binary_config_path}/${gem_canonical_name}Config.cmake")
            if(gem_binary_config_path AND EXISTS ${gem_binary_config})
                message(STATUS "Gem ${gem_canonical_name}: using prebuilt package (${gem_artifact}) at ${gem_binary_config_path}")
                include(${gem_binary_config})
                continue()
            else()
                message(WARNING
                    "Gem ${gem_canonical_name} is marked artifact=${gem_artifact} but no package "
                    "config was found at '${gem_binary_config}' — falling back to source build.")
            endif()
        endif()

        add_subdirectory(${gem_root} ${CMAKE_BINARY_DIR}/Gems/${gem_canonical_name})
    endforeach()
endfunction()
