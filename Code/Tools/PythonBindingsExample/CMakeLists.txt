#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

o3de_add_target(
    NAME PythonBindingsExample.Static STATIC
    NAMESPACE AZ
    FILES_CMAKE
        pythonbindingsexample_files.cmake
    PLATFORM_INCLUDE_FILES
        source/Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/pythonbindingsexample_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
)

o3de_add_target(
    NAME PythonBindingsExample EXECUTABLE
    NAMESPACE AZ
    FILES_CMAKE
        pythonbindingsexample_app_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
            PythonBindingsExample.Static
)

# The PythonBindingsExample application isn't really an O3DE_PROJECT,
# It's target name is being used to tag the tool_dependencies
# This allows both the PythonBindingsExample and PythonBindingsExample.Tests applications
# to load the generated cmake_dependencies.PythonBindingsExample.PythonBindingsExample.setreg file
# which contains the list of gem dependencies
o3de_add_target_dependencies(
    TARGETS
        PythonBindingsExample
    DEPENDENCIES_FILES
        tool_dependencies.cmake
)

# Adds the PythonBindingsExample as a C preprocessor define so that it can be used as a Settings Registry
# specialization in order to look up the generated .setreg which contains the dependencies
# specified for the target
if(TARGET PythonBindingsExample)
    set_source_files_properties(
        source/main.cpp
        PROPERTIES
            COMPILE_DEFINITIONS
                O3DE_CMAKE_TARGET="PythonBindingsExample"
    )
else()
    message(FATAL_ERROR "Cannot set O3DE_CMAKE_TARGET define to PythonBindingsExample as the target doesn't exist anymore."
        " Perhaps it has been renamed")
endif()

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME PythonBindingsExample.Tests EXECUTABLE
        NAMESPACE AZ
        FILES_CMAKE
            pythonbindingsexample_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzCore
                AZ::AzFramework
                AZ::AzTest
                AZ::AzToolsFramework
                PythonBindingsExample.Static
    )

    o3de_add_target_dependencies(
        TARGETS
            PythonBindingsExample.Tests
        DEPENDENCIES_FILES
            tool_dependencies.cmake
    )

    if(TARGET PythonBindingsExample)
        set_source_files_properties(
            tests/ApplicationTests.cpp
            PROPERTIES
                COMPILE_DEFINITIONS
                    # The PythonBindingsExample target is being defined here to allow the PythonBindingsExample.Tests executable
                    # to load the specializations which contains the "PythonBindingsExample" value'
                    O3DE_CMAKE_TARGET="PythonBindingsExample"
        )
    else()
        message(FATAL_ERROR "Cannot set O3DE_CMAKE_TARGET define to PythonBindingsExample as the target doesn't exist anymore."
            " Perhaps it has been renamed")
    endif()

    o3de_add_googletest(
        NAME AZ::PythonBindingsExample.Tests
        LABELS REQUIRES_tiaf
        TEST_COMMAND $<TARGET_FILE:AZ::PythonBindingsExample.Tests> --unittest
    )
endif()
