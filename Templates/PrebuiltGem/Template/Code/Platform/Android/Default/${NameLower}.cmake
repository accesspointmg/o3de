#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

get_property(${NameLower}_gem_root GLOBAL PROPERTY "@GEMROOT:${Name}@")
list(APPEND O3DE_TARGET_PROPERTIES
    IMPORTED_LOCATION ${${NameLower}_gem_root}/bin/${O3DE_PAL_PLATFORM_NAME}/${O3DE_BUILD_PERMUTATION}/release/lib${Name}.so
    IMPORTED_LOCATION_DEBUG ${${NameLower}_gem_root}/bin/${O3DE_PAL_PLATFORM_NAME}/${O3DE_BUILD_PERMUTATION}/debug/lib${Name}.so
)
