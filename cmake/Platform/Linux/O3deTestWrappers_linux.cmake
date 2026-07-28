#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(${o3de_add_test_TEST_LIBRARY} MATCHES "google(test|benchmark)" )
    o3de_set(O3DE_PAL_TEST_COMMAND_ARGS --platform minimal)
endif()