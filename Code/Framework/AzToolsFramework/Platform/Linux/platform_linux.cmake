#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_COMPILE_DEFINITIONS 
    PRIVATE 
        IMPLICIT_LOAD_PYTHON_SHARED_LIBRARY="${O3DE_PYTHON_SHARED_LIB}"
        AZ_TRAIT_PYTHON_LOADER_PYTHON_HOME_BIN_SUBPATH
)
