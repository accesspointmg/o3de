/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */

#include <stdint.h>
#include <AzCore/PlatformId/PlatformId.h>
#include <AzCore/Debug/Trace.h>

namespace AZ
{
    const char* GetPlatformName(PlatformID platform)
    {
        switch (platform)
        {
        case PlatformID::PLATFORM_WINDOWS_64:
            return "Win64";
        case PlatformID::PLATFORM_LINUX_64:
            return "Linux";
        case PlatformID::PLATFORM_ANDROID_64:
            return "Android64";
        case PlatformID::PLATFORM_APPLE_IOS:
            return "iOS";
        case PlatformID::PLATFORM_APPLE_MAC:
            return "Mac";
        case PlatformID::PLATFORM_EMSCRIPTEN:
            return "Emscripten";
        default:
            AZ_Assert(false, "Platform %u is unknown.", static_cast<uint32_t>(platform));
            return "";
        }
    }

} // namespace AZ

#include <AzCore/PlatformId/PlatformId_Platform.h>
