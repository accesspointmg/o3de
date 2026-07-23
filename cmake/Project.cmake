#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Project_cmake ${CMAKE_CURRENT_LIST_DIR})
macro(o3de_project_init)
    # include the absolute minimum cmake files needed to load Manifest.cmake
    include(${_cmake_Project_cmake}/O3deSet.cmake)
    include(${_cmake_Project_cmake}/GeneralSettings.cmake)
    include(${_cmake_Project_cmake}/O3DEJson.cmake)
    include(${_cmake_Project_cmake}/Version.cmake)
    include(${_cmake_Project_cmake}/Dependencies.cmake)
    include(${_cmake_Project_cmake}/Manifest.cmake)

    # Set the project path and JSON file locations
    set(project_path ${CMAKE_CURRENT_SOURCE_DIR})
    set(project_json_path ${project_path}/project.json)
    set(project_user_path ${project_path}/user)
    set(project_user_json_path ${project_user_path}/project.json)

    # Get all the resolved manifest info pertaining to this project object
    get_property(project_name GLOBAL PROPERTY O3DE_PATH_${project_json_path}_NAME)
    get_property(project_version GLOBAL PROPERTY O3DE_PATH_${project_json_path}_VERSION)
    o3de_version_get_major_minor_patch(${project_version} project_version_major project_version_minor project_version_patch)
    get_property(project_display_name GLOBAL PROPERTY O3DE_PATH_${project_json_path}_DISPLAY_NAME)
    if(NOT project_display_name)
        set(project_display_name ${project_name})
    endif()
    get_property(project_description GLOBAL PROPERTY O3DE_PATH_${project_json_path}_DESCRIPTION)
    if(NOT project_description)
        set(project_description ${project_name})
    endif()
    get_property(project_type GLOBAL PROPERTY O3DE_PATH_${project_json_path}_TYPE)
    if(NOT project_type)
        set(project_type "Project")
    endif()
    get_property(project_id GLOBAL PROPERTY O3DE_PATH_${project_json_path}_ID)
    if(NOT project_id)
        set(project_id 0)
    endif()
    get_property(project_copyright_year GLOBAL PROPERTY O3DE_PATH_${project_json_path}_COPYRIGHT_YEAR)
    if(NOT project_copyright_year)
        string(TIMESTAMP project_copyright_year "%Y")
    endif()
    get_property(project_copyright_text GLOBAL PROPERTY O3DE_PATH_${project_json_path}_COPYRIGHT_TEXT)
    if(NOT project_copyright_text)
        set(project_copyright_text "Copyright (c) ${project_copyright_year}.")
    endif()
    # all the engine specific fields
    get_property(project_engine GLOBAL PROPERTY O3DE_PATH_${project_json_path}_ENGINE)
    # all the standard object arrays
    get_property(project_child_engine_paths GLOBAL PROPERTY O3DE_PATH_${project_json_path}_CHILD_ENGINE_JSON_PATHS)
    get_property(project_child_project_paths GLOBAL PROPERTY O3DE_PATH_${project_json_path}_CHILD_PROJECT_JSON_PATHS)
    get_property(project_child_gem_paths GLOBAL PROPERTY O3DE_PATH_${project_json_path}_CHILD_GEM_JSON_PATHS)
    get_property(project_child_template_paths GLOBAL PROPERTY O3DE_PATH_${project_json_path}_CHILD_TEMPLATE_JSON_PATHS)
    get_property(project_child_repo_paths GLOBAL PROPERTY O3DE_PATH_${project_json_path}_CHILD_REPO_JSON_PATHS)
    get_property(project_parent_paths GLOBAL PROPERTY O3DE_PATH_${project_json_path}_PARENT_JSON_PATHS)
    get_property(project_dependent_engines GLOBAL PROPERTY O3DE_PATH_${project_json_path}_DEPENDENT_ENGINES)
    get_property(project_dependent_projects GLOBAL PROPERTY O3DE_PATH_${project_json_path}_DEPENDENT_PROJECTS)
    get_property(project_dependent_gems GLOBAL PROPERTY O3DE_PATH_${project_json_path}_DEPENDENT_GEMS)
    get_property(project_dependent_templates GLOBAL PROPERTY O3DE_PATH_${project_json_path}_DEPENDENT_TEMPLATES)

    # project platforms (consumed by o3de_project_setup PAL loop)
    get_property(O3DE_PROJECT_PLATFORMS GLOBAL PROPERTY O3DE_PATH_${project_json_path}_PLATFORMS)
    set_property(GLOBAL PROPERTY O3DE_PROJECT_PLATFORMS ${O3DE_PROJECT_PLATFORMS})

    # If there is not project engine set in the project json and there is no engine override set in the user project json
    # pretend the user set 'engine':'org.o3de.engine.o3de>=0.0.0' as an override in user project json
    if(NOT project_engine)
        set_property(GLOBAL PROPERTY O3DE_PATH_${project_json_path}_ENGINE "org.o3de.engine.o3de>=0.0.0")
        set(project_engine "org.o3de.engine.o3de>=0.0.0")
    endif()

    # find the project engine package
    o3de_find_package("${project_engine}" FOUND_VAR project_engine_found DIR_VAR project_engine_json_path)

    #get the project engine info and set the global properties that identify this engine as the one we are using
    set(O3DE_ENGINE_JSON_PATH ${project_engine_json_path})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_JSON_PATH ${O3DE_ENGINE_JSON_PATH})
    cmake_path(GET O3DE_ENGINE_JSON_PATH PARENT_PATH O3DE_ENGINE_PATH)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_PATH ${O3DE_ENGINE_PATH})
    cmake_path(APPEND O3DE_ENGINE_PATH "/user/engine.json" OUTPUT_VARIABLE O3DE_ENGINE_USER_PATH)

    # engine cmake paths (mirrors o3de_engine_init)
    set(O3DE_ENGINE_CMAKE_PATH ${O3DE_ENGINE_PATH}/cmake)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CMAKE_PATH ${O3DE_ENGINE_CMAKE_PATH})
    set(O3DE_ENGINE_CMAKE_3RDPARTY_PATH ${O3DE_ENGINE_PATH}/cmake/3rdParty)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CMAKE_3RDPARTY_PATH ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH})

    get_property(O3DE_ENGINE_NAME GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_NAME)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_NAME ${O3DE_ENGINE_NAME})
    get_property(O3DE_ENGINE_VERSION GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_VERSION)
    if(NOT O3DE_ENGINE_VERSION)
        set(O3DE_ENGINE_VERSION "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION ${O3DE_ENGINE_VERSION})
    o3de_version_get_major_minor_patch(${O3DE_ENGINE_VERSION} O3DE_ENGINE_VERSION_MAJOR O3DE_ENGINE_VERSION_MINOR O3DE_ENGINE_VERSION_PATCH)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION_MAJOR ${O3DE_ENGINE_VERSION_MAJOR})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION_MINOR ${O3DE_ENGINE_VERSION_MINOR})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_VERSION_PATCH ${O3DE_ENGINE_VERSION_PATCH})
    get_property(O3DE_ENGINE_DISPLAY_NAME GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DISPLAY_NAME)
    if(NOT O3DE_ENGINE_DISPLAY_NAME)
        set(O3DE_ENGINE_DISPLAY_NAME ${O3DE_ENGINE_NAME})
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DISPLAY_NAME ${O3DE_ENGINE_DISPLAY_NAME})
    get_property(O3DE_ENGINE_DESCRIPTION GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DESCRIPTION)
    if(NOT O3DE_ENGINE_DESCRIPTION)
        set(O3DE_ENGINE_DESCRIPTION ${O3DE_ENGINE_NAME})
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DESCRIPTION ${O3DE_ENGINE_DESCRIPTION})
    get_property(O3DE_ENGINE_TYPE GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_TYPE)
    if(NOT O3DE_ENGINE_TYPE)
        set(O3DE_ENGINE_TYPE "Engine")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_TYPE ${O3DE_ENGINE_TYPE})
    get_property(O3DE_ENGINE_ID GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_ID)
    if(NOT O3DE_ENGINE_ID)
        set(O3DE_ENGINE_ID 0)
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_ID ${O3DE_ENGINE_ID})
    get_property(O3DE_ENGINE_COPYRIGHT_YEAR GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_COPYRIGHT_YEAR)
    if(NOT O3DE_ENGINE_COPYRIGHT_YEAR)
        string(TIMESTAMP O3DE_ENGINE_COPYRIGHT_YEAR "%Y")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_COPYRIGHT_YEAR ${O3DE_ENGINE_COPYRIGHT_YEAR})
    get_property(O3DE_ENGINE_COPYRIGHT_TEXT GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_COPYRIGHT_TEXT)
    if(NOT O3DE_ENGINE_COPYRIGHT_TEXT)
        set(O3DE_ENGINE_COPYRIGHT_TEXT "Copyright (c) ${O3DE_ENGINE_COPYRIGHT_YEAR}.")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_COPYRIGHT_TEXT ${O3DE_ENGINE_COPYRIGHT_TEXT})
    get_property(O3DE_ENGINE_O3DE_VERSION GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_O3DE_VERSION)
    if(NOT O3DE_ENGINE_O3DE_VERSION)
        set(O3DE_ENGINE_O3DE_VERSION "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_O3DE_VERSION ${O3DE_ENGINE_O3DE_VERSION})
    get_property(O3DE_ENGINE_O3DE_BUILD_NUMBER GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_O3DE_BUILD_NUMBER)
    if(NOT O3DE_ENGINE_O3DE_BUILD_NUMBER)
        set(O3DE_ENGINE_O3DE_BUILD_NUMBER "0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_O3DE_BUILD_NUMBER ${O3DE_ENGINE_O3DE_BUILD_NUMBER})
    get_property(O3DE_ENGINE_DISPLAY_VERSION GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DISPLAY_VERSION)
    if(NOT O3DE_ENGINE_DISPLAY_VERSION)
        set(O3DE_ENGINE_DISPLAY_VERSION ${O3DE_ENGINE_NAME})
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DISPLAY_VERSION ${O3DE_ENGINE_DISPLAY_VERSION})
    get_property(O3DE_ENGINE_O3DE_FILE_VERSION GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_O3DE_FILE_VERSION)
    if(NOT O3DE_ENGINE_O3DE_FILE_VERSION)
        set(O3DE_ENGINE_O3DE_FILE_VERSION "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_O3DE_FILE_VERSION ${O3DE_ENGINE_O3DE_FILE_VERSION})
    get_property(O3DE_ENGINE_BUILD GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_BUILD)
    if(NOT O3DE_ENGINE_BUILD)
        set(O3DE_ENGINE_BUILD "0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_BUILD ${O3DE_ENGINE_BUILD})
    get_property(O3DE_ENGINE_API_VERSION_EDITOR GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_API_VERSION_EDITOR)
    if(NOT O3DE_ENGINE_API_VERSION_EDITOR)
        set(O3DE_ENGINE_API_VERSION_EDITOR "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_EDITOR ${O3DE_ENGINE_API_VERSION_EDITOR})
    get_property(O3DE_ENGINE_API_VERSION_FRAMEWORK GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_API_VERSION_FRAMEWORK)
    if(NOT O3DE_ENGINE_API_VERSION_FRAMEWORK)
        set(O3DE_ENGINE_API_VERSION_FRAMEWORK "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_FRAMEWORK ${O3DE_ENGINE_API_VERSION_FRAMEWORK})
    get_property(O3DE_ENGINE_API_VERSION_LAUNCHER GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_API_VERSION_LAUNCHER)
    if(NOT O3DE_ENGINE_API_VERSION_LAUNCHER)
        set(O3DE_ENGINE_API_VERSION_LAUNCHER "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_LAUNCHER ${O3DE_ENGINE_API_VERSION_LAUNCHER})
    get_property(O3DE_ENGINE_API_VERSION_TOOLS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_API_VERSION_TOOLS)
    if(NOT O3DE_ENGINE_API_VERSION_TOOLS)
        set(O3DE_ENGINE_API_VERSION_TOOLS "0.0.0")
    endif()
    set_property(GLOBAL PROPERTY O3DE_ENGINE_API_VERSION_TOOLS ${O3DE_ENGINE_API_VERSION_TOOLS})

    get_property(O3DE_ENGINE_CANONICAL_TAGS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_CANONICAL_TAGS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CANONICAL_TAGS ${O3DE_ENGINE_CANONICAL_TAGS})
    get_property(O3DE_ENGINE_USER_TAGS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_USER_TAGS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_USER_TAGS ${O3DE_ENGINE_USER_TAGS})
    get_property(O3DE_ENGINE_PLATFORMS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_PLATFORMS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_PLATFORMS ${O3DE_ENGINE_PLATFORMS})
    get_property(O3DE_ENGINE_CHILD_ENGINE_JSON_PATHS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_CHILD_ENGINE_JSON_PATHS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_ENGINE_JSON_PATHS ${O3DE_ENGINE_CHILD_ENGINE_JSON_PATHS})
    get_property(O3DE_ENGINE_CHILD_PROJECT_JSON_PATHS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_CHILD_PROJECT_JSON_PATHS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_PROJECT_JSON_PATHS ${O3DE_ENGINE_CHILD_PROJECT_JSON_PATHS})
    get_property(O3DE_ENGINE_CHILD_GEM_JSON_PATHS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_CHILD_GEM_JSON_PATHS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_GEM_JSON_PATHS ${O3DE_ENGINE_CHILD_GEM_JSON_PATHS})
    get_property(O3DE_ENGINE_CHILD_TEMPLATE_JSON_PATHS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_CHILD_TEMPLATE_JSON_PATHS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_TEMPLATE_JSON_PATHS ${O3DE_ENGINE_CHILD_TEMPLATE_JSON_PATHS})
    get_property(O3DE_ENGINE_CHILD_REPO_JSON_PATHS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_CHILD_REPO_JSON_PATHS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CHILD_REPO_JSON_PATHS ${O3DE_ENGINE_CHILD_REPO_JSON_PATHS})
    get_property(O3DE_ENGINE_PARENT_JSON_PATHS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_PARENT_JSON_PATHS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_PARENT_JSON_PATHS ${O3DE_ENGINE_PARENT_JSON_PATHS})
    get_property(O3DE_ENGINE_DEPENDENT_ENGINES GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DEPENDENT_ENGINES)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_ENGINES ${O3DE_ENGINE_DEPENDENT_ENGINES})
    get_property(O3DE_ENGINE_DEPENDENT_PROJECTS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DEPENDENT_PROJECTS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_PROJECTS ${O3DE_ENGINE_DEPENDENT_PROJECTS})
    get_property(O3DE_ENGINE_DEPENDENT_GEMS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DEPENDENT_GEMS)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_GEMS ${O3DE_ENGINE_DEPENDENT_GEMS})
    get_property(O3DE_ENGINE_DEPENDENT_TEMPLATES GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DEPENDENT_TEMPLATES)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_DEPENDENT_TEMPLATES ${O3DE_ENGINE_DEPENDENT_TEMPLATES})
    get_property(O3DE_ENGINE_DEPENDENT_REPOS GLOBAL PROPERTY O3DE_PATH_${project_engine_json_path}_DEPENDENT_REPOS)
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
endmacro()

macro(o3de_project_setup)
    # now that we have set the cmake project the CMAKE_SYSTEM_NAME is set    
    include(${_cmake_Project_cmake}/PAL.cmake)
    include(${_cmake_Project_cmake}/PALTools.cmake)
    include(${_cmake_Project_cmake}/Restricted.cmake)
    
    # add all pal platform names
    # These are all the platforms listed in the project.json
    foreach(platform ${O3DE_PROJECT_PLATFORMS})
        o3de_add_pal_platform_name(${platform})
    endforeach()
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
    
    # Set the O3DE_PAL_HOST_PLATFORM_NAME based on the CMAKE_SYSTEM_NAME
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

    # get the host wart and platform wart (mirrors o3de_engine_setup)
    o3de_pal_platform_name_wart(${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_PAL_HOST_PLATFORM_WART)
    o3de_pal_platform_name_wart(${O3DE_PAL_PLATFORM_NAME} O3DE_PAL_PLATFORM_WART)

    # Upstream-compatible aliases: 3rd-party packages ship their own
    # Find*.cmake files that consume the legacy PAL_* variable names.
    set(PAL_PLATFORM_NAME ${O3DE_PAL_PLATFORM_NAME})
    set(PAL_PLATFORM_NAME_LOWERCASE ${O3DE_PAL_PLATFORM_NAME_LOWERCASE})
    set(PAL_HOST_PLATFORM_NAME ${O3DE_PAL_HOST_PLATFORM_NAME})
    set(PAL_HOST_PLATFORM_NAME_LOWERCASE ${O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE})

    # Now that we have the O3DE_PAL_PLATFORM_NAME we can resolve pal paths
    include(${_cmake_Project_cmake}/Restricted.cmake)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_PATH}/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_CMAKE_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_PATH}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_cmake_path)
    set(O3DE_ENGINE_CMAKE_PAL_PATH ${pal_cmake_path})
    set_property(GLOBAL PROPERTY O3DE_ENGINE_CMAKE_PAL_PATH ${O3DE_ENGINE_CMAKE_PAL_PATH})

    # engine cmake 3rdParty pal paths (mirrors o3de_engine_setup)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH}/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_CMAKE_3RDPARTY_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH}/Platform/${O3DE_PAL_PLATFORM_NAME} O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH)

    # engine editor code pal paths (mirrors o3de_engine_setup)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Editor/Platform/${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_ENGINE_CODE_EDITOR_PAL_HOST_PATH)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Editor/Platform/${O3DE_PAL_PLATFORM_NAME} O3DE_ENGINE_CODE_EDITOR_PAL_PATH)

    # Include the cmake files for the PAL platform
    include(${_cmake_Project_cmake}/FileUtil.cmake)
    o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_PAL_HOST_PATH}/platform_${O3DE_PAL_HOST_PLATFORM_WART}_files.cmake)
    if( NOT ${O3DE_PAL_PLATFORM_NAME} STREQUAL ${O3DE_PAL_HOST_PLATFORM_NAME})
        o3de_append_cmake_file_list_to_ALLFILES(${pal_cmake_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake)
    endif()

    # Include the cmake files for this PAL platform
    include(${pal_cmake_path}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake)

    # Include the toolchain file for this PAL platform (mirrors o3de_engine_setup)
    include(${pal_cmake_path}/ToolChain_${O3DE_PAL_PLATFORM_WART}.cmake OPTIONAL)
    include(${pal_cmake_path}/PALTools_${O3DE_PAL_PLATFORM_WART}.cmake)
    include(${pal_cmake_path}/RuntimeDependencies_${O3DE_PAL_PLATFORM_WART}.cmake)

    # append platform pal tools files to ALLFILES so they show up
    o3de_append_cmake_file_list_to_ALLFILES(${pal_cmake_path}/pal_tools_${O3DE_PAL_PLATFORM_WART}_files.cmake)

    # NOTE: restricted PAL loops removed — restricted objects are legacy;
    # overlays are applied at workspace compose time.
    
    # Find all dependent packages
    include(${_cmake_Project_cmake}/Dependencies.cmake)
    # Find all packages the engine declares as dependencies
    o3de_find_packages("${O3DE_ENGINE_DEPENDENT_ENGINES}")
    o3de_find_packages("${O3DE_ENGINE_DEPENDENT_PROJECTS}")
    o3de_find_packages("${O3DE_ENGINE_DEPENDENT_GEMS}")
    o3de_find_packages("${O3DE_ENGINE_DEPENDENT_TEMPLATES}")
    o3de_find_packages("${O3DE_ENGINE_DEPENDENT_REPOS}")
    
    # Find all packages the project declares as dependencies
    o3de_find_packages("${project_dependent_engines}")
    o3de_find_packages("${project_dependent_projects}")
    o3de_find_packages("${project_dependent_gems}")
    o3de_find_packages("${project_dependent_templates}")
    o3de_find_packages("${project_dependent_repos}")
    
    #PAL
    o3de_pal_path(${project_path}/Platform/${O3DE_PAL_PLATFORM_NAME} project_pal_dir)

    include(${_cmake_Project_cmake}/GeneralSettings.cmake)    
    include(${_cmake_Project_cmake}/OutputDirectory.cmake)
    include(${_cmake_Project_cmake}/CompilerSettings.cmake)
    include(${_cmake_Project_cmake}/RuntimeDependencies.cmake)
    include(${_cmake_Project_cmake}/Configurations.cmake)
    include(${_cmake_Project_cmake}/Dependencies.cmake)
    include(${_cmake_Project_cmake}/Deployment.cmake)
    include(${_cmake_Project_cmake}/O3dePython.cmake)    
    include(${_cmake_Project_cmake}/3rdParty.cmake)
    include(${_cmake_Project_cmake}/Install.cmake)
    include(${_cmake_Project_cmake}/O3deWrappers.cmake)
    include(${_cmake_Project_cmake}/O3DEObjectSetup.cmake)
    include(${_cmake_Project_cmake}/Gems.cmake)
    include(${_cmake_Project_cmake}/UnitTest.cmake)
    include(${_cmake_Project_cmake}/TestImpactFramework/TestImpactTestTargetConfig.cmake) # O3deTestWrappers dependency
    include(${_cmake_Project_cmake}/O3deTestWrappers.cmake)
    include(${_cmake_Project_cmake}/Monolithic.cmake)
    include(${_cmake_Project_cmake}/SettingsRegistry.cmake)
    include(${_cmake_Project_cmake}/CMakeFiles.cmake)
    include(${_cmake_Project_cmake}/Subdirectories.cmake)
    include(${_cmake_Project_cmake}/TestImpactFramework/O3deTestImpactFramework.cmake) # Put at end as nothing else depends on it

    # Bring in the engine's own build targets (AzCore, launchers, Editor,
    # tools...).  In project-centric mode the engine is out-of-tree, so
    # give it an explicit binary dir.  The engine CMakeLists skips its
    # own bootstrap when PROJECT_NAME is already set.
    add_subdirectory(${O3DE_ENGINE_PATH} ${CMAKE_BINARY_DIR}/Engine)

    # Add every gem indexed in the resolved manifest (compose-time
    # solution).  The project's own embedded gem(s) are excluded — the
    # project CMakeLists adds them natively.
    o3de_add_manifest_gem_subdirectories("${project_path}")

endmacro()


macro(o3de_project_post_processing)
    include(CTest)
    # The following steps have to be done after all targets are registered:

    # 1. Add any dependencies registered via o3de_enable_gems
    o3de_enable_gems_delayed()

    # 1b. Resolve dependencies declared before their targets existed
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
        include(${_cmake_Project_cmake}/Packaging.cmake)
    endif()

endmacro()
