#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_source_dir)

o3de_add_target(
    NAME SimuCore.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        openparticlesystem_simucore_core.cmake
    NO_UNITY
    INCLUDE_DIRECTORIES
        PUBLIC
            SimuCore/core/include
        PRIVATE
            SimuCore/core/src
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
)

o3de_add_target(
    NAME SimuCoreParticleModules.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        openparticlesystem_simucore_modules.cmake
    NO_UNITY
    INCLUDE_DIRECTORIES
        PUBLIC
            SimuCore/modules/particle/core/include
        PRIVATE
            SimuCore/modules/particle/core/src
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::SimuCore.Static
)

o3de_add_target(
        NAME ${gem_name}.API HEADERONLY
        NAMESPACE Gem
        FILES_CMAKE
            openparticlesystem_api_files.cmake
        INCLUDE_DIRECTORIES
            INTERFACE
                Include
)


o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        openparticlesystem_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Source/Runtime
    BUILD_DEPENDENCIES
        PUBLIC
            Gem::${gem_name}.API
            Gem::Atom_Utils.Static
            Gem::Atom_Feature_Common.Public
            Gem::EMotionFX.Static
            AZ::AzCore
            SimuCoreParticleModules.Static
)

o3de_add_target(
        NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            openparticlesystem_shared_files.cmake
        INCLUDE_DIRECTORIES
            PUBLIC
                Source/Runtime
        BUILD_DEPENDENCIES
            PRIVATE
                ${gem_name}.Static
)

o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})

# If we are on a host platform, we want to add the host tools targets like the OpenParticleSystem.Editor target which
# will also depend on OpenParticleSystem.Private.Static
if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor.Static STATIC
        NAMESPACE Gem
        AUTOMOC
        FILES_CMAKE
            openparticlesystem_editor_files.cmake
        COMPILE_DEFINITIONS
            PRIVATE
                PARTICLE_EDITOR
        INCLUDE_DIRECTORIES
            PUBLIC
                Source
        BUILD_DEPENDENCIES
            PUBLIC
                Gem::${gem_name}.Static
                Legacy::EditorCore
            PRIVATE
                Gem::Atom_RPI.Edit
                Gem::AtomToolsFramework.Static
    )

    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        AUTORCC
        OUTPUT_NAME ${gem_name}.Editor.Gem
        FILES_CMAKE
            openparticlesystem_editor_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source/Runtime
        COMPILE_DEFINITIONS
            PRIVATE
                PARTICLE_EDITOR
        BUILD_DEPENDENCIES
            PUBLIC
                Gem::${gem_name}.API
            PRIVATE
                Gem::${gem_name}.Editor.Static
                Gem::AtomToolsFramework.Static
                Gem::OpenParticleSystemEditor
    )

    o3de_add_target(
        NAME ${gem_name}.Builder.Static STATIC
        NAMESPACE Gem
        FILES_CMAKE
            openparticlesystem_builder_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source/Builder
                Source/Runtime
        BUILD_DEPENDENCIES
            PUBLIC
                Gem::${gem_name}.Editor.Static
            PRIVATE
                AZ::SceneCore
                AZ::AssetBuilderSDK
                Gem::Atom_RPI.Edit
                Gem::Atom_RPI.Public
                Gem::Atom_RHI.Public
    )

    o3de_add_target(
        NAME ${gem_name}.Builder GEM_MODULE
        NAMESPACE Gem
        OUTPUT_NAME ${gem_name}.Builder.Gem
        FILES_CMAKE
            openparticlesystem_builder_shared_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source/Builder
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::${gem_name}.Builder.Static
                AZ::SceneCore
                AZ::AssetBuilderSDK
    )

    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Builder)

endif()
