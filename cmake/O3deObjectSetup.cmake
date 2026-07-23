#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

macro(o3de_gem_setup)

    #resolved manifest data
    set(gem_path ${CMAKE_CURRENT_SOURCE_DIR})    
    set(gem_json ${gem_path}/gem.json)
    set(gem_json_path ${gem_json})
    get_property(gem_name GLOBAL PROPERTY O3DE_PATH_${gem_json}_NAME)
    get_property(gem_version GLOBAL PROPERTY O3DE_PATH_${gem_json}_VERSION)
    get_property(cmake_relative_path GLOBAL PROPERTY O3DE_PATH_${gem_json}_CMAKE_RELATIVE_PATH)
    get_property(child_engine_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_CHILD_ENGINE_PATHS)
    get_property(child_project_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_CHILD_PROJECT_PATHS)
    get_property(child_gem_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_CHILD_GEM_PATHS)
    get_property(child_template_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_CHILD_TEMPLATE_PATHS)
    get_property(child_restricted_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_CHILD_RESTRICTED_PATHS)
    get_property(child_repo_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_CHILD_REPO_PATHS)
    get_property(parent_paths GLOBAL PROPERTY O3DE_PATH_${gem_json}_PARENT_PATHS)
    get_property(dependent_engines GLOBAL PROPERTY O3DE_PATH_${gem_json}_DEPENDENT_ENGINES)
    get_property(dependent_projects GLOBAL PROPERTY O3DE_PATH_${gem_json}_DEPENDENT_PROJECTS)
    get_property(dependent_gems GLOBAL PROPERTY O3DE_PATH_${gem_json}_DEPENDENT_GEMS)
    get_property(dependent_templates GLOBAL PROPERTY O3DE_PATH_${gem_json}_DEPENDENT_TEMPLATES)
    get_property(dependent_restricteds GLOBAL PROPERTY O3DE_PATH_${gem_json}_DEPENDENT_RESTRICTEDS)

    # Fall back to reading the gem.json directly when the gem is not in
    # the resolved manifest (e.g. project-embedded gems)
    if(NOT gem_name)
        o3de_read_json_key(gem_name ${gem_json} "gem" "name")
    endif()
    if(NOT gem_version)
        o3de_read_json_key(gem_version ${gem_json} "gem" "version")
    endif()

    # CMake TARGET names use the legacy short gem name (e.g. Atom_RPI):
    # cross-gem BUILD_DEPENDENCIES throughout the codebase reference
    # Gem::<ShortName>.* — the canonical reverse-domain name remains the
    # package/manifest identity only.  Read the legacy gem.json directly
    # (o3de_file_read_cache would transparently prefer the 2-0-0 sidecar,
    # which does not carry gem_name).
    if(EXISTS ${gem_json})
        file(READ ${gem_json} _legacy_gem_json_data)
        string(JSON _legacy_gem_name ERROR_VARIABLE _legacy_gem_name_err GET "${_legacy_gem_json_data}" "gem_name")
        if(NOT _legacy_gem_name_err AND _legacy_gem_name)
            set(gem_name ${_legacy_gem_name})
        endif()
        unset(_legacy_gem_json_data)
        unset(_legacy_gem_name)
        unset(_legacy_gem_name_err)
    endif()

    #PAL
    o3de_pal_path_object_json(${gem_json} ${CMAKE_CURRENT_SOURCE_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_dir)
endmacro()


macro(o3de_repo_setup default_repo_name)
    unset(repo_path)
    unset(repo_json)
    unset(repo_name)
    unset(repo_version)
    unset(repo_cmake_relative_path)
    unset(repo_cmake_path)
    unset(repo_restricted_path)
    unset(repo_parent_relative_path)
    unset(pal_dir)
    unset(child_engine_paths)
    unset(child_project_paths)
    unset(child_gem_paths)
    unset(child_template_paths)
    unset(child_restricted_paths)
    unset(child_repo_paths)
    unset(parent_paths)
    unset(dependent_engines)
    unset(dependent_projects)
    unset(dependent_gems)
    unset(dependent_templates)
    unset(dependent_restricteds)

    #resolved manifest data
    set(repo_path ${CMAKE_CURRENT_SOURCE_DIR})    
    set(repo_json ${repo_path}/repo.json)
    get_property(repo_name GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_NAME})
    get_property(repo_version GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_VERSION})
    #repos don't have a cmake relative path
    #get_property(cmake_relative_path GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CMAKE_RELATIVE_PATH})
    get_property(child_engine_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CHILD_ENGINE_PATHS})
    get_property(child_project_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CHILD_PROJECT_PATHS})
    get_property(child_gem_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CHILD_GEM_PATHS})
    get_property(child_template_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CHILD_TEMPLATE_PATHS})
    get_property(child_restricted_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CHILD_RESTRICTED_PATHS})
    get_property(child_repo_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_CHILD_REPO_PATHS})
    get_property(parent_paths GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_PARENT_PATHS})
    get_property(dependent_engines GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_DEPENDENT_ENGINES})
    get_property(dependent_projects GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_DEPENDENT_PROJECTS})
    get_property(dependent_gems GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_DEPENDENT_GEMS})
    get_property(dependent_templates GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_DEPENDENT_TEMPLATES})
    get_property(dependent_restricteds GLOBAL PROPERTY ${O3DE_PATH_${repo_json}_DEPENDENT_RESTRICTEDS})

    #PAL
    o3de_pal_path_object_json(${repo_json} ${CMAKE_CURRENT_SOURCE_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_dir)
endmacro()

# o3de_restricted_setup: Runs a CMAKE macro that reads the nearest ancestor restricted.json
# of where the calling CMakeLists.txt is located and queries information
# about the Restricted such as the Restricted name and version
# NOTE: A CMake `macro` is used and not a `function` as it a macro
# executes in the same scope of the caller
# https://cmake.org/cmake/help/latest/command/macro.html#macro-vs-function
#
# \param:default_restricted_name - Name to use for the ${restricted_name} variable
#        if a restricted.json file cannot be found by searching ancestor directories
#        or if the "restricted_json" file does not contain a "restricted_name" field
#
# \return:restricted_path - Sets the ${restricted_path} variable to the directory containing
#         the restricted.json that is the nearest ancestor directory of the calling CMakeLists.txt.
#         The "nearest ancestor" also includes the current CMakeLists.txt for clarification
# \return:restricted_name - Sets the ${restricted_name} variable to the "restricted_name" field
# \return:restricted_version - Sets the ${restricted_version} variable to the "restricted_version" field
macro(o3de_restricted_setup default_restricted_name)
    unset(restricted_path)
    unset(restricted_json)
    unset(restricted_name)
    unset(restricted_version)
    unset(restricted_cmake_relative_path)
    unset(restricted_cmake_path)
    unset(restricted_restricted_path)
    unset(restricted_parent_relative_path)
    unset(pal_dir)
    unset(child_engine_paths)
    unset(child_project_paths)
    unset(child_gem_paths)
    unset(child_template_paths)
    unset(child_restricted_paths)
    unset(child_repo_paths)
    unset(parent_paths)
    unset(dependent_engines)
    unset(dependent_projects)
    unset(dependent_gems)
    unset(dependent_templates)
    unset(dependent_restricteds)

    #resolved manifest data
    set(restricted_path ${CMAKE_CURRENT_SOURCE_DIR})    
    set(restricted_json ${repo_path}/restricted.json)
    get_property(repo_name GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_NAME})
    get_property(repo_version GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_VERSION})
    #restricted don't have a cmake relative path
    #get_property(cmake_relative_path GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CMAKE_RELATIVE_PATH})
    get_property(child_engine_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CHILD_ENGINE_PATHS})
    get_property(child_project_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CHILD_PROJECT_PATHS})
    get_property(child_gem_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CHILD_GEM_PATHS})
    get_property(child_template_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CHILD_TEMPLATE_PATHS})
    get_property(child_restricted_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CHILD_RESTRICTED_PATHS})
    get_property(child_repo_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_CHILD_REPO_PATHS})
    get_property(parent_paths GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_PARENT_PATHS})
    get_property(dependent_engines GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_DEPENDENT_ENGINES})
    get_property(dependent_projects GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_DEPENDENT_PROJECTS})
    get_property(dependent_gems GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_DEPENDENT_GEMS})
    get_property(dependent_templates GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_DEPENDENT_TEMPLATES})
    get_property(dependent_restricteds GLOBAL PROPERTY ${O3DE_PATH_${restricted_json}_DEPENDENT_RESTRICTEDS})

    #set this restricted cmake path from the restricted path / cmake relative path
    #restricted don't have a cmake relative path and therefore no cmake path
    #set(restricted_cmake_path ${restricted_path}/${cmake_relative_path})

    #PAL
    #restricted cant have restricted
endmacro()
