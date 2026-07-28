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
        vegetation_files.cmake
    COMPILE_DEFINITIONS
        PUBLIC
            # if we are in debug or profile, enable VEG_PROFILE_ENABLED
            $<$<IN_LIST:$<CONFIG>,debug;profile>:VEG_PROFILE_ENABLED>
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::LmbrCentral.API
            Gem::SurfaceData.Static
            Legacy::CryCommon
        PUBLIC
            Gem::CommonFeaturesAtom.Static
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        vegetation_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
            Legacy::CryCommon
    RUNTIME_DEPENDENCIES
        Gem::LmbrCentral
        Gem::GradientSignal
        Gem::SurfaceData
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/VegetationModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# the above module is for use in clients and server type applications
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE

        NAMESPACE Gem
        FILES_CMAKE
            vegetation_editor_files.cmake
        COMPILE_DEFINITIONS
            PRIVATE
                VEGETATION_EDITOR
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
            PUBLIC
                Include
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::${gem_name}.Static
                AZ::AzToolsFramework
                Legacy::CryCommon
    RUNTIME_DEPENDENCIES
        Gem::LmbrCentral.Editor
        Gem::GradientSignal.Editor
        Gem::SurfaceData.Editor
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/VegetationEditorModule.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

    # the above module is for use in dev tools
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

endif()

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            vegetation_tests_files.cmake
            vegetation_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
                Source
                .
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                AZ::AzFrameworkTestShared
                Gem::${gem_name}.Static
                Gem::LmbrCentral.Mocks
                Legacy::CryCommon
    )
    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )
endif()
