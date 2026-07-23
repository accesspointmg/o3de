#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include_guard()

# O3DE_GOOGLETEST_EXTRA_PARAMS to append additional
# google test parameters to every google test invocation.
set(O3DE_GOOGLETEST_EXTRA_PARAMS CACHE STRING "Allows injection of additional options to be passed to all google test commands")

# Note pytest does not need the above because it natively has PYTEST_ADDOPTS environment
# variable support.

find_package(Python REQUIRED MODULE)

o3de_set(O3DE_PYTEST_EXECUTABLE ${O3DE_PYTHON_CMD} -B -m pytest -v --tb=short --show-capture=stdout -c ${O3DE_ENGINE_PATH}/pytest.ini --build-directory "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<CONFIG>")
o3de_set(O3DE_TEST_GLOBAL_KNOWN_SUITE_NAMES "smoke" "main" "periodic" "benchmark" "sandbox" "awsi")
o3de_set(O3DE_TEST_GLOBAL_KNOWN_REQUIREMENTS "gpu")

# Set default test aborts to 25 minutes, avoids hitting the CI pipeline inactivity timeout usually set to 30 minutes
o3de_set(O3DE_TEST_DEFAULT_TIMEOUT 1500)

# Add the CMake Test targets for each suite if testing is supported
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_suite_build_and_run_targets(${O3DE_TEST_GLOBAL_KNOWN_SUITE_NAMES})
endif()

# Set and create folders for PyTest and GTest xml output
o3de_set(PYTEST_XML_OUTPUT_DIR ${CMAKE_BINARY_DIR}/Testing/Pytest)
o3de_set(GTEST_XML_OUTPUT_DIR ${CMAKE_BINARY_DIR}/Testing/Gtest)
o3de_set(O3DETESTTOOLS_OUTPUT_DIR ${CMAKE_BINARY_DIR}/Testing/O3deTestTools)
file(MAKE_DIRECTORY ${PYTEST_XML_OUTPUT_DIR})
file(MAKE_DIRECTORY ${GTEST_XML_OUTPUT_DIR})

#! o3de_check_valid_test_suites: internal helper to check for errors in test suites
function(o3de_check_valid_test_suite suite_name)
    if(NOT ${suite_name} IN_LIST O3DE_TEST_GLOBAL_KNOWN_SUITE_NAMES)
        message(SEND_ERROR "Invalid test suite name ${suite_name} in ${CMAKE_CURRENT_LIST_FILE}, it can only be one of the following: ${O3DE_TEST_GLOBAL_KNOWN_SUITE_NAMES} or unspecified.")
    endif()
endfunction()

#! o3de_check_valid_test_requires: internal helper to check for errors in test requirements
function(o3de_check_valid_test_requires)
    foreach(name_check ${ARGV})
        if(NOT ${name_check} IN_LIST O3DE_TEST_GLOBAL_KNOWN_REQUIREMENTS)
           message(SEND_ERROR "Invalid test requirement name ${name_check} in ${CMAKE_CURRENT_LIST_FILE}, it can only be one of the following: ${O3DE_TEST_GLOBAL_KNOWN_REQUIREMENTS} or unspecified")
        endif()
    endforeach()
endfunction()

