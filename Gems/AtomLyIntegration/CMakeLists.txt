#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_gem_setup()

# Child gems of this container (each has its own gem.json).  In the
# source tree the parent adds them; in composed workspaces they are
# flattened to workspace level and these directories do not exist here.
foreach(integration_child
        AtomBridge AtomFont AtomImGuiTools AtomRenderOptions
        AtomViewportDisplayIcons AtomViewportDisplayInfo CommonFeatures
        EditorModeFeedback EMotionFXAtom ImguiAtom
        TechnicalArt/DccScriptingInterface)
    if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${integration_child}/CMakeLists.txt)
        add_subdirectory(${integration_child})
    endif()
endforeach()

# The "AtomLyIntegration" Gem will alias the real Atom_AtomBridge target variants
o3de_create_alias(NAME AtomLyIntegration.Clients NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Clients)
o3de_create_alias(NAME AtomLyIntegration.Servers NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Servers)
o3de_create_alias(NAME AtomLyIntegration.HeadlessServers NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.HeadlessServers)
o3de_create_alias(NAME AtomLyIntegration.Unified NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Unified)
if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_create_alias(NAME AtomLyIntegration.Builders NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Builders)
    o3de_create_alias(NAME AtomLyIntegration.Tools    NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Tools)
endif()
