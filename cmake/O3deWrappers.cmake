#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_O3deWrappers_cmake ${CMAKE_CURRENT_LIST_DIR})
set(O3DE_UNITY_BUILD ON CACHE BOOL "UNITY builds")

include(CMakeFindDependencyMacro)
include(${_cmake_O3deWrappers_cmake}/O3deAutoGen.cmake)

include(${O3DE_ENGINE_CMAKE_PAL_PATH}/O3deWrappers_${O3DE_PAL_PLATFORM_WART}.cmake)

# Not all platforms support unity builds
if(O3DE_UNITY_BUILD AND NOT O3DE_PAL_TRAIT_BUILD_UNITY_SUPPORTED)
    message(ERROR "O3DE_UNITY_BUILD is specified, but not supported for the current target platform")
endif()

define_property(TARGET PROPERTY GEM_MODULE
    BRIEF_DOCS "Defines a MODULE library as a Gem"
    FULL_DOCS [[
        Property which is set on targets that should be seen as gems
        This is used to determine whether this target should load as
        when used as a runtime dependency should load at the same time
        as its dependee
    ]]
)

define_property(TARGET PROPERTY RUNTIME_DEPENDENCIES_DEPENDS
    BRIEF_DOCS "Defines the dependencies the runtime dependencies of a target has"
    FULL_DOCS [[
        Property which is queried through generator expressions at the moment
        the target is declared so a custom command that will do the copies can
        be generated later. Custom commands need to be declared in the same folder
        the target is declared, however, runtime dependencies need all targets
        to be declared, so it is done towards the end of CMake parsing. When
        runtime dependencies are processed, this target property is filled so the
        right dependencies are set for the custom command.
        This property contains all the files that are going to be copied to the output
        when the target gets built.
    ]]
)