#! o3de_strip_target_namespace: Strips all "::" namespaces from target
# \arg: TARGET - Target to remove namespace prefixes
# \arg: OUTPUT_VARIABLE  - Variable which will be set to output containing the stripped target
function(o3de_strip_target_namespace)
    set(one_value_args TARGET OUTPUT_VARIABLE)
    cmake_parse_arguments(o3de_strip_target_namespace "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    if(NOT o3de_strip_target_namespace_OUTPUT_VARIABLE)
        message(SEND_ERROR "Output variable must be supplied to ${CMAKE_CURRENT_FUNCTION}")
    endif()
    string(REPLACE "::" ";" qualified_name_list ${o3de_strip_target_namespace_TARGET})
    list(POP_BACK qualified_name_list stripped_target)
    set(${o3de_strip_target_namespace_OUTPUT_VARIABLE} ${stripped_target} PARENT_SCOPE)
endfunction()

#! o3de_add_test: Adds a new RUN_TEST for the specified target using the supplied command
#
# \arg:NAME - Name of the test run target
# \arg:PARENT_NAME(optional) - Name of the parent test run target (if this is a subsequent call to specify a suite)
# \arg:TEST_REQUIRES(optional) - List of system resources that are required to run this test.
#      Only available option is "gpu"
# \arg:TEST_SUITE(optional) - "smoke" or "periodic" or "benchmark" or "sandbox" or "awsi" - prevents the test from running normally
#      and instead places it in a special suite of tests that only run when requested.
#      Otherwise, do not specify a TEST_SUITE value and the default ("main") will apply.
#      "smoke" is tiny, quick tests of fundamental operation (tests with no suite marker will also execute here in CI)
#      "periodic" is low-priority verification, which should not block code submission
#      "benchmark" is currently reserved for Google Benchmarks
#      "sandbox" should be only be used for the workflow of flaky tests
#      "awsi" Time consuming AWS integration end-to-end tests
# \arg:TIMEOUT (optional) The timeout in seconds for the module. Defaults to O3DE_TEST_DEFAULT_TIMEOUT.
# \arg:TEST_COMMAND - Command which runs the tests. It is a required argument
# \arg:NON_IDE_PARAMS - extra params that will be run in ctest, but will not be used in the IDE.
#                       This exists because there is only one IDE "target" (dll or executable)
#                       but many potential tests which invoke it with different filters (suites).
#                       Those params which vary per CTest are stored in this parameter
#                       and do not appy to the "launch options" for the IDE target.
# \arg:RUNTIME_DEPENDENCIES (optional) - List of additional runtime dependencies required by this test.
# \arg:COMPONENT (optional) - Scope of the feature area that the test belongs to (eg. physics, graphics, etc.).
# \arg:LABELS (optional) - Additional labels to apply to the test target which can be used by ctest filters.
# \arg:EXCLUDE_TEST_RUN_TARGET_FROM_IDE(bool) - If set the test run target will be not be shown in the IDE
# \arg:TEST_LIBRARY(internal) - Internal variable that contains the library be used. This is only to be used by the other
#      o3de_add_* function below, not by user code
# sets O3DE_ADDED_TEST_NAME to the fully qualified name of the test, in parent scope
function(o3de_add_test)
    if(NOT O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        return()
    endif()

    set(options EXCLUDE_TEST_RUN_TARGET_FROM_IDE)
    set(one_value_args NAME PARENT_NAME TEST_LIBRARY TEST_SUITE TIMEOUT)
    set(multi_value_args TEST_REQUIRES TEST_COMMAND NON_IDE_PARAMS RUNTIME_DEPENDENCIES COMPONENT LABELS)
    # note that we dont use TEST_LIBRARY here, but PAL files might so do not remove!

    cmake_parse_arguments(o3de_add_test "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    if (o3de_add_test_UNPARSED_ARGUMENTS)
        message(SEND_ERROR "Invalid arguments passed to o3de_add_test: ${o3de_add_test_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT o3de_add_test_NAME)
        message(FATAL_ERROR "You must provide a name for the target")
    endif()

    if(NOT o3de_add_test_TEST_SUITE)
        set(o3de_add_test_TEST_SUITE "main")
    endif()

    # Set default test module timeout
    if(NOT o3de_add_test_TIMEOUT)
        set(o3de_add_test_TIMEOUT ${O3DE_TEST_DEFAULT_TIMEOUT})
    elseif(o3de_add_test_TIMEOUT GREATER O3DE_TEST_DEFAULT_TIMEOUT)
        message(FATAL_ERROR "TIMEOUT for test ${o3de_add_test_NAME} set at ${o3de_add_test_TIMEOUT} seconds which is longer than the default of ${O3DE_TEST_DEFAULT_TIMEOUT}. Allowing a single module to run exceedingly long creates problems in a CI pipeline.")
    endif()

    if(NOT o3de_add_test_TEST_COMMAND)
        message(FATAL_ERROR "TEST_COMMAND arguments must be supplied in order to run test")
    endif()

    # Treat supplied TEST_COMMAND argument as a list. The first element is used as the test command
    list(POP_FRONT o3de_add_test_TEST_COMMAND test_command)
    # The remaining elements are treated as arguments to the command
    set(test_arguments ${o3de_add_test_TEST_COMMAND})

    # Check that the supplied test suites and test requires are from the choices we provide
    o3de_check_valid_test_requires(${o3de_add_test_TEST_REQUIRES})
    o3de_check_valid_test_suite(${o3de_add_test_TEST_SUITE})

    set(qualified_test_run_name_with_suite "${o3de_add_test_NAME}.${o3de_add_test_TEST_SUITE}")

    # Retrieves platform specific arguments that is used for adding arguments to the test
    set(O3DE_PAL_TEST_COMMAND_ARGS)

    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/O3deTestWrappers_${O3DE_PAL_PLATFORM_WART}.cmake)

    add_test(
        NAME ${qualified_test_run_name_with_suite}::TEST_RUN
        COMMAND ${test_command} ${test_arguments} ${o3de_add_test_NON_IDE_PARAMS} ${O3DE_PAL_TEST_COMMAND_ARGS}
    )

    set(O3DE_ADDED_TEST_NAME ${qualified_test_run_name_with_suite}::TEST_RUN)
    set(O3DE_ADDED_TEST_NAME ${O3DE_ADDED_TEST_NAME} PARENT_SCOPE)

    set(final_labels SUITE_${o3de_add_test_TEST_SUITE})

    if (o3de_add_test_TEST_REQUIRES)
        list(TRANSFORM o3de_add_test_TEST_REQUIRES PREPEND "REQUIRES_" OUTPUT_VARIABLE prepended_list)
        list(APPEND final_labels ${prepended_list})

        # Workaround so we can filter "AND" of labels until https://gitlab.kitware.com/cmake/cmake/-/issues/21087 is fixed
        list(TRANSFORM prepended_list PREPEND "SUITE_${o3de_add_test_TEST_SUITE}_" OUTPUT_VARIABLE prepended_list)
        list(APPEND final_labels ${prepended_list})
    endif()

    if (o3de_add_test_COMPONENT)
        list(TRANSFORM o3de_add_test_COMPONENT PREPEND "COMPONENT_" OUTPUT_VARIABLE prepended_component_list)
        list(APPEND final_labels ${prepended_component_list})
    endif()

    if (o3de_add_test_LABELS)
        list(APPEND final_labels ${o3de_add_test_LABELS})
    endif()

    # Allow TIAF to apply the label of supported test categories from being run by CTest 
    o3de_test_impact_apply_test_labels(${o3de_add_test_TEST_LIBRARY} final_labels)

    # labels expects a single param, of concatenated labels
    # this always has a value because o3de_add_test_TEST_SUITE is automatically
    # filled in to be "main" if not specified.
    set_tests_properties(${O3DE_ADDED_TEST_NAME}
        PROPERTIES
            LABELS "${final_labels}"
            TIMEOUT ${o3de_add_test_TIMEOUT}
    )

    # o3de_add_test_NAME could be an alias, we need the actual un-aliased target
    set(unaliased_test_name ${o3de_add_test_NAME})
    if(TARGET ${o3de_add_test_NAME})
        get_target_property(alias ${o3de_add_test_NAME} ALIASED_TARGET)
        if(alias)
            set(unaliased_test_name ${alias})
        endif()
    endif()

    if(NOT o3de_add_test_EXCLUDE_TEST_RUN_TARGET_FROM_IDE AND NOT O3DE_PAL_TRAIT_BUILD_EXCLUDE_ALL_TEST_RUNS_FROM_IDE)

        list(JOIN test_arguments " " test_arguments_line)

        if(TARGET ${unaliased_test_name})

            # In this case we already have a target, we inject the debugging parameters for the target directly
            set_target_properties(${unaliased_test_name} PROPERTIES
                VS_DEBUGGER_COMMAND ${test_command}
                VS_DEBUGGER_COMMAND_ARGUMENTS "${test_arguments_line}"
            )

        else()

            # Adds a custom target for the test run
            # The true command is used to add a target-level dependency on the test command
            o3de_strip_target_namespace(TARGET ${unaliased_test_name} OUTPUT_VARIABLE unaliased_test_name)
            add_custom_target(${unaliased_test_name} COMMAND ${CMAKE_COMMAND} -E true ${args_TEST_COMMAND} ${args_TEST_ARGUMENTS})

            file(RELATIVE_PATH project_path ${O3DE_ENGINE_PATH} ${CMAKE_CURRENT_SOURCE_DIR})
            set(ide_path ${project_path})
            # Visual Studio doesn't support a folder layout that starts with ".."
            # So strip away the parent directory of a relative path
            if (${project_path} MATCHES [[^(\.\./)+(.*)]])
                set(ide_path "${CMAKE_MATCH_2}")
            endif()
            set_target_properties(${unaliased_test_name} PROPERTIES
                FOLDER "${ide_path}"
                VS_DEBUGGER_COMMAND ${test_command}
                VS_DEBUGGER_COMMAND_ARGUMENTS "${test_arguments_line}"
            )

            # In the case where we are creating a custom target, we need to add dependency to the target
            if(o3de_add_test_PARENT_NAME AND NOT ${o3de_add_test_NAME} STREQUAL ${o3de_add_test_PARENT_NAME})
                o3de_add_dependencies(${unaliased_test_name} ${o3de_add_test_PARENT_NAME})
            endif()

        endif()

        # For test projects that are custom targets, pass a props file that sets the project as "Console" so
        # it leaves the console open when it finishes
        set_target_properties(${unaliased_test_name} PROPERTIES VS_USER_PROPS "${O3DE_ENGINE_PATH}/cmake/Platform/Common/MSVC/TestProject.props")

        # Include additional dependencies
        if (o3de_add_test_RUNTIME_DEPENDENCIES)
            o3de_add_dependencies(${unaliased_test_name} ${o3de_add_test_RUNTIME_DEPENDENCIES})
        endif()

        # RUN_TESTS wont build dependencies: https://gitlab.kitware.com/cmake/cmake/issues/8774
        # In the mean time we add a custom target and mark the dependency
        o3de_add_dependencies(TEST_SUITE_${o3de_add_test_TEST_SUITE} ${unaliased_test_name})

    else()

        # Include additional dependencies
        if (o3de_add_test_RUNTIME_DEPENDENCIES)
            o3de_add_dependencies(TEST_SUITE_${o3de_add_test_TEST_SUITE} ${o3de_add_test_RUNTIME_DEPENDENCIES})
        endif()

        # Include additional tests
        if (TARGET ${unaliased_test_name})
            o3de_add_dependencies(TEST_SUITE_${o3de_add_test_TEST_SUITE} ${unaliased_test_name})
        endif()

    endif()

    if(NOT o3de_add_test_PARENT_NAME)
        set(test_target ${o3de_add_test_NAME})
    else()
        set(test_target ${o3de_add_test_PARENT_NAME})
    endif()

    # Check to see whether or not this test target has been stored in the global list for walking by the test impact analysis framework
    get_property(all_tests GLOBAL PROPERTY O3DE_ALL_TESTS)
    if(NOT "${test_target}" IN_LIST all_tests)
        # Extract the test target name from the namespace::target_name composite
        string(REGEX REPLACE ".*::" "" test_name "${test_target}")
        # Store the test target name sans namespace so they can be looked up without the preceeding namespace
        set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TESTS_DE_NAMESPACED ${test_name})
        # This is the first reference to this test target so add it to the global list
        set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TESTS ${test_target})
        set_property(GLOBAL PROPERTY O3DE_ALL_TESTS_${test_target}_TEST_LIBRARY ${o3de_add_test_TEST_LIBRARY})
    endif()
    # Add the test suite, timeout value and labels to the test target params
    set(O3DE_TEST_PARAMS "${O3DE_TEST_PARAMS}#${o3de_add_test_TEST_SUITE}")
    set(O3DE_TEST_PARAMS "${O3DE_TEST_PARAMS}#${o3de_add_test_TIMEOUT}")
    string(REPLACE ";" "," flattened_labels "${final_labels}")
    set(O3DE_TEST_PARAMS "${O3DE_TEST_PARAMS}#${flattened_labels}")
    # Store the params and labels for this test target
    set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TESTS_${test_target}_PARAMS ${O3DE_TEST_PARAMS})
