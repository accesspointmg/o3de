#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(AUDIOSYSTEM_COMPILEDEFINITIONS
    $<IF:$<CONFIG:Release>,AUDIO_RELEASE,ENABLE_AUDIO_LOGGING>
)

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_path)
set(pal_common_code_path ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)

################################################################################
# Client Targets
################################################################################
o3de_add_target(
    NAME ${gem_name}.API INTERFACE
    NAMESPACE Gem
    FILES_CMAKE
        audiosystem_api_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include/Engine
    BUILD_DEPENDENCIES
        INTERFACE
            AZ::AzCore
)

o3de_add_target(
    NAME ${gem_name}.Private.Object STATIC
    NAMESPACE Gem
    FILES_CMAKE
        audiosystem_files.cmake
        ${pal_code_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    TARGET_PROPERTIES
        O3DE_PRIVATE_TARGET TRUE
    INCLUDE_DIRECTORIES
        PRIVATE
            Include/Engine
            Source/Engine
            ${pal_code_path}
    PLATFORM_INCLUDE_FILES
            ${pal_code_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    COMPILE_DEFINITIONS
        PUBLIC
            ${AUDIOSYSTEM_COMPILEDEFINITIONS}
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            Gem::${gem_name}.API
            Gem::Atom_RPI.Public
            Legacy::CryCommon # Temporary, needs to be removed
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        audiosystem_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source/Engine
            ${pal_code_path}
    COMPILE_DEFINITIONS
        PUBLIC
            ${AUDIOSYSTEM_COMPILEDEFINITIONS}
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.API
        PRIVATE
            Gem::${gem_name}.Private.Object
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/AudioSystemModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# AudioSystem aliases for Clients and Unified launchers (no Servers)
o3de_create_alias(NAME ${gem_name}.Clients        NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Clients.API    NAMESPACE Gem TARGETS Gem::${gem_name}.API)
o3de_create_alias(NAME ${gem_name}.Unified        NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified.API    NAMESPACE Gem TARGETS Gem::${gem_name}.API)

################################################################################
# Tests
################################################################################
if (O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    set(common_dir ${CMAKE_CURRENT_LIST_DIR}/Platform/Common)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            audiosystem_tests_files.cmake
            audiosystem_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
                Source/Engine
        BUILD_DEPENDENCIES
            PUBLIC
                Gem::${gem_name}.API
            PRIVATE
                AZ::AzTest
                Gem::${gem_name}.Private.Object
                Legacy::CryCommon   # Temporary, needs to be removed
    )

    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
    )

    list(APPEND testTargets ${gem_name}.Tests)

    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/Legacy/MultipleMultiple/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/Legacy/MultipleMultiple
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/Legacy/MultipleOne/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/Legacy/MultipleOne
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/Legacy/OneMultiple/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/Legacy/OneMultiple
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/Legacy/OneOne/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/Legacy/OneOne
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/MultipleMultiple/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/MultipleMultiple
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/MultipleOne/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/MultipleOne
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/OneMultiple/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/OneMultiple
    )
    o3de_add_target_files(
        TARGETS
            ${testTargets}
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/Tests/ATLData/OneOne/ATLTestControls.xml
        OUTPUT_SUBDIRECTORY
            Test.Assets/Gems/AudioSystem/ATLData/OneOne
    )

endif() # O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED


################################################################################
# Editor
################################################################################
if (O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor.API INTERFACE
        NAMESPACE Gem
        FILES_CMAKE
            audiosystem_editor_api_files.cmake
        INCLUDE_DIRECTORIES
            INTERFACE
                Include/Editor
        BUILD_DEPENDENCIES
            INTERFACE
                AZ::AzCore
    )

    o3de_add_target(
        NAME ${gem_name}.Editor.Private.Object STATIC
        NAMESPACE Gem
        AUTOMOC
        AUTOUIC
        AUTORCC
        FILES_CMAKE
            audiosystem_editor_files.cmake
        TARGET_PROPERTIES
            O3DE_PRIVATE_TARGET TRUE
        INCLUDE_DIRECTORIES
            PRIVATE
                .               # <-- This is needed for Automoc, Autouic, Autorcc
                Source/Engine
                Source/Editor
                ${pal_code_path}
        COMPILE_DEFINITIONS
            PUBLIC
                ${AUDIOSYSTEM_COMPILEDEFINITIONS}
        BUILD_DEPENDENCIES
            PUBLIC
                AZ::AzCore
                AZ::AzToolsFramework
                Legacy::EditorCore
                Legacy::EditorCommon
                Gem::${gem_name}.API
                Gem::${gem_name}.Editor.API
                Legacy::CryCommon   # Temporary, needs to be removed
            PRIVATE
                Gem::${gem_name}.Private.Object
                3rdParty::Qt::Core
                3rdParty::Qt::Widgets
                3rdParty::Qt::Gui
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            audiosystem_editor_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source/Editor
                Source/Engine
        COMPILE_DEFINITIONS
            PRIVATE
                AUDIO_SYSTEM_EDITOR
        BUILD_DEPENDENCIES
            PUBLIC
                Gem::${gem_name}.API
                Gem::${gem_name}.Editor.API
            PRIVATE
                3rdParty::Qt::Core
                Gem::Atom_RPI.Public
                Gem::${gem_name}.Editor.Private.Object
    )

    # use the above "Editor" target in tools and builders:
    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

    if (O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        o3de_add_target(
            NAME ${gem_name}.Editor.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                audiosystem_editor_tests_files.cmake
                audiosystem_editor_shared_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
                    Source/Editor
                    Source/Engine
            BUILD_DEPENDENCIES
                PUBLIC
                    Gem::${gem_name}.API
                    Gem::${gem_name}.Editor.API
                PRIVATE
                    AZ::AzTest
                    3rdParty::Qt::Core
                    Gem::Atom_RPI.Public
                    Gem::${gem_name}.Editor.Private.Object
        )

        o3de_add_googletest(
            NAME Gem::AudioSystem.Editor.Tests
            LABELS REQUIRES_tiaf
        )

    endif() # O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED
endif() # O3DE_PAL_TRAIT_BUILD_HOST_TOOLS
