#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(FindPackageHandleStandardArgs)
get_filename_component(project_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_property(project_name GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_NAME")
get_property(project_version GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_VERSION")
find_package_handle_standard_args(${project_name} REQUIRED_VARS project_path project_name VERSION_VAR project_version)