endfunction()

#! o3de_add_pytest: registers target PyTest-based test with CTest
#
# \arg:NAME name of the test-module to register with CTest
# \arg:PATH path to the file (or dir) containing pytest-based tests
# \arg:PYTEST_MARKS (optional) extra pytest marker filtering string (see pytest arg "-m")
# \arg:EXTRA_ARGS (optional) additional arguments to pass to PyTest, should not include pytest marks (value for "-m" should be passed to PYTEST_MARKS)
# \arg:TEST_SERIAL (bool) disable parallel execution alongside other test modules, important when this test depends on shared resources or environment state
# \arg:TEST_REQUIRES (optional) list of system resources needed by the tests in this module.  Used to filter out execution when those system resources are not available.  For example, 'gpu'
# \arg:RUNTIME_DEPENDENCIES (optional) - List of additional runtime dependencies required by this test.
# \arg:COMPONENT (optional) - Scope of the feature area that the test belongs to (eg. physics, graphics, etc.).
# \arg:EXCLUDE_TEST_RUN_TARGET_FROM_IDE(bool) - If set the test run target will be not be shown in the IDE
# \arg:TEST_SUITE(optional) - "smoke" or "periodic" or "sandbox" or "awsi" - prevents the test from running normally
#      and instead places it a special suite of tests that only run when requested.
# \arg:TIMEOUT (optional) The timeout in seconds for the module. If not set defaults to O3DE_TEST_DEFAULT_TIMEOUT
#
function(o3de_add_pytest)

    if(NOT O3DE_PAL_TRAIT_TEST_PYTEST_SUPPORTED OR NOT O3DE_PAL_TRAIT_TEST_O3DETESTTOOLS_SUPPORTED)
        return()
    endif()

    set(options TEST_SERIAL)
    set(oneValueArgs NAME PATH TEST_SUITE PYTEST_MARKS)
    set(multiValueArgs EXTRA_ARGS COMPONENT)

    cmake_parse_arguments(o3de_add_pytest "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT o3de_add_pytest_PATH)
        message(FATAL_ERROR "Must supply a value for PATH to tests")
    endif()

    if(o3de_add_pytest_PYTEST_MARKS)
        # Suite marker args added by non_ide_params will duplicate those set by custom_marks_args
        # however resetting flags is safe and overrides with the final value set
        set(custom_marks_args "-m" "${o3de_add_pytest_PYTEST_MARKS}")
    endif()

    string(REPLACE "::" "_" pytest_report_directory "${PYTEST_XML_OUTPUT_DIR}/${o3de_add_pytest_NAME}.xml")
    string(REPLACE "::" "_" pytest_output_directory "${O3DETESTTOOLS_OUTPUT_DIR}/${o3de_add_pytest_NAME}")

    # Add the script path to the test target params
    set(O3DE_TEST_PARAMS "${o3de_add_pytest_PATH}")

    # Command to run the test
    set(test_command ${O3DE_PYTEST_EXECUTABLE} ${o3de_add_pytest_PATH} ${o3de_add_pytest_EXTRA_ARGS} --output-path ${pytest_output_directory} --junitxml=${pytest_report_directory} ${custom_marks_args})

    o3de_add_test(
        NAME ${o3de_add_pytest_NAME}
        PARENT_NAME ${o3de_add_pytest_NAME}
        TEST_SUITE ${o3de_add_pytest_TEST_SUITE}
        LABELS FRAMEWORK_pytest
        TEST_COMMAND ${test_command}
        TEST_LIBRARY pytest
        COMPONENT ${o3de_add_pytest_COMPONENT}
        ${o3de_add_pytest_UNPARSED_ARGUMENTS}
    )

    set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TESTS_${o3de_add_pytest_NAME}_SCRIPT_PATH ${o3de_add_pytest_PATH})
    set_property(GLOBAL APPEND PROPERTY O3DE_ALL_TESTS_${o3de_add_pytest_NAME}_TEST_COMMAND ${test_command})
    set_tests_properties(${O3DE_ADDED_TEST_NAME} PROPERTIES RUN_SERIAL "${o3de_add_pytest_TEST_SERIAL}")
