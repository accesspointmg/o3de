#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/TestImpactFramework/Runtime/Common/Code/Source/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_testimpactframework_runtime_common_code_path)
set(common_code_tools_testimpactframework_runtime_common_code_path ${O3DE_ENGINE_PATH}/Code/Tools/TestImpactFramework/Runtime/Common/Code/Source/Platform/Common)

o3de_add_target(
    NAME TestImpact.Runtime.Common.Headers HEADERONLY
    NAMESPACE AZ
    FILES_CMAKE
        testimpactframework_runtime_common_headers_files.cmake
    INCLUDE_DIRECTORIES
        INTERFACE
            Include/Headers
    BUILD_DEPENDENCIES
        INTERFACE
            AZ::AzCore
)

o3de_add_target(
    NAME TestImpact.Runtime.Common.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        testimpactframework_runtime_common_files.cmake
        ${pal_code_tools_testimpactframework_runtime_common_code_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${common_code_tools_testimpactframework_runtime_common_code_path}/${O3DE_PAL_TRAIT_COMPILER_ID}/testimpactframework_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include/Static
    BUILD_DEPENDENCIES
        PUBLIC
            TestImpact.Runtime.Common.Headers
)
