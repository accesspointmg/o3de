#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
set(_cmake_Platform_Windows_PAL_windows_cmake ${CMAKE_CURRENT_LIST_DIR})
include(${_cmake_Platform_Windows_PAL_windows_cmake}/../../CompilerSettings.cmake)

o3de_set(O3DE_PAL_EXECUTABLE_APPLICATION_FLAG WIN32)
o3de_set(O3DE_PAL_LINKOPTION_MODULE MODULE)

o3de_set(O3DE_PAL_TRAIT_BUILD_HOST_GUI_TOOLS TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_SERVER_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_UNIFIED_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_UNITY_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_UNITY_EXCLUDE_EXTENSIONS)
o3de_set(O3DE_PAL_TRAIT_BUILD_EXCLUDE_ALL_TEST_RUNS_FROM_IDE FALSE)
o3de_set(O3DE_PAL_TRAIT_BUILD_CPACK_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED FALSE)

o3de_set(O3DE_PAL_TRAIT_PROF_PIX_SUPPORTED TRUE)

# Determine if tests are supported based on the O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED_DEFAULT global property
get_property(is_test_supported_default_set GLOBAL PROPERTY O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED_DEFAULT SET)
if (is_test_supported_default_set)
    get_property(test_supported_default GLOBAL PROPERTY O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED_DEFAULT)
    o3de_set(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED ${test_supported_default})
else()
    o3de_set(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED TRUE)
endif()

# Test library support
o3de_set(O3DE_PAL_TRAIT_TEST_GOOGLE_TEST_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_TEST_GOOGLE_BENCHMARK_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_TEST_O3DETESTTOOLS_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_TEST_PYTEST_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_TEST_TARGET_TYPE MODULE)

if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    o3de_set(O3DE_PAL_TRAIT_COMPILER_ID MSVC)
    o3de_set(O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE msvc)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    o3de_set(O3DE_PAL_TRAIT_COMPILER_ID Clang)
    o3de_set(O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE clang)
else()
    message(FATAL_ERROR "Compiler ${CMAKE_CXX_COMPILER_ID} not supported in ${O3DE_PAL_PLATFORM_NAME}")
endif()

# Set the default asset type for deployment
set(O3DE_ASSET_DEPLOY_ASSET_TYPE "pc" CACHE STRING "Set the asset type for deployment.")

# Set the python cmd tool
o3de_set(O3DE_PYTHON_CMD ${O3DE_ENGINE_PATH}/python/python.cmd)

# Compiler flag to export all symbols from a library
# On Windows this is done directly with the WINDOWS_EXPORT_ALL_SYMBOLS cmake option instead
o3de_set(O3DE_PAL_TRAIT_EXPORT_ALL_SYMBOLS_COMPILE_OPTIONS)
