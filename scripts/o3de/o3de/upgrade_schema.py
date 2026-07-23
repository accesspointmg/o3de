#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
"""
This file contains all the code that has to do with upgrading o3de object json files
"""

import argparse
import logging
import json
import os
import pathlib
import sys
import urllib.parse
import urllib.request
import shutil
from datetime import datetime, timezone
from urllib.parse import urlparse
from o3de import o3de_object, repo, utils, validation, compatibility, cmake, schema, cache

logging.basicConfig(format=utils.LOG_FORMAT)
logger = logging.getLogger('o3de.upgrade_schema')
logger.setLevel(logging.INFO)

def is_reverse_domain_format(name: str) -> bool:
    if not name or name.count('.') < 2:
        return False
    
    # Common TLDs that might appear as first segment
    tlds = {'org', 'com', 'net', 'edu', 'gov', 'io'}
    
    # Check if first segment is a TLD and name is lowercase
    first_segment = name.split('.')[0]
    return first_segment in tlds and name.islower()

def is_valid_canonical_tag(tag: str) -> bool:
    valid_tags = {
        "Engine",
        "Project", 
        "Gem",
        "Template",
        "Repo",
        "Restricted",
        "Extension"
    }
    return tag in valid_tags

def is_valid_canonical_tag(tag: str) -> bool:
    canonical_mapping = {
        "engine": "Engine",
        "project": "Project",
        "gem": "Gem",
        "template": "Template",
        "repo": "Repo",
        "restricted": "Restricted"
    }
    return tag.lower() in canonical_mapping

def get_canonical_tag(tag: str) -> str:
    canonical_mapping = {
        "engine": "Engine",
        "project": "Project",
        "gem": "Gem",
        "template": "Template",
        "repo": "Repo",
        "restricted": "Restricted"
    }
    return canonical_mapping.get(tag.lower())

