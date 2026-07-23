#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_MONOLITHIC_GAME FALSE CACHE BOOL "Indicates if the game will be built monolithically (other targets are not supported)")

if(O3DE_MONOLITHIC_GAME)
    add_compile_definitions(AZ_MONOLITHIC_BUILD)
    o3de_set(O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE STATIC)
    o3de_set(O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE GEM_STATIC)
    o3de_set(O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_GEM_SHARED_TYPE GEM_STATIC)
    # Disable targets that are not supported with monolithic
    o3de_set(O3DE_PAL_TRAIT_BUILD_HOST_TOOLS FALSE)
    o3de_set(O3DE_PAL_TRAIT_BUILD_HOST_GUI_TOOLS FALSE)
    o3de_set(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED FALSE)
else()
    o3de_set(O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_LIBRARY_TYPE SHARED)
    o3de_set(O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_MODULE_TYPE GEM_MODULE)
    o3de_set(O3DE_PAL_TRAIT_MONOLITHIC_DRIVEN_GEM_SHARED_TYPE GEM_SHARED)
endif()

#! o3de_delayed_generate_static_modules_inl: generate the StaticModules.inl
#  listing for monolithic builds.
#
#  Called from engine/project post-processing.  In non-monolithic builds
#  gems are loaded dynamically and no static module listing is needed,
#  so this is a no-op.  Monolithic support is NOT yet implemented.
function(o3de_delayed_generate_static_modules_inl)
    if(O3DE_MONOLITHIC_GAME)
        message(FATAL_ERROR
            "Monolithic builds are not yet supported: "
            "o3de_delayed_generate_static_modules_inl is not implemented.")
    endif()
endfunction()