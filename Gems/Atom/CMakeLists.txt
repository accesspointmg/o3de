#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_gem_setup()

add_subdirectory(Tools)
add_subdirectory(Utils)

# Child gems of the Atom container (each has its own gem.json).  In the
# source tree the parent adds them (the manifest-driven traversal skips
# nested gems); in composed workspaces they are flattened to workspace
# level and these directories do not exist here.
foreach(atom_child Bootstrap RHI RPI Feature/Common Component/DebugCamera Asset/ImageProcessingAtom Asset/Shader)
    if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${atom_child}/CMakeLists.txt)
        add_subdirectory(${atom_child})
    endif()
endforeach()

# The "Atom" Gem will alias the real Atom_AtomBridge target variants
# allows the enabling and disabling the "Atom" Gem to build the pre-requisite dependencies
o3de_create_alias(NAME Atom.Clients NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Clients)
o3de_create_alias(NAME Atom.Servers NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Servers)
o3de_create_alias(NAME Atom.HeadlessServers NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.HeadlessServers)
o3de_create_alias(NAME Atom.Unified NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Unified)
if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_create_alias(NAME Atom.Builders NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Builders)
    o3de_create_alias(NAME Atom.Tools    NAMESPACE Gem TARGETS Gem::Atom_AtomBridge.Tools)
endif()
