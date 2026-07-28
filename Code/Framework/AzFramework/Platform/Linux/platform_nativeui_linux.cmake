#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Based on the linux window manager trait, perform the appropriate additional build configurations
# Only 'xcb' and 'wayland' are recognized
if (${O3DE_PAL_TRAIT_LINUX_WINDOW_MANAGER} STREQUAL "xcb")

    set(O3DE_COMPILE_DEFINITIONS PUBLIC O3DE_PAL_TRAIT_LINUX_WINDOW_MANAGER_XCB)
    set(O3DE_INCLUDE_DIRECTORIES
        PUBLIC
            Platform/Common/Xcb
    )
    set(O3DE_FILES_CMAKE
        Platform/Common/Xcb/azframework_xcb_files.cmake
    )
    set(O3DE_BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::X11::xcb
            3rdParty::X11::xcb_xkb
            3rdParty::X11::xcb_xfixes
            3rdParty::X11::xkbcommon
            3rdParty::X11::xkbcommon_X11
            xcb-xinput
    )

elseif(O3DE_PAL_TRAIT_LINUX_WINDOW_MANAGER STREQUAL "wayland")

    set(O3DE_COMPILE_DEFINITIONS PUBLIC O3DE_PAL_TRAIT_LINUX_WINDOW_MANAGER_WAYLAND)

else()

    message(FATAL_ERROR, "Linux Window Manager ${O3DE_PAL_TRAIT_LINUX_WINDOW_MANAGER} is not recognized")

endif()
