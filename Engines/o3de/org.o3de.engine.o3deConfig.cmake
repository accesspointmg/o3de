#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(FindPackageHandleStandardArgs)
get_filename_component(engine_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_property(engine_name GLOBAL PROPERTY "O3DE_PATH_${engine_path}/engine.json_NAME")
get_property(engine_version GLOBAL PROPERTY "O3DE_PATH_${engine_path}/engine.json_VERSION")
find_package_handle_standard_args(${engine_name} REQUIRED_VARS engine_path engine_name VERSION_VAR engine_version)
