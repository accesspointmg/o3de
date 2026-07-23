#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

##########################################################################
# The o3de manifest must be resolved immediately on the host
# NOTE: DO NOT CALL PYTHON THIS WAY ANYWHERE ELSE IN THE CMAKE FILES, THIS IS ONLY ACCEPTABLE FOR RESOLVING THE MANIFEST!!!

# Workspace builds carry a compose-time resolved manifest — resolution
# already happened when the workspace was assembled, so we must NOT
# re-resolve (it would consult the user manifest and point at sources
# instead of the composed workspace tree).
o3de_get_resolved_manifest_path(o3de_preresolved_manifest_path)
o3de_get_user_home_path(o3de_user_home_path)
if(NOT o3de_preresolved_manifest_path STREQUAL "${o3de_user_home_path}/.o3de/resolved_o3de_manifest.json")
    set(O3DE_MANIFEST_IS_WORKSPACE_SCOPED TRUE)
    message("Using workspace-scoped resolved manifest: ${o3de_preresolved_manifest_path}")
endif()

if(NOT O3DE_MANIFEST_IS_WORKSPACE_SCOPED)
# Make sure the user has ran get_python first
message("Checking Python installation...")
get_filename_component(python_path "${CMAKE_CURRENT_LIST_DIR}/../python" ABSOLUTE)
if(CMAKE_HOST_WIN32)
    execute_process(COMMAND
        ${python_path}/python.cmd --version
        WORKING_DIRECTORY ${python_path}
        RESULT_VARIABLE command_result
        ERROR_VARIABLE command_error
    )
    if(NOT command_result EQUAL 0)
        message(FATAL_ERROR "You must first run o3de/python> ./get_python.sh")
    endif()
else() #CMAKE_HOST_UNIX or CMAKE_HOST_APPLE
    execute_process(COMMAND
        ${python_path}/python.sh --version
        WORKING_DIRECTORY ${python_path}
        RESULT_VARIABLE command_result
        ERROR_VARIABLE command_error
    )
    if(NOT command_result EQUAL 0)
        message(FATAL_ERROR "You must first run o3de/python> get_python.cmd")
    endif()
endif()

# The user has run get_python

# Resolve the manifest
message("Resolving O3DE manifest...")
get_filename_component(scripts_path "${CMAKE_CURRENT_LIST_DIR}/../scripts" ABSOLUTE)
if(CMAKE_HOST_WIN32)
    execute_process(COMMAND
        ${scripts_path}/o3de.bat resolve
        WORKING_DIRECTORY ${scripts_path}
        RESULT_VARIABLE command_result
        ERROR_VARIABLE command_error
    )
    if(NOT command_result EQUAL 0)
        message(FATAL_ERROR "Failed to resolve O3DE manifest: ${scripts_path}/o3de.bat resolve\nError: ${command_error}")
    endif()
else() #CMAKE_HOST_UNIX or CMAKE_HOST_APPLE
    execute_process(COMMAND
        ${scripts_path}/o3de.sh resolve
        WORKING_DIRECTORY ${scripts_path}
        RESULT_VARIABLE command_result
        ERROR_VARIABLE command_error
    )
    if(NOT command_result EQUAL 0)
        message(FATAL_ERROR "Failed to resolve O3DE manifest: ${scripts_path}/o3de.sh resolve\nError: ${command_error}")
    endif()
endif()

#clean up
unset(command_result)
unset(command_error)
unset(python_path)
unset(script_path)
endif() # NOT O3DE_MANIFEST_IS_WORKSPACE_SCOPED
##########################################################################

# get the path to the resolved manifest
o3de_get_resolved_manifest_path(resolved_o3de_manifest_resolved_path)
if(NOT EXISTS ${resolved_o3de_manifest_resolved_path})
    message(FATAL_ERROR "The resolved manifest file ${resolved_o3de_manifest_resolved_path} does not exist!")
