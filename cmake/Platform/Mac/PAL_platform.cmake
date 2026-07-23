#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
o3de_add_pal_platform_mapping("mac:Darwin")

o3de_add_pal_platform_wart_mapping("darwin:mac")

o3de_set(O3DE_PLATFORM_DETECTION_Darwin Mac)
o3de_set(O3DE_HOST_PLATFORM_DETECTION_Darwin Mac)

# Mac supports multiple system architectures
o3de_set(O3DE_ARCHITECTURE_DETECTION_Darwin ${CMAKE_SYSTEM_PROCESSOR})
o3de_set(O3DE_HOST_ARCHITECTURE_DETECTION_Darwin ${CMAKE_HOST_SYSTEM_PROCESSOR})