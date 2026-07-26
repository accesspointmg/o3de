#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_Windows_RuntimeDependencies_windows_cmake ${CMAKE_CURRENT_LIST_DIR})
set(O3DE_RUNTIME_DEPENDENCIES_TEMPLATE ${O3DE_ENGINE_PATH}/cmake/Platform/Common/runtime_dependencies_common.cmake.in)
include(${_cmake_Platform_Windows_RuntimeDependencies_windows_cmake}/../Common/RuntimeDependencies_common.cmake)