#! o3de_add_target: adds a target and provides parameters for the common configurations.
#
# Adds a target (static/dynamic library, executable) and convenient wrappers around most
# common parameters that need to be set.
# This function also creates an interface to use for dependencies. The interface will be
# named as "NAMESPACE::NAME"
# Some examples:
#     o3de_add_target(NAME mystaticlib STATIC FILES_CMAKE somestatic_files.cmake)
#     o3de_add_target(NAME mydynamiclib SHARED FILES_CMAKE somedyn_files.cmake)
#     o3de_add_target(NAME myexecutable EXECUTABLE FILES_CMAKE someexe_files.cmake)
#
# \arg:NAME name of the target
# \arg:STATIC (bool) defines this target to be a static library
# \arg:GEM_STATIC (bool) defines this target to be a static library while also setting the GEM_MODULE property
# \arg:SHARED (bool) defines this target to be a dynamic library
# \arg:GEM_SHARED (bool) defines this target to be a dynamic library while also setting the GEM_MODULE property
# \arg:MODULE (bool) defines this target to be a module library
# \arg:GEM_MODULE (bool) defines this target to be a module library while also marking the target as a "Gem" via the GEM_MODULE property
# \arg:OBJECT (bool) defines this target to be an object library
# \arg:INTERFACE (bool) defines this target to be an interface library. A ${NAME}_HEADERS project will be created for the IDE
#                        The HEADERONLY option can be specified as an alternative
# \arg:EXECUTABLE (bool) defines this target to be an executable
# \arg:APPLICATION (bool) defines this target to be an application (executable that is not a console)
# \arg:IMPORTED (bool) defines this target to be imported.
# \arg:NAMESPACE namespace declaration for this target. It will be used for IDE and dependencies
# \arg:OUTPUT_NAME (optional) overrides the name of the output target. If not specified, the name will be used.
# \arg:OUTPUT_SUBDIRECTORY places the runtime binary in a subfolder within the output folder (this only affects to runtime binaries)
# \arg:AUTOMOC enables Qt moc in the target
# \arg:AUTOUIC enables Qt uic in the target
# \arg:AUTORCC enables Qt rcc in the target
# \arg:NO_UNITY Prevent the target from employing unity builds even when unity builds (O3DE_UNITY_BUILD) are enabled
# \arg:FILES_CMAKE list of *_files.cmake files that contain files for this target
# \arg:GENERATED_FILES list of files to add to this target that are generated out of some other task
# \arg:INCLUDE_DIRECTORIES list of directories to use as include paths
# \arg:BUILD_DEPENDENCIES list of interfaces this target depends on (could be a compilation dependency
#                             if the dependency is only exposing an include path, or could be a linking
#                             dependency is exposing a lib)
# \arg:RUNTIME_DEPENDENCIES list of dependencies this target depends on at runtime
# \arg:COMPILE_DEFINITIONS list of compilation definitions this target will use to compile
# \arg:PLATFORM_INCLUDE_FILES *.cmake files which should contain platform specific configuration to be added to the target
#                             Look at the documentation for the o3de_configure_target_platform_properties() function below
#                             for the list of variables that will be used by the target
# \arg:TARGET_PROPERTIES additional properties to set to the target
# \arg:AUTOGEN_RULES a set of AutoGeneration rules to be passed to the AzAutoGen expansion system
function(o3de_add_target)

    set(options STATIC SHARED MODULE GEM_STATIC GEM_MODULE OBJECT HEADERONLY EXECUTABLE APPLICATION IMPORTED AUTOMOC AUTOUIC AUTORCC NO_UNITY EXPORT_ALL_SYMBOLS)
    set(oneValueArgs NAME NAMESPACE OUTPUT_SUBDIRECTORY OUTPUT_NAME)
    set(multiValueArgs FILES_CMAKE GENERATED_FILES INCLUDE_DIRECTORIES COMPILE_DEFINITIONS BUILD_DEPENDENCIES RUNTIME_DEPENDENCIES PLATFORM_INCLUDE_FILES TARGET_PROPERTIES AUTOGEN_RULES)

    cmake_parse_arguments(o3de_add_target "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Since the term "INTERFACE" used in  other context such as INCLUDE_DIRECTORIES, COMPILE_DEFINITIONS to specify property visibility
    # It needs to be parsed after those arguments have been parsed to avoid the usage of INTERFACE as a visibility scope
    cmake_parse_arguments(o3de_add_target "INTERFACE" "" "" ${o3de_add_target_UNPARSED_ARGUMENTS})

    # Validate input arguments
    if(NOT o3de_add_target_NAME)
        message(FATAL_ERROR "You must provide a name for the target")
    endif()

    # Map HEADERONLY option to INTERFACE
    if(o3de_add_target_HEADERONLY)
        set(o3de_add_target_INTERFACE o3de_add_target_HEADERONLY)
    endif()
    if(NOT o3de_add_target_IMPORTED AND NOT o3de_add_target_INTERFACE)
        if(NOT o3de_add_target_FILES_CMAKE)
            message(FATAL_ERROR "You must provide a list of _files.cmake files for the target")
        endif()
    endif()

    # If the GEM_MODULE tag is passed set the normal MODULE argument
    if(o3de_add_target_GEM_MODULE)
        set(o3de_add_target_MODULE ${o3de_add_target_GEM_MODULE})
    endif()
    # If the GEM_STATIC tag is passed mark the target as STATIC
    if(o3de_add_target_GEM_STATIC)
        set(o3de_add_target_STATIC ${o3de_add_target_GEM_STATIC})
    endif()
    # If the GEM_SHARED tag is passed mark the target as SHARED
    if(o3de_add_target_GEM_SHARED)
        set(o3de_add_target_SHARED ${o3de_add_target_GEM_SHARED})
    endif()

    foreach(file_cmake ${o3de_add_target_FILES_CMAKE})
        o3de_append_cmake_file_list_to_ALLFILES(${file_cmake})
    endforeach()

    unset(linking_options)
    unset(linking_count)
    unset(target_type_options)
    if(o3de_add_target_STATIC)
        set(linking_options STATIC)
        set(target_type_options STATIC)
        set(linking_count "${linking_count}1")
    endif()
    if(o3de_add_target_OBJECT)
        set(linking_options OBJECT)
        set(target_type_options OBJECT)
        set(linking_count "${linking_count}1")
    endif()
    if(o3de_add_target_SHARED)
        set(linking_options SHARED)
        set(target_type_options SHARED)
        set(linking_count "${linking_count}1")
    endif()
    if(o3de_add_target_MODULE)
        set(linking_options ${O3DE_PAL_LINKOPTION_MODULE})
        set(target_type_options ${O3DE_PAL_LINKOPTION_MODULE})
        set(linking_count "${linking_count}1")
    endif()
    if(o3de_add_target_INTERFACE)
        set(linking_options INTERFACE)
        set(target_type_options INTERFACE)
        set(linking_count "${linking_count}1")
    endif()
    if(o3de_add_target_EXECUTABLE)
        set(linking_options EXECUTABLE)
        set(linking_count "${linking_count}1")
    endif()
    if(o3de_add_target_APPLICATION)
        set(linking_options APPLICATION)
        set(linking_count "${linking_count}1")
    endif()
    if(NOT ("${linking_count}" STREQUAL "1"))
        message(FATAL_ERROR "More than one of the following options [STATIC | SHARED | MODULE | OBJECT | INTERFACE | EXECUTABLE | APPLICATION ] was specified and they are mutually exclusive")
    endif()
    if(o3de_add_target_IMPORTED)
        list(APPEND target_type_options IMPORTED GLOBAL)
    endif()

    if(o3de_add_target_NAMESPACE)
        set(interface_name "${o3de_add_target_NAMESPACE}::${o3de_add_target_NAME}")
    else()
        set(interface_name "${o3de_add_target_NAME}")
    endif()

    set(project_NAME ${o3de_add_target_NAME})
    if(o3de_add_target_EXECUTABLE)
        add_executable(${o3de_add_target_NAME}
            ${target_type_options}
            ${ALLFILES} ${o3de_add_target_GENERATED_FILES}
        )
        o3de_apply_platform_properties(${o3de_add_target_NAME})
        if(o3de_add_target_IMPORTED)
            set_target_properties(${o3de_add_target_NAME} PROPERTIES LINKER_LANGUAGE CXX)
        endif()
    elseif(o3de_add_target_APPLICATION)
        add_executable(${o3de_add_target_NAME}
            ${target_type_options}
            ${O3DE_PAL_EXECUTABLE_APPLICATION_FLAG}
            ${ALLFILES} ${o3de_add_target_GENERATED_FILES}
        )
        o3de_apply_platform_properties(${o3de_add_target_NAME})
        if(o3de_add_target_IMPORTED)
            set_target_properties(${o3de_add_target_NAME} PROPERTIES LINKER_LANGUAGE CXX)
        endif()
    elseif(o3de_add_target_INTERFACE)
        add_library(${o3de_add_target_NAME}
            ${target_type_options}
            ${ALLFILES} ${o3de_add_target_GENERATED_FILES}
        )
    else()
        add_library(${o3de_add_target_NAME}
            ${target_type_options}
            ${ALLFILES} ${o3de_add_target_GENERATED_FILES}
        )
        o3de_apply_platform_properties(${o3de_add_target_NAME})
    endif()
    if(${o3de_add_target_GENERATED_FILES})
        set_source_files_properties(${o3de_add_target_GENERATED_FILES}
            PROPERTIES GENERATED TRUE
        )
    endif()

    if(${o3de_add_target_EXECUTABLE} OR ${o3de_add_target_APPLICATION})
        add_executable(${interface_name} ALIAS ${o3de_add_target_NAME})
    else()
        add_library(${interface_name} ALIAS ${o3de_add_target_NAME})
    endif()

    if(o3de_add_target_OUTPUT_NAME)
        set_target_properties(${o3de_add_target_NAME} PROPERTIES
            OUTPUT_NAME ${o3de_add_target_OUTPUT_NAME}
        )
    endif()

    # Add the target dependencies so they can be walked later
    if(o3de_add_target_BUILD_DEPENDENCIES)
        set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TARGETS_${o3de_add_target_NAME}_BUILD_DEPENDENCIES ${o3de_add_target_BUILD_DEPENDENCIES})
    endif()

    if(o3de_add_target_RUNTIME_DEPENDENCIES)
        set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TARGETS_${o3de_add_target_NAME}_RUNTIME_DEPENDENCIES ${o3de_add_target_RUNTIME_DEPENDENCIES})
    endif()

    if (o3de_add_target_SHARED OR o3de_add_target_MODULE OR o3de_add_target_EXECUTABLE OR o3de_add_target_APPLICATION)

        if (o3de_add_target_OUTPUT_SUBDIRECTORY)
            o3de_handle_custom_output_directory(${o3de_add_target_NAME} ${o3de_add_target_OUTPUT_SUBDIRECTORY})
        else()
            o3de_handle_custom_output_directory(${o3de_add_target_NAME} "")
        endif()
    endif()


    if(o3de_add_target_GEM_MODULE OR o3de_add_target_GEM_STATIC OR o3de_add_target_GEM_SHARED)
        set_target_properties(${o3de_add_target_NAME} PROPERTIES GEM_MODULE TRUE)
    endif()

    if (o3de_add_target_INCLUDE_DIRECTORIES)
        target_include_directories(${o3de_add_target_NAME}
            ${o3de_add_target_INCLUDE_DIRECTORIES}
        )
    endif()

    o3de_apply_debug_strip_options(${o3de_add_target_NAME})

    # Parse the 3rdParty library dependencies
    o3de_parse_third_party_dependencies("${o3de_add_target_BUILD_DEPENDENCIES}")
    o3de_target_link_libraries(${o3de_add_target_NAME}
        ${o3de_add_target_BUILD_DEPENDENCIES}
    )

    if(o3de_add_target_COMPILE_DEFINITIONS)
        target_compile_definitions(${o3de_add_target_NAME}
            ${o3de_add_target_COMPILE_DEFINITIONS}
        )
    endif()

    if(o3de_add_target_SHARED AND o3de_add_target_EXPORT_ALL_SYMBOLS)
        if(O3DE_PAL_PLATFORM_NAME STREQUAL "Windows")
            set_target_properties(${o3de_add_target_NAME} PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
        else()
            target_compile_options(${o3de_add_target_NAME} PRIVATE ${O3DE_PAL_TRAIT_EXPORT_ALL_SYMBOLS_COMPILE_OPTIONS})
        endif()
    endif()

    # For any target that depends on AzTest and is built as an executable, an additional 'AZ_TEST_EXECUTABLE' define will
    # enable the 'AZ_UNIT_TEST_HOOK' macro to also implement main() so that running the executable directly will run
    # the AZ_UNIT_TEST_HOOK function
    if (${linking_options} STREQUAL "EXECUTABLE" AND "AZ::AzTest" IN_LIST o3de_add_target_BUILD_DEPENDENCIES)
        target_compile_definitions(${o3de_add_target_NAME}
            PRIVATE
                AZ_TEST_EXECUTABLE
        )
    endif()

    if(o3de_add_target_TARGET_PROPERTIES)
        set_target_properties(${o3de_add_target_NAME} PROPERTIES
            ${o3de_add_target_TARGET_PROPERTIES})
    endif()

    set(unity_target_types SHARED MODULE EXECUTABLE APPLICATION STATIC OBJECT)
    if(linking_options IN_LIST unity_target_types)
        # For eligible target types, if unity builds (O3DE_UNITY_BUILD) is enabled and the target is not marked with 'NO_UNITY',
        # enable UNITY builds individually for the target
        if(O3DE_UNITY_BUILD AND NOT ${o3de_add_target_NO_UNITY})
            set_target_properties(${o3de_add_target_NAME} PROPERTIES
                UNITY_BUILD ON
                UNITY_BUILD_MODE BATCH
            )
        endif()
    endif()

    # IDE organization
    o3de_source_groups_from_folders("${ALLFILES}")
    source_group("Generated Files" REGULAR_EXPRESSION "(${CMAKE_BINARY_DIR})") # Any file coming from the output folder
    o3de_get_vs_folder_directory(${CMAKE_CURRENT_SOURCE_DIR} ide_path)
    set_property(TARGET ${project_NAME} PROPERTY FOLDER ${ide_path})


    if(o3de_add_target_RUNTIME_DEPENDENCIES)
        o3de_parse_third_party_dependencies("${o3de_add_target_RUNTIME_DEPENDENCIES}")
        o3de_add_dependencies(${o3de_add_target_NAME} ${o3de_add_target_RUNTIME_DEPENDENCIES})
    endif()

    o3de_configure_target_platform_properties()

    # Handle Qt MOC, RCC, UIC via the explicit wrappers provided by the Qt
    # package's FindQt.cmake (Qt 6.10+). CMake's AUTOMOC/AUTORCC autogen is
    # no longer used - the package wires moc/rcc/uic itself.
    get_target_property(all_sources ${o3de_add_target_NAME} SOURCES)
    if(${o3de_add_target_AUTOMOC})
        ly_qt_moc_target(${o3de_add_target_NAME} "${all_sources}")
    endif()
    if(${o3de_add_target_AUTOUIC})
        ly_qt_uic_target(${o3de_add_target_NAME} "${all_sources}")
    endif()
    if(${o3de_add_target_AUTORCC})
        ly_qt_qrc_target(${o3de_add_target_NAME} "${all_sources}")
    endif()

    # Add dependencies that were added before this target was available
    get_property(additional_dependencies GLOBAL PROPERTY O3DE_DELAYED_DEPENDENCIES_${o3de_add_target_NAME})
    if(additional_dependencies)
        o3de_add_dependencies(${o3de_add_target_NAME} ${additional_dependencies})
        # Clear the variable so we can track issues in case some dependency is added after
        set_property(GLOBAL PROPERTY O3DE_DELAYED_DEPENDENCIES_${o3de_add_target_NAME})
    endif()

    # Store the target so we can walk through all of them in LocationDependencies.cmake
    set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TARGETS ${interface_name})

    if(NOT o3de_add_target_IMPORTED)
        # Store the aliased target into a DIRECTORY property
        set_property(DIRECTORY APPEND PROPERTY O3DE_DIRECTORY_TARGETS ${interface_name})

        # Store the directory path in a GLOBAL property so that it can be accessed
        # in the layout install logic. Skip if the directory has already been added
        get_property(o3de_all_target_directories GLOBAL PROPERTY O3DE_ALL_TARGET_DIRECTORIES)
        if(NOT CMAKE_CURRENT_SOURCE_DIR IN_LIST o3de_all_target_directories)
            set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TARGET_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR})
        endif()
    endif()

    # Custom commands need to be declared in the same folder as the target that they use.
    # Not all the targets will require runtime dependencies, but we will generate at least an
    # empty file for them.
    set(runtime_dependencies_list SHARED MODULE EXECUTABLE APPLICATION)
    if(NOT o3de_add_target_IMPORTED AND linking_options IN_LIST runtime_dependencies_list)

        get_property(is_multi_config_generator GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
        # XCode generator doesnt support different source files per configuration, so we cannot have
        # the runtime dependencies using file-tracking, instead, we will have them as a post build step
        # Non-multi config generators like Ninja (not "Ninja Multi-Config"), Makefiles, etc have trouble to
        # produce file-level dependencies per configuration, so we also default to use a post build step
        if(NOT is_multi_config_generator OR CMAKE_GENERATOR MATCHES Xcode)

            add_custom_command(TARGET ${o3de_add_target_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/runtime_dependencies/$<CONFIG>/${o3de_add_target_NAME}.cmake
                COMMENT "Copying ${o3de_add_target_NAME} runtime dependencies to output..."
                DEPENDS ${CMAKE_BINARY_DIR}/runtime_dependencies/${o3de_add_target_NAME}.cmake
                COMMENT "Copying runtime dependencies..."
                VERBATIM
            )

        else()

            # the stamp file will be the one that triggers the execution of the custom rule. At the end
            # of running the copy of runtime dependencies, the stamp file is touched so the timestamp is updated.
            # Adding a config as part of the name since the stamp file is added to the VS project.
            # Note the STAMP_OUTPUT_FILE need to match with the one used in runtime dependencies (e.g. RuntimeDependencies_common.cmake)
            set(STAMP_OUTPUT_FILE ${CMAKE_BINARY_DIR}/runtime_dependencies/$<CONFIG>/${o3de_add_target_NAME}.stamp)
            add_custom_command(
                OUTPUT ${STAMP_OUTPUT_FILE}
                DEPENDS "$<GENEX_EVAL:$<TARGET_PROPERTY:${o3de_add_target_NAME},RUNTIME_DEPENDENCIES_DEPENDS>>"
                COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/runtime_dependencies/$<CONFIG>/${o3de_add_target_NAME}.cmake
                COMMENT "Copying ${o3de_add_target_NAME} runtime dependencies to output..."
                VERBATIM
            )

            # Unfortunately the VS generator cannot deal with generation expressions as part of the file name, wrapping the
            # stamp file on each configuration so it gets properly excluded by the generator
            unset(stamp_files_per_config)
            foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
                set(stamp_file_conf ${CMAKE_BINARY_DIR}/runtime_dependencies/${conf}/${o3de_add_target_NAME}.stamp)
                set_source_files_properties(${stamp_file_conf} PROPERTIES GENERATED TRUE SKIP_AUTOGEN TRUE)
                list(APPEND stamp_files_per_config $<$<CONFIG:${conf}>:${stamp_file_conf}>)
            endforeach()
            target_sources(${o3de_add_target_NAME} PRIVATE ${stamp_files_per_config})

        endif()

    endif()

    if(o3de_add_target_AUTOGEN_RULES)
        o3de_add_autogen(
            NAME ${o3de_add_target_NAME}
            INCLUDE_DIRECTORIES ${o3de_add_target_INCLUDE_DIRECTORIES}
            AUTOGEN_RULES ${o3de_add_target_AUTOGEN_RULES}
            ALLFILES ${ALLFILES}
        )
    endif()

endfunction()

#! o3de_target_link_libraries: wraps target_link_libraries handling also MODULE linkage.
#  MODULE libraries cannot be passed to target_link_libraries. MODULE libraries are shared libraries that we
#  dont want to link against because they will be loaded dynamically. However, we want to include their public headers
#  and transition their public dependencies.
#  To achieve this, we delay the target_link_libraries call to after all targets are declared (see o3de_delayed_target_link_libraries)
#
#  Signature is the same as target_link_libraries:
#     target_link_libraries(<target> ... <item>... ...)
#
function(o3de_target_link_libraries TARGET)

    if(NOT TARGET)
        message(FATAL_ERROR "You must provide a target")
    endif()

    set_property(TARGET ${TARGET} APPEND PROPERTY O3DE_DELAYED_LINK ${ARGN})
    set_property(GLOBAL APPEND PROPERTY O3DE_DELAYED_LINK_TARGETS ${TARGET}) # to walk them at the end

endfunction()

#! o3de_copy_targets_usage_requires: Copies the usage requirements of the input targets
# For input target that have a TYPE of "MODULE_LIBRARY", its INTERFACE_* properties are copied,
# since a MODULE_LIBRARY cannot be linked
# For input targets that are not of "MODULE_LIBRARY" TYPE, they are addded as dependency of the
# destination target through the target_link_libraries command
# See: https://cmake.org/cmake/help/latest/prop_tgt/TYPE.html for list of available library types
#
# The primary purpose of this function is to aggregate the usage requirements of multiple dependencies
# into an INTERFACE target, where it would act as a psuedo ALIAS target which can depend on multiple targets
#\arg:TARGET destination INTERFACE target where usage requirements of the input targets will be aggregated into
#\arg:SOURCE_TARGETS list of targets whose usage requirements will be copied from
function(o3de_copy_targets_usage_requirements)
    set(oneValueArgs TARGET)
    set(multiValueArgs SOURCE_TARGETS)
    cmake_parse_arguments(usage_dependencies "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT usage_dependencies_TARGET OR NOT TARGET ${usage_dependencies_TARGET})
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} must be specified a TARGET argument")
    endif()

    get_target_property(item_type ${usage_dependencies_TARGET} TYPE)
    if (NOT item_type STREQUAL INTERFACE_LIBRARY)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} only supports copy of usage requirements to an INTERFACE TARGET")
    endif()

    set(dest_target ${usage_dependencies_TARGET})

    foreach(source_target IN LISTS usage_dependencies_SOURCE_TARGETS)
        unset(item_type)
        # Retrieve the resolved source target name
        set(source_target_de_alias ${source_target})
        if (TARGET ${source_target})
            get_property(item_type TARGET ${source_target} PROPERTY TYPE)
            o3de_de_alias_target(${source_target} source_target_de_alias)
        endif()

        # If the source target does not exist the item_type is empty
        # In that case the TARGET is assumed to not be a MODULE_LIBRARY
        if(item_type STREQUAL MODULE_LIBRARY)
            # For module libraries the INTERFACE properties are copied over

            # Copy over include and system include directories
            target_include_directories(${dest_target} INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_INCLUDE_DIRECTORIES>>)
            target_include_directories(${dest_target} SYSTEM INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>>)

            # Copy over dependent link libraries and linker options
            target_link_libraries(${dest_target} INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_LINK_LIBRARIES>>)
            target_link_options(${dest_target} INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_LINK_OPTIONS>>)

            # Copy over compiler defintions and compiler options
            target_compile_definitions(${dest_target} INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_COMPILE_DEFINITIONS>>)
            target_compile_options(${dest_target} INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_COMPILE_OPTIONS>>)
            # Copy over source filenames; For the destionation INTERFACE target these will not compile,
            # but can be used as part of add_custom_command
            target_sources(${dest_target} INTERFACE $<GENEX_EVAL:$<TARGET_PROPERTY:${source_target_de_alias},INTERFACE_SOURCES>>)
        else()
            # The simpler case for non-MODULE targets is to copy the usage dependencies via target_link_libraries
            # This even works for source targets with a TYPE of "INTERFACE_LIBRARY" as its INTERFACE_* PROPERTIES
            # are transferred via target_link_libraries as well
            # https://cmake.org/cmake/help/latest/command/add_library.html#interface-libraries
            target_link_libraries(${dest_target} INTERFACE ${source_target_de_alias})
        endif()
    endforeach()
endfunction()

#! o3de_delayed_target_link_libraries: internal function called by the root CMakeLists.txt after all targets
#  have been declared to determine if they are regularly
#  1) If a MODULE is passed in the list of items, it will add the INTERFACE_INCLUDE_DIRECTORIES as include
#     directories of TARGET. It will also add the "INTERFACE_LINK_LIBRARIES" to TARGET. MODULEs cannot be
#     directly linked, but we can include the public headers and link against the things the MODULE expose
#     to link.
#  2) If a target that has not yet been declared is passed, then it will defer it to after all targets are
#     declared. This way we can do a check again. We could delay the link to when
#     target is declared. This is needed for (1) since we dont know the type of target. This also addresses
#     another issue with target_link_libraries where it will only validate that a MODULE is not being passed
#     if the target is already declared, if not, it will fail later at linking time.

function(o3de_delayed_target_link_libraries)

    set(visibilities PRIVATE PUBLIC INTERFACE)

    get_property(additional_module_paths GLOBAL PROPERTY O3DE_ADDITIONAL_MODULE_PATH)
    list(APPEND CMAKE_MODULE_PATH ${additional_module_paths})

    get_property(delayed_targets GLOBAL PROPERTY O3DE_DELAYED_LINK_TARGETS)
    foreach(target ${delayed_targets})

        get_property(delayed_link TARGET ${target} PROPERTY O3DE_DELAYED_LINK)
        if(delayed_link)

            cmake_parse_arguments(o3de_delayed_target_link_libraries "" "" "${visibilities}" ${delayed_link})

            foreach(visibility ${visibilities})
                foreach(alias_item ${o3de_delayed_target_link_libraries_${visibility}})

                    if(TARGET ${alias_item})
                        get_target_property(item_type ${alias_item} TYPE)
                        o3de_de_alias_target(${alias_item} item)
                    else()
                        # Namespace::Name aliases are directory-scoped and
                        # not visible here, but the underlying interface
                        # target <Name> is created GLOBAL ??? strip the
                        # namespace and retry.
                        o3de_strip_target_namespace(TARGET ${alias_item} OUTPUT_VARIABLE stripped_item)
                        if(NOT stripped_item STREQUAL alias_item AND TARGET ${stripped_item})
                            get_target_property(item_type ${stripped_item} TYPE)
                            o3de_de_alias_target(${stripped_item} item)
                        else()
                            unset(item_type)
                            set(item ${alias_item})
                        endif()
                    endif()

                    if(item_type STREQUAL MODULE_LIBRARY)
                        target_include_directories(${target} ${visibility} $<GENEX_EVAL:$<TARGET_PROPERTY:${item},INTERFACE_INCLUDE_DIRECTORIES>>)
                        target_link_libraries(${target} ${visibility} $<GENEX_EVAL:$<TARGET_PROPERTY:${item},INTERFACE_LINK_LIBRARIES>>)
                        target_compile_definitions(${target} ${visibility} $<GENEX_EVAL:$<TARGET_PROPERTY:${item},INTERFACE_COMPILE_DEFINITIONS>>)
                        target_compile_options(${target} ${visibility} $<GENEX_EVAL:$<TARGET_PROPERTY:${item},INTERFACE_COMPILE_OPTIONS>>)
                    else()
                        o3de_parse_third_party_dependencies(${item})
                        target_link_libraries(${target} ${visibility} ${item})
                    endif()

                endforeach()
            endforeach()

        endif()

    endforeach()
    set_property(GLOBAL PROPERTY O3DE_DELAYED_LINK_TARGETS)

endfunction()

#! o3de_parse_third_party_dependencies: Validates any 3rdParty library dependencies through the find_package command
#
# \arg:third_party_libraries name of the target libraries to validate existence of through the find_package command.
#
function(o3de_parse_third_party_dependencies third_party_libraries)
    # Support for deprecated O3DE_VERSION_ENGINE_NAME used in 3p-package-source and misc 3p packages
    set(O3DE_VERSION_ENGINE_NAME ${O3DE_ENGINE_NAME})

    # Interface dependencies may require to find_packages. So far, we are just using packages for 3rdParty, so we will
    # search for those and automatically bring those packages. The naming convention used is 3rdParty::PackageName::OptionalInterface
    unset(all_thirdparty_dependencies_found)

    foreach(dependency ${third_party_libraries})
        string(REPLACE "::" ";" dependency_list ${dependency})
        list(GET dependency_list 0 dependency_namespace)
        if(${dependency_namespace} STREQUAL "3rdParty")
            list(APPEND all_thirdparty_dependencies_found ${dependency})
            if (NOT TARGET ${dependency})
                if (O3DE_SCRIPT_ONLY)
                    # we don't actually need 3p deps to try to download the package or call find_package.
                    # instead we use pre-created part-of-the-installer 3p targets baked in from the above list
                    # which will have been made at install time.
                    # instead, we execute a pregenerated file that was created as part of install to 
                    # create this target:
                    string(REPLACE "::" "__" CLEAN_TARGET_NAME "${dependency}")  
                    # not all 3ps actually exist as real targets, so this is an OPTIONAL include.
                    include(${O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH}/Default/${CLEAN_TARGET_NAME}.cmake OPTIONAL)
                else()
                    list(GET dependency_list 1 dependency_package)
                    list(LENGTH dependency_list dependency_list_length)
                    o3de_download_associated_package(${dependency_package})
                    if (dependency_list_length GREATER 2)
                        # There's an optional interface specified
                        list(GET dependency_list 2 component)
                        list(APPEND packages_with_components ${dependency_package})
                        list(APPEND ${dependency_package}_components ${component})
                    else()
                        find_package(${dependency_package} REQUIRED MODULE)
                    endif()
                endif()

            endif()
        endif()
    endforeach()

    foreach(dependency IN LISTS packages_with_components)
        find_package(${dependency} REQUIRED MODULE COMPONENTS ${${dependency}_components})
    endforeach()
    
    foreach(dependency ${all_thirdparty_dependencies_found})
        if (TARGET ${dependency})
            # keep track of all the 3p dependencies we actually depended on.
            get_property(o3de_all_3rdparty_targets GLOBAL PROPERTY O3DE_ALL_3RDPARTY_TARGETS)
            if(NOT ${dependency} IN_LIST o3de_all_3rdparty_targets)
                set_property(GLOBAL APPEND PROPERTY O3DE_ALL_3RDPARTY_TARGETS "${dependency}")
            endif()
        endif()
    endforeach()
endfunction()

#! o3de_configure_target_platform_properties: Configures any platform specific properties on target
#
# Looks at the the following variables within the platform include file to set the equivalent target properties
# O3DE_FILES_CMAKE -> extract list of files -> target_sources
# O3DE_FILES -> target_source
# O3DE_INCLUDE_DIRECTORIES -> target_include_directories
# O3DE_COMPILE_DEFINITIONS -> target_compile_definitions
# O3DE_COMPILE_OPTIONS -> target_compile_options
# O3DE_LINK_OPTIONS -> target_link_options
# O3DE_BUILD_DEPENDENCIES -> target_link_libraries
# O3DE_RUNTIME_DEPENDENCIES -> o3de_add_dependencies
# O3DE_TARGET_PROPERTIES -> target_properties
#
macro(o3de_configure_target_platform_properties)
    foreach(platform_include_file ${o3de_add_target_PLATFORM_INCLUDE_FILES})

        set(O3DE_FILES_CMAKE)
        set(O3DE_FILES)
        set(O3DE_INCLUDE_DIRECTORIES)
        set(O3DE_COMPILE_DEFINITIONS)
        set(O3DE_COMPILE_OPTIONS)
        set(O3DE_LINK_OPTIONS)
        set(O3DE_BUILD_DEPENDENCIES)
        set(O3DE_RUNTIME_DEPENDENCIES)
        set(O3DE_TARGET_PROPERTIES)

        include(${platform_include_file} RESULT_VARIABLE o3de_platform_cmake_file)
        if(NOT o3de_platform_cmake_file)
            message(FATAL_ERROR "The supplied PLATFORM_INCLUDE_FILE(${platform_include_file}) cannot be included. Parsing of target will halt")
        endif()
        if(o3de_add_target_INTERFACE OR o3de_add_target_IMPORTED)
            target_sources(${o3de_add_target_NAME} INTERFACE ${platform_include_file})
        else()
            target_sources(${o3de_add_target_NAME} PRIVATE ${platform_include_file})
        endif()
        o3de_source_groups_from_folders("${platform_include_file}")

        if(O3DE_FILES_CMAKE)
            foreach(file_cmake ${O3DE_FILES_CMAKE})
                o3de_append_cmake_file_list_to_ALLFILES(${file_cmake})
            endforeach()
            target_sources(${o3de_add_target_NAME} PRIVATE ${ALLFILES})
            o3de_source_groups_from_folders("${ALLFILES}")
        endif()
        if(O3DE_FILES)
            target_sources(${o3de_add_target_NAME} PRIVATE ${O3DE_FILES})
        endif()
        if (O3DE_INCLUDE_DIRECTORIES)
            target_include_directories(${o3de_add_target_NAME} ${O3DE_INCLUDE_DIRECTORIES})
        endif()
        if(O3DE_COMPILE_DEFINITIONS)
            target_compile_definitions(${o3de_add_target_NAME} ${O3DE_COMPILE_DEFINITIONS})
        endif()
        if(O3DE_COMPILE_OPTIONS)
            target_compile_options(${o3de_add_target_NAME} ${O3DE_COMPILE_OPTIONS})
        endif()
        if(O3DE_LINK_OPTIONS)
            target_link_options(${o3de_add_target_NAME} ${O3DE_LINK_OPTIONS})
        endif()
        if(O3DE_BUILD_DEPENDENCIES)
            o3de_target_link_libraries(${o3de_add_target_NAME} ${O3DE_BUILD_DEPENDENCIES})
        endif()
        if(O3DE_RUNTIME_DEPENDENCIES)
            o3de_add_dependencies(${o3de_add_target_NAME} ${O3DE_RUNTIME_DEPENDENCIES})
        endif()
        if(O3DE_TARGET_PROPERTIES)
            set_target_properties(${o3de_add_target_NAME} PROPERTIES ${O3DE_TARGET_PROPERTIES})
        endif()
    endforeach()
endmacro()


#! o3de_add_target_files: adds files to a target. This will copy the specified files to where the target is.
#
# \arg:TARGETS name of the targets that depends on this file
# \arg:FILES files to copy
# \arg:OUTPUT_SUBDIRECTORY (OPTIONAL) where to place the files relative to TARGET_NAME's output dir.
#      If not specified, they are located in the same folder as TARGET_NAME
#
function(o3de_add_target_files)

    set(options)
    set(oneValueArgs OUTPUT_SUBDIRECTORY)
    set(multiValueArgs TARGETS FILES)

    cmake_parse_arguments(o3de_add_target_files "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input arguments
    if(NOT o3de_add_target_files_TARGETS)
        message(FATAL_ERROR "You must provide at least one target")
    endif()
    if(NOT o3de_add_target_files_FILES)
        message(FATAL_ERROR "You must provide at least a file to copy")
    endif()

    foreach(target ${o3de_add_target_files_TARGETS})

        foreach(file ${o3de_add_target_files_FILES})
            set_property(TARGET ${target} APPEND PROPERTY INTERFACE_O3DE_TARGET_FILES "${file}\n${o3de_add_target_files_OUTPUT_SUBDIRECTORY}")
        endforeach()

    endforeach()

endfunction()


#! o3de_add_source_properties: adds/appends properties to a source file.
#
# This wraps set_source_files_properties to be able to pass a property with multiple values
# and get it appended instead of set.
#
# \arg:SOURCES list of sources to apply this property on
# \arg:PROPERTY property to set
# \arg:VALUES values to append
#
function(o3de_add_source_properties)

    set(options)
    set(oneValueArgs PROPERTY)
    set(multiValueArgs SOURCES VALUES)

    cmake_parse_arguments(o3de_add_source_properties "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input arguments
    if(NOT o3de_add_source_properties_SOURCES)
        message(FATAL_ERROR "You must provide at least one source")
    endif()
    if(NOT o3de_add_source_properties_PROPERTY)
        message(FATAL_ERROR "You must provide a property")
    endif()

    foreach(file ${o3de_add_source_properties_SOURCES})
        if(NOT IS_ABSOLUTE ${file})
            get_filename_component(file ${file} ABSOLUTE)
        endif()
        if(NOT EXISTS ${file})
            message(SEND_ERROR "File ${file} not found when setting property ${o3de_add_source_properties_PROPERTY}")
        endif()
    endforeach()

    # We allow to pass empty values because in some cases we expand the values based on conditions
    # If the values are empty then this call does nothing
    if(o3de_add_source_properties_VALUES)
        set_property(
            SOURCE ${o3de_add_source_properties_SOURCES}
            APPEND PROPERTY ${o3de_add_source_properties_PROPERTY} ${o3de_add_source_properties_VALUES}
        )
    endif()

endfunction()


# given a target name, returns the "real" name of the target if its an alias.
# this function recursively de-aliases
function(o3de_de_alias_target target_name output_variable_name)
    # its not okay to call get_target_property on a non-existent target
    if (NOT TARGET ${target_name})
        message(FATAL_ERROR "o3de_de_alias_target called on non-existent target: ${target_name}")
    endif()

    while(target_name)
        set(de_aliased_target_name ${target_name})
        get_target_property(target_name ${target_name} ALIASED_TARGET)
    endwhile()

    if(NOT de_aliased_target_name)
        message(FATAL_ERROR "Empty de_aliased for ${target_name}")
    endif()
    set(${output_variable_name} ${de_aliased_target_name} PARENT_SCOPE)
endfunction()

#! o3de_get_vs_folder_directory: Sets the Visual Studio folder name used for organizing vcxproj
#  in the IDE
#
# Visual Studio cannot load projects that with a ".." relative path or contain a colon ":" as part of its FOLDER
# Therefore if the .vcxproj is absolute, the drive letter must be removed from the folder name
#
# What this method does is first check if the target being added to the Visual Studio solution is within
# the O3DE_ENGINE_PATH(i.e is the O3DE_ENGINE_PATH a prefix of the target source directory)
# If it is a relative path to the target is used as the folder name
# Otherwise the target directory would either
# 1. Be a path outside of the O3DE_ENGINE_PATH on the same drive.
#    In that case forming a relative path would cause it to start with ".." which will not work
# 2. Be an path outside of the O3DE_ENGINE_PATH on a different drive
#    Here a relative path cannot be formed and therefore the path would start with "<drive>:/Path/To/Project"
#    Which shows up as unloaded due to containing a colon
# In this scenario the relative part of the path from the drive letter is used as the FOLDER name
# to make sure the projects show up in the loaded .sln
function(o3de_get_vs_folder_directory absolute_target_source_dir output_source_dir)
    # Get a relative directory to the O3DE_ENGINE_PATH if possible for the Visual Studio solution hierarchy
    # If a relative path cannot be formed, then retrieve a path with the drive letter stripped from it
    cmake_path(IS_PREFIX O3DE_ENGINE_PATH ${absolute_target_source_dir} is_target_prefix_of_engine_root)
    if(is_target_prefix_of_engine_root)
        cmake_path(RELATIVE_PATH absolute_target_source_dir BASE_DIRECTORY ${O3DE_ENGINE_PATH} OUTPUT_VARIABLE relative_target_source_dir)
    else()
        cmake_path(IS_PREFIX CMAKE_SOURCE_DIR ${absolute_target_source_dir} is_target_prefix_of_source_dir)
        if(is_target_prefix_of_source_dir)
            cmake_path(RELATIVE_PATH absolute_target_source_dir BASE_DIRECTORY ${CMAKE_SOURCE_DIR} OUTPUT_VARIABLE relative_target_source_dir)
        else()
            cmake_path(GET absolute_target_source_dir RELATIVE_PART relative_target_source_dir)
        endif()
    endif()

    set(${output_source_dir} ${relative_target_source_dir} PARENT_SCOPE)
endfunction()
