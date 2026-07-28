#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})
set(pal_common_code_source_path ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

# Load the PAL trait file at top level so O3DE_PAL_TRAIT_MICROPHONE_USES_LIBSAMPLERATE
# is in scope for the conditional dependency below. ly_add_target also loads
# this file via PLATFORM_INCLUDE_FILES; re-loading at top scope is safe -- the
# PAL files are pure variable-set scripts.
include(${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake)

# Conditionally include libsamplerate only on platforms that actually call its
# API. On Linux the Microphone Gem uses the None stub, which never exercises
# libsamplerate; gating the dependency on the PAL trait drops a 3rdParty fetch
# + link from Linux builds where it's unused. Other platforms (Mac/iOS/Android/
# Windows) keep O3DE_PAL_TRAIT_MICROPHONE_USES_LIBSAMPLERATE=TRUE, preserving
# existing behavior.
set(MICROPHONE_BUILD_DEPENDENCIES Gem::AudioSystem.API Legacy::CryCommon)
set(MICROPHONE_COMPILE_DEFINITIONS "")
if (O3DE_PAL_TRAIT_MICROPHONE_USES_LIBSAMPLERATE)
    list(APPEND MICROPHONE_BUILD_DEPENDENCIES 3rdParty::libsamplerate)
    list(APPEND MICROPHONE_COMPILE_DEFINITIONS USE_LIBSAMPLERATE)
endif()

o3de_add_target(
    NAME ${gem_name}.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        microphone_files.cmake
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_source_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Source
    BUILD_DEPENDENCIES
        PUBLIC
            ${MICROPHONE_BUILD_DEPENDENCIES}
    COMPILE_DEFINITIONS
        PUBLIC
            ${MICROPHONE_COMPILE_DEFINITIONS}
)

o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    FILES_CMAKE
        microphone_shared_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Static
)

# Inject the gem name into the Module source file
o3de_add_source_properties(
    SOURCES
        Source/MicrophoneModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})


o3de_create_alias(NAME ${gem_name}.Clients  NAMESPACE Gem TARGETS Gem::${gem_name} Gem::AudioSystem)
o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name} Gem::AudioSystem.Editor)
