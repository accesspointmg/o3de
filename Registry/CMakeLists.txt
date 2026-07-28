#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(O3DE_MONOLITHIC_GAME)
    return()
endif()

o3de_install_directory(DIRECTORIES .)

foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER ${conf} UCONF)
    string(REPLACE "$<CONFIG>" "${conf}" output ${runtime_output_directory})
    o3de_install_directory(DIRECTORIES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${conf}/Registry
        DESTINATION ${output}
        COMPONENT ${O3DE_INSTALL_PERMUTATION_COMPONENT}_${UCONF}
    )
endforeach()
