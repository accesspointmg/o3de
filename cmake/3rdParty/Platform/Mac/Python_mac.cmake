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
o3de_set(O3DE_PYTHON_PACKAGE_NAME python-3.10.13-rev1-darwin)
o3de_set(O3DE_PYTHON_PACKAGE_HASH 14a88370fa8673344cf51354ce1a1021a0a1fb1742d774b5a0033a94e3384ec1)

# Python package relative paths
o3de_set(O3DE_PYTHON_BIN_PATH "Python.framework/Versions/Current/bin/")
o3de_set(O3DE_PYTHON_LIB_PATH "Python.framework/Versions/Current/lib")
o3de_set(O3DE_PYTHON_EXECUTABLE "python3")

# Python venv relative paths
o3de_set(O3DE_PYTHON_VENV_BIN_PATH "bin")
o3de_set(O3DE_PYTHON_VENV_LIB_PATH "lib")
o3de_set(O3DE_PYTHON_VENV_SITE_PACKAGES "${O3DE_PYTHON_VENV_LIB_PATH}/python3.10/site-packages")
o3de_set(O3DE_PYTHON_VENV_PYTHON "${O3DE_PYTHON_VENV_BIN_PATH}/python")

function(o3de_post_python_venv_install venv_path)
    # Noop
endfunction()
