#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    AUTOMOC
    AUTOUIC
    AUTORCC
    FILES_CMAKE
        atomtoolsframework_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            ${pal_code_source_path}
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            3rdParty::Python
            3rdParty::Qt::Core
            3rdParty::Qt::Gui
            3rdParty::Qt::Network
            3rdParty::Qt::Widgets
            AZ::AzCore
            AZ::AzQtComponents
            AZ::AzToolsFramework
            Gem::Atom_Bootstrap.Headers
            Gem::Atom_Component_DebugCamera.Static
            Gem::Atom_Feature_Common
            Gem::Atom_Feature_Common.Public
            Gem::Atom_RHI.Public
            Gem::Atom_RHI.Reflect
            Gem::Atom_RPI.Edit
            Gem::Atom_RPI.Public
            Gem::GraphCanvasWidgets
            Gem::GraphModel.Editor.Static
            Gem::ImageProcessingAtom.Headers
)

o3de_add_target(
    NAME ${gem_name}.Editor GEM_MODULE

    NAMESPACE Gem
    AUTOMOC
    FILES_CMAKE
        atomtoolsframework_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
    RUNTIME_DEPENDENCIES
        Gem::Atom_Bootstrap
        Gem::Atom_Component_DebugCamera
        Gem::Atom_Feature_Common.Editor
        Gem::Atom_RHI.Private
        Gem::Atom_RHI_Null.Private
        Gem::Atom_RPI.Editor
        Gem::EditorPythonBindings.Editor
        Gem::GraphCanvas.Editor
        Gem::GraphCanvasWidgets
        Gem::GraphModel.Editor
        Gem::ImageProcessingAtom.Editor
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/AtomToolsFrameworkModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# Add a 'builders' alias to allow the ${gem_name} root gem path to be added to the generated
# cmake_dependencies.<project>.assetprocessor.setreg to allow the asset scan folder for it to be added
o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME ${gem_name}.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atomtoolsframework_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Tests
        BUILD_DEPENDENCIES
            PRIVATE
                3rdParty::Qt::Test
                AZ::AzFrameworkTestShared
                AZ::AzTest
                AZ::AzTestShared
                Gem::Atom_Utils.TestUtils.Static
                Gem::${gem_name}.Static
    )

    o3de_add_googletest(
        NAME Gem::${gem_name}.Tests
        LABELS REQUIRES_tiaf
    )

endif()
