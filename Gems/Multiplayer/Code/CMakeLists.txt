#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${gem_json_path} ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_source_path)
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

# The ${gem_name}Stats.API target declares the common interface for tracking and recording multiplayer stats for profiling purposes.
o3de_add_target(
    NAME ${gem_name}Stats.API INTERFACE
    NAMESPACE Gem
    FILES_CMAKE
        multiplayerstats_api_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include
    BUILD_DEPENDENCIES
        INTERFACE
           AZ::AzCore
)

o3de_add_target(
    NAME ${gem_name}.Common.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${pal_code_source_path}
            Source
            .
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            AZ::AzNetworking
    AUTOGEN_RULES
        *.AutoPackets.xml,AutoPackets_Header.jinja,$path/$fileprefix.AutoPackets.h
        *.AutoPackets.xml,AutoPackets_Inline.jinja,$path/$fileprefix.AutoPackets.inl
        *.AutoPackets.xml,AutoPackets_Source.jinja,$path/$fileprefix.AutoPackets.cpp
        *.AutoPackets.xml,AutoPacketDispatcher_Header.jinja,$path/$fileprefix.AutoPacketDispatcher.h
        *.AutoPackets.xml,AutoPacketDispatcher_Inline.jinja,$path/$fileprefix.AutoPacketDispatcher.inl
)

# Typically, the Editor Connection Listener is enabled in all regular builds, and disabled in all monolithic builds.
# This can be overridden by passing -DFORCE_ENABLE_O3DE_EDITOR_CONNECTION_LISTENER=0 or 1 when generating the build files.
# The override can be removed by passing -UFORCE_ENABLE_O3DE_EDITOR_CONNECTION_LISTENER when generating the build files.
set(FORCE_ENABLE_O3DE_EDITOR_CONNECTION_LISTENER "" CACHE STRING 
"Overrides the creation of the Editor Connection Listener.
  If unset, it is only created in non-monolithic builds.
  0 always disables the Editor Connection Listener.
  1 always enables the Editor Connection Listener.")

# If there's a value in FORCE_ENABLE_O3DE_EDITOR_CONNECTION_LISTENER, the compiler flag will get set to it.
# Otherwise, the variable will be empty and no compiler flag will be set, leaving it to the code to decide
# whether or not to include the listener.
set(O3DE_EDITOR_CONNECTION_LISTENER_ENABLE_FLAG $<$<NOT:$<STREQUAL:"${FORCE_ENABLE_O3DE_EDITOR_CONNECTION_LISTENER}","">>:O3DE_EDITOR_CONNECTION_LISTENER_ENABLE=$<BOOL:${FORCE_ENABLE_O3DE_EDITOR_CONNECTION_LISTENER}>>)

o3de_add_target(
    NAME ${gem_name}.Client.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_split_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${pal_code_source_path}
            Source
            .
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PUBLIC
            AZ_TRAIT_CLIENT=1
            AZ_TRAIT_SERVER=0
            ${O3DE_EDITOR_CONNECTION_LISTENER_ENABLE_FLAG}
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Common.Static
        PRIVATE
            Gem::EMotionFXStaticLib
            Gem::PhysX5.Static
    AUTOGEN_RULES
        *.AutoComponent.xml,AutoComponent_Header.jinja,$path/$fileprefix.AutoComponent.h
        *.AutoComponent.xml,AutoComponent_Source.jinja,$path/$fileprefix.AutoComponent.cpp
        *.AutoComponent.xml,AutoComponentTypes_Header.jinja,$path/AutoComponentTypes.h
        *.AutoComponent.xml,AutoComponentTypes_Source.jinja,$path/AutoComponentTypes.cpp
)

o3de_add_target(
    NAME ${gem_name}.Server.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_split_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${pal_code_source_path}
            Source
            .
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PUBLIC
            AZ_TRAIT_CLIENT=0
            AZ_TRAIT_SERVER=1
            ${O3DE_EDITOR_CONNECTION_LISTENER_ENABLE_FLAG}
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Common.Static
        PRIVATE
            Gem::EMotionFXStaticLib
            Gem::PhysX5.Static
    AUTOGEN_RULES
        *.AutoComponent.xml,AutoComponent_Header.jinja,$path/$fileprefix.AutoComponent.h
        *.AutoComponent.xml,AutoComponent_Source.jinja,$path/$fileprefix.AutoComponent.cpp
        *.AutoComponent.xml,AutoComponentTypes_Header.jinja,$path/AutoComponentTypes.h
        *.AutoComponent.xml,AutoComponentTypes_Source.jinja,$path/AutoComponentTypes.cpp
)

o3de_add_target(
    NAME ${gem_name}.Unified.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_split_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${pal_code_source_path}
            Source
            .
        PUBLIC
            Include
    COMPILE_DEFINITIONS
        PUBLIC
            AZ_TRAIT_CLIENT=1
            AZ_TRAIT_SERVER=1
            ${O3DE_EDITOR_CONNECTION_LISTENER_ENABLE_FLAG}
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.Common.Static
        PRIVATE
            Gem::EMotionFXStaticLib
            Gem::PhysX5.Static
    AUTOGEN_RULES
        *.AutoComponent.xml,AutoComponent_Header.jinja,$path/$fileprefix.AutoComponent.h
        *.AutoComponent.xml,AutoComponent_Source.jinja,$path/$fileprefix.AutoComponent.cpp
        *.AutoComponent.xml,AutoComponentTypes_Header.jinja,$path/AutoComponentTypes.h
        *.AutoComponent.xml,AutoComponentTypes_Source.jinja,$path/AutoComponentTypes.cpp
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            .
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Unified.Static
    RUNTIME_DEPENDENCIES
        Gem::CertificateManager
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/MultiplayerGem.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

o3de_add_target(
    NAME ${gem_name}.Client ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            .
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Client.Static
    RUNTIME_DEPENDENCIES
        Gem::CertificateManager
)

o3de_add_target(
    NAME ${gem_name}.Server ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            .
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Server.Static
    RUNTIME_DEPENDENCIES
        Gem::CertificateManager
)

o3de_add_target(
    NAME ${gem_name}.Debug.Client ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_debug_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            .
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AtomCore
            AZ::AzFramework
            AZ::AzNetworking
            Gem::Atom_Feature_Common.Public
            Gem::${gem_name}.Client.Static
            Gem::ImGui.Static
)

o3de_add_target(
    NAME ${gem_name}.Debug ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        multiplayer_debug_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            .
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AtomCore
            AZ::AzFramework
            AZ::AzNetworking
            Gem::Atom_Feature_Common.Public
            Gem::${gem_name}.Unified.Static
            Gem::ImGui.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/Debug/MultiplayerDebugModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# The "Multiplayer" target is used by clients and servers, Debug is used only on clients.
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name}.Client Gem::${gem_name}.Debug.Client)
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name}.Server)
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name} Gem::${gem_name}.Debug)