endif()

# reading the resolved manifest json
file(READ ${resolved_o3de_manifest_resolved_path} O3DE_MANIFEST_RESOLVED_JSON_DATA)
set_property(GLOBAL PROPERTY O3DE_MANIFEST_RESOLVED_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA})

message("Loading O3DE resolved manifest...")

#manifest properties
set(manifest_properties "country_code;default_engines_path;default_projects_path;default_gems_path;default_templates_path;default_repos_path;default_overlays_path;default_third_party_path")
foreach(manifest_property IN LISTS manifest_properties)
    string(TOUPPER ${manifest_property} manifest_property_upper)
    o3de_get_json_key(O3DE_MANIFEST_${manifest_property_upper} ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${manifest_property})
    set_property(GLOBAL PROPERTY O3DE_MANIFEST_${manifest_property_upper} ${O3DE_MANIFEST_${manifest_property_upper}})
endforeach()

#manifest name arrays
#note: these 'names' are "name==version" i.e. "org.o3de.template.assetgem==1.0.0"
set(manifest_arrays "all_engine_names;all_project_names;all_gem_names;all_template_names;all_repo_names;all_overlay_names")
foreach(manifest_array IN LISTS manifest_arrays)
    string(TOUPPER ${manifest_array} manifest_array_upper)
    o3de_get_json_array(O3DE_MANIFEST_${manifest_array_upper} ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${manifest_array})
    set_property(GLOBAL PROPERTY O3DE_MANIFEST_${manifest_array_upper} ${O3DE_MANIFEST_${manifest_array_upper}})
endforeach()

