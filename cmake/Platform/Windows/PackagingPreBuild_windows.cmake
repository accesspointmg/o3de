#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

file(REAL_PATH "${CPACK_SOURCE_DIR}/.." O3DE_ENGINE_PATH)
include(${O3DE_ENGINE_PATH}/cmake/Platform/Common/PackagingPreBuild_common.cmake)
include(${CPACK_CODESIGN_SCRIPT})

if(NOT CPACK_UPLOAD_URL) # Skip signing if we are not uploading the package
    return()
endif()

set(_cpack_wix_out_dir ${CPACK_TOPLEVEL_DIRECTORY})
o3de_sign_binaries("${_cpack_wix_out_dir}" "exePath")