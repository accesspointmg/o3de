#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Setup the Python global variables and download and associate python to the correct package

# Python package info
o3de_set(LY_PYTHON_VERSION 3.10.13)
o3de_set(LY_PYTHON_VERSION_MAJOR_MINOR 3.10)
o3de_set(LY_PYTHON_PACKAGE_NAME python-3.10.13-rev1-mac-arm64)
o3de_set(LY_PYTHON_PACKAGE_HASH 2d572bc5f6aac243051eea0e13544564d02d0af0dc1e78024d0136a5abf7a8ec)

# Python package relative paths
o3de_set(LY_PYTHON_BIN_PATH "Python.framework/Versions/Current/bin/")
o3de_set(LY_PYTHON_LIB_PATH "Python.framework/Versions/Current/lib")
o3de_set(LY_PYTHON_EXECUTABLE "python3")

# Python venv relative paths
o3de_set(LY_PYTHON_VENV_BIN_PATH "bin")
o3de_set(LY_PYTHON_VENV_LIB_PATH "lib")
o3de_set(LY_PYTHON_VENV_SITE_PACKAGES "${LY_PYTHON_VENV_LIB_PATH}/python3.10/site-packages")
o3de_set(LY_PYTHON_VENV_PYTHON "${LY_PYTHON_VENV_BIN_PATH}/python")

function(ly_post_python_venv_install venv_path)
    # Noop
endfunction()
