#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Engine_cmake ${CMAKE_CURRENT_LIST_DIR})
macro(o3de_engine_init)
    # Print CMake version for debugging
    message(STATUS "CMake version: ${CMAKE_VERSION}")
    message(STATUS "CMAKE_FIND_USE_PACKAGE_REGISTRY (before): ${CMAKE_FIND_USE_PACKAGE_REGISTRY}")
        
    # include the absolute minimum cmake files needed to load Manifest.cmake
    include(${_cmake_Engine_cmake}/O3DEJson.cmake)
    include(${_cmake_Engine_cmake}/Manifest.cmake)
    include(${_cmake_Engine_cmake}/Version.cmake)

    # Set the engine path and JSON file locations
    set(engine_path ${CMAKE_CURRENT_SOURCE_DIR})
    set(engine_json_path ${engine_path}/engine.json)
    set(engine_user_path ${engine_path}/user)
    set(engine_user_json_path ${engine_user_path}/engine.json)

    # Get all the resolved manifest info pertaining to this engine object
    # Note all lower case variables are THIS engines info, all upper case are the global engine info
    # all the engine header fields
    get_property(engine_name GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_NAME)
    get_property(engine_version GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_VERSION)
    o3de_version_get_major_minor_patch(${engine_version} engine_version_major engine_version_minor engine_version_patch)
    get_property(engine_display_name GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DISPLAY_NAME)
    if(NOT engine_display_name)
        set(engine_display_name ${engine_name})
    endif()
    get_property(engine_description GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DESCRIPTION)
    if(NOT engine_description)
        set(engine_description ${engine_name})
    endif()
    get_property(engine_type GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_TYPE)
    if(NOT engine_type)
        set(engine_type "Engine")
    endif()
    get_property(engine_id GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_ID)
    if(NOT engine_id)
        set(engine_id 0)
    endif()
    get_property(engine_copyright_year GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_COPYRIGHT_YEAR)
    if(NOT engine_copyright_year)
        string(TIMESTAMP engine_copyright_year "%Y")
    endif()
    get_property(engine_copyright_text GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_COPYRIGHT_TEXT)
    if(NOT engine_copyright_text)
        set(engine_copyright_text "Copyright (c) ${engine_copyright_year}.")
    endif()
    # all the engine specific fields
    get_property(engine_O3DEVersion GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_O3DEVersion)
    if(NOT engine_O3DEVersion)
        set(engine_O3DEVersion "0.0.0")
    endif()
    get_property(engine_O3DEBuildNumber GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_O3DEBuildNumber)
    if(NOT engine_O3DEBuildNumber)
        set(engine_O3DEBuildNumber "0")
    endif()
    get_property(engine_display_version GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DISPLAY_VERSION)
    if(NOT engine_display_version)
        set(engine_display_version ${engine_version})
    endif()
    get_property(engine_file_version GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_FILE_VERSION)
    if(NOT engine_file_version)
        set(engine_file_version "0")
    endif()
    get_property(engine_build GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_BUILD)
    if(NOT engine_build)
        set(engine_build "0")
    endif()
    get_property(engine_api_version_editor GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_API_VERSION_EDITOR)
    if(NOT engine_api_version_editor)
        set(engine_api_version_editor "0")
    endif()
    get_property(engine_api_version_framework GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_API_VERSION_FRAMEWORK)
    if(NOT engine_api_version_framework)
        set(engine_api_version_framework "0")
    endif()
    get_property(engine_api_version_launcher GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_API_VERSION_LAUNCHER)
    if(NOT engine_api_version_launcher)
        set(engine_api_version_launcher "0")
    endif()
    get_property(engine_api_version_tools GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_API_VERSION_TOOLS)
    if(NOT engine_api_version_tools)
        set(engine_api_version_tools "0")
    endif()

    # all the standard object arrays
    get_property(engine_canonical_tags GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_CANONICAL_TAGS)
    get_property(engine_user_tags GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_USER_TAGS)
    get_property(engine_platforms GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_PLATFORMS)
    get_property(engine_child_engine_paths GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_CHILD_ENGINE_JSON_PATHS)
    get_property(engine_child_project_paths GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_CHILD_PROJECT_JSON_PATHS)
    get_property(engine_child_gem_paths GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_CHILD_GEM_JSON_PATHS)
    get_property(engine_child_template_paths GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_CHILD_TEMPLATE_JSON_PATHS)
    get_property(engine_child_repo_paths GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_CHILD_REPO_JSON_PATHS)
    get_property(engine_parent_paths GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_PARENT_JSON_PATHS)
    get_property(engine_dependent_engines GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DEPENDENT_ENGINES)
    get_property(engine_dependent_projects GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DEPENDENT_PROJECTS)
    get_property(engine_dependent_gems GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DEPENDENT_GEMS)
    get_property(engine_dependent_templates GLOBAL PROPERTY O3DE_PATH_${engine_json_path}_DEPENDENT_TEMPLATES)

    # set this project engine info as the global engine properties that identify this is the engine we are using
    set(O3DE_ENGINE_PATH ${engine_path})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_PATH ${O3DE_ENGINE_PATH})
    set(O3DE_ENGINE_JSON_PATH ${engine_json_path})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_JSON_PATH ${O3DE_ENGINE_JSON_PATH})
    set(O3DE_ENGINE_USER_PATH ${engine_user_path})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_USER_PATH ${O3DE_ENGINE_USER_PATH})
    set(O3DE_ENGINE_CMAKE_PATH ${engine_path}/cmake/)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CMAKE_PATH ${O3DE_ENGINE_CMAKE_PATH})
    set(O3DE_ENGINE_CMAKE_3RDPARTY_PATH ${engine_path}/cmake/3rdParty)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CMAKE_3RDPARTY_PATH ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH})

    set(O3DE_ENGINE_NAME ${engine_name})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_NAME ${O3DE_ENGINE_NAME})
    set(O3DE_ENGINE_VERSION ${engine_version})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION ${O3DE_ENGINE_VERSION})
    set(O3DE_ENGINE_VERSION_MAJOR ${engine_version_major})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION_MAJOR ${O3DE_ENGINE_VERSION_MAJOR})
    set(O3DE_ENGINE_VERSION_MINOR ${engine_version_minor})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION_MINOR ${O3DE_ENGINE_VERSION_MINOR})
    set(O3DE_ENGINE_VERSION_PATCH ${engine_version_patch})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION_PATCH ${O3DE_ENGINE_VERSION_PATCH})
    set(O3DE_ENGINE_DISPLAY_NAME ${engine_display_name})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DISPLAY_NAME ${O3DE_ENGINE_DISPLAY_NAME})
    set(O3DE_ENGINE_DESCRIPTION ${engine_description})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DESCRIPTION ${O3DE_ENGINE_DESCRIPTION})
    set(O3DE_ENGINE_TYPE ${engine_type})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_TYPE ${O3DE_ENGINE_TYPE})
    set(O3DE_ENGINE_ID ${engine_id})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_ID ${O3DE_ENGINE_ID})
    set(O3DE_ENGINE_COPYRIGHT_YEAR ${engine_copyright_year})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_COPYRIGHT_YEAR ${O3DE_ENGINE_COPYRIGHT_YEAR})
    set(O3DE_ENGINE_COPYRIGHT_TEXT ${engine_copyright_text})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_COPYRIGHT_TEXT ${O3DE_ENGINE_COPYRIGHT_TEXT})
    set(O3DE_ENGINE_O3DE_VERSION ${engine_O3DEVersion})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_O3DE_VERSION ${O3DE_ENGINE_O3DE_VERSION})
    set(O3DE_ENGINE_O3DE_BUILD_NUMBER ${engine_O3DEBuildNumber})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_O3DE_BUILD_NUMBER ${O3DE_ENGINE_O3DE_BUILD_NUMBER})
    set(O3DE_ENGINE_DISPLAY_VERSION ${engine_display_version})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DISPLAY_VERSION ${O3DE_ENGINE_DISPLAY_VERSION})
    set(O3DE_ENGINE_FILE_VERSION ${engine_file_version})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_FILE_VERSION ${O3DE_ENGINE_FILE_VERSION})
    set(O3DE_ENGINE_BUILD ${engine_build})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_BUILD ${O3DE_ENGINE_BUILD})
    set(O3DE_ENGINE_API_VERSION_EDITOR ${engine_api_version_editor})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_EDITOR ${O3DE_ENGINE_API_VERSION_EDITOR})
    set(O3DE_ENGINE_API_VERSION_FRAMEWORK ${engine_api_version_framework})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_FRAMEWORK ${O3DE_ENGINE_API_VERSION_FRAMEWORK})
    set(O3DE_ENGINE_API_VERSION_LAUNCHER ${engine_api_version_launcher})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_LAUNCHER ${O3DE_ENGINE_API_VERSION_LAUNCHER})
    set(O3DE_ENGINE_API_VERSION_TOOLS ${engine_api_version_tools})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_TOOLS ${O3DE_ENGINE_API_VERSION_TOOLS})
    
    set(O3DE_ENGINE_CANONICAL_TAGS ${engine_canonical_tags})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CANONICAL_TAGS ${O3DE_ENGINE_CANONICAL_TAGS})
    set(O3DE_ENGINE_USER_TAGS ${engine_user_tags})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_USER_TAGS ${O3DE_ENGINE_USER_TAGS})
    set(O3DE_ENGINE_PLATFORMS ${engine_platforms})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_PLATFORMS ${O3DE_ENGINE_PLATFORMS})
    set(O3DE_ENGINE_CHILD_ENGINE_JSON_PATHS ${engine_child_engine_paths})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_ENGINE_JSON_PATHS ${O3DE_ENGINE_CHILD_ENGINE_JSON_PATHS})
    set(O3DE_ENGINE_CHILD_PROJECT_JSON_PATHS ${engine_child_project_paths})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_PROJECT_JSON_PATHS ${O3DE_ENGINE_CHILD_PROJECT_JSON_PATHS})
    set(O3DE_ENGINE_CHILD_GEM_JSON_PATHS ${engine_child_gem_paths})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_GEM_JSON_PATHS ${O3DE_ENGINE_CHILD_GEM_JSON_PATHS})
    set(O3DE_ENGINE_CHILD_TEMPLATE_JSON_PATHS ${engine_child_template_paths})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_TEMPLATE_JSON_PATHS ${O3DE_ENGINE_CHILD_TEMPLATE_JSON_PATHS})
    set(O3DE_ENGINE_CHILD_REPO_JSON_PATHS ${engine_child_repo_paths})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_REPO_JSON_PATHS ${O3DE_ENGINE_CHILD_REPO_JSON_PATHS})
    set(O3DE_ENGINE_PARENT_JSON_PATHS ${engine_parent_paths})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_PARENT_JSON_PATHS ${O3DE_ENGINE_PARENT_JSON_PATHS})
    set(O3DE_ENGINE_DEPENDENT_ENGINES ${engine_dependent_engines})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_ENGINES ${O3DE_ENGINE_DEPENDENT_ENGINES})
    set(O3DE_ENGINE_DEPENDENT_PROJECTS ${engine_dependent_projects})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_PROJECTS ${O3DE_ENGINE_DEPENDENT_PROJECTS})
    set(O3DE_ENGINE_DEPENDENT_GEMS ${engine_dependent_gems})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_GEMS ${O3DE_ENGINE_DEPENDENT_GEMS})
    set(O3DE_ENGINE_DEPENDENT_TEMPLATES ${engine_dependent_templates})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_TEMPLATES ${O3DE_ENGINE_DEPENDENT_TEMPLATES})
    set(O3DE_ENGINE_DEPENDENT_REPOS ${engine_dependent_repos})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_REPOS ${O3DE_ENGINE_DEPENDENT_REPOS})

    #env vars
    set(O3DE_ENGINE_INSTALL_NAME "@O3DE_ENGINE_NAME@" CACHE STRING "Open 3D Engine's engine name for the INSTALL target")
    if(NOT "$ENV{O3DE_ENGINE_INSTALL_NAME}" STREQUAL "")
        set(O3DE_ENGINE_INSTALL_NAME "$ENV{O3DE_ENGINE_INSTALL_NAME}")
    endif()
    string(CONFIGURE ${O3DE_ENGINE_INSTALL_NAME} O3DE_ENGINE_INSTALL_NAME @ONLY)

    set(O3DE_ENGINE_INSTALL_VERSION "@O3DE_ENGINE_VERSION@" CACHE STRING "Open 3D Engine's version for the INSTALL target")
    if(NOT "$ENV{O3DE_ENGINE_INSTALL_VERSION}" STREQUAL "")
        set(O3DE_ENGINE_INSTALL_VERSION "$ENV{O3DE_ENGINE_INSTALL_VERSION}")
    endif()
    string(CONFIGURE ${O3DE_ENGINE_INSTALL_VERSION} O3DE_ENGINE_INSTALL_VERSION @ONLY)

    set(O3DE_ENGINE_INSTALL_DISPLAY_VERSION "@O3DE_ENGINE_DISPLAY_VERSION@" CACHE STRING "Open 3D Engine's display version for the INSTALL target")
    if(NOT "$ENV{O3DE_ENGINE_INSTALL_DISPLAY_VERSION}" STREQUAL "")
        set(O3DE_ENGINE_INSTALL_DISPLAY_VERSION "$ENV{O3DE_ENGINE_INSTALL_DISPLAY_VERSION}")
    endif()
    string(CONFIGURE ${O3DE_ENGINE_INSTALL_DISPLAY_VERSION} O3DE_ENGINE_INSTALL_DISPLAY_VERSION @ONLY)

    set(O3DE_ENGINE_INSTALL_BUILD "@O3DE_ENGINE_BUILD@" CACHE STRING "Open 3D Engine's build number for the INSTALL target")
    if(NOT "$ENV{O3DE_ENGINE_INSTALL_BUILD}" STREQUAL "")
        set(O3DE_ENGINE_INSTALL_BUILD "$ENV{O3DE_ENGINE_INSTALL_BUILD}")
    endif()
    string(CONFIGURE ${O3DE_ENGINE_INSTALL_BUILD} O3DE_ENGINE_INSTALL_BUILD @ONLY)

    include(${_cmake_Engine_cmake}/O3deSet.cmake)
    include(${_cmake_Engine_cmake}/GeneralSettings.cmake)
    include(${_cmake_Engine_cmake}/CompilerSettings.cmake)
    include(${_cmake_Engine_cmake}/OutputDirectory.cmake)
