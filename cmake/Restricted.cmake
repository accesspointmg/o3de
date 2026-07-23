#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Platform Abstraction Layer (PAL) path resolution.
#
# Platform-specific files live at <object>/Platform/<PlatformName>/... .
# Platforms that are not part of an object's base tree (NDA/console
# platforms, or optionally-split open platforms) are delivered as OVERLAY
# objects and composed into the object tree at workspace compose time by
# o3de-cli - by the time CMake runs, every platform file that should exist
# is already at its canonical path. There is no configure-time path
# remapping (the legacy "restricted" parallel-tree mechanism is retired).
#
# These functions therefore simply return the requested path.

#! o3de_pal_path: returns the PAL path for a platform file/directory.
# \arg:path_to_where_the_platform_file_should_be - requested path
# \arg:path_to_where_the_platform_file_really_is - output variable
function(o3de_pal_path path_to_where_the_platform_file_should_be path_to_where_the_platform_file_really_is)
    set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
endfunction()

#! o3de_pal_dir: upstream-compatible PAL directory resolution.
#
# Object CMakeLists (gems/projects) call
#   o3de_pal_dir(out_dir <dir> "${restricted_path}" "${object_path}" "${parent_relative_path}")
# The trailing args are ignored legacy parameters.
function(o3de_pal_dir out_dir in_dir)
    set(${out_dir} ${in_dir} PARENT_SCOPE)
endfunction()

#! o3de_pal_path_object_json: PAL path resolution scoped to an object.
# The object json argument is retained for signature compatibility.
# \arg:object_json_path - the object json file (unused)
# \arg:path_to_where_the_platform_file_should_be - requested path
# \arg:path_to_where_the_platform_file_really_is - output variable
function(o3de_pal_path_object_json object_json_path path_to_where_the_platform_file_should_be path_to_where_the_platform_file_really_is)
    set(${path_to_where_the_platform_file_really_is} ${path_to_where_the_platform_file_should_be} PARENT_SCOPE)
endfunction()
