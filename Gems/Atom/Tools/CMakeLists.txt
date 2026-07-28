#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Atom tool gems (each has its own gem.json).  In the source tree this
# container adds them; in composed workspaces they are flattened to
# workspace level and these directories do not exist here.
if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    foreach(atom_tool AtomToolsFramework MaterialEditor MaterialCanvas PassCanvas ShaderManagementConsole)
        if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${atom_tool}/CMakeLists.txt)
            add_subdirectory(${atom_tool})
        endif()
    endforeach()
endif()
