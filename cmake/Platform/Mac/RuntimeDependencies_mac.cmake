#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_Mac_RuntimeDependencies_mac_cmake ${CMAKE_CURRENT_LIST_DIR})
set(O3DE_BUILD_FIXUP_BUNDLE TRUE CACHE BOOL "Fix bundles on build (deploys frameworks and calls fixup_bundle)")

set(O3DE_RUNTIME_DEPENDENCIES_TEMPLATE ${O3DE_ENGINE_PATH}/cmake/Platform/Mac/runtime_dependencies_mac.cmake.in)
include(${_cmake_Platform_Mac_RuntimeDependencies_mac_cmake}/../Common/RuntimeDependencies_common.cmake)