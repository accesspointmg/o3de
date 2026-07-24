#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_gem_setup()

# This gem relies on the PhysX gem
o3de_find_gem("PhysX5" physx_gem_path)
set(physx_pal_source_dir ${physx_gem_path}/Source/Platform/${O3DE_PAL_PLATFORM_NAME})

include(${physx_pal_source_dir}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake) # for O3DE_PAL_TRAIT_PHYSX_SUPPORTED

if(O3DE_PAL_TRAIT_PHYSX_SUPPORTED)
    set(physxdebug_dependency physx_5_dependency)
    set(physxdebug_files Code/physxdebug_files.cmake)
    set(physxdebug_module_files physxdebug_module_files.cmake)
    set(physxdebug_editor_files Code/physxdebug_editor_files.cmake)
else()
    set(physxdebug_files Code/physxdebug_unsupported_files.cmake)
    set(physxdebug_module_files physxdebug_unsupported_module_files.cmake)
    set(physxdebug_editor_files Code/physxdebug_unsupported_files.cmake)
endif()

########################################################################################
o3de_add_target(
    NAME ${gem_name} ${O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE}
    NAMESPACE Gem
    OUTPUT_NAME ${gem_name}.Gem
    FILES_CMAKE
        ${physxdebug_module_files}
        ${physxdebug_files}
    INCLUDE_DIRECTORIES
        PRIVATE
            Code/Source
        PUBLIC
            Code/Include
    BUILD_DEPENDENCIES
        PUBLIC
            ${physxdebug_dependency}
            Legacy::CryCommon
            Gem::PhysX5
            Gem::ImGui.imguilib
            Gem::ImGui
    RUNTIME_DEPENDENCIES
        Gem::PhysX5
        Gem::ImGui
)

########################################################################################
# Inject the gem name into the Module source file
if (O3DE_PAL_TRAIT_PHYSX_SUPPORTED)
    o3de_add_source_properties(
        SOURCES
            Source/Module.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})
else()
    o3de_add_source_properties(
        SOURCES
            Source/ModuleUnsupported.cpp
        PROPERTY COMPILE_DEFINITIONS
            VALUES
                O3DE_GEM_NAME=${gem_name}
                O3DE_GEM_VERSION=${gem_version})
endif()

# use the ${gem_name} module in Clients and Servers:
o3de_create_alias(NAME ${gem_name}.Clients NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Servers NAMESPACE Gem TARGETS Gem::${gem_name})
o3de_create_alias(NAME ${gem_name}.Unified NAMESPACE Gem TARGETS Gem::${gem_name})

if(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    ########################################################################################
    o3de_add_target(
        NAME ${gem_name}.Editor GEM_MODULE
        NAMESPACE Gem
        OUTPUT_NAME ${gem_name}.Editor.Gem
        FILES_CMAKE
            ${physxdebug_module_files}
            ${physxdebug_editor_files}
        COMPILE_DEFINITIONS
            PRIVATE
                PHYSXDEBUG_GEM_EDITOR
        INCLUDE_DIRECTORIES
            PRIVATE
                Code/Source
            PUBLIC
                Code/Include
        BUILD_DEPENDENCIES
            PRIVATE
                ${physxdebug_dependency}
                Legacy::CryCommon
                Legacy::Editor.Headers
                AZ::AzToolsFramework
                Gem::PhysX5.Editor
                Gem::ImGui.imguilib
                Gem::ImGui.Editor
        RUNTIME_DEPENDENCIES
            Gem::PhysX5.Editor
            Gem::ImGui.Editor
    )
    # use the ${gem_name}.Editor module in dev tools:
    o3de_create_alias(NAME ${gem_name}.Builders NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
    o3de_create_alias(NAME ${gem_name}.Tools    NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

endif()
