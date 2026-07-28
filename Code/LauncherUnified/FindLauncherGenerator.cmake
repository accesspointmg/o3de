#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_dir ${O3DE_ENGINE_PATH}/LauncherGenerator/Platform/${O3DE_PAL_PLATFORM_NAME})
include(${pal_dir}/LauncherUnified_traits_${O3DE_PAL_PLATFORM_WART}.cmake)
include(${O3DE_ENGINE_PATH}/LauncherGenerator/launcher_generator.cmake)
