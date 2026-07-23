#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path(${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_source_dir)

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME OpenParticleSystemEditor STATIC
        NAMESPACE Gem
        AUTOMOC
        AUTORCC
        AUTOUIC
        FILES_CMAKE
            openparticlesystemeditor_files.cmake
            OpenParticleSystemEditor/Platform/${O3DE_PAL_PLATFORM_NAME}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
        INCLUDE_DIRECTORIES
            PUBLIC
                .
                OpenParticleSystemEditor
                OpenParticleSystemEditor/Window
                OpenParticleSystemEditor/Viewport
        BUILD_DEPENDENCIES
            PRIVATE
                Gem::AtomToolsFramework.Static
                Gem::AtomToolsFramework.Editor
                Gem::Atom_Feature_Common.Public
                Gem::AtomLyIntegration_CommonFeatures.Static
                Gem::Atom_Component_DebugCamera.Static
                Gem::OpenParticleSystem.Editor.Static
        RUNTIME_DEPENDENCIES
            Gem::Atom_RHI_Null.Private
            Gem::Atom_RHI_DX12.Private
            Gem::Atom_RHI_Vulkan.Private
            Gem::Atom_RHI.Private
            Gem::Atom_Component_DebugCamera
            Gem::Atom_RPI.Editor
            Gem::Atom_RPI.Builders
            Gem::Atom_Feature_Common.Editor
            Gem::AtomToolsFramework.Editor
            Gem::AtomLyIntegration_CommonFeatures.Editor
    )
endif()
