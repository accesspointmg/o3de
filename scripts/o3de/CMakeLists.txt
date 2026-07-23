#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

add_subdirectory(tests)

o3de_pal_dir(pal_dir ${CMAKE_CURRENT_LIST_DIR}/Platform/${O3DE_PAL_PLATFORM_NAME} ${O3DE_ENGINE_RESTRICTED_PATH} ${O3DE_ENGINE_PATH})
include(${pal_dir}/o3de_install_${O3DE_PAL_PLATFORM_WART}.cmake)

o3de_install_files(FILES ../o3de.py 
    DESTINATION scripts
)

o3de_install_files(FILES setup.py PROGRAMS
    DESTINATION scripts/o3de
)
o3de_install_files(FILES README.txt
    DESTINATION scripts/o3de
)

o3de_install_directory(
    DIRECTORIES
        o3de.egg-info
    VERBATIM
)

o3de_install_directory(DIRECTORIES .
    EXCLUDE_PATTERNS
        tests
        Platform
)
