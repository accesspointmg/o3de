#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_add_target(
        NAME ${gem_name}.Editor ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            atomviewportdisplayicons_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
                AZ::AzToolsFramework
                AZ::AtomCore
                3rdParty::Qt::Core
                3rdParty::Qt::Gui
                3rdParty::Qt::Svg
                Gem::Atom_RHI.Reflect
                Gem::Atom_RPI.Public
                Gem::Atom_Bootstrap.Headers
                Gem::Atom_AtomBridge.Static
    )

    # Inject the gem name into the Module source file
    o3de_add_source_properties(
        SOURCES
            Source/Module.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})

endif()
