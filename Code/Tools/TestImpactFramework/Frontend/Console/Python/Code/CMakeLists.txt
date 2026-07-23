#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(O3DE_MONOLITHIC_GAME)
    return()
endif()

set(common_dir ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

o3de_add_target(
    NAME TestImpact.Frontend.Console.Python.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        testimpactframework_frontend_console_python_static_files.cmake
    PLATFORM_INCLUDE_FILES
        ${common_dir}/${O3DE_PAL_TRAIT_COMPILER_ID}/testimpactframework_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
        PRIVATE
            Source
    COMPILE_DEFINITIONS
        PRIVATE
            ${O3DE_TEST_IMPACT_CONFIG_FILE_PATH_DEFINITION}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::TestImpact.Frontend.Console.Common.Static
            AZ::TestImpact.Runtime.Python.Static
        PUBLIC
            AZ::TestImpact.Frontend.Console.Common.Headers
)

o3de_add_target(
    NAME TestImpact.Frontend.Console.Python EXECUTABLE
    OUTPUT_NAME tiaf_python
    NAMESPACE AZ
    FILES_CMAKE
        testimpactframework_frontend_console_python_files.cmake
    PLATFORM_INCLUDE_FILES
        ${common_dir}/${O3DE_PAL_TRAIT_COMPILER_ID}/testimpactframework_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::TestImpact.Frontend.Console.Python.Static
)
