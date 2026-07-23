#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_add_target(
    NAME PhysX.NumericalMethods STATIC
    NAMESPACE Gem
    FILES_CMAKE
        numericalmethods_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
        PUBLIC
            Include
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME PhysX.NumericalMethods.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE Gem
        FILES_CMAKE
            numericalmethods_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
                Source
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzTest
                Gem::PhysX.NumericalMethods
                AZ::AzFramework
    )
    o3de_add_googletest(
        NAME Gem::PhysX.NumericalMethods.Tests
        LABELS REQUIRES_tiaf
    )
endif()
