#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_COMPILE_OPTIONS
    PRIVATE
        -fexceptions # The macro PYBIND11_EMBEDDED_MODULE uses a try catch block
)

set(O3DE_COMPILE_DEFINITIONS 
    PRIVATE 
        PY_VERSION_MAJOR_MINOR="${O3DE_PYTHON_VERSION_MAJOR_MINOR}"
)
