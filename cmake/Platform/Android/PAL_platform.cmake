#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# add pal platform mappings
o3de_add_pal_platform_mapping("android:Android")
o3de_add_pal_platform_wart_mapping("android:android")

o3de_set(O3DE_PLATFORM_DETECTION_Android Android)

if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL Darwin)
    o3de_set(O3DE_HOST_PLATFORM_DETECTION_Android Mac)
elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL Linux)
    # Linux supports multiple system architectures
    o3de_set(O3DE_HOST_PLATFORM_DETECTION_Android ${CMAKE_HOST_SYSTEM_NAME})
    o3de_set(O3DE_HOST_ARCHITECTURE_DETECTION_Android ${CMAKE_HOST_SYSTEM_PROCESSOR})
else()
    o3de_set(O3DE_HOST_PLATFORM_DETECTION_Android ${CMAKE_HOST_SYSTEM_NAME})
endif()