def upgrade_0_0_0_to_1_0_0(json_path, input_data) -> tuple[int, dict]:
    """
    Updates a o3de object json from 0.0.0 -> 1.0.0   

    :return: 0 for success or non 0 failure code
    """
    result = 0

    # Create new dict with schema version first
    output_data = {
        '$schemaVersion': '1.0.0',        
    }
    if 'o3de_manifest_name' in input_data:
        output_data['o3de_manifest_name'] = input_data['o3de_manifest_name']
        output_data['default_engines_folder'] = input_data.get('default_engines_folder', o3de_object.get_user_o3de_engines_path().as_posix())
        output_data['default_projects_folder'] = input_data.get('default_projects_folder', o3de_object.get_user_o3de_projects_path().as_posix())
        output_data['default_gems_folder'] = input_data.get('default_gems_folder', o3de_object.get_user_o3de_gems_path().as_posix())
        output_data['default_templates_folder'] = input_data.get('default_templates_folder', o3de_object.get_user_o3de_templates_path().as_posix())
        output_data['default_restricted_folder'] = input_data.get('default_restricted_folder', o3de_object.get_user_o3de_restricteds_path().as_posix())
        output_data['default_repos_folder'] = input_data.get('default_repos_folder', o3de_object.get_user_o3de_repos_path().as_posix())
        output_data['default_third_party_folder'] = input_data.get('default_third_party_folder', o3de_object.get_user_o3de_third_party_path().as_posix())

    elif 'engine_name' in input_data:
        output_data['engine_name'] = input_data['engine_name']
        if 'engine_uri' in input_data or 'engine_url' in input_data or 'url' in input_data or 'uri' in input_data:
            output_data['engine_uri'] = input_data.get('engine_uri', input_data.get('engine_url', input_data.get('url', input_data.get('uri', ""))))
        if 'engine_type' in input_data or 'type' in input_data:
            output_data['engine_type'] = input_data.get('engine_type', input_data.get('type', ""))
        if 'O3DEVersion' in input_data:
            output_data['O3DEVersion'] = input_data['O3DEVersion']
        if 'O3DEBuildNumber' in input_data:
            output_data['O3DEBuildNumber'] = input_data['O3DEBuildNumber']

    elif 'project_name' in input_data:
        output_data['project_name'] = input_data['project_name']
        if 'project_uri' in input_data or 'project_url' in input_data or 'url' in input_data or 'uri' in input_data:
            output_data['project_uri'] = input_data.get('project_uri', input_data.get('project_url', input_data.get('url', input_data.get('uri', ""))))
        if 'project_type' in input_data or 'type' in input_data:
            output_data['project_type'] = input_data.get('project_type', input_data.get('type', ""))
        if 'project_id' in input_data:
            output_data['project_id'] = input_data['project_id']
        if 'product_name' in input_data:
            output_data['product_name'] = input_data['product_name']
        if 'executable_name' in input_data:
            output_data['executable_name'] = input_data['executable_name']
        if 'engine' in input_data:
            output_data['engine'] = input_data['engine']

    elif 'gem_name' in input_data:
        output_data['gem_name'] = input_data['gem_name']
        if 'gem_uri' in input_data or 'gem_url' in input_data or 'url' in input_data or 'uri' in input_data:
            output_data['gem_uri'] = input_data.get('gem_uri', input_data.get('gem_url', input_data.get('url', input_data.get('uri', ""))))
        if 'gem_type' in input_data or 'type' in input_data:
            output_data['gem_type'] = input_data.get('gem_type', input_data.get('type', ""))

    elif 'template_name' in input_data:
        output_data['template_name'] = input_data['template_name']
        if 'template_uri' in input_data or 'template_url' in input_data or 'url' in input_data or 'uri' in input_data:
            output_data['template_uri'] = input_data.get('template_uri', input_data.get('template_url', input_data.get('url', input_data.get('uri', ""))))
        if 'template_type' in input_data or 'type' in input_data:
            output_data['template_type'] = input_data.get('template_type', input_data.get('type', ""))

    elif 'repo_name' in input_data:
        output_data['repo_name'] = input_data['repo_name']
        if 'repo_uri' in input_data or 'repo_url' in input_data or 'url' in input_data or 'uri' in input_data:
            output_data['repo_uri'] = input_data.get('repo_uri', input_data.get('repo_url', input_data.get('url', input_data.get('uri', ""))))
        if 'repo_type' in input_data or 'type' in input_data:
            output_data['repo_type'] = input_data.get('repo_type', input_data.get('type', ""))

    elif 'restricted_name' in input_data:
        output_data['restricted_name'] = input_data['restricted_name']
        if 'restricted_uri' in input_data or 'restricted_url' in input_data or 'url' in input_data or 'uri' in input_data:
            output_data['restricted_uri'] = input_data.get('restricted_uri', input_data.get('restricted_url', input_data.get('url', input_data.get('uri', ""))))
        if 'restricted_type' in input_data or 'type' in input_data:
            output_data['restricted_type'] = input_data.get('restricted_type', input_data.get('type', ""))
        output_data['extends'] = input_data.get('extends', '')
        output_data['precedence'] = input_data.get('precedence', 0)
        output_data['platform_maps'] = input_data.get('platform_maps', [])
        output_data['platform_wart_maps'] = input_data.get('platform_wart_maps', [])

    if 'o3de_manifest_name' not in input_data:
        output_data['version'] = input_data.get('version', '0.0.0')
        output_data['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['summary'] = input_data.get('summary', input_data.get('description', input_data.get('display_name', input_data.get('name', ""))))

        if 'last_updated' in input_data:
            output_data['last_updated'] = input_data['last_updated']
        else:
            output_data['last_updated'] = datetime.now(timezone.utc).isoformat()

        if 'origin' in input_data:
            output_data['origin'] = input_data['origin']
        if 'origin_name' in input_data:
            output_data['origin_name'] = input_data['origin_name']
        if 'origin_url' in input_data or 'origin_uri' in input_data:
            output_data['origin_url'] = input_data.get('origin_url', input_data.get('origin_uri', ''))

        if 'copyright' in input_data:
            output_data['copyright'] = input_data['copyright']
        elif 'copyright_text' in input_data:
            output_data['copyright_text'] = input_data['copyright_text']

        if 'copyright_year' in input_data:
            output_data['copyright_year'] = input_data['copyright_year']
        
        if 'modules' in input_data:
            output_data['modules'] = input_data['modules']
        if 'additional_info' in input_data:
            output_data['additional_info'] = input_data['additional_info']
        if 'last_updated' in input_data:
            output_data['last_updated'] = input_data['last_updated']
        if 'sha256' in input_data:
            output_data['sha256'] = input_data['sha256'],
        if 'api_version' in input_data:
            output_data['api_version'] = input_data['api_version'],

        if 'canonical_tags' in input_data:
            output_data['canonical_tags'] = input_data['canonical_tags']
        if 'user_tags' in input_data:
            output_data['user_tags'] = input_data['user_tags']
        if 'type' in input_data:
            output_data['type'] = input_data['type']

        if 'icon_path' in input_data:
            output_data['icon_path'] = input_data['icon_path']
        if 'icon_url' in input_data or 'icon_uri' in input_data:
            output_data['icon_url'] = input_data.get('icon_url', input_data.get('icon_uri', ''))

        if 'requirements' in input_data:
            output_data['requirements'] = input_data.get('requirements', '')

        if 'documentation_path' in input_data:
            output_data['documentation_path'] = input_data['documentation_path'],
        if 'documentation_url' in input_data or 'documentation_uri' in input_data:
            output_data['documentation_url'] = input_data.get('documentation_url', input_data.get('documentation_uri', ''))

        if 'dependencies' in input_data:
            output_data['dependencies'] = input_data['dependencies']

        if 'api_versions' in input_data:
            output_data['api_versions'] = input_data['api_versions']

        if 'file_version' in input_data:
            output_data['file_version'] = input_data['file_version']

        if 'build' in input_data:
            output_data['build'] = input_data['build']

        if 'gem_names' in input_data:
            output_data['gem_names'] = input_data['gem_names']

    if 'engines' in input_data:
        output_data['engines'] = input_data['engines']
    if 'engines_path' in input_data:
        output_data['engines_path'] = input_data['engines_path']
    if 'projects' in input_data:
        output_data['projects'] = input_data['projects']
    if 'gems' in input_data:
        output_data['gems'] = input_data['gems']
    if 'external_subdirectories' in input_data:
        output_data['external_subdirectories'] = input_data['external_subdirectories']
    if 'templates' in input_data:
        output_data['templates'] = input_data['templates']
    if 'repos' in input_data:
        output_data['repos'] = input_data['repos']
    if 'restricteds' in input_data:
        output_data['restricteds'] = input_data['restricteds']
    if 'restricted' in input_data:
        output_data['restricted'] = input_data['restricted']

    if 'copyFiles' in input_data:
        output_data['copyFiles'] = input_data['copyFiles']
    if 'createDirectories' in input_data:
        output_data['createDirectories'] = input_data['createDirectories']

    if 'restricted_platform_relative_path' in input_data:
        output_data['restricted_platform_relative_path'] = input_data['restricted_platform_relative_path']
    if 'template_restricted_platform_relative_path' in input_data:
        output_data['template_restricted_platform_relative_path'] = input_data['template_restricted_platform_relative_path']

    if 'source_control_uri' in input_data:
        output_data['source_control_uri'] = input_data['source_control_uri']
    if 'source_control_path' in input_data:
        output_data['source_control_path'] = input_data['source_control_path']
    if 'source_control_branch' in input_data:
        output_data['source_control_branch'] = input_data['source_control_branch']
    if 'source_control_tag' in input_data:
        output_data['source_control_tag'] = input_data['source_control_tag']
    if 'versions_data' in input_data:
        output_data['versions_data'] = input_data['versions_data']
    if 'platforms' in input_data:
        output_data['platforms'] = input_data['platforms']
    if 'compatible_engines' in input_data:
        output_data['compatible_engines'] = input_data['compatible_engines']

    if 'download_source_uri' in input_data:
        output_data['download_source_uri'] = input_data['download_source_uri']

    if 'engine_api_dependencies' in input_data:
        output_data['engine_api_dependencies'] = input_data['engine_api_dependencies']

    if 'downloads' in input_data:
        output_data['downloads'] = input_data['downloads']
    if 'source_control' in input_data:
        output_data['source_control'] = input_data['source_control']
    if 'releases' in input_data:
        output_data['releases'] = input_data['releases']

    return 0, output_data

def upgrade_1_0_0_to_2_0_0(input_json_path, input_data) -> tuple[int, dict]:
    """
    Updates a o3de object json from 1.0.0 -> 2.0.0   

    :return: 0 for success or non 0 failure code
    """
    output_data = {
        '$schemaVersion': '2.0.0',
    }

    # Find first non-repo URL in any field
    reversed_domain = 'org.o3de'  # default fallback
    if 'o3de_manifest_name' in input_data:
        if is_reverse_domain_format(input_data.get("o3de_manifest_name")) == False:
            reversed_domain = 'me.home'

    is_o3de = False

    is_manifest = False
    is_engine = False
    is_project = False
    is_gem = False
    is_template = False
    is_repo = False
    is_restricted = False

    if 'o3de_manifest_name' in input_data:
        is_manifest = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-manifest-2.0.0.json"
        output_data['o3de_manifest'] = {}
        if is_reverse_domain_format(input_data['o3de_manifest_name']):
            output_data['o3de_manifest']['name'] = input_data['o3de_manifest_name'].lower()
        else:
            output_data['o3de_manifest']['name'] = f"{reversed_domain}.manifest.{input_data.get('o3de_manifest_name', '')}".lower()
        
        if 'country' in input_data:
            output_data['country'] = input_data['country']
        else:
            output_data['country'] = {
                'code': utils.determine_country_code()
            }

        output_data['default'] = {
            'engines_path': input_data.get('default_engines_folder', o3de_object.get_user_o3de_engines_path().as_posix()),
            'projects_path': input_data.get('default_projects_folder', o3de_object.get_user_o3de_projects_path().as_posix()),
            'gems_path': input_data.get('default_gems_folder', o3de_object.get_user_o3de_gems_path().as_posix()),
            'templates_path': input_data.get('default_templates_folder', o3de_object.get_user_o3de_templates_path().as_posix()),
            'repos_path': input_data.get('default_repos_folder', o3de_object.get_user_o3de_repos_path().as_posix()),
            'restricteds_path': input_data.get('default_restricted_folder', input_data.get('default_restricteds_folder', o3de_object.get_user_o3de_restricteds_path().as_posix())),
            'third_party_path': input_data.get('default_third_party_folder', o3de_object.get_user_o3de_third_party_path().as_posix())
        }

    elif 'engine_name' in input_data:
        is_engine = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-engine-2.0.0.json"
        output_data['engine'] = {}
        if is_reverse_domain_format(input_data.get("engine_name")):
            output_data['engine']['name'] = input_data.get('engine_name', '').lower()
        else:
            output_data['engine']['name'] = f"{reversed_domain}.engine.{input_data.get('engine_name', '')}".lower()
            is_o3de = True
        output_data['engine']['version'] = input_data.get('version', '0.0.0')
        output_data['engine']['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['engine']['description'] = input_data.get('description', input_data.get('summary', input_data.get('display_name', input_data.get('name', ""))))
        output_data['engine']['type'] = input_data.get('engine_type', input_data.get('type', "")).lower()
        output_data['engine']['id'] = input_data.get('engine_id', "")
        output_data['engine']['copyright_year'] = input_data.get('copyright_year', "")
        output_data['engine']['copyright_text'] = input_data.get('copyright_text', input_data.get('copyright', ""))
        output_data['api_versions'] = input_data.get('api_versions', [])
        output_data['O3DEVersion'] = input_data.get('O3DEVersion', "")
        output_data['O3DEBuildNumber'] = input_data.get('O3DEBuildNumber', "")
        output_data['file_version'] = input_data.get('file_version', "")
        output_data['build'] = input_data.get('build', "")
        cmake_config_path = pathlib.Path(input_json_path).parent / f"{output_data['engine']['name']}Config.cmake"
        if not cmake_config_path.exists():
            # add a default cmake config file
            with open(cmake_config_path, 'w') as f:
                if is_o3de:
                    f.write('#\n')
                    f.write('# Copyright (c) Contributors to the Open 3D Engine Project.\n')
                    f.write('# For complete copyright and license terms please see the LICENSE at the root of this distribution.\n')
                    f.write('#\n')
                    f.write('# SPDX-License-Identifier: Apache-2.0 OR MIT\n')
                    f.write('#\n')
                    f.write('#\n')
                    f.write('\n')
                f.write('include(FindPackageHandleStandardArgs)\n')
                f.write('get_filename_component(engine_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)\n')
                f.write('get_property(engine_name GLOBAL PROPERTY "O3DE_PATH_${engine_path}/engine.json_NAME")\n')
                f.write('get_property(engine_version GLOBAL PROPERTY "O3DE_PATH_${engine_path}/engine.json_VERSION")\n')
                f.write('find_package_handle_standard_args(${engine_name} REQUIRED_VARS gem_path gem_name VERSION_VAR engine_version)\n')
        cmake_config_version_path = pathlib.Path(input_json_path).parent / f"{output_data['engine']['name']}ConfigVersion.cmake"
        if not cmake_config_version_path.exists():
            # add a default cmake config file
            with open(cmake_config_version_path, 'w') as f:
                if is_o3de:
                    f.write('#\n')
                    f.write('# Copyright (c) Contributors to the Open 3D Engine Project.\n')
                    f.write('# For complete copyright and license terms please see the LICENSE at the root of this distribution.\n')
                    f.write('#\n')
                    f.write('# SPDX-License-Identifier: Apache-2.0 OR MIT\n')
                    f.write('#\n')
                    f.write('#\n')
                    f.write('\n')
                f.write(f'# This file is included by find_package({output_data["engine"]["name"]} CONFIG) and will set PACKAGE_VERSION_COMPATIBLE\n')
                f.write('# to TRUE or FALSE based on whether the requested version is compatible with this engine.\n')
                f.write('# This file also sets PACKAGE_VERSION and PACKAGE_VERSION_EXACT if it can determine\n')
                f.write('# that information from the engine.json.\n')
                f.write('set(PACKAGE_VERSION_COMPATIBLE FALSE)\n')
                f.write('set(PACKAGE_VERSION_EXACT FALSE)\n')
                f.write('get_filename_component(engine_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)\n')
                f.write('get_property(engine_name GLOBAL PROPERTY "O3DE_PATH_${engine_path}/engine.json_NAME")\n')
                f.write('get_property(engine_version GLOBAL PROPERTY "O3DE_PATH_${engine_path}/engine.json_VERSION")\n')
                f.write('set(PACKAGE_VERSION ${engine_version})\n')
                f.write('if(NOT PACKAGE_FIND_VERSION)\n')
                f.write('    set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('    return()\n')
                f.write('endif()\n')
                f.write('if(PACKAGE_FIND_VERSION_EXACT)\n')
                f.write('    # Exact version match required\n')
                f.write('    if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('        set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('        set(PACKAGE_VERSION_EXACT TRUE)\n')
                f.write('    endif()\n')
                f.write('else()\n')
                f.write('    # Compatible version (requested version >= actual version)\n')
                f.write('    if(PACKAGE_VERSION VERSION_GREATER_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('        set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('        # Check if it\'s an exact match\n')
                f.write('        if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('            set(PACKAGE_VERSION_EXACT TRUE)\n')
                f.write('        endif()\n')
                f.write('    endif()\n')
                f.write('endif()\n')
                f.write('# Debug output\n')
                f.write('if(PACKAGE_VERSION_COMPATIBLE)\n')
                f.write('    message(VERBOSE "The engine \'${engine_name}\' version \'${engine_version}\' at \'${engine_path}\' is compatible with requested version \'${PACKAGE_FIND_VERSION}\'")\n')
                f.write('else()\n')
                f.write('    message(VERBOSE "The engine \'${engine_name}\' version \'${engine_version}\' at \'${engine_path}\' is NOT compatible with requested version \'${PACKAGE_FIND_VERSION}\'")\n')
                f.write('endif()\n')

    elif 'project_name' in input_data:
        is_project = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-project-2.0.0.json"
        output_data['project'] = {}
        if is_reverse_domain_format(input_data.get("project_name")):
            output_data['project']['name'] = input_data.get('project_name', '').lower()
        else:
            output_data['project']['name'] = f"{reversed_domain}.project.{input_data.get('project_name', '')}".lower()
            is_o3de = True
        output_data['project']['version'] = input_data.get('version', '0.0.0')
        output_data['project']['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['project']['description'] = input_data.get('description', input_data.get('summary', input_data.get('display_name', input_data.get('name', ""))))
        output_data['project']['type'] = input_data.get('project_type', input_data.get('type', "")).lower()
        output_data['project']['id'] = input_data.get('project_id', "")
        output_data['project']['copyright_year'] = input_data.get('copyright_year', "")
        output_data['project']['copyright_text'] = input_data.get('copyright_text', input_data.get('copyright', ""))
        output_data['product_name'] = input_data.get('product_name', "")
        output_data['executable_name'] = input_data.get('executable_name', "")
        output_data['engine'] = input_data.get('engine', "")
        cmake_config_path = pathlib.Path(input_json_path).parent / f"{output_data['project']['name']}Config.cmake"
        if not cmake_config_path.exists():
            # add a default project find file
            with open(cmake_config_path, 'w') as f:
                if is_o3de:
                    f.write('#\n')
                    f.write('# Copyright (c) Contributors to the Open 3D Engine Project.\n')
                    f.write('# For complete copyright and license terms please see the LICENSE at the root of this distribution.\n')
                    f.write('#\n')
                    f.write('# SPDX-License-Identifier: Apache-2.0 OR MIT\n')
                    f.write('#\n')
                    f.write('#\n')
                    f.write('\n')
                f.write('include(FindPackageHandleStandardArgs)\n')
                f.write('get_filename_component(project_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)\n')
                f.write('get_property(project_name GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_NAME")\n')
                f.write('get_property(project_version GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_VERSION")\n')
                f.write('find_package_handle_standard_args(${project_name} REQUIRED_VARS project_path project_name VERSION_VAR project_version)\n')
        cmake_config_version_path = pathlib.Path(input_json_path).parent / f"{output_data['project']['name']}ConfigVersion.cmake"
        if not cmake_config_version_path.exists():
            # add a default cmake config file
            with open(cmake_config_version_path, 'w') as f:
                if is_o3de:
                    f.write('#\n')
                    f.write('# Copyright (c) Contributors to the Open 3D Engine Project.\n')
                    f.write('# For complete copyright and license terms please see the LICENSE at the root of this distribution.\n')
                    f.write('#\n')
                    f.write('# SPDX-License-Identifier: Apache-2.0 OR MIT\n')
                    f.write('#\n')
                    f.write('#\n')
                    f.write('\n')
                f.write(f'# This file is included by find_package({output_data["project"]["name"]} CONFIG) and will set PACKAGE_VERSION_COMPATIBLE\n')
                f.write('# to TRUE or FALSE based on whether the requested version is compatible with this project.\n')
                f.write('# This file also sets PACKAGE_VERSION and PACKAGE_VERSION_EXACT if it can determine\n')
                f.write('# that information from the project.json.\n')
                f.write('set(PACKAGE_VERSION_COMPATIBLE FALSE)\n')
                f.write('set(PACKAGE_VERSION_EXACT FALSE)\n')
                f.write('get_filename_component(project_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)\n')
                f.write('get_property(project_name GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_NAME")\n')
                f.write('get_property(project_version GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_VERSION")\n')
                f.write('set(PACKAGE_VERSION ${project_version})\n')
                f.write('if(NOT PACKAGE_FIND_VERSION)\n')
                f.write('    set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('    return()\n')
                f.write('endif()\n')
                f.write('if(PACKAGE_FIND_VERSION_EXACT)\n')
                f.write('    # Exact version match required\n')
                f.write('    if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('        set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('        set(PACKAGE_VERSION_EXACT TRUE)\n')
                f.write('    endif()\n')
                f.write('else()\n')
                f.write('    # Compatible version (requested version >= actual version)\n')
                f.write('    if(PACKAGE_VERSION VERSION_GREATER_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('        set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('        # Check if it\'s an exact match\n')
                f.write('        if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('            set(PACKAGE_VERSION_EXACT TRUE)\n')
                f.write('        endif()\n')
                f.write('    endif()\n')
                f.write('endif()\n')
                f.write('# Debug output\n')
                f.write('if(PACKAGE_VERSION_COMPATIBLE)\n')
                f.write('    message(VERBOSE "The project \'${project_name}\' version \'${project_version}\' at \'${project_path}\' is compatible with requested version \'${PACKAGE_FIND_VERSION}\'")\n')
                f.write('else()\n')
                f.write('    message(VERBOSE "The project \'${project_name}\' version \'${project_version}\' at \'${project_path}\' is NOT compatible with requested version \'${PACKAGE_FIND_VERSION}\'")\n')
                f.write('endif()\n')

    elif 'gem_name' in input_data:
        is_gem = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-gem-2.0.0.json"
        output_data['gem'] = {}
        if is_reverse_domain_format(input_data.get("gem_name")):
            output_data['gem']['name'] = input_data.get('gem_name', '').lower()
        else:
            output_data['gem']['name'] = f"{reversed_domain}.gem.{input_data.get('gem_name', '')}".lower()
            is_o3de = True
        output_data['gem']['version'] = input_data.get('version', '0.0.0')
        output_data['gem']['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['gem']['description'] = input_data.get('description', input_data.get('summary', input_data.get('display_name', input_data.get('name', ""))))
        output_data['gem']['type'] = input_data.get('gem_type', input_data.get('type', "")).lower()
        output_data['gem']['id'] = input_data.get('gem_id', "")
        output_data['gem']['copyright_year'] = input_data.get('copyright_year', "")
        output_data['gem']['copyright_text'] = input_data.get('copyright_text', input_data.get('copyright', ""))
        cmake_config_path = pathlib.Path(input_json_path).parent / f"{output_data['gem']['name']}Config.cmake"
        if not cmake_config_path.exists():
            # add a default gem find file
            with open(cmake_config_path, 'w') as f:
                if is_o3de:
                    f.write('#\n')
                    f.write('# Copyright (c) Contributors to the Open 3D Engine Project.\n')
                    f.write('# For complete copyright and license terms please see the LICENSE at the root of this distribution.\n')
                    f.write('#\n')
                    f.write('# SPDX-License-Identifier: Apache-2.0 OR MIT\n')
                    f.write('#\n')
                    f.write('#\n')
                    f.write('\n')
                f.write('include(FindPackageHandleStandardArgs)\n')
                f.write('get_filename_component(gem_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)\n')
                f.write('get_property(gem_name GLOBAL PROPERTY "O3DE_PATH_${gem_path}/gem.json_NAME")\n')
                f.write('get_property(gem_version GLOBAL PROPERTY "O3DE_PATH_${gem_path}/gem.json_VERSION")\n')
                f.write('find_package_handle_standard_args(${gem_name} REQUIRED_VARS gem_path gem_name VERSION_VAR gem_version)\n')
        cmake_config_version_path = pathlib.Path(input_json_path).parent / f"{output_data['gem']['name']}ConfigVersion.cmake"
        if not cmake_config_version_path.exists():
            # add a default cmake config file
            with open(cmake_config_version_path, 'w') as f:
                if is_o3de:
                    f.write('#\n')
                    f.write('# Copyright (c) Contributors to the Open 3D Engine Project.\n')
                    f.write('# For complete copyright and license terms please see the LICENSE at the root of this distribution.\n')
                    f.write('#\n')
                    f.write('# SPDX-License-Identifier: Apache-2.0 OR MIT\n')
                    f.write('#\n')
                    f.write('#\n')
                    f.write('\n')
                f.write(f'# This file is included by find_package({output_data["gem"]["name"]} CONFIG) and will set PACKAGE_VERSION_COMPATIBLE\n')
                f.write('# to TRUE or FALSE based on whether the requested version is compatible with this gem.\n')
                f.write('# This file also sets PACKAGE_VERSION and PACKAGE_VERSION_EXACT if it can determine\n')
                f.write('# that information from the gem.json.\n')
                f.write('set(PACKAGE_VERSION_COMPATIBLE FALSE)\n')
                f.write('set(PACKAGE_VERSION_EXACT FALSE)\n')
                f.write('get_filename_component(gem_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)\n')
                f.write('get_property(gem_name GLOBAL PROPERTY "O3DE_PATH_${gem_path}/gem.json_NAME")\n')
                f.write('get_property(gem_version GLOBAL PROPERTY "O3DE_PATH_${gem_path}/gem.json_VERSION")\n')
                f.write('set(PACKAGE_VERSION ${gem_version})\n')
                f.write('if(NOT PACKAGE_FIND_VERSION)\n')
                f.write('    set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('    return()\n')
                f.write('endif()\n')
                f.write('if(PACKAGE_FIND_VERSION_EXACT)\n')
                f.write('    # Exact version match required\n')
                f.write('    if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('        set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('        set(PACKAGE_VERSION_EXACT TRUE)\n')
                f.write('    endif()\n')
                f.write('else()\n')
                f.write('    # Compatible version (requested version >= actual version)\n')
                f.write('    if(PACKAGE_VERSION VERSION_GREATER_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('        set(PACKAGE_VERSION_COMPATIBLE TRUE)\n')
                f.write('        # Check if it\'s an exact match\n')
                f.write('        if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)\n')
                f.write('            set(PACKAGE_VERSION_EXACT TRUE)\n')
                f.write('        endif()\n')
                f.write('    endif()\n')
                f.write('endif()\n')
                f.write('# Debug output\n')
                f.write('if(PACKAGE_VERSION_COMPATIBLE)\n')
                f.write('    message(VERBOSE "The gem \'${gem_name}\' version \'${gem_version}\' at \'${gem_path}\' is compatible with requested version \'${PACKAGE_FIND_VERSION}\'")\n')
                f.write('else()\n')
                f.write('    message(VERBOSE "The gem \'${gem_name}\' version \'${gem_version}\' at \'${gem_path}\' is NOT compatible with requested version \'${PACKAGE_FIND_VERSION}\'")\n')
                f.write('endif()\n')
    
    elif 'template_name' in input_data:
        is_template = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-template-2.0.0.json"
        output_data['template'] = {}
        if is_reverse_domain_format(input_data.get("template_name")):
            output_data['template']['name'] = input_data.get('template_name', '').lower()
        else:
            output_data['template']['name'] = f"{reversed_domain}.template.{input_data.get('template_name', '')}".lower()
            is_o3de = True
        output_data['template']['version'] = input_data.get('version', '0.0.0')    
        output_data['template']['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['template']['description'] = input_data.get('description', input_data.get('summary', input_data.get('display_name', input_data.get('name', ""))))
        output_data['template']['type'] = input_data.get('template_type', input_data.get('type', "")).lower()
        output_data['template']['id'] = input_data.get('template_id', "")
        output_data['template']['copyright_year'] = input_data.get('copyright_year', "")
        output_data['template']['copyright_text'] = input_data.get('copyright_text', input_data.get('copyright', ""))
        output_data['copyFiles'] = input_data.get('copyFiles', [])
        output_data['createDirectories'] = input_data.get('createDirectories', [])

    elif 'repo_name' in input_data:
        is_repo = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-repo-2.0.0.json"
        output_data['repo'] = {}
        if is_reverse_domain_format(input_data.get("repo_name")):
            output_data['repo']['name'] = input_data.get('repo_name', '').lower()
        else:
            output_data['repo']['name'] = f"{reversed_domain}.repo.{input_data.get('repo_name', '')}".lower()
            is_o3de = True
        output_data['repo']['version'] = input_data.get('version', '0.0.0')
        output_data['repo']['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['repo']['description'] = input_data.get('description', input_data.get('summary', input_data.get('display_name', input_data.get('name', ""))))
        output_data['repo']['type'] = input_data.get('repo_type', input_data.get('type', "")).lower()
        output_data['repo']['id'] = input_data.get('repo_id', "")
        output_data['repo']['copyright_year'] = input_data.get('copyright_year', "")
        output_data['repo']['copyright_text'] = input_data.get('copyright_text', "")

    elif 'restricted_name' in input_data:
        is_restricted = True
        output_data["$schema"] = "https://canonical.o3de.org/o3de-restricted-2.0.0.json"
        output_data['restricted'] = {}
        if is_reverse_domain_format(input_data.get("restricted_name")):
            output_data['restricted']['name'] = input_data.get('restricted_name', '').lower()
        else:
            output_data['restricted']['name'] = f"{reversed_domain}.restricted.{input_data.get('restricted_name', '')}".lower()
            is_o3de = True
        output_data['restricted']['version'] = input_data.get('version', '0.0.0')
        output_data['extends'] = input_data.get('extends', '')
        output_data['platform_maps'] = input_data.get('platform_maps', [])
        output_data['platform_wart_maps'] = input_data.get('platform_wart_maps', [])
        output_data['precedence'] = input_data.get('precedence', 0)
        output_data['restricted']['display_name'] = input_data.get('display_name', input_data.get('name', ""))
        output_data['restricted']['description'] = input_data.get('description', input_data.get('summary', input_data.get('display_name', input_data.get('name', ""))))
        output_data['restricted']['type'] = input_data.get('restricted_type', input_data.get('type', "")).lower()
        output_data['restricted']['id'] = input_data.get('restricted_id', "")
        output_data['restricted']['copyright_year'] = input_data.get('copyright_year', "")
        output_data['restricted']['copyright_text'] = input_data.get('copyright_text', input_data.get('copyright', ""))


    # if it has no origin and is in the o3de directory then add the default o3de owned origin
    for field in ["engine_name", "gem_name", "project_name", "template_name", "repo_name", "restricted_name"]:
        if field in input_data:
            if "o3de" in input_data[field].lower():
                is_o3de = True
                break
    if 'origin' in input_data:
        if 'name' in input_data['origin']:
            if 'o3de.org' in input_data['origin']['name'].lower():
                is_o3de = True
        if 'uri' in input_data['origin']:
            if 'o3de.org' in input_data['origin']['uri'].lower():
                is_o3de = True

    add_origin = False
    if not is_manifest:
        output_data['origin'] = {}
        if 'origin' in input_data:
            output_data['origin']['name'] = input_data['origin']
        elif 'origin_name' in input_data:
            output_data['origin']['name'] = input_data['origin_name']

        if 'origin_uri' in input_data:
            output_data['origin']['uri'] = input_data['origin_uri']
        elif 'origin_url' in input_data:
            output_data['origin']['uri'] = input_data['origin_url']
        elif 'engine_uri' in input_data:
            output_data['origin']['uri'] = input_data['engine_uri']
        elif 'engine_url' in input_data:
            output_data['origin']['uri'] = input_data['engine_url']
        elif 'project_uri' in input_data:
            output_data['origin']['uri'] = input_data['project_uri']
        elif 'project_url' in input_data:
            output_data['origin']['uri'] = input_data['project_url']
        elif 'gem_uri' in input_data:
            output_data['origin']['uri'] = input_data['gem_uri']
        elif 'gem_url' in input_data:
            output_data['origin']['uri'] = input_data['gem_url']
        elif 'template_uri' in input_data:
            output_data['origin']['uri'] = input_data['template_uri']
        elif 'template_url' in input_data:
            output_data['origin']['uri'] = input_data['template_url']
        elif 'repo_uri' in input_data:
            output_data['origin']['uri'] = input_data['repo_uri']
        elif 'repo_url' in input_data:
            output_data['origin']['uri'] = input_data['repo_url']
        elif 'restricted_uri' in input_data:
            output_data['origin']['uri'] = input_data['restricted_uri']
        elif 'restricted_url' in input_data:
            output_data['origin']['uri'] = input_data['restricted_url']
        elif 'uri' in input_data:
            output_data['origin']['uri'] = input_data['uri']
        elif 'url' in input_data:
            output_data['origin']['uri'] = input_data['url']
        else:
            add_origin = True

        # special case o3de objects
        # if these fields are set to these values, then add the origin
        #   "origin": "Open 3D Engine - o3de.org",
        #   "origin_url": "https://github.com/o3de/o3de",
        if 'origin' in input_data:
            if 'o3de.org' in input_data.get('origin', '').lower():
                add_origin = True
                is_o3de = True
        if 'origin_url' in input_data or 'origin_uri' in input_data:
            if 'o3de.org' in input_data.get('origin_url', '').lower():
                add_origin = True
                is_o3de = True
            if 'o3de.org' in input_data.get('origin_uri', '').lower():
                add_origin = True
                is_o3de = True

        #if we dont have any of these, try to determine if this is an o3de object and add the default o3de origin
        if add_origin and is_o3de:
            output_data["origin"] = {
                "name": "The Linux Foundation",
                "uri": "https://www.linuxfoundation.org"
            }
        # if we still dont have an origin, then add the default unknown origin
        elif add_origin:
            output_data["origin"] = {
                "name": 'Unknown Origin/Author/Owner'
            }

        # if the license is not set
        add_licenses = False
        if 'license' in input_data:
            output_data['licenses'] = [
                {
                    'license_identifier': input_data.get('license', ''),
                    'uri': input_data.get('license_url', input_data.get('license_uri', '')),
                    'display_name': input_data.get('license', '').replace('-', ' ').replace('_', ' '),
                    'relative_path': input_data.get('license_path', '')
                }
            ]
        elif is_o3de:
            add_licenses = True

        # special case for o3de objects, they all have the same licenses
        if add_licenses and is_o3de:
            output_data["licenses"] = [
                {
                    "license_identifier": "Apache-2.0",
                    "uri": "https://spdx.org/licenses/Apache-2.0.html",
                    "display_name": "Apache 2.0",
                    "relative_path": "LICENSE_APACHE2.TXT",
                    "comments": [
                        "The licensee of this object has the choice of Apache-2.0 or MIT ",
                        "licenses for the code. See the LICENSE_APACHE2.TXT, LICENSE_MIT.TXT ",
                        "and LICENSE.TXT for more information."
                    ],
                    "scopes": [
                        "All source code"
                    ]
                },
                {
                    "license_identifier": "MIT",
                    "uri": "https://spdx.org/licenses/MIT.html",
                    "display_name": "MIT",
                    "relative_path": "LICENSE_MIT.TXT",
                    "comments": [
                        "The licensee of this object has the choice of Apache-2.0 or MIT ",
                        "licenses for the code. See the LICENSE_APACHE2.TXT, LICENSE_MIT.TXT ",
                        "and LICENSE.TXT for more information."
                    ],
                    "scopes": [
                        "All source code"
                    ]
                },
                {
                    "license_identifier": "CC0-1.0",
                    "uri": "https://spdx.org/licenses/CC0-1.0.html",
                    "display_name": "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication",
                    "relative_path": "LICENSE_CC0.TXT",
                    "comments": [
                        "All artistic assets in this object are released under the CC0 1.0 ",
                        "Universal (CC0 1.0) Public Domain Dedication license. For more ",
                        "information see the LICENSE_CC0.TXT file.",
                    ],
                    "scopes": [
                        "All assets"
                    ]
                },
                {
                    "license_identifier": "O3DE",
                    "display_name": "O3DE License",
                    "relative_path": "LICENSE.TXT",
                    "comments": [
                        "The O3DE License is a custom license for the Open 3D Engine. ",
                        "The LICENSE.TXT file contains the full text which describes ",
                        "It primarily describes how to find all third party license information."
                    ],
                    "scopes": [
                        "All third party"
                    ]
                }
            ]
        #if not then default to unknown license
        elif add_licenses:
            output_data["licenses"] = [
                {
                    "license_identifier": "Unknown",
                    "display_name": "Unknown",
                    "comments": [
                        "!!!DO NOT USE THIS OBJECT WITHOUT KNOWING THE LICENSE!!! ",
                        "Try to find the licensing information in the documentation of this object or ",
                        "try to contact the originator of this object and ask them to update license information."
                    ]
                }
            ]

        # handle the common fields if its not the manifest
        if not is_manifest:
            # Schema 2.0.0 uses canonical_tags and user_tags as top-level arrays
            output_data['canonical_tags'] = []
            output_data['user_tags'] = []
            
            if 'canonical_tags' in input_data:
                output_data['canonical_tags'] = [
                    get_canonical_tag(tag) for tag in input_data['canonical_tags'] if is_valid_canonical_tag(tag)
                ]
            if 'user_tags' in input_data:
                output_data['user_tags'] = input_data['user_tags']

            if is_engine:
                if 'Engine' not in output_data['canonical_tags']:
                    output_data['canonical_tags'].append(get_canonical_tag('engine'))
                if input_data['engine_name'] in output_data['user_tags']:
                    output_data['user_tags'].remove(input_data['engine_name'])
                if output_data['engine']['name'] not in output_data['user_tags']:
                    output_data['user_tags'].append(output_data['engine']['name'])
            elif is_project:
                if 'Project' not in output_data['canonical_tags']:
                    output_data['canonical_tags'].append(get_canonical_tag('project'))
                if input_data['project_name'] in output_data['user_tags']:
                    output_data['user_tags'].remove(input_data['project_name'])
                if output_data['project']['name'] not in output_data['user_tags']:
                    output_data['user_tags'].append(output_data['project']['name'])
            elif is_gem:
                if 'Gem' not in output_data['canonical_tags']:
                    output_data['canonical_tags'].append(get_canonical_tag('gem'))
                if input_data['gem_name'] in output_data['user_tags']:
                    output_data['user_tags'].remove(input_data['gem_name'])
                if output_data['gem']['name'] not in output_data['user_tags']:
                    output_data['user_tags'].append(output_data['gem']['name'])
            elif is_template:
                if 'Template' not in output_data['canonical_tags']:
                    output_data['canonical_tags'].append(get_canonical_tag('template'))
                if input_data['template_name'] in output_data['user_tags']:
                    output_data['user_tags'].remove(input_data['template_name'])
                if output_data['template']['name'] not in output_data['user_tags']:
                    output_data['user_tags'].append(output_data['template']['name'])
            elif is_repo:
                if 'Repo' not in output_data['canonical_tags']:
                    output_data['canonical_tags'].append(get_canonical_tag('repo'))
                if input_data['repo_name'] in output_data['user_tags']:
                    output_data['user_tags'].remove(input_data['repo_name'])
                if output_data['repo']['name'] not in output_data['user_tags']:
                    output_data['user_tags'].append(output_data['repo']['name'])
            elif is_restricted:
                if 'Restricted' not in output_data['canonical_tags']:
                    output_data['canonical_tags'].append(get_canonical_tag('restricted'))
                if input_data['restricted_name'] in output_data['user_tags']:
                    output_data['user_tags'].remove(input_data['restricted_name'])
                if output_data['restricted']['name'] not in output_data['user_tags']:
                    output_data['user_tags'].append(output_data['restricted']['name'])

            #remove duplicates
            output_data['canonical_tags'] = list(set(output_data['canonical_tags']))
            output_data['user_tags'] = list(set(output_data['user_tags']))
            
            output_data['icon'] = {
                'relative_path': input_data.get('icon_path', ''),
                'uri': input_data.get('icon_url', input_data.get('icon_uri', ''))
            }
        
            output_data['documentation'] = {
                'relative_path': input_data.get('documentation_path', ''),
                'uri': input_data.get('documentation_url', input_data.get('documentation_uri', ''))
            }

    # Only add non-empty lists to children
    children = {
        "engines": [],
        "projects": [],
        "gems": [],
        "templates": [],
        "repos": [],
        "restricteds": []
    }
    remote = {
        "engines": [],
        "projects": [],
        "gems": [],
        "templates": [],
        "repos": [],
        "restricteds": []
    }
    
    def _split_local_remote(collection):
        """Split a collection into local and remote items
        :param collection: List of items to split
        """
        local_items = []
        remote_items = []
        if collection:
            for item in collection:
                if isinstance(item, str) and (item.startswith('http://') or item.startswith('https://') or 
                                             item.startswith('ftp://') or item.startswith('ftps://')):
                    remote_items.append(item)
                else:
                    local_items.append(item)
        return local_items, remote_items
    
    def _process_remote_urls(remote_items, object_type, remote_dict):
        """
        Process remote URLs for a specific object type, trying different URI formats
        
        :param remote_items: List of remote URLs to process
        :param object_type: Type of object (engine, project, gem, etc.)
        :param remote_dict: Dictionary to update with the processed URLs
        """
        if not remote_items:
            return
            
        json_ext = f"{object_type}.json"
        processed_items = []
        
        for item in remote_items:
            # If the URI already ends with .git or the expected JSON file, keep it as is
            if item.endswith('.git') or item.endswith(json_ext):
                processed_items.append(item)
            else:
                # Try as git repo first
                git_url = o3de_object.sanitize_uri(item, ".git")
                try:
                    req = urllib.request.Request(git_url, method='HEAD')
                    with urllib.request.urlopen(req, timeout=5) as response:
                        if 200 <= response.status < 300:
                            processed_items.append(git_url)
                            continue
                except Exception as e:
                    logger.debug(f'Error checking URL {git_url}: {str(e)}')
                
                # If .git doesn't work, default to [type].json
                processed_items.append(o3de_object.sanitize_uri(item, json_ext))
        
        # Add processed items to remote dictionary
        remote_dict[f"{object_type}s"] = processed_items
        
    # Process engines
    if input_data.get('engines'):
        local_engines, remote_engines = _split_local_remote(input_data['engines'])
        if local_engines:
            children['engines'] = [o3de_object.sanitize_uri(engine, "engine.json") for engine in local_engines]
        if remote_engines:
            _process_remote_urls(remote_engines, 'engine', remote)

    # Process projects
    if input_data.get('projects'):
        local_projects, remote_projects = _split_local_remote(input_data['projects'])
        if local_projects:
            children['projects'] = [o3de_object.sanitize_uri(project, "project.json") for project in local_projects]
        if remote_projects:
            _process_remote_urls(remote_projects, 'project', remote)    

    # Process gems
    if input_data.get('gems'):
        local_gems, remote_gems = _split_local_remote(input_data['gems'])
        if local_gems:
            children['gems'] = [o3de_object.sanitize_uri(gem, "gem.json") for gem in local_gems]
        if remote_gems:
            _process_remote_urls(remote_gems, 'gem', remote)

    # Process templates
    if input_data.get('templates'):
        local_templates, remote_templates = _split_local_remote(input_data['templates'])
        if local_templates:
            children['templates'] = [o3de_object.sanitize_uri(template, "template.json") for template in local_templates]
        if remote_templates:
            _process_remote_urls(remote_templates, 'template', remote)

    # Process repos
    if input_data.get('repos'):
        local_repos, remote_repos = _split_local_remote(input_data['repos'])
        if local_repos:
            children['repos'] = [o3de_object.sanitize_uri(repo, "repo.json") for repo in local_repos]
        if remote_repos:
            _process_remote_urls(remote_repos, 'repo', remote)

    # Process restricted
    if input_data.get('restricted'):
        if isinstance(input_data.get('restricted'), list):
            local_restricteds, remote_restricteds = _split_local_remote(input_data['restricted'])
            if local_restricteds:
                children['restricteds'] = [o3de_object.sanitize_uri(restricted, "restricted.json") for restricted in local_restricteds]
            if remote_restricteds:
                _process_remote_urls(remote_restricteds, 'restricted', remote)
    
    if input_data.get('restricteds'):
        local_restricteds, remote_restricteds = _split_local_remote(input_data['restricteds'])
        if local_restricteds:
            children['restricteds'].extend([o3de_object.sanitize_uri(restricted, "restricted.json") for restricted in local_restricteds])
        if remote_restricteds:
            ext_remote = {}
            _process_remote_urls(remote_restricteds, 'restricted', ext_remote)
            remote['restricteds'].extend(ext_remote.get('restricteds', []))


    # Process external_subdirectories
    # Due to a misunderstanding of the original schema, gems were added to external_subdirectories
    # This functioned because technically all gems are external subdirectories, however not all external
    # subdirectories are gems. External subdirectories are any folder that is not an o3de object like a gem,
    # must have a CMakeLists.txt file in it. Any remote external subdirectory has to be a remote gem because
    # there is no such thing as a remote external directory. The local entries could be a gem, we can
    # check if the gem.json file exists and if it does, treat it as a local gem, if not it should just be
    # added to a CMakeLists.txt file using the add_subdirectory command. Therefore "external_subdirectories"
    # are removed in schema 2.0.0
    if input_data.get('external_subdirectories'):
        local_ext, remote_gems = _split_local_remote(input_data.get('external_subdirectories'))
        if local_ext:
            local_gems = []
            external_subdirectories = []
            for potential_gem in local_ext:
                potential_gem_path = pathlib.Path(input_json_path).parent / potential_gem
                potential_gem_path = o3de_object.sanitize_uri(potential_gem_path.as_posix(), "gem.json")
                if pathlib.Path(potential_gem_path).is_file():
                    local_gems.append(o3de_object.sanitize_uri(potential_gem, "gem.json"))
                else:
                    external_subdirectories.append(potential_gem)
                    logger.debug(f"Retaining 'external_subdirectory': {potential_gem}")
                    #replace the gem.json with a CMakeLists.txt file and see if that file exists
                    cmake_path = pathlib.Path(potential_gem_path).parent / 'CMakeLists.txt'
                    cmake_path = o3de_object.sanitize_uri(cmake_path.as_posix(), "CMakeLists.txt")
                    if pathlib.Path(cmake_path).is_file():
                        logger.debug(f"This should be removed and {cmake_path} should have a line added 'add_subdirectory({potential_gem_path})'")
                    else:
                        logger.debug(f"This should be removed and a CMakeLists.txt should have a line added 'add_subdirectory({potential_gem_path})'")
                        
            children['gems'].extend([o3de_object.sanitize_uri(gem, "gem.json") for gem in local_gems])

            #if external subdirectories is not empty, add it to the output data
            #the configure script will now error message you on finding "external_subdirectories" in your object json
            if external_subdirectories:
                output_data['external_subdirectories'] = external_subdirectories

        if remote_gems:
            ext_remote = {}
            _process_remote_urls(remote_gems, 'gem', ext_remote)
            remote['gems'].extend(ext_remote.get('gems', []))

    # If children/local is not empty add it to mapped_data
    # Manifests use 'local' with full paths, other objects use 'children' with relative paths
    if children:
        if is_manifest:
            output_data['local'] = children
        else:
            output_data['children'] = children
    # If remote is not empty add it to mapped_data
    if remote:
        output_data['remote'] = remote

    # we cannot use o3de_object.manifest.find_gem for this, it
    # needs to be an independent find because this happens before the manifest
    # is loaded 
    def _find_object_by_type_and_name(object_uri, target_type, target_name, traversed=None):
        """
        Find an O3DE object by its type and name, searching recursively through children and remotes.
        
        :param object_uri: Path to the JSON file to search
        :param target_type: Type of object to find ('engine', 'project', 'gem', etc.)
        :param target_name: Name of the object to find
        :param traversed: Set of paths already traversed to prevent cycles
        :return: Tuple of (path, json_data) if found, or (None, None) if not found
        """
        # Initialize traversed set if not provided
        if traversed is None:
            traversed = set()
        if object_uri in traversed:
            return None, None
        traversed.add(object_uri)

        # get the cache_file name for this uri and the parsed uri
        cache_file, parsed_uri = cache.get_cache_file_uri(object_uri)

        # allow the git provider to alter the parsed uri
        git_provider = utils.get_git_provider(parsed_uri)
        if git_provider:
            parsed_uri = git_provider.get_specific_file_uri(parsed_uri)

        # copy this file to the cache or download it if not local
        if o3de_object.is_local(object_uri):
            #remove the cache file if it exists
            if pathlib.Path(cache_file).is_file():
                pathlib.Path(cache_file).unlink()
            #copy the object_uri file over to cache
            if pathlib.Path(object_uri).is_file():
                # ensure the cache directory exists
                pathlib.Path(cache_file).parent.mkdir(parents=True, exist_ok=True)
                # copy the file to the cache
                shutil.copyfile(object_uri, cache_file)
        else:
                # download the parsed uri to the cache_file
                if pathlib.Path(cache_file).is_file():
                    # check if the file is older than 1 day
                    if (datetime.now(timezone.utc) - datetime.fromtimestamp(cache_file.stat().st_mtime, timezone.utc)).days > 1:
                        # download the file again
                        utils.download_file(parsed_uri, cache_file, True, object_uri)
                else:
                    # download the file
                    utils.download_file(parsed_uri, cache_file, True, object_uri)

        # load the object json data from the cache file
        if pathlib.Path(cache_file).is_file() == False:
            return None, None
        with pathlib.Path(cache_file).open('r') as f:
            try:
                json_data = json.load(f)
            except json.JSONDecodeError as e:
                logger.error(f'{cache_file} failed to load: {str(e)}')
                return None, None
            
        # get the schema version from the json data        
        schema_version = schema.get_schema_version(json_data)

        # check the type and name
        # the file name is just the type with .json extension
        file_name = f'{target_type}.json'
        if file_name == pathlib.Path(object_uri).name:
            if schema_version >= schema.VERSION_2_0_0:
                # For schema 2.0.0+, objects are stored in fields like 'engine.name', 'project.name', etc.
                object_field = json_data.get(target_type)
                if object_field and object_field.get('name') == target_name:
                    return object_uri, json_data
            else:
                # For schema 1.0.0 or older, check fields like 'engine_name', 'project_name', etc.
                name_field = f"{target_type}_name"
                if name_field in json_data and json_data[name_field] == target_name:
                    return object_uri, json_data

        # Not a match, search in children and remote collections
        if schema_version >= schema.VERSION_2_0_0:
            # Check children collection
            children = json_data.get('children', {})
            for collection_name, paths in children.items():
                for child_path in paths:
                    # children can be relative paths
                    if not pathlib.Path(child_path).is_absolute():
                        child_path = pathlib.Path(object_uri).parent / child_path
                        child_path = o3de_object.sanitize_uri(child_path, f'{collection_name}.json')
                        child_path = pathlib.Path(child_path).as_posix()
                    result_path, result_data = _find_object_by_type_and_name(child_path, target_type, target_name, traversed)
                    if result_path:
                        return result_path, result_data
            
            # Check remote collection
            remote = json_data.get('remote', {})
            for collection_name, urls in remote.items():
                for remote_url in urls:
                    # For remote URLs, check if we have a cached version
                    remote_url = o3de_object.sanitize_uri(remote_url, f'{collection_name}.json')
                    cache_file, parsed_uri = cache.get_cache_file_uri(remote_url)
                    if cache_file and cache_file.exists():
                        cache_file = cache_file.as_posix()
                        result_path, result_data = _find_object_by_type_and_name(cache_file, target_type, target_name, cache, traversed)
                        if result_path:
                            return result_path, result_data
        else:
            # For older schema versions, check the direct collections
            collections = {
                'engines': 'engine',
                'projects': 'project',
                'gems': 'gem',
                'external_subdirectories': 'gem',
                'templates': 'template',
                'repos': 'repo',
                'restricteds': 'restricted'
            }
            for json_name, o3de_type in collections.items():
                if json_name in json_data:
                    file_name = f'{o3de_type}.json'
                    for item_path in json_data[json_name]:
                        # Handle relative paths
                        item_path = o3de_object.sanitize_uri(item_path, file_name)
                        item_path = pathlib.Path(item_path).as_posix()
                        if o3de_object.is_local(item_path):
                            if not pathlib.Path(item_path).is_absolute():
                                item_path = pathlib.Path(object_uri).parent / item_path
                                item_path = item_path.as_posix()
                        # For remote URLs, check if we have a cached version
                        elif o3de_object.is_remote(item_path):
                            remote_url = o3de_object.sanitize_uri(item_path, file_name)
                            remote_url = pathlib.Path(remote_url).as_posix()
                            cache_file, parsed_uri = cache.get_cache_file_uri(remote_url)
                            if cache_file and cache_file.exists():
                                item_path = cache_file
                                item_path = item_path.as_posix()
                        
                        result_path, result_data = _find_object_by_type_and_name(item_path, target_type, target_name, traversed)
                        if result_path:
                            return result_path, result_data
        
        # If we got here, the object wasn't found
        return None, None

    def _get_restricted_version(restricted_name):
        # load the o3de_manifest.json file
        manifest_path = o3de_object.get_user_o3de_manifest_path().as_posix()

        # Read restricted.json from the restricted path
        restricted_path, restricted_json_data = _find_object_by_type_and_name(manifest_path, "restricted", restricted_name)
        if not restricted_json_data:
            logger.error(f'Could not read restricted.json content under {restricted_path}.')
            return '0.0.0'

        # include the version specifier if provided e.g. restricted==1.2.3
        return restricted_json_data['version'] or '0.0.0'

    def _get_gem_version(gem_name):
        # load the o3de_manifest.json file
        manifest_path = o3de_object.get_user_o3de_manifest_path().as_posix()

        # Read gem.json from the gem path
        gem_path, gem_json_data = _find_object_by_type_and_name(manifest_path, "gem", gem_name)
        if not gem_json_data:
            logger.error(f'Could not read gem.json content under {gem_path}.')
            return '0.0.0'

        # include the version specifier if provided e.g. gem==1.2.3
        return gem_json_data['version'] or '0.0.0'


    def _get_engine_version(engine_name):
        # load the o3de_manifest.json file
        manifest_path = o3de_object.get_user_o3de_manifest_path().as_posix()

        # Read engine.json from the engine path
        engine_path, engine_json_data = _find_object_by_type_and_name(manifest_path, "engine", engine_name)
        if not engine_json_data:
            logger.error(f'Could not read engine.json content under {engine_path}.')
            return '0.0.0'

        # include the version specifier if provided e.g. engine==1.2.3
        return engine_json_data['version'] or '0.0.0'

    
    if not is_manifest:
        # if it a project and the project specifies an engine...
        # Note: It is better that a project does not specify an engine, in that case we default to /user/engine.json override
        # should be generated and 'engine' should be set to 'org.o3de.engine.o3de>=1.0.0'
        if is_project:
            if 'engine' in input_data:
                if utils.has_version_specifier(input_data['engine']) or is_reverse_domain_format(input_data['engine']):
                    output_data['engine'] = input_data['engine']
                #special cases
                elif input_data['engine'] == 'o3de':
                    output_data['engine'] = 'org.o3de.engine.o3de>=1.0.0'
                elif input_data['engine'] == 'o3de-sdk':
                    output_data['engine'] = 'org.o3de.engine.o3de-sdk>=1.0.0'
                else:
                    output_data['engine'] = f'org.o3de.engine.{input_data["engine"]}>={_get_engine_version(input_data["engine"])}'.lower()

        # gem_names, dependencies => dependent
        #all dependencies as of 1.0.0 are gems, so 'gem_names' and 'dependencies' are combined
        dependent = {
            "gems": []
        }
        input_gems = input_data.get('gem_names', [])
        input_gems.extend(input_data.get('dependencies', []))
        dependent_gems = []
        for gem_name in input_gems:
            if utils.has_version_specifier(gem_name) or is_reverse_domain_format(gem_name):
                dependent_gems.append(gem_name)
            else:
                dependent_gems.append(f"org.o3de.gem.{gem_name}>={_get_gem_version(gem_name)}".lower())

        if dependent_gems:
            dependent['gems'] = dependent_gems

        
        output_data['dependent'] = dependent

        #disable the restricteds as they are not declared anymore
        #if 'restricted' in input_data:
        #    if utils.has_version_specifier(input_data['restricted']) or is_reverse_domain_format(input_data['restricted']):
        #        output_data['restricteds'] = [input_data['restricted']]
        #    else:
        #        output_data['restricteds'] = [f"org.o3de.restricted.{input_data['restricted']}>={_get_restricted_version(input_data['restricted'])}".lower()]

        if 'download_source_uri' in input_data or 'download_lfs_uri' in input_data or 'download_targz_uri' in input_data or 'download_lfs_targz_uri' in input_data:
            # Schema 2.0.0 uses 'downloads' array with 'source' and 'lfs' properties
            download_zip = {}
            download_targz = {}
            if 'download_source_uri' in input_data:
                uri = input_data.get('download_source_uri')
                download_zip['source'] = f"{uri}.zip" if uri and not uri.endswith('.zip') else uri
            if 'download_lfs_uri' in input_data:
                uri = input_data.get('download_lfs_uri')
                download_zip['lfs'] = f"{uri}.zip" if uri and not uri.endswith('.zip') else uri
            if 'download_targz_uri' in input_data:
                uri = input_data.get('download_targz_uri')
                download_targz['source'] = f"{uri}.tar.gz" if uri and not uri.endswith('.tar.gz') else uri
            if 'download_lfs_targz_uri' in input_data:
                uri = input_data.get('download_lfs_targz_uri')
                download_targz['lfs'] = f"{uri}.tar.gz" if uri and not uri.endswith('.tar.gz') else uri
            downloads = []
            if download_zip:
                downloads.append(download_zip)
            if download_targz:
                downloads.append(download_targz)
            if downloads:
                output_data['downloads'] = downloads

        if 'source_control_uri' in input_data or 'source_control_path' in input_data or 'source_control_branch' in input_data or 'source_control_tag' in input_data:
            output_data['source_control'] = {}
            if 'source_control_uri' in input_data:
                uri = input_data.get('source_control_uri')
                output_data['source_control']['git'] = f"{uri}.git" if uri and not uri.endswith('.git') else uri
            if 'source_control_path' in input_data:
                output_data['source_control']['relative_path'] = input_data.get('source_control_path')
            if 'source_control_branch' in input_data:
                output_data['source_control']['branch'] = input_data.get('source_control_branch')
            if 'source_control_tag' in input_data:
                output_data['source_control']['tag'] = input_data.get('source_control_tag')

        if 'releases' in input_data:
            output_data['releases'] = input_data['releases']

        if 'versions_data' in input_data:
            if 'releases' not in output_data:
                output_data['releases'] = []

            releases = []
            for item in input_data['versions_data']:
                downloads = []
                source_controls = []
                
                # Build download objects (zip and/or targz) for this release
                if 'download_source_uri' in item or 'download_lfs_uri' in item or 'download_targz_uri' in item or 'download_lfs_targz_uri' in item:
                    download_zip = {}
                    download_targz = {}
                    if 'download_source_uri' in item:
                        uri = item.get('download_source_uri')
                        download_zip['source'] = f"{uri}.zip" if uri and not uri.endswith('.zip') else uri
                    if 'download_lfs_uri' in item:
                        uri = item.get('download_lfs_uri')
                        download_zip['lfs'] = f"{uri}.zip" if uri and not uri.endswith('.zip') else uri
                    if 'download_targz_uri' in item:
                        uri = item.get('download_targz_uri')
                        download_targz['source'] = f"{uri}.tar.gz" if uri and not uri.endswith('.tar.gz') else uri
                    if 'download_lfs_targz_uri' in item:
                        uri = item.get('download_lfs_targz_uri')
                        download_targz['lfs'] = f"{uri}.tar.gz" if uri and not uri.endswith('.tar.gz') else uri
                    if download_zip:
                        downloads.append(download_zip)
                    if download_targz:
                        downloads.append(download_targz)

                # Build source_control object for this release
                if 'source_control_uri' in item or 'source_control_path' in item or 'source_control_branch' in item or 'source_control_tag' in item:
                    source_control = {}
                    if 'source_control_uri' in item:
                        uri = item.get('source_control_uri')
                        source_control['git'] = f"{uri}.git" if uri and not uri.endswith('.git') else uri
                    if 'source_control_path' in item:
                        source_control['relative_path'] = item.get('source_control_path')
                    if 'source_control_branch' in item:
                        source_control['branch'] = item.get('source_control_branch')
                    if 'source_control_tag' in item:
                        source_control['tag'] = item.get('source_control_tag')
                    if source_control:
                        source_controls.append(source_control)

                # Build release object with required 'name' from version
                release = {
                    "name": item.get('version', '')
                }
                if downloads:
                    release["downloads"] = downloads
                if source_controls:
                    release["source_controls"] = source_controls

                releases.append(release)
            
            output_data['releases'].extend(releases)
        
        #add platforms
        if 'restricted_name' in input_data:
            output_data["platforms"] = [
            ]
        else:
            output_data["platforms"] = [
                "Windows",
                "Linux",
                "Mac",
                "iOS",
                "Android"
            ]
        if "platforms" in input_data:
            output_data["platforms"] = input_data["platforms"]

        if 'additional_info' in input_data:
            output_data['additional_info'] = input_data['additional_info']

        if 'requirements' in input_data:
            output_data['requirements'] = input_data['requirements']

    # add the schema version
    return 0, output_data


def upgrade_to_1_0_0(input_json_path: pathlib.Path = None, output_json_path: pathlib.Path = None) -> int:
    """
    Updates a o3de object json to 1.0.0   

    :return: 0 for success or non 0 failure code
    """
    input_json_data = None
    output_json_data = None

    # load the json file  
    if isinstance(input_json_path, pathlib.PurePath):
        try:
            with open(input_json_path, 'r') as f:
                input_json_data = json.load(f)
        except Exception as e:
            logger.error(f'Failed to load json file: {input_json_path}')
            return 1

    # check what $schemaVersion the input file is
    schema_version = schema.SchemaVersion(input_json_data.get('$schemaVersion', schema.VERSION_IMPLICIT))

    #upgrade as needed
    result = 0
    if not result and schema_version < schema.VERSION_1_0_0:
        result, output_json_data = upgrade_0_0_0_to_1_0_0(input_json_path, input_json_data)
        schema_version = schema.SchemaVersion(schema.VERSION_1_0_0)
    else:
        output_json_data = input_json_data

    if result:
        logger.error(f'Failed to upgrade to schema version: {schema_version}')
        return 1
    
     # write the output json file
    if isinstance(output_json_path, pathlib.PurePath):
        try:
            with open(output_json_path, 'w') as f:
                json.dump(output_json_data, f, indent=4)
        except Exception as e:
            logger.error(f'Failed to write json file: {output_json_path}')
            return 1
    else:
        try:
            with open(input_json_path, 'w') as f:
                json.dump(output_json_data, f, indent=4)
        except Exception as e:
            logger.error(f'Failed to write json file: {input_json_path}')
            return 1
    
    return 0

def upgrade_to_2_0_0(input_json_path: pathlib.Path = None, output_json_path: pathlib.Path = None) -> int:
    """
    Updates a o3de object json to 2.0.0   

    :return: 0 for success or non 0 failure code
    """    
    input_json_data = None
    output_json_data = None

    # load the json file
    if isinstance(input_json_path, pathlib.PurePath):
        try:
            with open(input_json_path, 'r') as f:
                input_json_data = json.load(f)
        except Exception as e:
            logger.error(f'Failed to load json file: {input_json_path}')
            return 1

    # check what $schemaVersion the input file is
    schema_version = schema.SchemaVersion(input_json_data.get('$schemaVersion', schema.VERSION_IMPLICIT))
    
    #upgrade as needed
    result = 0
    if not result and schema_version < schema.VERSION_1_0_0:
        result, output_json_data = upgrade_0_0_0_to_1_0_0(input_json_path, input_json_data)
        schema_version = schema.SchemaVersion(schema.VERSION_1_0_0)
    else:
        output_json_data = input_json_data
        
    if not result and schema_version < schema.VERSION_2_0_0:
        result, output_json_data = upgrade_1_0_0_to_2_0_0(input_json_path, output_json_data)
        schema_version = schema.SchemaVersion(schema.VERSION_2_0_0)

    if result:
        logger.error(f'Failed to upgrade to schema version: {schema_version}')
        return 1
    
     # write the output json file
    if isinstance(output_json_path, pathlib.PurePath):
        try:
            with open(output_json_path, 'w') as f:
                json.dump(output_json_data, f, indent=4)
        except Exception as e:
            logger.error(f'Failed to write json file: {output_json_path}')
            return 1
    else:
        try:
            with open(input_json_path, 'w') as f:
                json.dump(output_json_data, f, indent=4)
        except Exception as e:
            logger.error(f'Failed to write json file: {input_json_path}')
            return 1
    
    return 0

def _run_upgrade(args: argparse) -> int:
   
    if hasattr(args, 'to_1_0_0') and args.to_1_0_0:
        return upgrade_to_1_0_0(input_json_path=args.object_json, output_json_path=args.to_1_0_0)

    elif hasattr(args, 'to_2_0_0') and args.to_2_0_0:
        return upgrade_to_2_0_0(input_json_path=args.object_json, output_json_path=args.to_2_0_0)
    
    # if no version is specified, upgrade fully inplace
    else:
        return upgrade_to_2_0_0(input_json_path=args.object_json, output_json_path=args.object_json)
        

def add_args(subparsers) -> None:
    """
    add_args is called to add subparsers arguments to each command such that it can be
    a central python file such as o3de.py.
    It can be run from the o3de.py script as follows
    call add_args and execute: python o3de.py upgrade-schema --object-json "C:/Gems/MyGem/gem.json" --to_2.0.0 "C:/Gems/MyGem/gem-2.0.0.json"
    :param subparsers: the caller instantiates subparsers and passes it in here
    """
    upgrade_schema_subparser = subparsers.add_parser('upgrade-schema')

    # Sub-commands should declare their own verbosity flag, if desired
    utils.add_verbosity_arg(upgrade_schema_subparser)

    upgrade_schema_subparser.description = "Upgrades O3DE JSON schema files to newer versions"
    upgrade_schema_subparser.add_argument('--object-json', 
                       dest='object_json',
                       type=pathlib.Path, 
                       required=True,
                       help='Input o3de JSON file to upgrade')
                       
    group = upgrade_schema_subparser.add_mutually_exclusive_group()
    group.add_argument('--to-1.0.0',
                      dest='to_1_0_0',
                      type=pathlib.Path,
                      help='Upgrade to schema 1.0.0')
    group.add_argument('--to-2.0.0', 
                      dest='to_2_0_0',
                      type=pathlib.Path,
                      help='Upgrade to schema 2.0.0')
       
    upgrade_schema_subparser.set_defaults(func=_run_upgrade)