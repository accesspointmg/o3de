#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Legacy compatibility layer.
#
# Shared 3rd-party packages (in LY_3RDPARTY_PATH/packages) ship their own
# Find*.cmake scripts written against the upstream O3DE cmake API, which
# used the ly_ prefix.  Those packages are immutable shared artifacts, so
# rather than editing them we forward the legacy names to the fork's
# renamed o3de_ implementations.
#
# Only functions actually consumed by packages are shimmed.  Do NOT use
# these names in engine/gem/project code — use the o3de_ names.

include_guard()

function(ly_add_dependencies)
    o3de_add_dependencies(${ARGN})
endfunction()

function(ly_add_target)
    o3de_add_target(${ARGN})
endfunction()

function(ly_add_target_files)
    o3de_add_target_files(${ARGN})
endfunction()

function(ly_create_alias)
    o3de_create_alias(${ARGN})
endfunction()

macro(ly_download_associated_package find_library_name)
    o3de_download_associated_package(${find_library_name} ${ARGN})
endmacro()

function(ly_pip_install_local_package_editable)
    o3de_pip_install_local_package_editable(${ARGN})
endfunction()

function(ly_target_include_system_directories)
    o3de_target_include_system_directories(${ARGN})
endfunction()

# Reverse shim: the fork's O3deWrappers calls o3de_qt_uic_target, but the
# implementation ships inside the shared Qt package (FindQt.cmake) under
# its legacy name.
function(o3de_qt_uic_target)
    ly_qt_uic_target(${ARGN})
endfunction()