if (O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Tools.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            multiplayer_tools_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                ${pal_code_source_path}
                Source
                .
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PUBLIC
                AZ::AzCore
                AZ::AzFramework
                AZ::AzNetworking
                AZ::AzToolsFramework
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            multiplayer_editor_shared_files.cmake
        COMPILE_DEFINITIONS
            PUBLIC
                MULTIPLAYER_EDITOR
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source
                ${pal_code_source_path}
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                Legacy::EditorLib
                Legacy::CryCommon
                Legacy::Editor.Headers
                AZ::AzCore
                AZ::AzFramework
                AZ::AzNetworking
                AZ::AzToolsFramework
                Gem::Atom_RPI.Public
                Gem::Atom_RHI.Reflect
                Gem::${gem_name}.Unified.Static
                Gem::${gem_name}.Tools.Static
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
        Source/Editor/MultiplayerEditorGem.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

    o3de_create_alias(NAME ${gem_name}.Builders  NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    # use the ${gem_name}.Editor module in tools like the Editor:  Such tools also get the visual debug view:
    o3de_create_alias(NAME ${gem_name}.Tools     NAMESPACE Gem TARGETS Gem::${gem_name}.Debug Gem::${gem_name}.Builders)
endif()

if (O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            multiplayer_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
                ${pal_code_source_path}
                Source
                .
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::${gem_name}.Unified.Static
                Gem::PhysX5.Static
        AUTOGEN_RULES
            *.AutoComponent.xml,AutoComponent_Header.jinja,$path/$fileprefix.AutoComponent.h
            *.AutoComponent.xml,AutoComponent_Source.jinja,$path/$fileprefix.AutoComponent.cpp
            *.AutoComponent.xml,AutoComponentTypes_Header.jinja,$path/AutoComponentTypes.h
            *.AutoComponent.xml,AutoComponentTypes_Source.jinja,$path/AutoComponentTypes.cpp
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )
    o3de_add_googlebenchmark(
        NAME Gem::${gem_name}.Benchmarks
        TARGET Gem::${gem_name}.Tests
    )

    if (O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
        o3de_add_target(
            NAME ${gem_name}.Builders.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                multiplayer_tools_tests_files.cmake
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
                    Source
                    .
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
                    AZ::AzTestShared
                    AZ::AzToolsFrameworkTestCommon
                    Gem::${gem_name}.Unified.Static
                    Gem::${gem_name}.Tools.Static
        )
        o3de_add_googletest(
            NAME Gem::${gem_name}.Builders.Tests
            LABELS REQUIRES_tiaf
        )
    endif()

endif()
