/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */


// Description : to get some defines available in every CryEngine project


#pragma once


#include "BaseTypes.h"
#include <AzCore/PlatformDef.h>

#if defined(WIN32) || defined(WIN64)
    #if !defined(_RELEASE)
        #define ENABLE_STATS_AGENT
    #endif
#endif


// Type used for vertex indices
// WARNING: If you change this typedef, you need to update AssetProcessorPlatformConfig.ini to convert cgf and abc files to the proper index format.
#if defined(MOBILE)
    typedef uint16 vtx_idx;
#else
    // Uncomment one of the two following typedefs:
    typedef uint32 vtx_idx;
    //typedef uint16 vtx_idx;
#endif


// When non-zero, const cvar accesses (by name) are logged in release-mode on consoles.
// This can be used to find non-optimal usage scenario's, where the constant should be used directly instead.
// Since read accesses tend to be used in flow-control logic, constants allow for better optimization by the compiler.
#define LOG_CONST_CVAR_ACCESS 0

#if defined(WIN32) || defined(WIN64) || LOG_CONST_CVAR_ACCESS
    #define RELEASE_LOGGING
#endif

#if defined(_RELEASE) && !defined(RELEASE_LOGGING)
    #define EXCLUDE_NORMAL_LOG
#endif

// Add the "REMOTE_ASSET_PROCESSOR" define except in release
// this makes it so that asset processor functions.  Without this, all assets must be present and on local media
// with this, the asset processor can be used to remotely process assets.
#if !defined(_RELEASE)
    #define REMOTE_ASSET_PROCESSOR
#endif

#if !defined(_RELEASE)
    #define USE_HTTP_WEBSOCKETS 0
#endif


#define PROJECTDEFINES_H_TRAIT_DISABLE_MONOLITHIC_PROFILING_MARKERS 1
#define PROJECTDEFINES_H_TRAIT_USE_MESH_TESSELLATION 1
#if defined(WIN32)
    #define PROJECTDEFINES_H_TRAIT_USE_SVO_GI 1
#endif
#if defined(APPLE) || defined(LINUX)
    #define AZ_LEGACY_CRYCOMMON_TRAIT_USE_PTHREADS 1
    #define AZ_LEGACY_CRYCOMMON_TRAIT_USE_UNIX_PATHS 1
#endif

#if !defined(_RELEASE)
    #ifndef ENABLE_PROFILING_CODE
        #define ENABLE_PROFILING_CODE
    #endif

    //lightweight profilers, disable for submissions, disables displayinfo inside 3dengine as well
    #ifndef ENABLE_LW_PROFILERS
        #define ENABLE_LW_PROFILERS
    #endif
#endif

// Reflect texture slot information - only used in the editor
#if defined(WIN32) || defined(WIN64) || defined(AZ_PLATFORM_MAC)
    #define SHADER_REFLECT_TEXTURE_SLOTS 1
#else
    #define SHADER_REFLECT_TEXTURE_SLOTS 0
#endif

#if !defined(MOBILE)
    //---------------------------------------------------------------------
    // Enable Tessellation Features
    // (displacement mapping, subdivision, water tessellation)
    //---------------------------------------------------------------------
    // Modules   : 3DEngine, Renderer
    // Depends on: DX11

    // Global tessellation feature flag
    #define TESSELLATION
    #ifdef TESSELLATION
        // Specific features flags
        #define WATER_TESSELLATION

        #if PROJECTDEFINES_H_TRAIT_USE_MESH_TESSELLATION
            // Mesh tessellation (displacement, smoothing, subd)
            #define MESH_TESSELLATION
            // Mesh tessellation also in motion blur passes
            #define MOTIONBLUR_TESSELLATION
        #endif

        // Dependencies
        #ifdef MESH_TESSELLATION
            #define MESH_TESSELLATION_ENGINE
        #endif
        #ifndef NULL_RENDERER
            #ifdef WATER_TESSELLATION
                #define WATER_TESSELLATION_RENDERER
            #endif
            #ifdef MESH_TESSELLATION_ENGINE
                #define MESH_TESSELLATION_RENDERER
            #endif

            #if defined(WATER_TESSELLATION_RENDERER) || defined(MESH_TESSELLATION_RENDERER)
                // Common tessellation flag enabling tessellation stages in renderer
                #define TESSELLATION_RENDERER
            #endif
        #endif // !NULL_RENDERER
    #endif // TESSELLATION
#endif // !defined(MOBILE)

//------------------------------------------------------
// SVO GI
//------------------------------------------------------
// Modules   : Renderer, Engine
// Platform  : DX11
#if !defined(RENDERNODES_LEAN_AND_MEAN)
    #if PROJECTDEFINES_H_TRAIT_USE_SVO_GI
        #define FEATURE_SVO_GI
    #endif
#endif

#if defined(ENABLE_PROFILING_CODE)
    #define USE_DISK_PROFILER
#endif

// The maximum number of joints in an animation
#define MAX_JOINT_AMOUNT 1024
