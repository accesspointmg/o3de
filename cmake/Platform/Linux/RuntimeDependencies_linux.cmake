#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_Linux_RuntimeDependencies_linux_cmake ${CMAKE_CURRENT_LIST_DIR})
set(O3DE_RUNTIME_DEPENDENCIES_TEMPLATE ${O3DE_ENGINE_PATH}/cmake/Platform/Linux/runtime_dependencies_linux.cmake.in)
include(${_cmake_Platform_Linux_RuntimeDependencies_linux_cmake}/../Common/RuntimeDependencies_common.cmake)