endfunction()

#! o3de_add_googletest: Adds a new RUN_TEST using for the specified target using the supplied command or fallback to running
#                     googletest tests through AzTestRunner
# \arg:NAME Name to for the test run target
# \arg:TARGET Name of the target module that is being run for tests. If not provided, will default to 'NAME'
# \arg:TEST_REQUIRES(optional) List of system resources that are required to run this test.
#      Only available option is "gpu"
# \arg:TEST_SUITE(optional) - "smoke" or "periodic" or "sandbox" or "awsi" - prevents the test from running normally
#      and instead places it a special suite of tests that only run when requested.
# \arg:TEST_COMMAND(optional) - Command which runs the tests.
#      If not supplied, a default of "AzTestRunner $<TARGET_FILE:${NAME}> AzRunUnitTests" will be used
# \arg:COMPONENT (optional) - Scope of the feature area that the test belongs to (eg. physics, graphics, etc.).
# \arg:TIMEOUT (optional) The timeout in seconds for the module. If not set, will have its timeout set by o3de_add_test to the default timeout.
# \arg:EXCLUDE_TEST_RUN_TARGET_FROM_IDE(bool) - If set the test run target will be not be shown in the IDE
function(o3de_add_googletest)
    if(NOT O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        message(FATAL_ERROR "Platform does not support test targets")
    endif()

    set(one_value_args NAME TARGET TEST_SUITE)
    set(multi_value_args TEST_COMMAND COMPONENT)
    cmake_parse_arguments(o3de_add_googletest "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    if (o3de_add_googletest_TARGET)
        set(target_name ${o3de_add_googletest_TARGET})
    else()
        set(target_name ${o3de_add_googletest_NAME})
    endif()


    # AzTestRunner modules only supports google test libraries, regardless of whether or not
    # google test suites are supported
    set_property(GLOBAL APPEND PROPERTY O3DE_AZTESTRUNNER_TEST_MODULES "${target_name}")

    if(NOT O3DE_PAL_TRAIT_TEST_GOOGLE_TEST_SUPPORTED)
        return()
    endif()


    if (o3de_add_googletest_TEST_SUITE AND NOT o3de_add_googletest_TEST_SUITE STREQUAL "main")
        # if a suite is specified, we filter to only accept things which match that suite (in c++)
        set(non_ide_params "--gtest_filter=*SUITE_${o3de_add_googletest_TEST_SUITE}*")
    else()
        # otherwise, if its the main suite we only runs things that dont have any of the other suites.
        # Note: it doesn't do AND, only 'or' - so specifying SUITE_main:REQUIRES_gpu
        # will actually run everything in main OR everything tagged as requiring a GPU
        # instead of only tests tagged with BOTH main and gpu...
        # so we have to do it this way (negating all others)
        set(non_ide_params "--gtest_filter=-*SUITE_smoke*:*SUITE_periodic*:*SUITE_benchmark*:*SUITE_sandbox*:*SUITE_awsi*")
    endif()

    if(NOT o3de_add_googletest_TEST_COMMAND)
        # Use the NAME parameter as the build target
        set(build_target ${target_name})
        o3de_strip_target_namespace(TARGET ${build_target} OUTPUT_VARIABLE build_target)

        if(NOT TARGET ${build_target})
            message(FATAL_ERROR "A valid build target \"${build_target}\" for test run \"${target_name}\" has not been found.\
                A valid target via the TARGET parameter or a custom TEST_COMMAND must be supplied")
        endif()

        # If command is not supplied attempts, uses the AzTestRunner to run googletest on the supplied NAME
        set(full_test_command $<TARGET_FILE:AZ::AzTestRunner> $<TARGET_FILE:${build_target}> AzRunUnitTests)
        # Add AzTestRunner as a build dependency
        o3de_add_dependencies(${build_target} AZ::AzTestRunner)
        # Start the test target params and dd the command runner command
        # Ideally, we would populate the full command procedurally but the generator expressions won't be expanded by the time we need this data
        set(O3DE_TEST_PARAMS "AzRunUnitTests")
    else()
        set(full_test_command ${o3de_add_googletest_TEST_COMMAND})
        # Remove the generator expressions so we are left with the argument(s) required to run unit tests for executable targets
        string(REPLACE ";" "" stripped_test_command ${full_test_command})
        string(GENEX_STRIP ${stripped_test_command} stripped_test_command)
        # Start the test target params and dd the command runner command
        set(O3DE_TEST_PARAMS "${stripped_test_command}")
    endif()

    string(REPLACE "::" "_" report_directory "${GTEST_XML_OUTPUT_DIR}/${o3de_add_googletest_NAME}.xml")

    # Invoke the lower level o3de_add_test command to add the actual ctest and setup the test labels to add_dependencies on the target
    o3de_add_test(
        NAME ${o3de_add_googletest_NAME}
        PARENT_NAME ${target_name}
        TEST_SUITE ${o3de_add_googletest_TEST_SUITE}
        LABELS FRAMEWORK_googletest
        TEST_COMMAND ${full_test_command} --gtest_output=xml:${report_directory} ${O3DE_GOOGLETEST_EXTRA_PARAMS}
        TEST_LIBRARY googletest
        ${o3de_add_googletest_UNPARSED_ARGUMENTS}
        NON_IDE_PARAMS ${non_ide_params}
        RUNTIME_DEPENDENCIES AZ::AzTestRunner
        COMPONENT ${o3de_add_googletest_COMPONENT}
    )
endfunction()

#! o3de_add_googlebenchmark: Adds a new RUN_TEST using for the specified target using the supplied command or fallback to running
#                     benchmark tests through AzTestRunner
# \arg:NAME Name to for the test run target
# \arg:TARGET Target to use to retrieve target file to run test on. NAME is adds TARGET as a dependency
# \arg:TEST_REQUIRES(optional) List of system resources that are required to run this test.
#      Only available option is "gpu"
# \arg:TEST_COMMAND(optional) - Command which runs the tests
#      If not supplied, a default of "AzTestRunner $<TARGET_FILE:${TARGET}> AzRunBenchmarks" will be used
# \arg:COMPONENT (optional) - Scope of the feature area that the test belongs to (eg. physics, graphics, etc.).
# \arg:OUTPUT_FILE_FORMAT(optional) - Format of benchmark output file. Valid options are <console|json|csv>
#      If not supplied, json is used as a default and the test run command will output results to
#      "${CMAKE_BINARY_DIR}/BenchmarkResults/" directory
#      NOTE: Not used if a custom TEST_COMMAND is supplied
# \arg:TIMEOUT (optional) The timeout in seconds for the module. If not set, will have its timeout set by o3de_add_test to the default timeout.
function(o3de_add_googlebenchmark)
    if(NOT O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
        message(FATAL_ERROR "Platform does not support test targets")
    endif()
    if(NOT O3DE_PAL_TRAIT_TEST_GOOGLE_BENCHMARK_SUPPORTED)
        return()
    endif()

    set(one_value_args NAME TARGET OUTPUT_FILE_FORMAT TIMEOUT)
    set(multi_value_args TEST_REQUIRES TEST_COMMAND COMPONENT)
    cmake_parse_arguments(o3de_add_googlebenchmark "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    o3de_strip_target_namespace(TARGET ${o3de_add_googlebenchmark_NAME} OUTPUT_VARIABLE stripped_name)
    string(TOLOWER "${o3de_add_googlebenchmark_OUTPUT_FILE_FORMAT}" output_file_format_lower)

    # Make the BenchmarkResults at configure time so that benchmark results can be stored there
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/BenchmarkResults")
    if("${output_file_format_lower}" STREQUAL "console")
        set(output_format_args
            "--benchmark_out_format=console"
            "--benchmark_out=${CMAKE_BINARY_DIR}/BenchmarkResults/${stripped_name}.log"
        )
    elseif("${output_file_format_lower}" STREQUAL "csv")
        set(output_format_args
            "--benchmark_out_format=csv"
            "--benchmark_out=${CMAKE_BINARY_DIR}/BenchmarkResults/${stripped_name}.csv"
        )
    else()
        set(output_format_args
            "--benchmark_out_format=json"
            "--benchmark_out=${CMAKE_BINARY_DIR}/BenchmarkResults/${stripped_name}.json"
        )
    endif()

    if(NOT o3de_add_googlebenchmark_TEST_COMMAND)
        # Use the TARGET parameter as the build target if supplied, otherwise fallback to using the NAME parameter
        set(build_target ${o3de_add_googlebenchmark_TARGET})
        if(NOT build_target)
            set(build_target ${o3de_add_googlebenchmark_NAME}) # Assume NAME is the TARGET if not specified
        endif()
        o3de_strip_target_namespace(TARGET ${build_target} OUTPUT_VARIABLE build_target)

        if(NOT TARGET ${build_target})
            message(FATAL_ERROR "A valid build target \"${build_target}\" for test run \"${o3de_add_googlebenchmark_NAME}\" has not been found.\
                A valid target via the TARGET parameter or a custom TEST_COMMAND must be supplied")
        endif()

        # If command is not supplied attempts, uses the AzTestRunner to run googlebenchmarks on the supplied TARGET
        set(full_test_command $<TARGET_FILE:AZ::AzTestRunner> $<TARGET_FILE:${build_target}> AzRunBenchmarks ${output_format_args})
        # Start the test target params and dd the command runner command
        # Ideally, we would populate the full command procedurally but the generator expressions won't be expanded by the time we need this data
        set(O3DE_TEST_PARAMS "AzRunUnitTests")
    else()
        set(full_test_command ${o3de_add_googlebenchmark_TEST_COMMAND})
        # Remove the generator expressions so we are left with the argument(s) required to run unit tests for executable targets
        string(REPLACE ";" "" stripped_test_command ${full_test_command})
        string(GENEX_STRIP ${stripped_test_command} stripped_test_command)
        # Start the test target params and dd the command runner command
        set(O3DE_TEST_PARAMS "${stripped_test_command}")
    endif()

    # Set the name of the current test target for storage in the global list
    o3de_add_test(
        NAME ${o3de_add_googlebenchmark_NAME}
        PARENT_NAME ${o3de_add_googlebenchmark_NAME}
        TEST_REQUIRES ${o3de_add_googlebenchmark_TEST_REQUIRES}
        TEST_COMMAND ${full_test_command} ${O3DE_GOOGLETEST_EXTRA_PARAMS}
        TEST_SUITE "benchmark"
        LABELS FRAMEWORK_googlebenchmark
        TEST_LIBRARY googlebenchmark
        TIMEOUT ${o3de_add_googlebenchmark_TIMEOUT}
        RUNTIME_DEPENDENCIES
            ${build_target}
            AZ::AzTestRunner
        COMPONENT ${o3de_add_googlebenchmark_COMPONENT}
    )
endfunction()

