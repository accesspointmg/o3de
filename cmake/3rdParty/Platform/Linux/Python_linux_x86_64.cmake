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
o3de_set(O3DE_PYTHON_PACKAGE_NAME python-3.10.13-rev2-linux)
o3de_set(O3DE_PYTHON_PACKAGE_HASH a7832f9170a3ac93fbe678e9b3d99a977daa03bb667d25885967e8b4977b86f8)

# Python package relative paths
o3de_set(O3DE_PYTHON_BIN_PATH "python/bin")
o3de_set(O3DE_PYTHON_LIB_PATH "python/lib")
o3de_set(O3DE_PYTHON_EXECUTABLE "python")
o3de_set(O3DE_PYTHON_SHARED_LIB "libpython3.10.so.1.0")

# Python venv relative paths
o3de_set(O3DE_PYTHON_VENV_BIN_PATH "bin")
o3de_set(O3DE_PYTHON_VENV_LIB_PATH "lib")
o3de_set(O3DE_PYTHON_VENV_SITE_PACKAGES "${O3DE_PYTHON_VENV_LIB_PATH}/python3.10/site-packages")
o3de_set(O3DE_PYTHON_VENV_PYTHON "${O3DE_PYTHON_VENV_BIN_PATH}/python")

function(o3de_post_python_venv_install venv_path)

    # We need to create a symlink to the shared library in the venv
    execute_process(COMMAND ln -s -f "${PYTHON_PACKAGES_ROOT_PATH}/${O3DE_PYTHON_PACKAGE_NAME}/${O3DE_PYTHON_LIB_PATH}/${O3DE_PYTHON_SHARED_LIB}" ${O3DE_PYTHON_SHARED_LIB}
                    WORKING_DIRECTORY "${PYTHON_VENV_PATH}/${O3DE_PYTHON_VENV_LIB_PATH}"
                    RESULT_VARIABLE command_result)
    if (NOT ${command_result} EQUAL 0)
        message(WARNING "Unable to create a venv shared library link.")
    endif()

endfunction()