endmacro()

macro(o3de_engine_setup)
    # now that we have set the cmake project the CMAKE_SYSTEM_NAME is set
    include(${_cmake_Engine_cmake}/PAL.cmake)
    include(${_cmake_Engine_cmake}/PALTools.cmake)
    include(${_cmake_Engine_cmake}/Restricted.cmake)
    
    # add all pal platform names
    # These are all the platforms listed in the engine.json
    foreach(platform ${O3DE_ENGINE_PLATFORMS})
        o3de_add_pal_platform_name(${platform})
    endforeach()

    # Now that we have all possible PAL platforms, include all pal platform cmake files
    get_property(O3DE_ALL_PAL_PLATFORM_NAMES GLOBAL PROPERTY O3DE_ALL_PAL_PLATFORM_NAMES)
    foreach(pal_platform ${O3DE_ALL_PAL_PLATFORM_NAMES})
        o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/cmake/Platform/${pal_platform}/PAL_platform.cmake pal_platform_cmake_file)
        include(${pal_platform_cmake_file})
    endforeach()
    
    # Now that we have run all the pal platform cmake files all the pal mappings and platform detections are defined
    # Set the O3DE_PAL_HOST_PLATFORM_NAME based on the CMAKE_SYSTEM_NAME and PAL detection defines
    set(O3DE_PAL_HOST_PLATFORM_NAME ${O3DE_HOST_PLATFORM_DETECTION_${CMAKE_SYSTEM_NAME}})
    set_property(GLOBAL PROPERTY O3DE_PAL_HOST_PLATFORM_NAME ${O3DE_PAL_HOST_PLATFORM_NAME})
    string(TOLOWER "${O3DE_PAL_HOST_PLATFORM_NAME}" O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE)
    set_property(GLOBAL PROPERTY O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE ${O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE})
    
    # Set the O3DE_PAL_PLATFORM_NAME based on the CMAKE_SYSTEM_NAME
    set(O3DE_PAL_PLATFORM_NAME ${O3DE_PLATFORM_DETECTION_${CMAKE_SYSTEM_NAME}})
    set_property(GLOBAL PROPERTY O3DE_PAL_PLATFORM_NAME ${O3DE_PAL_PLATFORM_NAME})
    string(TOLOWER "${O3DE_PAL_PLATFORM_NAME}" O3DE_PAL_PLATFORM_NAME_LOWERCASE)
    set_property(GLOBAL PROPERTY O3DE_PAL_PLATFORM_NAME_LOWERCASE ${O3DE_PAL_PLATFORM_NAME_LOWERCASE})

    # Set the O3DE_HOST_ARCHITECTURE_NAME_EXTENSION based on the O3DE_PAL_HOST_PLATFORM_NAME
    set(O3DE_HOST_ARCHITECTURE_NAME_EXTENSION "_${O3DE_HOST_ARCHITECTURE_DETECTION_${O3DE_PAL_HOST_PLATFORM_NAME}}")
    set_property(GLOBAL PROPERTY O3DE_HOST_ARCHITECTURE_NAME_EXTENSION ${O3DE_HOST_ARCHITECTURE_NAME_EXTENSION})

    # Set the O3DE_ARCHITECTURE_NAME_EXTENSION based on the O3DE_PAL_HOST_PLATFORM_NAME
    set(O3DE_ARCHITECTURE_NAME_EXTENSION "_${O3DE_ARCHITECTURE_DETECTION_${O3DE_PAL_PLATFORM_NAME}}")
    set_property(GLOBAL PROPERTY O3DE_ARCHITECTURE_NAME_EXTENSION ${O3DE_ARCHITECTURE_NAME_EXTENSION})

    # get the host wart and platform wart
    o3de_pal_platform_name_wart(${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_PAL_HOST_PLATFORM_WART) 
    o3de_pal_platform_name_wart(${O3DE_PAL_PLATFORM_NAME} O3DE_PAL_PLATFORM_WART)      

    # Upstream-compatible aliases: 3rd-party packages ship their own
    # Find*.cmake files that consume the legacy PAL_* variable names.
    set(PAL_PLATFORM_NAME ${O3DE_PAL_PLATFORM_NAME})
    set(PAL_PLATFORM_NAME_LOWERCASE ${O3DE_PAL_PLATFORM_NAME_LOWERCASE})
    set(PAL_HOST_PLATFORM_NAME ${O3DE_PAL_HOST_PLATFORM_NAME})
    set(PAL_HOST_PLATFORM_NAME_LOWERCASE ${O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE})

    # Engine object pal path
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Platform/${O3DE_PAL_PLATFORM_NAME} O3DE_ENGINE_PAL_PATH)

    #engine object cmake pal path
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_PATH}/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_CMAKE_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_PATH}/Platform/${O3DE_PAL_PLATFORM_NAME} O3DE_ENGINE_CMAKE_PAL_PATH)

    #engine object cmake 3rdparty pal path
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH}/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_CMAKE_3RDPARTY_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH}/Platform/${O3DE_PAL_PLATFORM_NAME} O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH)

    #engine object cmake 3rdparty pal path
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Editor/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_CODE_EDITOR_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Editor/Platform/${O3DE_PAL_PLATFORM_NAME} O3DE_ENGINE_CODE_EDITOR_PAL_PATH)

    # Set up build configurations now that the PAL platform paths and warts are known.
    # This must run after project() (compilers/languages enabled) and after the PAL
    # detection above, since it includes Platform/<name>/Configurations_<wart>.cmake
    include(${_cmake_Engine_cmake}/Configurations.cmake)


    # append platform files for the host platform to ALLFILES so they show up
    include(${_cmake_Engine_cmake}/FileUtil.cmake)
    o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_PAL_HOST_PATH}/platform_${O3DE_PAL_HOST_PLATFORM_WART}_files.cmake)

    # if target platform is different than the host platform, append them to ALLFILES too
    if( NOT ${O3DE_PAL_PLATFORM_NAME} STREQUAL ${O3DE_PAL_HOST_PLATFORM_NAME})
        o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_PAL_PATH}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake)
    endif()

    # include the cmake files for the target platform
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/ToolChain_${O3DE_PAL_PLATFORM_WART}.cmake)
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/PALTools_${O3DE_PAL_PLATFORM_WART}.cmake)
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/RuntimeDependencies_${O3DE_PAL_PLATFORM_WART}.cmake)

    # append platform pal tools files to ALLFILES so they show up
    o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_PAL_PATH}/pal_tools_${O3DE_PAL_PLATFORM_WART}_files.cmake)

    # Find all dependent packages
    message("Finding O3DE engine dependent packages...")
    include(${_cmake_Engine_cmake}/Dependencies.cmake)
    foreach(o3de_package_name_and_version IN LISTS engine_dependent_engines)
        o3de_find_package("${o3de_package_name_and_version}")
    endforeach()
    foreach(o3de_package_name_and_version IN LISTS engine_dependent_projects)
        o3de_find_package("${o3de_package_name_and_version}")
    endforeach()
    foreach(o3de_package_name_and_version IN LISTS engine_dependent_gems)
        o3de_find_package("${o3de_package_name_and_version}")
    endforeach()
    foreach(o3de_package_name_and_version IN LISTS engine_dependent_templates)
        o3de_find_package("${o3de_package_name_and_version}")
    endforeach()
    foreach(o3de_package_name_and_version IN LISTS engine_dependent_repos)
        o3de_find_package("${o3de_package_name_and_version}")
    endforeach()

    include(${_cmake_Engine_cmake}/3rdPartyPackages.cmake)





    include(CTest)
    include(${_cmake_Engine_cmake}/Deployment.cmake)
    include(${_cmake_Engine_cmake}/O3dePython.cmake)    
    include(${_cmake_Engine_cmake}/3rdParty.cmake)
    include(${_cmake_Engine_cmake}/Install.cmake)
    include(${_cmake_Engine_cmake}/O3deWrappers.cmake)
    include(${_cmake_Engine_cmake}/O3DEObjectSetup.cmake)
    include(${_cmake_Engine_cmake}/Gems.cmake)
    include(${_cmake_Engine_cmake}/UnitTest.cmake)
    include(${_cmake_Engine_cmake}/TestImpactFramework/TestImpactTestTargetConfig.cmake) # O3deTestWrappers dependency
    include(${_cmake_Engine_cmake}/O3deTestWrappers.cmake)
    include(${_cmake_Engine_cmake}/Monolithic.cmake)
    include(${_cmake_Engine_cmake}/SettingsRegistry.cmake)
    include(${_cmake_Engine_cmake}/CMakeFiles.cmake)
    include(${_cmake_Engine_cmake}/Subdirectories.cmake)
    include(${_cmake_Engine_cmake}/TestImpactFramework/O3deTestImpactFramework.cmake) # Put at end as nothing else depends on it

