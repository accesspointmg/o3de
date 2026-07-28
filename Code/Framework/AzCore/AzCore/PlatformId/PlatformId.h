/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */
#pragma once

#include <stdint.h>
#include <AzCore/base.h>

namespace AZ
{
    /**
     * Enum of supported platforms. Just for user convenience.
     */
    enum class PlatformID
    {
        PLATFORM_WINDOWS_64,
        PLATFORM_LINUX_64,
        PLATFORM_APPLE_IOS,
        PLATFORM_APPLE_MAC,
        PLATFORM_ANDROID_64,    // ARMv8 / 64-bit
        PLATFORM_EMSCRIPTEN,    // WebAssembly
        // Add new platforms here

        PLATFORM_MAX  ///< Must be last
    };

    inline bool IsBigEndian(PlatformID /*id*/)
    {
        return false;
    }

    AZCORE_API const char* GetPlatformName(PlatformID platform);
} // namespace AZ

#include <AzCore/PlatformId/PlatformId_Platform.h>
