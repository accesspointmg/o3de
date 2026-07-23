#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include_guard(GLOBAL)
set(_cmake_Configurations_cmake ${CMAKE_CURRENT_LIST_DIR})

# O3DE_CONFIGURATION_TYPES defines all the configuration types that O3DE supports
# We dont set CMAKE_CONFIGURATION_TYPES directly because we want to be able to configure which 
# configuration types are supported in an SDK installation. SDK installations will fill a 
# CMAKE_CONFIGURATION_TYPES based on the configurations that were generated during the install process.
# o3de_append_configurations_options depends on O3DE_CONFIGURATION_TYPES being
# set in order to successfully parse the arguments. Even for non-multi-config
# generators, it needs to be set.
set(O3DE_CONFIGURATION_TYPES "debug;profile;release" CACHE STRING "" FORCE)

include(${_cmake_Configurations_cmake}/ConfigurationTypes.cmake)

#! o3de_append_configurations_options: adds options to the different configurations (debug, profile, release, etc)
#
# \arg:DEFINES
# \arg:DEFINES_${CONFIGURATION}
# \arg:COMPILATION
# \arg:COMPILATION_${CONFIGURATION}
# \arg:COMPILATION_C
# \arg:COMPILATION_C_${CONFIGURATION}
# \arg:COMPILATION_CXX
# \arg:COMPILATION_CXX_${CONFIGURATION}
# \arg:LINK
# \arg:LINK_${CONFIGURATION}
# \arg:LINK_STATIC
# \arg:LINK_STATIC_${CONFIGURATION}
# \arg:LINK_NON_STATIC
# \arg:LINK_NON_STATIC_${CONFIGURATION}
# \arg:LINK_EXE
# \arg:LINK_EXE_${CONFIGURATION}
# \arg:LINK_MODULE
# \arg:LINK_MODULE_${CONFIGURATION}
# \arg:LINK_SHARED
# \arg:LINK_SHARED_${CONFIGURATION}
#
# Note: COMPILATION_C/COMPILATION_CXX are mutually exclusive with COMPILATION. You can only specify COMPILATION for C/C++ flags or 
#       a combination of COMPILATION_C/COMPILATION_CXX for the separate c/c++ flags separately.
function(o3de_append_configurations_options)

    set(options)
    set(oneValueArgs)
    set(multiArgs
        DEFINES
        COMPILATION
        COMPILATION_C
        COMPILATION_CXX
        LINK
        LINK_STATIC
        LINK_NON_STATIC
        LINK_EXE
        LINK_MODULE
        LINK_SHARED
    )
    foreach(arg IN LISTS multiArgs)
        list(APPEND multiValueArgs ${arg})
        # we parse the parameters based on all configuration types so unknown configurations
        # are not passed as values to other parameters
        foreach(conf IN LISTS O3DE_CONFIGURATION_TYPES)
            string(TOUPPER ${conf} UCONF)
            list(APPEND multiValueArgs ${arg}_${UCONF})
        endforeach()
    endforeach()

    cmake_parse_arguments(o3de_append_configurations_options "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(o3de_append_configurations_options_DEFINES)
        add_compile_definitions(${o3de_append_configurations_options_DEFINES})
    endif()

    if(o3de_append_configurations_options_COMPILATION)
        string(REPLACE ";" " " COMPILATION_STR "${o3de_append_configurations_options_COMPILATION}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMPILATION_STR}" PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMPILATION_STR}" PARENT_SCOPE)
    endif()
    if(o3de_append_configurations_options_COMPILATION_C)
        string(REPLACE ";" " " COMPILATION_STR "${o3de_append_configurations_options_COMPILATION_C}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMPILATION_STR}" PARENT_SCOPE)
    endif()
    if(o3de_append_configurations_options_COMPILATION_CXX)
        string(REPLACE ";" " " COMPILATION_STR "${o3de_append_configurations_options_COMPILATION_CXX}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMPILATION_STR}" PARENT_SCOPE)        
    endif()

    if(o3de_append_configurations_options_LINK)
        string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK}")
        set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
        set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LINK_OPTIONS}" PARENT_SCOPE)
    endif()

    if(o3de_append_configurations_options_LINK_STATIC)
        string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_STATIC}")
        set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
    endif()

    if(o3de_append_configurations_options_LINK_NON_STATIC)
        string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_NON_STATIC}")
        set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
    endif()

    if(o3de_append_configurations_options_LINK_EXE)
        string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_EXE}")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
    endif()

    if(o3de_append_configurations_options_LINK_MODULE)
        string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_MODULE}")
        set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
    endif()

    if(o3de_append_configurations_options_LINK_SHARED)
        string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_SHARED}")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${LINK_STR}" PARENT_SCOPE)
    endif()

    # We only iterate for the actual configuration types
    foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)

        string(TOUPPER ${conf} UCONF)
        if(o3de_append_configurations_options_DEFINES_${UCONF})
            #Transform defines using generator expressions
            list(TRANSFORM o3de_append_configurations_options_DEFINES_${UCONF} REPLACE "^.+$" "$<$<CONFIG:${conf}>:\\0>"
                OUTPUT_VARIABLE DEFINES_${UCONF}_GENEX)
            add_compile_definitions(${DEFINES_${UCONF}_GENEX})
        endif()
        if(o3de_append_configurations_options_COMPILATION_${UCONF})
            string(REPLACE ";" " " COMPILATION_STR "${o3de_append_configurations_options_COMPILATION_${UCONF}}")
            set(CMAKE_C_FLAGS_${UCONF} "${CMAKE_C_FLAGS_${UCONF}} ${COMPILATION_STR}" PARENT_SCOPE)
            set(CMAKE_CXX_FLAGS_${UCONF} "${CMAKE_CXX_FLAGS_${UCONF}} ${COMPILATION_STR}" PARENT_SCOPE)
        endif()
        if(o3de_append_configurations_options_LINK_${UCONF})
            string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_${UCONF}}")
            set(CMAKE_STATIC_LINKER_FLAGS_${UCONF} "${CMAKE_STATIC_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
            set(CMAKE_MODULE_LINKER_FLAGS_${UCONF} "${CMAKE_MODULE_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
            set(CMAKE_SHARED_LINKER_FLAGS_${UCONF} "${CMAKE_SHARED_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
            set(CMAKE_EXE_LINKER_FLAGS_${UCONF} "${CMAKE_EXE_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
        endif()
        if(o3de_append_configurations_options_LINK_STATIC_${UCONF})
            string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_STATIC_${UCONF}}")
            set(CMAKE_STATIC_LINKER_FLAGS_${UCONF} "${CMAKE_STATIC_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
        endif()
        if(o3de_append_configurations_options_LINK_NON_STATIC_${UCONF})
            string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_NON_STATIC_${UCONF}}")
            set(CMAKE_MODULE_LINKER_FLAGS_${UCONF} "${CMAKE_MODULE_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
            set(CMAKE_SHARED_LINKER_FLAGS_${UCONF} "${CMAKE_SHARED_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
            set(CMAKE_EXE_LINKER_FLAGS_${UCONF} "${CMAKE_EXE_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
        endif()
        if(o3de_append_configurations_options_LINK_EXE_${UCONF})
            string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_EXE_${UCONF}}")
            set(CMAKE_EXE_LINKER_FLAGS_${UCONF} "${CMAKE_EXE_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
        endif()
        if(o3de_append_configurations_options_LINK_MODULE_${UCONF})
            string(REPLACE ";" " " LINK_STR "${o3de_append_configurations_options_LINK_MODULE_${UCONF}}")
            set(CMAKE_MODULE_LINKER_FLAGS_${UCONF} "${CMAKE_MODULE_LINKER_FLAGS_${UCONF}} ${LINK_STR}" PARENT_SCOPE)
        endif()
    endforeach()

endfunction()

# Set the C++ standard that is being targeted to C++17
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ Standard to target")
o3de_set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(O3DE_STACK_CAPTURE_DEPTH 3 CACHE STRING "The depth of the callstack to capture when tracking allocations")

get_property(_isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT _isMultiConfig)
    # No reason set CMAKE_BUILD_TYPE if it's a multiconfig generator.
    if(NOT CMAKE_BUILD_TYPE)
        message("No build type specified (CMAKE_BUILD_TYPE), defaulting to profile build")
        set(CMAKE_BUILD_TYPE profile CACHE STRING "" FORCE)
    endif()
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY HELPSTRING "Type of build (debug|profile|release)")
    # set options for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "debug;profile;release")
endif()
unset(_isMultiConfig)

# Now these CMake variables are cleared out in the cache here.
# This must be done before including the Platform specific Configurations_<platform>.cmake files as non-standard configurations
# such as profile doesn't already have a cache version of these variable.
# For configurations such as debug and release, the CMake internal module files initialize variable such as
# CMAKE_EXE_LINKER_FLAGS_DEBUG and CMAKE_EXE_LINKER_FLAGS_RELEASE, so the set call below for those CACHE variables do nothing.
# But for profile this defines the cache variable for the first time, therefore allowing the o3de_append_configurations_options() function
# to append to the CMAKE_*_LINKER_FLAGS_PROFILE variables in the parent scope when it runs
foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER ${conf} UCONF)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/${conf} CACHE PATH "Installation directory for ${conf} ar")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${conf} CACHE PATH "Installation directory for ${conf} libraries")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${UCONF} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${conf} CACHE PATH "Installation directory for ${conf} executables")
    set(CMAKE_STATIC_LINKER_FLAGS_${UCONF} CACHE STRING "Flags to pass to the archiver for ${conf}")
    set(CMAKE_MODULE_LINKER_FLAGS_${UCONF} CACHE STRING "Flags to pass to the linker when creating a module library for ${conf}")
    set(CMAKE_SHARED_LINKER_FLAGS_${UCONF} CACHE STRING "Flags to pass to the linker when creating a shared library for ${conf}")
    set(CMAKE_EXE_LINKER_FLAGS_${UCONF} CACHE STRING "Flags to pass to the linker when creating an executable for ${conf}")
endforeach()

# flags are defined per platform, follow platform files under Platform/<PlatformName>/Configurations_<platform_wart>(_<platform_architecture>).cmake
# Prefer the architecture-specific file; fall back to the plain platform file
if(EXISTS ${O3DE_ENGINE_CMAKE_PAL_PATH}/Configurations_${O3DE_PAL_PLATFORM_WART}${O3DE_ARCHITECTURE_NAME_EXTENSION}.cmake)
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/Configurations_${O3DE_PAL_PLATFORM_WART}${O3DE_ARCHITECTURE_NAME_EXTENSION}.cmake)
elseif(EXISTS ${O3DE_ENGINE_CMAKE_PAL_PATH}/Configurations_${O3DE_PAL_PLATFORM_WART}.cmake)
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/Configurations_${O3DE_PAL_PLATFORM_WART}.cmake)
else()
    message(FATAL_ERROR "No platform configuration file found at ${O3DE_ENGINE_CMAKE_PAL_PATH}/Configurations_${O3DE_PAL_PLATFORM_WART}[${O3DE_ARCHITECTURE_NAME_EXTENSION}].cmake")
endif()

