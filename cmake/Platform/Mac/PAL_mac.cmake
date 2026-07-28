#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_set(O3DE_PAL_EXECUTABLE_APPLICATION_FLAG MACOSX_BUNDLE)
o3de_set(O3DE_PAL_LINKOPTION_MODULE MODULE)

o3de_set(O3DE_PAL_TRAIT_BUILD_HOST_GUI_TOOLS TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_SERVER_SUPPORTED FALSE)
o3de_set(O3DE_PAL_TRAIT_BUILD_UNIFIED_SUPPORTED FALSE)
o3de_set(O3DE_PAL_TRAIT_BUILD_UNITY_SUPPORTED TRUE)
o3de_set(O3DE_PAL_TRAIT_BUILD_UNITY_EXCLUDE_EXTENSIONS ".mm")
o3de_set(O3DE_PAL_TRAIT_BUILD_EXCLUDE_ALL_TEST_RUNS_FROM_IDE FALSE)
o3de_set(O3DE_PAL_TRAIT_BUILD_CPACK_SUPPORTED FALSE)

o3de_set(O3DE_PAL_TRAIT_PROF_PIX_SUPPORTED FALSE)

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
o3de_set(O3DE_PAL_TRAIT_TEST_PYTEST_SUPPORTED FALSE)
o3de_set(O3DE_PAL_TRAIT_TEST_TARGET_TYPE MODULE)

if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    o3de_set(O3DE_PAL_TRAIT_COMPILER_ID Clang)
    o3de_set(O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE clang)
else()
    message(FATAL_ERROR "Compiler ${CMAKE_CXX_COMPILER_ID} not supported in ${O3DE_PAL_PLATFORM_NAME}")
endif()

# Set the default asset type for deployment
set(O3DE_ASSET_DEPLOY_ASSET_TYPE "mac" CACHE STRING "Set the asset type for deployment.")

# Set the deployment target for Mac
set(O3DE_MAC_DEPLOYMENT_TARGET "11.0" CACHE STRING "Mac Deployment Target")
set(CMAKE_OSX_DEPLOYMENT_TARGET ${O3DE_MAC_DEPLOYMENT_TARGET})

# Set the python cmd tool
o3de_set(O3DE_PYTHON_CMD ${CMAKE_CURRENT_SOURCE_DIR}/python/python.sh)

# Compiler flag to export all symbols from a library
o3de_set(O3DE_PAL_TRAIT_EXPORT_ALL_SYMBOLS_COMPILE_OPTIONS -fvisibility=default)

# Only x86_64 is currently supported on Mac
o3de_set(CMAKE_OSX_ARCHITECTURES "x86_64")
