#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(FindPackageHandleStandardArgs)
get_filename_component(gem_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_property(gem_name GLOBAL PROPERTY "O3DE_PATH_${gem_path}/gem.json_NAME")
get_property(gem_version GLOBAL PROPERTY "O3DE_PATH_${gem_path}/gem.json_VERSION")
find_package_handle_standard_args(${gem_name} REQUIRED_VARS gem_path gem_name VERSION_VAR gem_version)
