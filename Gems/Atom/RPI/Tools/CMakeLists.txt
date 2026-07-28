#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if (O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    o3de_pip_install_local_package_editable(${CMAKE_CURRENT_LIST_DIR} atom_rpi_tools)

    if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        o3de_add_pytest(
            NAME RPI::atom_rpi_tools_tests
            PATH ${CMAKE_CURRENT_LIST_DIR}/atom_rpi_tools/tests/
            TIMEOUT 30
            LABELS REQUIRES_tiaf
        )
    endif()
endif()

o3de_install_directory(DIRECTORIES .
    EXCLUDE_PATTERNS tests
)
