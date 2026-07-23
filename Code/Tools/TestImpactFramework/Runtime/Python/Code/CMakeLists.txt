#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

#o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/TestImpactFramework/Runtime/Python/Code/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_testimpactframework_runtime_python_code_path)
set(common_code_tools_testimpactframework_runtime_python_code_path ${O3DE_ENGINE_PATH}/Code/Tools/TestImpactFramework/Runtime/Python/Code/Source/Platform/Common)

o3de_add_target(
    NAME TestImpact.Runtime.Python.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        testimpactframework_runtime_python_files.cmake
    PLATFORM_INCLUDE_FILES
        ${common_code_tools_testimpactframework_runtime_python_code_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/testimpactframework_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
        PRIVATE
            Source
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::TestImpact.Runtime.Common.Static
        PUBLIC
            AZ::AzCore
            AZ::TestImpact.Runtime.Common.Headers
)