endmacro()


macro(o3de_engine_post_processing)
    
    # The following steps have to be done after all targets are registered:

    # 1. Add any dependencies registered via o3de_enable_gems
    o3de_enable_gems_delayed()

    # Resolve dependencies declared before their targets existed
    o3de_flush_deferred_dependencies()

    # 2. Defer generation of the StaticModules.inl file which is needed to create the AZ::Module derived class in monolithic
    #    builds until after all the targets are known and all the gems are enabled
    o3de_delayed_generate_static_modules_inl()

    # 3. generate a settings registry .setreg file for all o3de_add_project_dependencies() and o3de_add_target_dependencies() calls
    #    to provide applications with the filenames of gem modules to load
    #    This must be done before o3de_delayed_target_link_libraries() as that inserts BUILD_DEPENDENCIES as MANUALLY_ADDED_DEPENDENCIES
    #    if the build dependency is a MODULE_LIBRARY. That would cause a false load dependency to be generated
    o3de_delayed_generate_settings_registry()

    # 4. link targets where the dependency was yet not declared, we need to have the declaration so we do different
    #    linking logic depending on the type of target
    o3de_delayed_target_link_libraries()

    # 5. generate a registry file for unit testing for platforms that support unit testing
    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        o3de_delayed_generate_unit_test_module_registry()
    endif()

    # 5. inject runtime dependencies to the targets. We need to do this after (1) since we are going to walk through
    #    the dependencies
    o3de_delayed_generate_runtime_dependencies()

    # 6. Perform test impact framework post steps once all of the targets have been enumerated
    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        o3de_test_impact_post_step()
    endif()

    # 7. Generate the O3DE find file and setup install locations for scripts, tools, assets etc., required by the engine
    if(O3DE_INSTALL_ENABLED)
        # 8. Generate the O3DE find file and setup install locations for scripts, tools, assets etc., required by the engine
        o3de_setup_o3de_install()
        # 9. CPack information (to be included after install)
        include(${_cmake_Engine_cmake}/Packaging.cmake)
    endif()

endmacro()