#manifest path arrays
set(manifest_arrays "all_engine_paths;all_project_paths;all_gem_paths;all_template_paths;all_repo_paths;all_overlay_paths")
foreach(manifest_array IN LISTS manifest_arrays)
    string(TOUPPER ${manifest_array} manifest_array_upper)
    o3de_get_json_array(O3DE_MANIFEST_${manifest_array_upper} ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${manifest_array})
    list(REMOVE_DUPLICATES O3DE_MANIFEST_${manifest_array_upper})
    set_property(GLOBAL PROPERTY O3DE_MANIFEST_${manifest_array_upper} ${O3DE_MANIFEST_${manifest_array_upper}})

    #use the path to read the manifest objects
    foreach(path_entry IN LISTS O3DE_MANIFEST_${manifest_array_upper})
        #get the directory and add it to the CMAKE_PREFIX_PATH so find_package can locate it
        get_filename_component(directory "${path_entry}" DIRECTORY)
        list(APPEND CMAKE_PREFIX_PATH "${directory}")

        if(manifest_array STREQUAL "all_engine_paths")
            # Read the engine object at this path
            o3de_get_json_key(O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${path_entry})
            set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_PATH_${path_entry}_JSON_DATA})

            # Read the engine properties
            set(engine_properties "name;version;display_name;description;type;id;copyright_year;copyright_text;api_version_editor;api_version_framework;api_version_launcher;api_version_tools")
            foreach(engine_property IN LISTS engine_properties)
                string(TOUPPER ${engine_property} engine_property_upper)
                o3de_get_json_key(O3DE_PATH_${path_entry}_${engine_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${engine_property})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${engine_property_upper} ${O3DE_PATH_${path_entry}_${engine_property_upper}})

                if(engine_property STREQUAL "name")
                    set(last_engine_name ${O3DE_PATH_${path_entry}_NAME})
                endif()

                if(engine_property STREQUAL "version")
                    set(last_engine_version ${O3DE_PATH_${path_entry}_VERSION})
                    
                    set(O3DE_ENGINE_${last_engine_name}_${last_engine_version} ${path_entry})
                    set_property(GLOBAL PROPERTY O3DE_ENGINE_${last_engine_name}_${last_engine_version} ${O3DE_ENGINE_${last_engine_name}_${last_engine_version}})
                endif()
            endforeach()
        
            # Read the engine arrays
            set(engine_arrays "canonical_tags;user_tags;platforms;child_engine_json_paths;child_project_json_paths;child_gem_json_paths;child_template_json_paths;child_repo_json_paths;parent_json_paths;dependent_engines;dependent_projects;dependent_gems;dependent_templates;dependent_repos")
            foreach(engine_array IN LISTS engine_arrays)
                string(TOUPPER ${engine_array} engine_array_upper)
                o3de_get_json_array(O3DE_PATH_${path_entry}_${engine_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${engine_array})
                list(REMOVE_DUPLICATES O3DE_PATH_${path_entry}_${engine_array_upper})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${engine_array_upper} ${O3DE_PATH_${path_entry}_${engine_array_upper}})
            endforeach()

            # Check for optional overrides in the user/engine.json
            # get the parent directory of the path_entry
            get_filename_component(engine_path "${path_entry}" DIRECTORY)
            set(user_engine_json ${engine_path}/user/engine.json)
            if(EXISTS ${user_engine_json})
                file(READ "${user_engine_json}" O3DE_PATH_${user_engine_json}_JSON_DATA)
                set_property(GLOBAL PROPERTY O3DE_PATH_${user_engine_json}_JSON_DATA ${O3DE_PATH_${user_engine_json}_JSON_DATA})

                # Read the engine override properties
                set(engine_override_properties "")
                foreach(engine_override_property IN LISTS engine_override_properties)
                    string(TOUPPER ${engine_override_property} engine_override_property_upper)
                    o3de_get_json_key(O3DE_PATH_${path_entry}_${engine_override_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${engine_override_property})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${engine_override_property_upper} ${O3DE_PATH_${path_entry}_${engine_override_property_upper}})
                endforeach()
            
                # Read the engine override arrays
                set(engine_override_arrays "")
                foreach(engine_array IN LISTS engine_arrays)
                    string(TOUPPER ${engine_array} engine_array_upper)
                    o3de_get_json_array(O3DE_PATH_${path_entry}_${engine_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${engine_array})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${engine_array_upper} ${O3DE_PATH_${path_entry}_${engine_array_upper}})
                endforeach()
            endif()

        elseif(manifest_array STREQUAL "all_project_paths")
            # Read the project object at this path
            o3de_get_json_key(O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${path_entry})
            set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_PATH_${path_entry}_JSON_DATA})

            # Read the project properties
            set(project_properties "name;version;display_name;description;type;id;copyright_year;copyright_text;product_name;executable_name;engine")
            foreach(project_property IN LISTS project_properties)
                string(TOUPPER ${project_property} project_property_upper)
                o3de_get_json_key(O3DE_PATH_${path_entry}_${project_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${project_property})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${project_property_upper} ${O3DE_PATH_${path_entry}_${project_property_upper}})

                if(project_property STREQUAL "name")
                    set(last_project_name ${O3DE_PATH_${path_entry}_NAME})
                endif()

                if(project_property STREQUAL "version")
                    set(last_project_version ${O3DE_PATH_${path_entry}_VERSION})

                    set(O3DE_PROJECT_${last_project_name}_${last_project_version} ${path_entry})
                    set_property(GLOBAL PROPERTY O3DE_PROJECT_${last_project_name}_${last_project_version} ${O3DE_PROJECT_${last_project_name}_${last_project_version}})
                endif()
            endforeach()

            # Read the project arrays
            set(project_arrays "canonical_tags;user_tags;platforms;child_engine_json_paths;child_project_json_paths;child_gem_json_paths;child_template_json_paths;child_repo_json_paths;parent_json_paths;dependent_engines;dependent_projects;dependent_gems;dependent_templates;dependent_repos")
            foreach(project_array IN LISTS project_arrays)
                string(TOUPPER ${project_array} project_array_upper)
                o3de_get_json_array(O3DE_PATH_${path_entry}_${project_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${project_array})
                list(REMOVE_DUPLICATES O3DE_PATH_${path_entry}_${project_array_upper})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${project_array_upper} ${O3DE_PATH_${path_entry}_${project_array_upper}})
            endforeach()

            # Check for optional overrides in the user/project.json
            # get the parent directory of the path_entry
            get_filename_component(project_path "${path_entry}" DIRECTORY)
            set(user_project_json ${project_path}/user/project.json)
            if(EXISTS ${user_project_json})
                file(READ "${user_project_json}" O3DE_PATH_${user_project_json}_JSON_DATA)
                set_property(GLOBAL PROPERTY O3DE_PATH_${user_project_json}_JSON_DATA ${O3DE_PATH_${user_project_json}_JSON_DATA})

                # Read the project override properties
                set(project_override_properties "engine")
                foreach(project_override_property IN LISTS project_override_properties)
                    string(TOUPPER ${project_override_property} project_override_property_upper)
                    o3de_get_json_key(O3DE_PATH_${path_entry}_${project_override_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${project_override_property})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${project_override_property_upper} ${O3DE_PATH_${path_entry}_${project_override_property_upper}})
                endforeach()

                # Read the project override arrays
                set(project_override_arrays "")
                foreach(project_array IN LISTS project_arrays)
                    string(TOUPPER ${project_array} project_array_upper)
                    o3de_get_json_array(O3DE_PATH_${path_entry}_${project_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${project_array})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${project_array_upper} ${O3DE_PATH_${path_entry}_${project_array_upper}})
                endforeach()
            endif()

        elseif(manifest_array STREQUAL "all_gem_paths")
            # Read the gem object at this path
            o3de_get_json_key(O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${path_entry})
            set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_PATH_${path_entry}_JSON_DATA})

            # Read the gem properties.
            # artifact + binary_config_path are workspace-manifest-only fields
            # selecting the artifact form (source vs prebuilt binary package);
            # consumed by o3de_add_manifest_gem_subdirectories.
            set(gem_properties "name;version;display_name;description;type;id;copyright_year;copyright_text;artifact;binary_config_path")
            foreach(gem_property IN LISTS gem_properties)
                string(TOUPPER ${gem_property} gem_property_upper)
                o3de_get_json_key(O3DE_PATH_${path_entry}_${gem_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${gem_property})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${gem_property_upper} ${O3DE_PATH_${path_entry}_${gem_property_upper}})

                if(gem_property STREQUAL "name")
                    set(last_gem_name ${O3DE_PATH_${path_entry}_NAME})
                endif()

                if(gem_property STREQUAL "version")
                    set(last_gem_version ${O3DE_PATH_${path_entry}_VERSION})

                    set(O3DE_GEM_${last_gem_name}_${last_gem_version} ${path_entry})
                    set_property(GLOBAL PROPERTY O3DE_GEM_${last_gem_name}_${last_gem_version} ${O3DE_GEM_${last_gem_name}_${last_gem_version}})

                    # Register the gem root for target file lists and
                    # gem machinery ("@GEMROOT:<name>@").  Register the
                    # canonical name (org.o3de.gem.multiplayer) and the
                    # legacy gem_name from the unversioned gem.json
                    # (unique per gem — unlike directory names, which
                    # collide: Core/PhysX5 vs Debug/PhysX5).
                    get_filename_component(gemroot_dir "${path_entry}" DIRECTORY)
                    set_property(GLOBAL PROPERTY "@GEMROOT:${last_gem_name}@" "${gemroot_dir}")
                    if(EXISTS ${gemroot_dir}/gem.json)
                        file(READ ${gemroot_dir}/gem.json legacy_gem_json_data)
                        string(JSON legacy_gem_name ERROR_VARIABLE legacy_gem_name_err GET "${legacy_gem_json_data}" "gem_name")
                        if(NOT legacy_gem_name_err AND legacy_gem_name)
                            set_property(GLOBAL PROPERTY "@GEMROOT:${legacy_gem_name}@" "${gemroot_dir}")
                        endif()
                        unset(legacy_gem_json_data)
                        unset(legacy_gem_name)
                        unset(legacy_gem_name_err)
                    endif()
                endif()
            endforeach()

            # Read the gem arrays
            set(gem_arrays "canonical_tags;user_tags;platforms;child_engine_json_paths;child_project_json_paths;child_gem_json_paths;child_template_json_paths;child_repo_json_paths;parent_json_paths;dependent_engines;dependent_projects;dependent_gems;dependent_templates;dependent_repos")
            foreach(gem_array IN LISTS gem_arrays)
                string(TOUPPER ${gem_array} gem_array_upper)
                o3de_get_json_array(O3DE_PATH_${path_entry}_${gem_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${gem_array})
                list(REMOVE_DUPLICATES O3DE_PATH_${path_entry}_${gem_array_upper})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${gem_array_upper} ${O3DE_PATH_${path_entry}_${gem_array_upper}})
            endforeach()

            # Check for optional overrides in the user/gem.json
            # get the parent directory of the path_entry
            get_filename_component(gem_path "${path_entry}" DIRECTORY)
            set(user_gem_json ${gem_path}/user/gem.json)
            if(EXISTS ${user_gem_json})
                file(READ "${user_gem_json}" O3DE_PATH_${user_gem_json}_JSON_DATA)
                set_property(GLOBAL PROPERTY O3DE_PATH_${user_gem_json}_JSON_DATA ${O3DE_PATH_${user_gem_json}_JSON_DATA})

                # Read the gem override properties
                set(gem_override_properties "")
                foreach(gem_override_property IN LISTS gem_override_properties)
                    string(TOUPPER ${gem_override_property} gem_override_property_upper)
                    o3de_get_json_key(O3DE_PATH_${path_entry}_${gem_override_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${gem_override_property})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${gem_override_property_upper} ${O3DE_PATH_${path_entry}_${gem_override_property_upper}})
                endforeach()

                # Read the gem override arrays
                set(gem_override_arrays "")
                foreach(gem_array IN LISTS gem_arrays)
                    string(TOUPPER ${gem_array} gem_array_upper)
                    o3de_get_json_array(O3DE_PATH_${path_entry}_${gem_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${gem_array})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${gem_array_upper} ${O3DE_PATH_${path_entry}_${gem_array_upper}})
                endforeach()
            endif()

        elseif(manifest_array STREQUAL "all_template_paths")
            # Read the template object at this path
            o3de_get_json_key(O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${path_entry})
            set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_PATH_${path_entry}_JSON_DATA})

            # Read the template properties
            set(template_properties "name;version;display_name;description;type;id;copyright_year;copyright_text")
            foreach(template_property IN LISTS template_properties)
                string(TOUPPER ${template_property} template_property_upper)
                o3de_get_json_key(O3DE_PATH_${path_entry}_${template_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${template_property})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${template_property_upper} ${O3DE_PATH_${path_entry}_${template_property_upper}})

                if(template_property STREQUAL "name")
                    set(last_template_name ${O3DE_PATH_${path_entry}_NAME})
                endif()

                if(template_property STREQUAL "version")
                    set(last_template_version ${O3DE_PATH_${path_entry}_VERSION})

                    set(O3DE_TEMPLATE_${last_template_name}_${last_template_version} ${path_entry})
                    set_property(GLOBAL PROPERTY O3DE_TEMPLATE_${last_template_name}_${last_template_version} ${O3DE_TEMPLATE_${last_template_name}_${last_template_version}})
                endif()
            endforeach()

            # Read the template arrays
            set(template_arrays "canonical_tags;user_tags;platforms;child_engine_json_paths;child_project_json_paths;child_gem_json_paths;child_template_json_paths;child_repo_json_paths;parent_json_paths;dependent_engines;dependent_projects;dependent_gems;dependent_templates;dependent_repos")
            foreach(template_array IN LISTS template_arrays)
                string(TOUPPER ${template_array} template_array_upper)
                o3de_get_json_array(O3DE_PATH_${path_entry}_${template_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${template_array})
                list(REMOVE_DUPLICATES O3DE_PATH_${path_entry}_${template_array_upper})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${template_array_upper} ${O3DE_PATH_${path_entry}_${template_array_upper}})
            endforeach()

            # Check for optional overrides in the user/template.json
            # get the parent directory of the path_entry
            get_filename_component(template_path "${path_entry}" DIRECTORY)
            set(user_template_json ${template_path}/user/template.json)
            if(EXISTS ${user_template_json})
                file(READ "${user_template_json}" O3DE_PATH_${user_template_json}_JSON_DATA)
                set_property(GLOBAL PROPERTY O3DE_PATH_${user_template_json}_JSON_DATA ${O3DE_PATH_${user_template_json}_JSON_DATA})

                # Read the template override properties
                set(template_override_properties "")
                foreach(template_override_property IN LISTS template_override_properties)
                    string(TOUPPER ${template_override_property} template_override_property_upper)
                    o3de_get_json_key(O3DE_PATH_${path_entry}_${template_override_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${template_override_property})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${template_override_property_upper} ${O3DE_PATH_${path_entry}_${template_override_property_upper}})
                endforeach()

                # Read the template override arrays
                set(template_override_arrays "")
                foreach(template_array IN LISTS template_arrays)
                    string(TOUPPER ${template_array} template_array_upper)
                    o3de_get_json_array(O3DE_PATH_${path_entry}_${template_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${template_array})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${template_array_upper} ${O3DE_PATH_${path_entry}_${template_array_upper}})
                endforeach()
            endif()

        elseif(manifest_array STREQUAL "all_repo_paths")
            # Read the repo object at this path
            o3de_get_json_key( O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${path_entry})
            set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_PATH_${path_entry}_JSON_DATA})

            # Read the repo properties
            set(repo_properties "name;version;display_name;description;type;id;copyright_year;copyright_text")
            foreach(repo_property IN LISTS repo_properties)
                string(TOUPPER ${repo_property} repo_property_upper)
                o3de_get_json_key(O3DE_PATH_${path_entry}_${repo_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${repo_property})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${repo_property_upper} ${O3DE_PATH_${path_entry}_${repo_property_upper}})

                if(repo_property STREQUAL "name")
                    set(last_repo_name ${O3DE_PATH_${path_entry}_NAME})
                endif()

                if(repo_property STREQUAL "version")
                    set(last_repo_version ${O3DE_PATH_${path_entry}_VERSION})

                    set(O3DE_REPO_${last_repo_name}_${last_repo_version} ${path_entry})
                    set_property(GLOBAL PROPERTY O3DE_REPO_${last_repo_name}_${last_repo_version} ${O3DE_REPO_${last_repo_name}_${last_repo_version}})
                endif()
            endforeach()

            # Read the repo arrays
            set(repo_arrays "canonical_tags;user_tags;platforms;child_engine_json_paths;child_project_json_paths;child_gem_json_paths;child_template_json_paths;child_repo_json_paths;parent_json_paths;dependent_engines;dependent_projects;dependent_gems;dependent_templates;dependent_repos")
            foreach(repo_array IN LISTS repo_arrays)
                string(TOUPPER ${repo_array} repo_array_upper)
                o3de_get_json_array(O3DE_PATH_${path_entry}_${repo_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${repo_array})
                list(REMOVE_DUPLICATES O3DE_PATH_${path_entry}_${repo_array_upper})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${repo_array_upper} ${O3DE_PATH_${path_entry}_${repo_array_upper}})
            endforeach()

            # Check for optional overrides in the user/repo.json
            # get the parent directory of the path_entry
            get_filename_component(repo_path "${path_entry}" DIRECTORY)
            set(user_repo_json ${repo_path}/user/repo.json)
            if(EXISTS ${user_repo_json})
                file(READ "${user_repo_json}" O3DE_PATH_${user_repo_json}_JSON_DATA)
                set_property(GLOBAL PROPERTY O3DE_PATH_${user_repo_json}_JSON_DATA ${O3DE_PATH_${user_repo_json}_JSON_DATA})

                # Read the repo override properties
                set(repo_override_properties "")
                foreach(repo_override_property IN LISTS repo_override_properties)
                    string(TOUPPER ${repo_override_property} repo_override_property_upper)
                    o3de_get_json_key(O3DE_PATH_${path_entry}_${repo_override_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${repo_override_property})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${repo_override_property_upper} ${O3DE_PATH_${path_entry}_${repo_override_property_upper}})
                endforeach()

                # Read the repo override arrays
                set(repo_override_arrays "")
                foreach(repo_array IN LISTS repo_arrays)
                    string(TOUPPER ${repo_array} repo_array_upper)
                    o3de_get_json_array(O3DE_PATH_${path_entry}_${repo_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${repo_array})
                    set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${repo_array_upper} ${O3DE_PATH_${path_entry}_${repo_array_upper}})
                endforeach()
            endif()

        elseif(manifest_array STREQUAL "all_overlay_paths")
            # Read the overlay object at this path. Overlays are composed into
            # object trees by o3de-cli at workspace compose time; at configure
            # time CMake only consumes their platform declarations so PAL can
            # enumerate platforms delivered via overlays.
            o3de_get_json_key(O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_MANIFEST_RESOLVED_JSON_DATA} ${path_entry})
            set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_JSON_DATA ${O3DE_PATH_${path_entry}_JSON_DATA})

            # Read the overlay properties
            set(overlay_properties "name;version;display_name;description;type;id;copyright_year;copyright_text;extends;precedence")
            foreach(overlay_property IN LISTS overlay_properties)
                string(TOUPPER ${overlay_property} overlay_property_upper)
                o3de_get_json_key(O3DE_PATH_${path_entry}_${overlay_property_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${overlay_property})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${overlay_property_upper} ${O3DE_PATH_${path_entry}_${overlay_property_upper}})

                if(overlay_property STREQUAL "name")
                    set(last_overlay_name ${O3DE_PATH_${path_entry}_NAME})
                endif()

                if(overlay_property STREQUAL "version")
                    set(last_overlay_version ${O3DE_PATH_${path_entry}_VERSION})

                    set(O3DE_OVERLAY_${last_overlay_name}_${last_overlay_version} ${path_entry})
                    set_property(GLOBAL PROPERTY O3DE_OVERLAY_${last_overlay_name}_${last_overlay_version} ${O3DE_OVERLAY_${last_overlay_name}_${last_overlay_version}})
                endif()
            endforeach()

            # Read the overlay arrays
            set(overlay_arrays "canonical_tags;user_tags;platforms;platform_maps;platform_wart_maps;parent_json_paths")
            foreach(overlay_array IN LISTS overlay_arrays)
                string(TOUPPER ${overlay_array} overlay_array_upper)
                o3de_get_json_array(O3DE_PATH_${path_entry}_${overlay_array_upper} ${O3DE_PATH_${path_entry}_JSON_DATA} ${overlay_array})
                list(REMOVE_DUPLICATES O3DE_PATH_${path_entry}_${overlay_array_upper})
                set_property(GLOBAL PROPERTY O3DE_PATH_${path_entry}_${overlay_array_upper} ${O3DE_PATH_${path_entry}_${overlay_array_upper}})
            endforeach()

        endif()
    endforeach()
endforeach()
