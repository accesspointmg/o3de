#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        fastnoise_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Source
            .       # To give acess to External/FastNoise
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::GradientSignal
        PUBLIC
            AZ::AzCore
        PRIVATE
            AZ::AzFramework
            Gem::LmbrCentral
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        fastnoise_shared_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
    RUNTIME_DEPENDENCIES
        Gem::LmbrCentral
        Gem::GradientSignal
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/FastNoiseModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# Clients and Servers use the above module
o3de_create_alias(NAME ${gem_name}.Clients  NAMESPACE Gem TARGETS ${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers  NAMESPACE Gem TARGETS ${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified  NAMESPACE Gem TARGETS ${gem_name})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            fastnoise_editor_files.cmake
        COMPILE_DEFINITIONS
            PUBLIC
                FASTNOISE_EDITOR
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::LmbrCentral.Editor
                Gem::GradientSignal.Editor.Static
            PUBLIC
                Gem::${gem_name}.Static
                AZ::AzToolsFramework
                Gem::SurfaceData
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        FILES_CMAKE
            fastnoise_editor_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::${gem_name}.Editor.Static
                Gem::LmbrCentral.Editor
        RUNTIME_DEPENDENCIES
            Gem::LmbrCentral.Editor
            Gem::SurfaceData.Editor
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/FastNoiseEditorModule.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

    # builders and tools load the above tool module.
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS ${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS ${gem_name}.Editor)


endif()

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
        o3de_add_target(
            NAME ${gem_name}.Editor.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
            NAMESPACE Gem
            FILES_CMAKE
                fastnoise_editor_tests_files.cmake
            COMPILE_DEFINITIONS
                PUBLIC
                    FASTNOISE_EDITOR
            INCLUDE_DIRECTORIES
                PRIVATE
                    Tests
            BUILD_DEPENDENCIES
                PRIVATE
                    AZ::AzTest
                    ${gem_name}.Editor.Static
                    Gem::LmbrCentral.Editor
        )
        o3de_add_googletest(
            NAME Gem::${gem_name}.Editor.Tests
            LABELS REQUIRES_tiaf
        )
    endif()

    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            fastnoise_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::${gem_name}.Static
                Gem::GradientSignal
                Gem::GradientSignal.Tests.Static
                Gem::LmbrCentral
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )

    o3de_add_googlebenchmark(
        NAME Gem::${gem_name}.Benchmarks
        TARGET Gem::${gem_name}.Tests
    )

endif()
