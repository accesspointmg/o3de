#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_RADEON_GPU_ANALYZER_ENABLED FALSE CACHE BOOL "Whether to download Radeon GPU Analyzer from Github.")
set(O3DE_FETCHCONTENT_MESSAGE_LEVEL "ERROR" CACHE STRING "Message level when fetching 3rd party libraries.  Set to DEBUG or VERBOSE to debug")
set(O3DE_FETCHCONTENT_FORCE_GIT OFF CACHE BOOL "Force FetchContent to use git to acquire packages instead of downloading archives")

define_property(TARGET PROPERTY O3DE_SYSTEM_LIBRARY
    BRIEF_DOCS "Defines a 3rdParty library as a system library"
    FULL_DOCS [[
        Property which is set on third party targets that should be considered
        as provided by the system. Such targets are excluded from the runtime
        dependencies considerations, and are not distributed as part of the
        O3DE SDK package. Instead, users of the SDK are expected to install
        such a third party library themselves.
    ]]
)

get_property(o3de_default_third_party_path GLOBAL PROPERTY "O3DE_MANIFEST_DEFAULT_THIRD_PARTY_PATH")
set(O3DE_3RDPARTY_PATH "${o3de_default_third_party_path}" CACHE PATH "Path to the 3rdParty folder")

if(O3DE_3RDPARTY_PATH)
    file(TO_CMAKE_PATH ${O3DE_3RDPARTY_PATH} O3DE_3RDPARTY_PATH)
    if(NOT EXISTS ${O3DE_3RDPARTY_PATH})
        file(MAKE_DIRECTORY ${O3DE_3RDPARTY_PATH})
    endif()
endif()
if(NOT EXISTS ${O3DE_3RDPARTY_PATH})
    message(FATAL_ERROR "3rdParty folder: ${O3DE_3RDPARTY_PATH} does not exist, call cmake defining a valid O3DE_3RDPARTY_PATH or use cmake-gui to configure it")
endif()

#! o3de_add_external_target_path: adds a path to module path so 3rdparty Find files can be added from paths different than cmake/3rdParty
#
# \arg:PATH path to add
#
function(o3de_add_external_target_path PATH)
    list(APPEND CMAKE_MODULE_PATH ${PATH})
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)
    set_property(GLOBAL APPEND PROPERTY O3DE_ADDITIONAL_MODULE_PATH ${PATH})
endfunction()

