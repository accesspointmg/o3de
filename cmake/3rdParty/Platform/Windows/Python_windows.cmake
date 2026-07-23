#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Setup the Python global variables and download and associate python to the correct package

# Python package info
o3de_set(O3DE_PYTHON_VERSION 3.10.13)
o3de_set(O3DE_PYTHON_VERSION_MAJOR_MINOR 3.10)
o3de_set(O3DE_PYTHON_PACKAGE_NAME python-3.10.13-rev1-windows)
o3de_set(O3DE_PYTHON_PACKAGE_HASH a6f1fd50552c8780852b75186a97469f77d55d06a01de73e5ca601e4a12be232)

# Python package relative paths
o3de_set(O3DE_PYTHON_BIN_PATH "python")
o3de_set(O3DE_PYTHON_LIB_PATH "Lib")
o3de_set(O3DE_PYTHON_EXECUTABLE "python.exe")

# Python venv relative paths
o3de_set(O3DE_PYTHON_VENV_BIN_PATH "Scripts")
o3de_set(O3DE_PYTHON_VENV_LIB_PATH "Lib")
o3de_set(O3DE_PYTHON_VENV_SITE_PACKAGES "${O3DE_PYTHON_VENV_LIB_PATH}/site-packages")
o3de_set(O3DE_PYTHON_VENV_PYTHON "${O3DE_PYTHON_VENV_BIN_PATH}/python.exe")

function(o3de_post_python_venv_install venv_path)
    # Noop
endfunction()
