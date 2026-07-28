#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(FindPackageHandleStandardArgs)

# Legacy ly_* API shims for shared 3rd-party package Find scripts
include(${CMAKE_CURRENT_LIST_DIR}/LegacyCompatibility.cmake)

#! o3de_add_dependencies: wrapper to add_dependencies, however, this wrapper collaborates with
#  O3deWrappers.cmake to delay adding dependencies if the target is not declared yet.
#
# This wrapper will add the dependency to the indicated target immediately if the target was
# already added. If the target was not added at the moment this function is called, the dependency
# will be stored in a global variable which o3de_add_target will access and create those dependencies
# after the target is added.
#
# \arg:TARGET name of the target
# \arg:DEPENDENCIES dependencies to add to TARGET
#
function(o3de_add_dependencies TARGET)

    if(NOT TARGET)
        message(FATAL_ERROR "You must provide a target")
    endif()
    set (extra_function_args ${ARGN})
    if(num_extra_args)
        message(FATAL_ERROR "You must provide at least a dependency")
    endif()

    if(${TARGET} IN_LIST extra_function_args)
        message(FATAL_ERROR "Cyclic dependency detected ${TARGET} depends on ${extra_function_args}")
    endif()
    if(TARGET ${TARGET})
        # Target already created — add dependencies that exist now, and
        # defer the ones whose targets haven't been declared yet (gems
        # are processed in manifest order, not dependency order).
        o3de_parse_third_party_dependencies("${extra_function_args}")
        # Dependencies can only be added on non-alias target
        o3de_de_alias_target(${TARGET} de_aliased_target)
        unset(existing_dependencies)
        foreach(dependency IN LISTS extra_function_args)
            if(TARGET ${dependency})
                list(APPEND existing_dependencies ${dependency})
            else()
                set_property(GLOBAL APPEND PROPERTY O3DE_DEFERRED_TARGET_DEPENDENCIES "${de_aliased_target}|${dependency}")
            endif()
        endforeach()
        if(existing_dependencies)
            add_dependencies(${de_aliased_target} ${existing_dependencies})
        endif()
    else()
        set_property(GLOBAL APPEND PROPERTY O3DE_DELAYED_DEPENDENCIES_${TARGET} ${extra_function_args})
    endif()

endfunction()

#! o3de_flush_deferred_dependencies: resolve dependencies that were
#  declared before their dependency targets existed.  Must run in
#  post-processing, after every target has been created.
function(o3de_flush_deferred_dependencies)
    get_property(deferred_pairs GLOBAL PROPERTY O3DE_DEFERRED_TARGET_DEPENDENCIES)
    foreach(pair IN LISTS deferred_pairs)
        string(REPLACE "|" ";" pair_list "${pair}")
        list(GET pair_list 0 pair_target)
        list(GET pair_list 1 pair_dependency)
        if(TARGET ${pair_dependency})
            o3de_de_alias_target(${pair_dependency} de_aliased_dependency)
            add_dependencies(${pair_target} ${de_aliased_dependency})
        else()
            message(WARNING "Target '${pair_target}' declared a dependency on '${pair_dependency}', which was never created — skipping")
        endif()
    endforeach()
    set_property(GLOBAL PROPERTY O3DE_DEFERRED_TARGET_DEPENDENCIES)
endfunction()

#! o3de_find_packages: find every package in a list of O3DE name/version specifiers
#
# \arg:o3de_package_names_and_versions - list of specifiers (e.g. "org.o3de.gem.a>=1.0.0;org.o3de.gem.b")
function(o3de_find_packages o3de_package_names_and_versions)
    foreach(o3de_package_name_and_version IN LISTS o3de_package_names_and_versions)
        o3de_find_package("${o3de_package_name_and_version}")
    endforeach()
endfunction()

#! o3de_find_package: Find a package using O3DE naming convention
#
# This function wraps CMake's find_package() to work with O3DE package naming and version 
# specifiers. It supports version constraints and optionally returns package information
# to the caller through output variables.
#
# \arg:o3de_package_name_and_version - Package name with optional version constraint 
#                                      (e.g., "MyPackage>=1.2.0", "AnotherPackage==2.1.0")
# \arg:FOUND_VAR - (Optional) Variable name to store the package found status (TRUE/FALSE)
# \arg:DIR_VAR - (Optional) Variable name to store the package configuration directory path
#
# The function will call FATAL_ERROR if the package is not found (REQUIRED behavior).
# If found, it logs the package name and version, and optionally sets return variables.
#
# Examples:
# 
# Basic usage (no return values):
#   o3de_find_package("org.o3de.gem.achievements>=1.1.0")
#
# Get package found status:
#   o3de_find_package("org.o3de.gem.achievements>=1.1.0" FOUND_VAR achievements_found)
#   if(achievements_found)
#       message(STATUS "Achievements was successfully found")
#   endif()
#
# Get both found status and config directory:
#   o3de_find_package("org.o3de.gem.achievements>=1.1.0" FOUND_VAR found DIR_VAR achievements_json)
#   message(STATUS "Achievements found: ${found}, at: ${achievements_json}")
#
function(o3de_find_package o3de_package_name_and_version)# found, object_json_path) 
    # Parse additional arguments for optional return values
    set(options "")
    set(oneValueArgs FOUND_VAR DIR_VAR)
    set(multiValueArgs "")
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # convert the O3DE package name and version specifier to CMake format
    o3de_version_specifier_to_cmake_format("${o3de_package_name_and_version}" cmake_package_name cmake_package_version cmake_package_args)

    # Use the converted version and arguments to find the package
    find_package(${cmake_package_name} ${cmake_package_version} ${cmake_package_args} REQUIRED)

    #see if we found the package
    set(package_found ${${cmake_package_name}_FOUND})
    if(NOT ${package_found})
        message(FATAL_ERROR "Failed to find package ${cmake_package_name}")
    else()
        #see which package version was found
        set(package_version ${${cmake_package_name}_VERSION})
        
        # Set optional return values if requested
        if(ARG_FOUND_VAR)
            set(${ARG_FOUND_VAR} ${package_found} PARENT_SCOPE)
        endif()
        
        if(ARG_DIR_VAR AND ${package_found} AND ${cmake_package_name}_DIR)
            #set the list of types to try on the candidate_path
            set(package_path ${${cmake_package_name}_DIR})
            set(candidate_path ${package_path})
            set(candidate_types "engine.json" "project.json" "gem.json" "template.json" "repo.json")

            #walk up from the package dir until an object json is found
            unset(object_json_path)
            while(NOT candidate_path STREQUAL "")
                # loop through the candidate_types and check if the file exists
                foreach(candidate_type ${candidate_types})
                    # append the candidate_type to the candidate_path
                    cmake_path(APPEND candidate_path ${candidate_type} OUTPUT_VARIABLE test_json_path)
                    if (EXISTS ${test_json_path})
                        # if we found an object_json_path, we break out of the loop
                        set(object_json_path ${test_json_path})
                        break()
                    endif()
                endforeach()
                if(object_json_path)
                    break()
                endif()
                # try the parent path; stop at the filesystem root where
                # the parent equals the current path
                cmake_path(GET candidate_path PARENT_PATH parent_path)
                if(parent_path STREQUAL candidate_path)
                    break()
                endif()
                set(candidate_path ${parent_path})
            endwhile()

            #If we don't find one then something went wrong
            if(NOT object_json_path)
                message(FATAL_ERROR "Failed to find package ${cmake_package_name}")
            else()
                set(${ARG_DIR_VAR} ${object_json_path} PARENT_SCOPE)
            endif()
        endif()
    endif()
endfunction()

