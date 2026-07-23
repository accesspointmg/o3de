#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_TARGET_PROPERTIES
    BUILD_RPATH @executable_path/
)

# Add resources and app icons to launchers
list(APPEND candidate_paths ${project_real_path}/Resources/Platform/Mac)
list(APPEND candidate_paths ${project_real_path}/Gem/Resources/Platform/Mac) # Legacy projects
list(APPEND candidate_paths ${project_real_path}/Gem/Resources/MacLauncher) # Legacy projects
foreach(resource_path IN LISTS candidate_paths)
    if(EXISTS ${resource_path})
        set(o3de_game_resource_folder ${resource_path})
        break()
    endif()
endforeach()

if(NOT EXISTS ${o3de_game_resource_folder})
    list(JOIN candidate_paths " " formatted_error)
    message(FATAL_ERROR "Missing 'Resources' folder. Candidate paths tried were: ${formatted_error}")
endif()


target_sources(${project_name}.GameLauncher PRIVATE ${o3de_game_resource_folder}/Images.xcassets)
set_target_properties(${project_name}.GameLauncher PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${o3de_game_resource_folder}/Info.plist
    RESOURCE ${o3de_game_resource_folder}/Images.xcassets
    XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME ${project_name}AppIcon
)

set(layout_tool_dir ${O3DE_ENGINE_PATH}/cmake/Tools)

add_custom_command(TARGET ${project_name}.GameLauncher POST_BUILD
    COMMAND ${O3DE_PYTHON_CMD} layout_tool.py
        -p Mac
        -a ${O3DE_ASSET_DEPLOY_ASSET_TYPE}
        --project-path ${project_real_path}
        -m ${O3DE_ASSET_DEPLOY_MODE}
        --create-layout-root
        -l $<TARGET_BUNDLE_DIR:${project_name}.GameLauncher>/Contents/Resources/assets
        --build-config $<CONFIG>
        --warn-on-missing-assets
        --verify
        ${O3DE_OVERRIDE_PAK_ARGUMENT}
    WORKING_DIRECTORY ${layout_tool_dir}
    COMMENT "Synchronizing Layout Assets ..."
    VERBATIM
)
