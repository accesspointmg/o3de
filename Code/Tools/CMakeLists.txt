#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

add_subdirectory(SceneAPI) # Needs to go before AssetProcessor since it provides a builder
add_subdirectory(AssetProcessor)
add_subdirectory(AWSNativeSDKInit)
add_subdirectory(AzTestRunner)
add_subdirectory(CrashHandler)
add_subdirectory(PythonBindingsExample)
add_subdirectory(RemoteConsole)
add_subdirectory(DeltaCataloger)
add_subdirectory(SerializeContextTools)
add_subdirectory(AssetBundler)
add_subdirectory(LuaIDE)
add_subdirectory(TestImpactFramework)
# ProjectManager retired: replaced by o3de-pilot (its python bindings depended
# on the object-management scripts now owned by o3de-cli)
add_subdirectory(BundleLauncher)
add_subdirectory(Android)