#! o3de_add_external_target: adds a library interface that exposes external libraries to be used as cmake dependencies.
#
# \arg:NAME name of the external library
# \arg:VERSION version of the external library. Location will be defined by 3rdPartyPath/NAME/VERSION
# \arg:3RDPARTY_DIRECTORY overrides the path to use when searching in the 3rdPartyPath (instead of NAME).
#                         If not indicated, PACKAGE will be used, if not indicated, NAME will be used.
# \arg:3RDPARTY_ROOT_DIRECTORY overrides the root path to the external library directory. This will be used instead of ${O3DE_3RDPARTY_PATH}.
# \arg:INCLUDE_DIRECTORIES include folders (relative to the root path where the external library is: ${O3DE_3RDPARTY_PATH}/${NAME}/${VERSION})
# \arg:PACKAGE if defined, defines the name of the external library "package". This is used when a package exposes multiple interfaces
#              if not defined, NAME is used
# \arg:COMPILE_DEFINITIONS compile definitions to be added to the interface
# \arg:BUILD_DEPENDENCIES list of interfaces this target depends on (could be a compilation dependency if the dependency is only
#                         exposing an include path, or could be a linking dependency is exposing a lib)
# \arg:RUNTIME_DEPENDENCIES list of files this target depends on (could be a dynamic libraries, text files, executables,
#                           applications, other 3rdParty targets, etc)
# \arg:OUTPUT_SUBDIRECTORY Subdirectory within bin/<Profile/Debug>/ where the ${PACKAGE_AND_NAME}_RUNTIME_DEPENDENCIES exported by the target will be copied to.
#                          If not specified, then the ${PACKAGE_AND_NAME}_RUNTIME_DEPENDENCIES will be copied directly under bin/<Profile/Debug>/.
#                          Each file listed in runtime dependencies can also customize its own output subfolder
#                          by adding "\n<subfolder path>" at the end of each listed file. OUTPUT_SUBDIRECTORY only works
#                          if such customized subfolder per file is NOT specified.
#                          Examples:
#                          1- If there are 5 files listed in ${PACKAGE_AND_NAME}_RUNTIME_DEPENDENCIES, and all of them
#                             should be copied to the same output subfolder named "My/Output/Subfolder" then it is advisable
#                             to set OUTPUT_SUBDIRECTORY to "My/Output/Subfolder" instead of appending: "\nMy/Output/Subfolder"
#                             at the end of each listed file.
#                          2- Assume there are 2 files listed in ${PACKAGE_AND_NAME}_RUNTIME_DEPENDENCIES, "fileA" must go to
#                             subdirectory "My/Output/Subfolder/lib" and "fileB" must go to subdirectory "My/Output/Subfolder/bin".
#                             In this case OUTPUT_SUBDIRECTORY should NOT be used, instead the files can be listed as:
#                             "fileA\nMy/Output/Subfolder/lib"
#                             "fileB\nMy/Output/Subfolder/bin"
#
# \arg:SYSTEM           If specified, the library is considered a system library, and is not copied to the build output directory
function(o3de_add_external_target)

    set(options SYSTEM)
    set(oneValueArgs NAME VERSION 3RDPARTY_DIRECTORY PACKAGE 3RDPARTY_ROOT_DIRECTORY OUTPUT_SUBDIRECTORY)
    set(multiValueArgs HEADER_CHECK COMPILE_DEFINITIONS INCLUDE_DIRECTORIES BUILD_DEPENDENCIES RUNTIME_DEPENDENCIES)

    cmake_parse_arguments(o3de_add_external_target "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input arguments
    if(NOT o3de_add_external_target_NAME)
        message(FATAL_ERROR "You must provide a name for the 3rd party library")
    endif()

    if(NOT o3de_add_external_target_PACKAGE)
        set(o3de_add_external_target_PACKAGE ${o3de_add_external_target_NAME})
        set(PACKAGE_AND_NAME "${o3de_add_external_target_NAME}")
        set(NAME_WITH_NAMESPACE "${o3de_add_external_target_NAME}")
        set(has_package FALSE)
    else()
        set(PACKAGE_AND_NAME "${o3de_add_external_target_PACKAGE}_${o3de_add_external_target_NAME}")
        set(NAME_WITH_NAMESPACE "${o3de_add_external_target_PACKAGE}::${o3de_add_external_target_NAME}")
        set(has_package TRUE)
    endif()
    string(TOUPPER ${PACKAGE_AND_NAME} PACKAGE_AND_NAME)
    string(TOUPPER ${o3de_add_external_target_PACKAGE} PACKAGE)

    if(NOT TARGET 3rdParty::${NAME_WITH_NAMESPACE})

        if(NOT DEFINED o3de_add_external_target_VERSION AND NOT VERSION IN_LIST o3de_add_external_target_KEYWORDS_MISSING_VALUES)
            message(FATAL_ERROR "You must provide a version of the \"${o3de_add_external_target_PACKAGE}\" 3rd party library")
        endif()

        if(NOT o3de_add_external_target_3RDPARTY_ROOT_DIRECTORY)
            if(NOT o3de_add_external_target_3RDPARTY_DIRECTORY)
                if(o3de_add_external_target_PACKAGE)
                    set(o3de_add_external_target_3RDPARTY_DIRECTORY ${o3de_add_external_target_PACKAGE})
                else()
                    set(o3de_add_external_target_3RDPARTY_DIRECTORY ${o3de_add_external_target_NAME})
                endif()
            endif()
            set(BASE_PATH "${O3DE_3RDPARTY_PATH}/${o3de_add_external_target_3RDPARTY_DIRECTORY}")

        else()
            # only install external 3rdParty that are within the source tree
            cmake_path(IS_PREFIX O3DE_ENGINE_PATH ${o3de_add_external_target_3RDPARTY_ROOT_DIRECTORY} NORMALIZE is_in_source_tree)
            if(is_in_source_tree)
                o3de_install_external_target(${o3de_add_external_target_3RDPARTY_ROOT_DIRECTORY})
            endif()
            set(BASE_PATH "${o3de_add_external_target_3RDPARTY_ROOT_DIRECTORY}")
        endif()

        if(o3de_add_external_target_VERSION)
            set(BASE_PATH "${BASE_PATH}/${o3de_add_external_target_VERSION}")
        endif()

        # Setting BASE_PATH variable in the parent scope to allow for the Find<3rdParty>.cmake scripts to use them
        set(BASE_PATH ${BASE_PATH} PARENT_SCOPE)

        add_library(3rdParty::${NAME_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

        if(o3de_add_external_target_INCLUDE_DIRECTORIES)
            list(TRANSFORM o3de_add_external_target_INCLUDE_DIRECTORIES PREPEND ${BASE_PATH}/)
            foreach(include_path ${o3de_add_external_target_INCLUDE_DIRECTORIES})
                if(NOT EXISTS ${include_path})
                    message(FATAL_ERROR "Cannot find include path ${include_path} for 3rdParty::${NAME_WITH_NAMESPACE}")
                endif()
            endforeach()
            o3de_target_include_system_directories(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                INTERFACE ${o3de_add_external_target_INCLUDE_DIRECTORIES}
            )
        endif()

        # Check if there is a pal file for this platform.
        # Prefer the PAL file next to the calling Find<package>.cmake
        # (gems ship their own Platform/ trees for external targets),
        # then fall back to the engine cmake PAL directory.
        set(external_target_pal_file ${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME}/${o3de_add_external_target_PACKAGE}_${O3DE_PAL_PLATFORM_WART}.cmake)
        if(EXISTS ${external_target_pal_file})
            include(${external_target_pal_file})
        else()
            include(${O3DE_ENGINE_CMAKE_PAL_PATH}/${o3de_add_external_target_PACKAGE}_${O3DE_PAL_PLATFORM_WART}.cmake OPTIONAL) # Optional in case the pal file does not exist
        endif()

        if(${PACKAGE_AND_NAME}_INCLUDE_DIRECTORIES)
            list(TRANSFORM ${PACKAGE_AND_NAME}_INCLUDE_DIRECTORIES PREPEND ${BASE_PATH}/)
            foreach(include_path ${${PACKAGE_AND_NAME}_INCLUDE_DIRECTORIES})
                string(GENEX_STRIP ${include_path} include_genex_expr)
                if(include_genex_expr STREQUAL include_path AND NOT EXISTS ${include_path}) # Exclude include paths that have generation expressions from validation
                    message(FATAL_ERROR "Cannot find include path ${include_path} for 3rdParty::${NAME_WITH_NAMESPACE}")
                endif()
            endforeach()
            o3de_target_include_system_directories(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                INTERFACE ${${PACKAGE_AND_NAME}_INCLUDE_DIRECTORIES}
            )
        endif()

        if(has_package AND ${PACKAGE}_LIBS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_LINK_LIBRARIES "${${PACKAGE}_LIBS}"
            )
        endif()

        if(${PACKAGE_AND_NAME}_LIBS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_LINK_LIBRARIES "${${PACKAGE_AND_NAME}_LIBS}"
            )
        endif()

        if(has_package AND ${PACKAGE}_LINK_OPTIONS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_LINK_OPTIONS "${${PACKAGE}_LINK_OPTIONS}"
            )
        endif()
        if(${PACKAGE_AND_NAME}_LINK_OPTIONS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_LINK_OPTIONS "${${PACKAGE_AND_NAME}_LINK_OPTIONS}"
            )
        endif()

        if(has_package AND ${PACKAGE}_COMPILE_OPTIONS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_COMPILE_OPTIONS "${${PACKAGE}_COMPILE_OPTIONS}"
            )
        endif()
        if(${PACKAGE_AND_NAME}_COMPILE_OPTIONS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_COMPILE_OPTIONS "${${PACKAGE_AND_NAME}_COMPILE_OPTIONS}"
            )
        endif()

        unset(all_dependencies)
        if(o3de_add_external_target_RUNTIME_DEPENDENCIES)
            list(APPEND all_dependencies ${o3de_add_external_target_RUNTIME_DEPENDENCIES})
        endif()
        if(has_package AND ${PACKAGE}_RUNTIME_DEPENDENCIES)
            list(APPEND all_dependencies ${${PACKAGE}_RUNTIME_DEPENDENCIES})
        endif()
        if(${PACKAGE_AND_NAME}_RUNTIME_DEPENDENCIES)
            list(APPEND all_dependencies ${${PACKAGE_AND_NAME}_RUNTIME_DEPENDENCIES})
        endif()

        unset(locations)
        unset(manual_dependencies)
        if(all_dependencies)
            foreach(dependency ${all_dependencies})
                if(dependency MATCHES "3rdParty::")
                    list(APPEND manual_dependencies ${dependency})
                else()
                    if(o3de_add_external_target_OUTPUT_SUBDIRECTORY)
                        string(APPEND dependency "\n${o3de_add_external_target_OUTPUT_SUBDIRECTORY}")
                    endif()
                    list(APPEND locations ${dependency})
                endif()
            endforeach()
        endif()
        if(locations)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_IMPORTED_LOCATION "${locations}"
            )
        endif()
        if(manual_dependencies)
            o3de_add_dependencies(3rdParty::${NAME_WITH_NAMESPACE} ${manual_dependencies})
        endif()
        get_property(additional_dependencies GLOBAL PROPERTY O3DE_DELAYED_DEPENDENCIES_3rdParty::${NAME_WITH_NAMESPACE})
        if(additional_dependencies)
            o3de_add_dependencies(3rdParty::${NAME_WITH_NAMESPACE} ${additional_dependencies})
            # Clear the variable so we can track issues in case some dependency is added after
            set_property(GLOBAL PROPERTY O3DE_DELAYED_DEPENDENCIES_3rdParty::${NAME_WITH_NAMESPACE})
        endif()

        if(o3de_add_external_target_COMPILE_DEFINITIONS)
            target_compile_definitions(3rdParty::${NAME_WITH_NAMESPACE}
                INTERFACE ${o3de_add_external_target_COMPILE_DEFINITIONS}
            )
        endif()
        if(has_package AND ${PACKAGE}_COMPILE_DEFINITIONS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_COMPILE_DEFINITIONS "${${PACKAGE}_COMPILE_DEFINITIONS}"
            )
        endif()
        if(${PACKAGE_AND_NAME}_COMPILE_DEFINITIONS)
            set_property(TARGET 3rdParty::${NAME_WITH_NAMESPACE}
                APPEND PROPERTY
                    INTERFACE_COMPILE_DEFINITIONS "${${PACKAGE_AND_NAME}_COMPILE_DEFINITIONS}"
            )
        endif()

        if(has_package AND ${PACKAGE}_BUILD_DEPENDENCIES)
            list(APPEND o3de_add_external_target_BUILD_DEPENDENCIES "${${PACKAGE}_BUILD_DEPENDENCIES}")
            list(REMOVE_DUPLICATES o3de_add_external_target_BUILD_DEPENDENCIES)
        endif()
        if(${PACKAGE_AND_NAME}_BUILD_DEPENDENCIES)
            list(APPEND o3de_add_external_target_BUILD_DEPENDENCIES "${${PACKAGE_AND_NAME}_BUILD_DEPENDENCIES}")
            list(REMOVE_DUPLICATES o3de_add_external_target_BUILD_DEPENDENCIES)
        endif()

        # Interface dependencies may require to find_packages. So far, we are just using packages for 3rdParty, so we will
        # search for those and automatically bring those packages. The naming convention used is 3rdParty::PackageName::OptionalInterface
        foreach(dependency ${o3de_add_external_target_BUILD_DEPENDENCIES})
            string(REPLACE "::" ";" dependency_list ${dependency})
            list(GET dependency_list 0 dependency_namespace)
            if(${dependency_namespace} STREQUAL "3rdParty")
                list(GET dependency_list 1 dependency_package)
                o3de_download_associated_package(${dependency_package})
                find_package(${dependency_package} REQUIRED MODULE)
            endif()
        endforeach()

        if(o3de_add_external_target_BUILD_DEPENDENCIES)
            target_link_libraries(3rdParty::${NAME_WITH_NAMESPACE}
                INTERFACE
                    ${o3de_add_external_target_BUILD_DEPENDENCIES}
            )
        endif()

        if(o3de_add_external_target_SYSTEM)
            set_target_properties(3rdParty::${NAME_WITH_NAMESPACE} PROPERTIES O3DE_SYSTEM_LIBRARY TRUE)
        endif()

    endif()

endfunction()

#! o3de_install_external_target: external libraries which are not part of 3rdParty need to be installed
#
# \arg:3RDPARTY_ROOT_DIRECTORY custom 3rd party directory which needs to be installed
function(o3de_install_external_target 3RDPARTY_ROOT_DIRECTORY)

    # Install the Find file to our <install_location>/cmake/3rdParty directory
    o3de_install_files(FILES ${CMAKE_CURRENT_LIST_FILE}
        DESTINATION cmake/3rdParty
    )
    o3de_install_directory(DIRECTORIES "${3RDPARTY_ROOT_DIRECTORY}")

endfunction()

# Utility function, pass it a single target or a list of targets, and it will do the following to them
# 1. Turn off warnings as errors (we are not responsible for warnings in 3p libraries)
# 2. Make sure its output directory is set to be different for each configuration so that binaries
#    do not overwrite each other between, for example, debug and release.
# 3. If the IDE the user is using has a visual display of folders, put the targets generated in that
#    folder instead of the root folder for visual display.
# 4. Specify that the target be installed
#
# Parameters:
#    IDE_FOLDER string - optional, default is "3rdParty Dependencies" - The folder to use in the IDE.
#    TARGETS list      - required - The targets to fix up (can be a list or a single)
function(o3de_fixup_fetchcontent_targets)
    set(options)
    set(oneValueArgs IDE_FOLDER)
    set(multiValueArgs TARGETS)

    cmake_parse_arguments(o3de_fixup_fetchcontent_targets "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT o3de_fixup_fetchcontent_targets_IDE_FOLDER)
        set(o3de_fixup_fetchcontent_targets_IDE_FOLDER "3rdParty Dependencies")
    endif()

    if(NOT o3de_fixup_fetchcontent_targets_TARGETS)
        message(FATAL_ERROR "o3de_fixup_fetchcontent_targets requires TARGETS to be specified")
        return()
    endif()

    # Suppress any developer warnings, fixing 3p libraries themselves are out of scope for us.
    set(PRIOR_SUPPRESS_DEVELOPER_WARNINGS ${CMAKE_SUPPRESS_DEVELOPER_WARNINGS}) # save the old CMAKE_SUPPRESS_DEVELOPER_WARNINGS
    set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ON CACHE BOOL "" FORCE)

    set(BASE_LIBRARY_FOLDER "lib/${PAL_PLATFORM_NAME}")
    foreach(TARGET_TO_FIXUP ${o3de_fixup_fetchcontent_targets_TARGETS})
        if (NOT TARGET ${TARGET_TO_FIXUP})
            message(FATAL_ERROR "o3de_fixup_fetchcontent_targets invoked on non-existent target ${TARGET_TO_FIXUP}")
            continue()
        endif()
        get_property(this_gem_root GLOBAL PROPERTY "@GEMROOT:${gem_name}@")
        o3de_get_engine_relative_source_dir(${this_gem_root} relative_this_gem_root)

        # Set the location that the library shows up in the IDE:
        set_property(TARGET ${TARGET_TO_FIXUP} PROPERTY FOLDER "${relative_this_gem_root}/External")
        
        # alias it with 3rdParty::targetname
        add_library(3rdParty::${TARGET_TO_FIXUP} ALIAS ${TARGET_TO_FIXUP})

        # We install headers for fetchcontent libraries explicitly, so clear any PUBLIC_HEADER property.
        # Installing the target below without a PUBLIC_HEADER DESTINATION would warn.
        set_property(TARGET ${TARGET_TO_FIXUP} PROPERTY PUBLIC_HEADER)

        foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
            string(TOUPPER ${conf} UCONF)

            # make sure that when building, the library and executable files end up in a place
            # that does not overwrite each other in different configs.
            set_target_properties(${TARGET_TO_FIXUP} PROPERTIES
                RUNTIME_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${UCONF}}
                LIBRARY_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY_${UCONF}}
                )

            # 3p targets don't use warning-as-error
            target_compile_options(${TARGET_TO_FIXUP} ${O3DE_COMPILE_OPTION_DISABLE_WARNINGS})

            # install any libraries to the install/lib/<Profile/Debug/Release> folder
            o3de_install(TARGETS ${TARGET_TO_FIXUP}
                ARCHIVE
                    DESTINATION "${BASE_LIBRARY_FOLDER}/${conf}"
                    COMPONENT ${LY_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
                    CONFIGURATIONS ${conf}
            )
        endforeach()
    endforeach()
    # restore the prior value of CMAKE_SUPPRESS_DEVELOPER_WARNINGS
    set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ${PRIOR_SUPPRESS_DEVELOPER_WARNINGS} CACHE BOOL "" FORCE)
endfunction() # o3de_fixup_fetchcontent_targets


# Add the 3rdParty folder to find the modules
list(APPEND CMAKE_MODULE_PATH ${O3DE_ENGINE_CMAKE_3RDPARTY_PATH})
list(APPEND CMAKE_MODULE_PATH ${O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH})

if(NOT INSTALLED_ENGINE)
    # Add the 3rdParty cmake files to the IDE
    o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_3RDPARTY_PATH}/cmake_files.cmake)
    o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH}/cmake_${O3DE_PAL_PLATFORM_WART}_files.cmake)
    if(O3DE_RADEON_GPU_ANALYZER_ENABLED)
        include(${O3DE_ENGINE_CMAKE_3RDPARTY_PATH}/FetchRGA.cmake)
    endif()
endif()
