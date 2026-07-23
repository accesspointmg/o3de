#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
"""
Contains methods for query CMake gem target information
"""

import argparse
import enum
import json
import logging
import os
import pathlib
import string
import sys

# add the scripts/o3de directory to the front of the sys.path temporarily to import 
# some o3de python modules
sys.path.insert(0, os.path.dirname(pathlib.Path(__file__).parent))
from o3de import o3de_object, utils, compatibility, validation
# Remove the temporarily added path
sys.path = sys.path[1:]

logger = logging.getLogger('o3de.cmake')
logging.basicConfig(format=utils.LOG_FORMAT)





def get_enabled_gem_cmake_file(project_name: str = None,
                                project_path: str or pathlib.Path = None,
                                platform: str = 'Common') -> pathlib.Path or None:
    """
    get the standard cmake file name for a particular type of dependency
    :param gem_name: name of the gem, resolves gem_path
    :param gem_path: path of the gem
    :return: list of gem targets
    """
    if not project_name and not project_path:
        logger.error(f'Must supply either a Project Name or Project Path.')
        return None

    if project_name and not project_path:
        project_path = get_registered(project_name=project_name)

    project_path = pathlib.Path(project_path).resolve()
    enable_gem_filename = "enabled_gems.cmake"

    if platform == 'Common':
        possible_project_enable_gem_filename_paths = [
            pathlib.Path(project_path / 'Gem' / enable_gem_filename),
            pathlib.Path(project_path / 'Gem/Code' / enable_gem_filename),
            pathlib.Path(project_path / 'Code' / enable_gem_filename)
        ]
        for possible_project_enable_gem_filename_path in possible_project_enable_gem_filename_paths:
            if possible_project_enable_gem_filename_path.is_file():
                return possible_project_enable_gem_filename_path.resolve()
        return possible_project_enable_gem_filename_paths[0].resolve()
    else:
        possible_project_platform_enable_gem_filename_paths = [
            pathlib.Path(project_path / 'Gem/Platform' / platform / enable_gem_filename),
            pathlib.Path(project_path / 'Gem/Code/Platform' / platform / enable_gem_filename),
            pathlib.Path(project_path / 'Code/Platform' / platform / enable_gem_filename)
        ]
        for possible_project_platform_enable_gem_filename_path in possible_project_platform_enable_gem_filename_paths:
            if possible_project_platform_enable_gem_filename_path.is_file():
                return possible_project_platform_enable_gem_filename_path.resolve()
        return possible_project_platform_enable_gem_filename_paths[0].resolve()


def get_enabled_gems(cmake_file: pathlib.Path) -> set:
    """
    Gets a list of enabled gems from the cmake file
    :param cmake_file: path to the cmake file
    :return: set of gem targets found
    """
    cmake_file = pathlib.Path(cmake_file).resolve()

    if not cmake_file.is_file():
        logger.error(f'Failed to locate cmake file {cmake_file}')
        return set()

    enable_gem_start_marker = 'set(ENABLED_GEMS'
    enable_gem_end_marker = ')'

    gem_target_set = set()
    with cmake_file.open('r') as s:
        in_gem_list = False
        for line in s:
            line = line.strip()
            if line.startswith(enable_gem_start_marker):
                # Set the flag to indicate that we are in the ENABLED_GEMS variable
                in_gem_list = True
                # Skip pass the 'set(ENABLED_GEMS' marker just in case their are gems declared on the same line
                line = line[len(enable_gem_start_marker):]
            if in_gem_list:
                # Since we are inside the ENABLED_GEMS variable determine if the line has the end_marker of ')'
                if line.endswith(enable_gem_end_marker):
                    # Strip away the line end marker
                    line = line[:-len(enable_gem_end_marker)]
                    # Set the flag to indicate that we are no longer in the ENABLED_GEMS variable after this line
                    in_gem_list = False
                # Split the rest of the line on whitespace just in case there are multiple gems in a line
                gem_name_list = list(map(lambda gem_name: gem_name.strip('"'), line.split()))
                gem_target_set.update(gem_name_list)

    return gem_target_set


FALLBACK_ENGINE_PROJECT_PATHS_WARNINGS = set()

def get_project_enabled_gems(project_path: pathlib.Path, include_dependencies:bool = True) -> dict or None:
    """
    Returns a dictionary of "<gem name with optional specifier>":"<gem path>"
    Example: {"gemA>=1.2.3":"c:/gemA", "gemB":"c:/gemB"}
    :param project_path The path to the project
    :param include_gem_dependencies True to include all gem dependencies, otherwise just return
    gems listed in project.json and the deprecated enabled_gems.json
    """
    project_json_data = get_project_json_data(project_path=project_path)
    if not project_json_data:
        logger.error(f"Failed to get project json data for the project at '{project_path}'")
        return None

    active_gem_names = project_json_data.get('gem_names',[])
    enabled_gems_file = get_enabled_gem_cmake_file(project_path=project_path)
    if enabled_gems_file and enabled_gems_file.is_file():
        active_gem_names.extend(get_enabled_gems(enabled_gems_file))

    gem_names_with_optional_gems = utils.get_gem_names_set(active_gem_names, include_optional=True)
    if not gem_names_with_optional_gems:
        return {}
    
    # We have the gem names but not the resolved paths yet
    result = {gem_name: None for gem_name in gem_names_with_optional_gems}

    engine_path = get_project_engine_path(project_path=project_path)
    if not engine_path:
        engine_path = get_this_engine_path()
        if not engine_path:
            logger.error('Failed to find an engine path for the project at '
                            f'"{project_path}" which is required to resolve gem dependencies.')
            return result

        # Warn about falling back to a default engine once per project
        global FALLBACK_ENGINE_PROJECT_PATHS_WARNINGS
        if project_path not in FALLBACK_ENGINE_PROJECT_PATHS_WARNINGS:
            FALLBACK_ENGINE_PROJECT_PATHS_WARNINGS.add(project_path)
            logger.warning('Failed to determine the correct engine for the project at '
                           f'"{project_path}", falling back to this engine at {engine_path}.')
    
    engine_json_data = get_engine_json_data(engine_path=engine_path)
    if not engine_json_data:
        logger.error('Failed to retrieve engine json data for the engine at '
                     f'"{engine_path}" which is required to resolve gem dependencies.')
        return result 

    all_gems_json_data = get_gems_json_data_by_name(engine_path=engine_path, 
                                                    project_path=project_path, 
                                                    include_manifest_gems=True, 
                                                    include_engine_gems=True)

    # we need a mapping of gem name to gem name with version specifier because
    # the resolver will remove the version specifier
    gem_names_with_version_specifiers = {}
    for gem_name_with_specifier in gem_names_with_optional_gems:
        gem_name_only, _ = utils.get_object_name_and_optional_version_specifier(gem_name_with_specifier)
        gem_names_with_version_specifiers[gem_name_only] = gem_name_with_specifier

    # Try to resolve with optional gems
    resolved_gems, errors = compatibility.resolve_gem_dependencies(gem_names_with_optional_gems, 
                                                             all_gems_json_data, 
                                                             engine_json_data, 
                                                             include_optional=True)
    if errors:
        # Try without optional gems
        gem_names_without_optional = utils.get_gem_names_set(active_gem_names, include_optional=False)
        resolved_gems, errors = compatibility.resolve_gem_dependencies(gem_names_without_optional, 
                                                                 all_gems_json_data, 
                                                                 engine_json_data,
                                                                 include_optional=False)
    if not errors:
        for _, gem in resolved_gems.items():
            gem_name = gem.gem_json_data['gem_name']
            gem_name_with_specifier = gem_names_with_version_specifiers.get(gem_name,gem_name)
            if gem_name_with_specifier in result or include_dependencies:
                result[gem_name_with_specifier] = gem.gem_json_data['path'].as_posix() if gem.gem_json_data['path'] else None
    else:
        # Likely there is no resolution because gems are missing or wrong version
        # Provide the paths for the gems that are available
        for gem_name in result.keys():
            gem_path = get_most_compatible_gem(gem_name, all_gems_json_data)
            if gem_path:
                result[gem_name] = gem_path.resolve().as_posix()
    return result


def get_project_engine_path(project_path: pathlib.Path, 
                            project_json_data: dict = None, 
                            user_project_json_data: dict = None, 
                            engines_json_data: dict = None) -> pathlib.Path or None:
    """
    Returns the most compatible engine path for a project based on the project's 'engine' field and taking into account
    <project_path>/user/project.json overrides or the engine the project is registered with.
    :param project_path: Path to the project
    :param project_json_data: Optional json data to use to avoid reloading project.json  
    :param user_project_json_data: Optional json data to use to avoid reloading <project_path>/user/project.json  
    :param engines_json_data: Optional engines json data to use for engines to avoid reloading all engine.json files
    """
    engine_path = compatibility.get_most_compatible_project_engine_path(project_path, 
                                                                        project_json_data, 
                                                                        user_project_json_data, 
                                                                        engines_json_data)
    if engine_path:
        return engine_path

    # check if the project is registered in an engine.json
    # in a parent folder
    resolved_project_path = pathlib.Path(project_path).resolve()
    engine_path = utils.find_ancestor_dir_containing_file(pathlib.PurePath('engine.json'), resolved_project_path)
    if engine_path:
        projects = get_engine_projects(engine_path)
        for engine_project_path in projects:
            if resolved_project_path.samefile(pathlib.Path(engine_project_path).resolve()):
                return engine_path

    return None


def add_dependency_gem_names(gem_name:str, gems_json_data_by_name:dict, all_gem_names:set):
    """
    Add gem names for all gem dependencies to the all_gem_names set recursively
    param: gem_name the gem name to add with its dependencies
    param: gems_json_data_by_name a dict of all gem json data to use
    param: all_gem_names the set that all dependency gem names are added to
    """
    gem_json_data = gems_json_data_by_name.get(gem_name, None)
    if gem_json_data:
        dependencies = gem_json_data.get('dependencies',[])
        for dependency_gem_name in dependencies:
            if dependency_gem_name not in all_gem_names:
                all_gem_names.add(dependency_gem_name)
                add_dependency_gem_names(dependency_gem_name, gems_json_data_by_name, all_gem_names)


def remove_non_dependency_gem_json_data(gem_names:list, gems_json_data_by_name:dict) -> None:
    """
    Given a list of gem names and a dict of all gem json data, remove all gem entries that are not
    in the list and not dependencies. 
    param: gem_names the list of gem names
    param: gems_json_data_by_name a dict of all gem json data that will be modified
    """
    gem_names_to_keep = set(gem_names)
    for gem_name in set(gem_names):
        add_dependency_gem_names(gem_name, gems_json_data_by_name, gem_names_to_keep)

    gem_names_to_remove = [gem_name for gem_name in gems_json_data_by_name if gem_name not in gem_names_to_keep]
    for gem_name in gem_names_to_remove:
        del gems_json_data_by_name[gem_name]


def get_gems_json_data_by_path(engine_path:pathlib.Path = None, 
                               project_path: pathlib.Path = None, 
                               include_manifest_gems: bool = False,
                               include_engine_gems: bool = False,
                               external_subdirectories: list = None) -> dict:
    """
    Create a dictionary of gem.json data with gem paths as keys based on the provided list of
    external subdirectories, engine_path or project_path.  Optionally, include gems
    found using the o3de manifest.

    param: engine_path optional engine path
    param: project_path optional project path
    param: include_manifest_gems if True, include gems found using the o3de manifest 
    param: include_engine_gems if True, include gems found using the engine, 
    will use the current engine if no engine_path is provided and none can be deduced from
    the project_path
    param: external_subdirectories optional external_subdirectories to include
    return: a dictionary of gem_path -> gem.json data
    """
    all_gems_json_data = {}

    # we don't use a default list() value in the function params
    # because Python will persist changes to this default list across
    # multiple function calls which is FUN to debug
    external_subdirectories = list() if not external_subdirectories else external_subdirectories

    if include_manifest_gems:
        external_subdirectories.extend(get_manifest_external_subdirectories())

    if project_path:
        external_subdirectories.extend(get_project_external_subdirectories(project_path))
        if not engine_path and include_engine_gems:
            engine_path = get_project_engine_path(project_path=project_path)

    if engine_path or include_engine_gems:
        # this will use the current engine if engine_path is None
        external_subdirectories.extend(get_engine_external_subdirectories(engine_path))

    # Filter out duplicate external_subdirectories before querying if they contain gem.json files
    external_subdirectories = list(dict.fromkeys(external_subdirectories))

    gem_paths = kludge_find_gems_in_external_subdirectories(external_subdirectories)
    for gem_path in gem_paths:
        get_gem_external_subdirectories(gem_path, list(), all_gems_json_data)
    
    return all_gems_json_data


def get_gems_json_data_by_name(engine_path:pathlib.Path = None, 
                               project_path: pathlib.Path = None, 
                               include_manifest_gems: bool = False,
                               include_engine_gems: bool = False,
                               external_subdirectories: list = None) -> dict:
                        
    """
    Create a dictionary of gem.json data with gem names as keys based on the provided list of
    external subdirectories, engine_path or project_path.  Optionally, include gems
    found using the o3de manifest.

    It's often more efficient to open all gem.json files instead of 
    looking up each by name, which will load many gem.json files multiple times
    It takes about 150ms to populate this structure with 137 gems, 4696 bytes in total

    param: engine_path optional engine path
    param: project_path optional project path
    param: include_manifest_gems if True, include gems found using the o3de manifest 
    param: include_engine_gems if True, include gems found using the engine, 
    will use the current engine if no engine_path is provided and none can be deduced from
    the project_path
    param: external_subdirectories optional external_subdirectories to include
    return: a dictionary of gem_name -> gem.json data
    """
    all_gems_json_data = get_gems_json_data_by_path(engine_path, 
                                                    project_path, 
                                                    include_manifest_gems, 
                                                    include_engine_gems, 
                                                    external_subdirectories)

    # convert from being keyed on gem_path to gem_name and store the paths
    # resulting dictionary format will look like
    # {
    #     '<gem name>': [
    #         {'gem_name':'<gem name>', 'version':'<version>', 'path':'<path>'}
    #     ],
    # }
    #     e.g.
    # {
    #     'gem1': [
    #         {'gem_name':'gem1', 'version':'1.0.0'},
    #         {'gem_name':'gem1', 'version':'2.0.0'},
    #     ],
    #     'gem2': [
    #         {'gem_name':'gem2', 'version':'1.0.0'},
    #         {'gem_name':'gem2', 'version':'2.0.0'},
    #     ],
    # }
    # For Schema 2.0 gems, ensure gem_name and version are populated from the header
    for path, gem_data in all_gems_json_data.items():
        if gem_data and 'gem_name' not in gem_data:
            name = validation.get_object_name(gem_data, 'gem')
            if name:
                gem_data['gem_name'] = name
        if gem_data and 'version' not in gem_data:
            ver = validation.get_object_version(gem_data, 'gem')
            if ver:
                gem_data['version'] = ver

    utils.replace_dict_keys_with_value_key(all_gems_json_data, value_key='gem_name', replaced_key_name='path', place_values_in_list=True)

    return all_gems_json_data


def get_all_external_subdirectories(engine_path:pathlib.Path = None, project_path: pathlib.Path = None, gems_json_data_by_path: dict = None) -> list:
    external_subdirectories_data = get_manifest_external_subdirectories()
    external_subdirectories_data.extend(get_engine_external_subdirectories(engine_path))
    if project_path:
        external_subdirectories_data.extend(get_project_external_subdirectories(project_path))

    # Filter out duplicate external_subdirectories before querying if they contain gem.json files
    external_subdirectories_data = list(dict.fromkeys(external_subdirectories_data))

    gem_paths = kludge_find_gems_in_external_subdirectories(external_subdirectories_data)
    for gem_path in gem_paths:
        external_subdirectories_data.extend(get_gem_external_subdirectories(gem_path, list(), gems_json_data_by_path))

    # Remove duplicates from the list
    return list(dict.fromkeys(external_subdirectories_data))


# Template functions
def get_templates_for_engine_creation() -> list:
    return o3de_manifest.get_child_engine_templates()

def get_templates_for_project_creation() -> list:
    return o3de_manifest.get_child_project_templates()

def get_templates_for_gem_creation() -> list:
    return o3de_manifest.get_child_gem_templates()

def get_templates_for_restricted_creation() -> list:
    return o3de_manifest.get_child_restricted_templates()

def get_templates_for_repo_creation() -> list:
    return o3de_manifest.get_child_repo_templates()

def get_templates_for_generic_creation() -> list:
    generic_templates = []
    for template_path in o3de_manifest.get_child_templates():
        template_path = pathlib.Path(template_path)
        engine_path = template_path / 'Template' / 'engine.json'
        if not engine_path.is_file():
            continue
        project_path = template_path / 'Template' / 'project.json'
        if not project_path.is_file():
            continue
        template_json_path = template_path / 'template.json'
        if not template_json_path.is_file():
            continue
        gem_json_path = template_path / 'Template' / 'gem.json'
        if not gem_json_path.is_file():
            continue
        repo_json_path = template_path / 'Template' / 'repo.json'
        if not repo_json_path.is_file():
            continue

        generic_templates.append(template_path)

    return generic_templates


def get_most_compatible_gem(gem_name: str, 
                            gem_json_data_by_name: dict or None) -> pathlib.Path or None:
    """
    Optimized version of get_most_compatible_object() for gems when we have already
    opened all the gem.json files
    :param gem_name The gem name with optional version specifier, example: o3de>=1.2.3
    :param gem_json_data_by_name Gem data from get_gems_json_data_by_name()
    """
    gem_name_with_version_specifier = gem_name
    gem_name, version_specifier = utils.get_object_name_and_optional_version_specifier(gem_name)
    if not gem_name in gem_json_data_by_name:
        return None

    matching_paths = deque()
    most_compatible_version = Version('0.0.0')
    for gem_json_data in gem_json_data_by_name.get(gem_name, {}):
        if version_specifier:
            candidate_version = gem_json_data.get('version','0.0.0')
            if compatibility.has_compatible_version([gem_name_with_version_specifier], gem_name, candidate_version):
                if not matching_paths:
                    matching_paths.appendleft(gem_json_data['path'])
                    most_compatible_version = Version(candidate_version)
                elif Version(candidate_version) > most_compatible_version:
                    matching_paths.appendleft(gem_json_data['path'])
                    most_compatible_version = Version(candidate_version)
                else:
                    matching_paths.append(gem_json_data['path'])
        else:
            matching_paths.append(gem_json_data['path'])

    return None if not matching_paths else matching_paths[0]


def get_most_compatible_object(object_name: str, 
                              name_key: str, 
                              objects: list) -> dict or None:
    """
    Looks for the most compatible object based on object_name which may contain a version specifier.
    Example: o3de>=1.2.3

    :param object_name: Name of the object with optional version specifier 
    :param name_key: Object name key inside the object's json file e.g. 'engine_name' 
    :param objects: List of object json data to consider 
    :return the most compatible object json data dict or None
    """
    most_compatible_version = Version('0.0.0')
    object_name, version_specifier = utils.get_object_name_and_optional_version_specifier(object_name)
    most_compatible_object = None

    def update_most_compatible(candidate_version:str, json_data:dict):
        nonlocal most_compatible_object
        nonlocal most_compatible_version

        if not most_compatible_object:
            most_compatible_object = json_data 
            most_compatible_version = Version(candidate_version)
        elif Version(candidate_version) > most_compatible_version:
            most_compatible_object = json_data 
            most_compatible_version = Version(candidate_version)

    for json_data in objects:
        candidate_name = json_data.get(name_key,'')
        if candidate_name != object_name:
            continue

        candidate_version = json_data.get('version','0.0.0')
        if version_specifier:
            if compatibility.has_compatible_version([object_name + version_specifier], candidate_name, candidate_version):
                update_most_compatible(candidate_version, json_data)
        else:
            update_most_compatible(candidate_version, json_data)

    return most_compatible_object


def get_most_compatible_object_path(object_name: str, 
                              object_typename: str, 
                              object_validator: callable, 
                              name_key: str, 
                              objects: list) -> pathlib.Path or None:
    """
    Looks for the most compatible object based on object_name which may contain a version specifier.
    Example: o3de>=1.2.3

    :param object_name: Name of the object with optional version specifier 
    :param object_typename: Type of object e.g. 'engine','project' or 'gem' 
    :param object_validator: Validator to use for json file 
    :param name_key: Object name key inside the object's json file e.g. 'engine_name' 
    :param objects: List of paths to search
    :return the most compatible object path or None
    """
    matching_paths = deque()
    most_compatible_version = Version('0.0.0')
    object_name, version_specifier = utils.get_object_name_and_optional_version_specifier(object_name)
    for object in objects:
        if isinstance(object, dict):
            path = pathlib.Path(object['path']).resolve()
        else:
            path = pathlib.Path(object).resolve()

        json_data = get_json_data(object_typename, path, object_validator)
        if json_data:
            candidate_name = json_data.get(name_key,'')
            if version_specifier:
                candidate_version = json_data.get('version','0.0.0')
                if compatibility.has_compatible_version([object_name + version_specifier], candidate_name, candidate_version):
                    if not matching_paths:
                        matching_paths.appendleft(path)
                        most_compatible_version = Version(candidate_version)
                    elif Version(candidate_version) > most_compatible_version:
                        matching_paths.appendleft(path)
                        most_compatible_version = Version(candidate_version)
                    else:
                        matching_paths.append(path)
            elif candidate_name == object_name:
                matching_paths.append(path)
    if matching_paths:
        best_candidate_path = matching_paths[0]
        if len(matching_paths) > 1:
            matches = "\n".join(map(str,matching_paths))
            logger.warning(f"Multiple matches found for: '{object_name}'\n{matches}\nMost compatible match: '{best_candidate_path}'")
        return best_candidate_path

    return None

def get_registered(engine_name: str = None,
                   project_name: str = None,
                   gem_name: str = None,
                   template_name: str = None,
                   default_folder: str = None,
                   repo_name: str = None,
                   restricted_name: str = None,
                   project_path: pathlib.Path = None) -> pathlib.Path or None:
    """
       Looks up a registered entry in either the  ~/.o3de/o3de_manifest.json, <this-engine-root>/engine.json
       or the <project-path>/project.json (if the project_path parameter is supplied)

       :param engine_name: Name of a registered engine to lookup in the ~/.o3de/o3de_manifest.json file
       :param project_name: Name of a project to lookup in either the ~/.o3de/o3de_manifest.json or
              <this-engine-root>/engine.json file
       :param gem_name: Name of a gem to lookup in either the ~/.o3de/o3de_manifest.json, <this-engine-root>/engine.json
            or <project-path>/project.json. NOTE: The project_path parameter must be supplied to lookup the registration
            with the project.json
       :param template_name: Name of a template to lookup in either the ~/.o3de/o3de_manifest.json, <this-engine-root>/engine.json
            or <project-path>/project.json. NOTE: The project_path parameter must be supplied to lookup the registration
            with the project.json
       :param repo_name: Name of a repo to lookup in the ~/.o3de/o3de_manifest.json
       :param default_folder: Type of "default" folder to lookup in the ~/.o3de/o3de_manifest.json
              Valid values are "engines", "projects", "gems", "templates,", "restricted"
       :param restricted_name: Name of a restricted directory object to lookup in either the ~/.o3de/o3de_manifest.json,
            <this-engine-root>/engine.json or <project-path>/project.json.
            NOTE: The project_path parameter must be supplied to lookup the registration with the project.json
       :param project_path: Path to project root, which is used to examined the project.json file in order to
              query either gems, templates or restricted directories registered with the project

       :return path value associated with the registered object name if found. Otherwise None is returned
    """
    json_data = get_o3de_manifest_json_data()

    if isinstance(engine_name, str):
        return get_most_compatible_object_path(engine_name, 'engine', validation.valid_o3de_engine_json, 'engine_name', get_manifest_child_engines())

    elif isinstance(project_name, str):
        return get_most_compatible_object_path(project_name, 'project', validation.valid_o3de_project_json, 'project_name', get_all_projects())

    elif isinstance(gem_name, str):
        gems = []
        if project_path:
            gems = get_all_gems(project_path)
        else:
            # If project_path is not supplied
            registered_project_paths = get_all_projects()
            if not registered_project_paths:
                # query all gems from this engine if no projects exist
                gems = get_all_gems()
            else:
                # query all registered projects
                for registered_project_path in registered_project_paths:
                    gems.extend(get_all_gems(registered_project_path))
                gems = list(dict.fromkeys(gems))
        return get_most_compatible_object_path(gem_name, 'gem', validation.valid_o3de_gem_json, 'gem_name', gems)

    elif isinstance(template_name, str):
        templates = []
        if project_path:
            templates = get_all_templates(project_path)
        else:
            # If project_path is not supplied
            registered_project_paths = get_all_projects()
            if not registered_project_paths:
                # if no projects exist, query all templates from this engine and gems
                templates = get_all_templates()
            else:
                # query all registered projects
                for registered_project_path in registered_project_paths:
                    templates.extend(get_all_templates(registered_project_path))
                templates = list(dict.fromkeys(templates))

        for template_path in templates:
            template_path = pathlib.Path(template_path).resolve()
            template_json = template_path / 'template.json'
            if not pathlib.Path(template_json).is_file():
                logger.warning(f'{template_json} does not exist')
            else:
                with template_json.open('r') as f:
                    try:
                        template_json_data = json.load(f)
                    except json.JSONDecodeError as e:
                        logger.warning(f'{template_path} failed to load: {str(e)}')
                    else:
                        this_templates_name = template_json_data['template_name']
                        if this_templates_name == template_name:
                            return template_path

    elif isinstance(restricted_name, str):
        restricted = get_manifest_child_restricteds()
        for restricted_path in restricted:
            restricted_path = pathlib.Path(restricted_path).resolve()
            restricted_json = restricted_path / 'restricted.json'
            if not pathlib.Path(restricted_json).is_file():
                logger.warning(f'{restricted_json} does not exist')
            else:
                with restricted_json.open('r') as f:
                    try:
                        restricted_json_data = json.load(f)
                    except json.JSONDecodeError as e:
                        logger.warning(f'{restricted_json} failed to load: {str(e)}')
                    else:
                        this_restricted_name = restricted_json_data['restricted_name']
                        if this_restricted_name == restricted_name:
                            return restricted_path

    elif isinstance(default_folder, str):
        if default_folder == 'engines':
            if 'default_engines_folder' in json_data:
                default_engines_folder = pathlib.Path(json_data['default_engines_folder'])
            else:
                default_engines_folder = pathlib.Path(
                    get_default_o3de_manifest_json_data().get('default_engines_folder', None))
            return default_engines_folder.resolve() if default_engines_folder else None
        elif default_folder == 'projects':
            if 'default_projects_folder' in json_data:
                default_projects_folder = pathlib.Path(json_data['default_projects_folder'])
            else:
                default_projects_folder = pathlib.Path(
                    get_default_o3de_manifest_json_data().get('default_projects_folder', None))
            return default_projects_folder.resolve() if default_projects_folder else None
        elif default_folder == 'gems':
            if 'default_gems_folder' in json_data:
                default_gems_folder = pathlib.Path(json_data['default_gems_folder'])
            else:
                default_gems_folder = pathlib.Path(
                    get_default_o3de_manifest_json_data().get('default_gems_folder', None))
            return default_gems_folder.resolve() if default_gems_folder else None
        elif default_folder == 'templates':
            if 'default_templates_folder' in json_data:
                default_templates_folder = pathlib.Path(json_data['default_templates_folder'])
            else:
                default_templates_folder = pathlib.Path(
                    get_default_o3de_manifest_json_data().get('default_templates_folder', None))
            return default_templates_folder.resolve() if default_templates_folder else None
        elif default_folder == 'restricteds':
            if 'default_restricteds_folder' in json_data:
                default_restricteds_folder = pathlib.Path(json_data['default_restricteds_folder'])
            else:
                default_restricteds_folder = pathlib.Path(
                    get_default_o3de_manifest_json_data().get('default_restricteds_folder', None))
            return default_restricteds_folder.resolve() if default_restricteds_folder else None

    elif isinstance(repo_name, str):
        cache_folder = get_user_o3de_cache_path()
        for repo_uri in json_data['repos']:
            cache_file = get_repo_path(repo_uri=repo_uri, cache_folder=cache_folder)
            if cache_file.is_file():
                repo = pathlib.Path(cache_file).resolve()
                with repo.open('r') as f:
                    try:
                        repo_json_data = json.load(f)
                    except json.JSONDecodeError as e:
                        logger.warning(f'{cache_file} failed to load: {str(e)}')
                    else:
                        this_repos_name = repo_json_data['repo_name']
                        if this_repos_name == repo_name:
                            return repo_uri
    return None









TEMPLATE_CMAKE_PRESETS_INCLUDE_JSON = """
{
    "version": 4,
    "cmakeMinimumRequired": {
        "major": 3,
        "minor": 23,
        "patch": 0
    },
    "include": [
        "${CMakePresetsInclude}"
    ]
}
"""

PROJECT_ENGINE_PRESET_RELATIVE_PATH = pathlib.PurePath('user/cmake/engine/CMakePresets.json')

class UpdatePresetResult(enum.Enum):
    EnginePathAdded = 0
    EnginePathAlreadyIncluded = 1
    Error = 2

def update_cmake_presets_for_project(preset_path: pathlib.PurePath, engine_name: str = '',
                                     engine_version: str = '',
                                     engine_path: pathlib.PurePath or None = None) -> UpdatePresetResult:
    """
    Updates a cmake-presets formatted JSON file with an include that points
    to the root CMakePresets.json inside the registered engine
    :param preset_path: path to the file to update with cmake-preset formatted json
    :param engine_name: name of the engine
    :param engine_version: version specifier for the engine.
           if empty string it is not used
    :return: UpdatePresetResult enum with value EnginePathAdded or EnginePathAlreadyIncluded
             if successful
    """
    if not engine_path:
        engine_with_specifier = f'{engine_name}=={engine_version}' if engine_version else engine_name
        engine_path = o3de_object.get_registered(engine_name=engine_with_specifier)
        if not engine_path:
            logger.error(f'Engine with identifier {engine_with_specifier} is not registered.\n'
                         f'The cmake-presets file at {preset_path} will not be modified')
            return UpdatePresetResult.Error

    engine_cmake_presets_path = engine_path / "CMakePresets.json"
    preset_json = {}
    # Convert the path to a concrete Path option
    preset_path = pathlib.Path(preset_path)
    try:
        with preset_path.open('r') as preset_fp:
            try:
                preset_json = json.load(preset_fp)
            except json.JSONDecodeError as e:
                logger.warning(f'Cannot parse JSON data from cmake-presets file at path "{preset_path}".\n'
                            'The JSON content in the file will be reset to only include the path to the registered engine:\n'
                            f'{str(e)}')
    except OSError as e:
        # It is OK if the preset_path file does not exist
        pass

    # Update an existing preset file if it exist
    if preset_json:
        preset_include_list = preset_json.get('include', [])
        if engine_cmake_presets_path in map(lambda preset_json_include: pathlib.PurePath(preset_json_include), preset_include_list):
            # If the engine_path is already included in the preset file, return without writing to the file
            return UpdatePresetResult.EnginePathAlreadyIncluded

        # Replace all "include" paths in the existing preset file
        # The reason this occurs is to prevent a scenario where previously registered engines
        # are being referenced by this preset file
        preset_json['include'] = [ engine_cmake_presets_path.as_posix() ]
    else:
        try:
            preset_json = json.loads(string.Template(TEMPLATE_CMAKE_PRESETS_INCLUDE_JSON).safe_substitute(
                CMakePresetsInclude=engine_cmake_presets_path.as_posix()))
        except json.JSONDecodeError as e:
            logger.error(f'Failed to substitute engine path {engine_path} into project CMake Presets template')
            return UpdatePresetResult.Error

    result = UpdatePresetResult.EnginePathAdded
    # Write the updated cmake-presets json to the preset_path file
    try:
        preset_path.parent.mkdir(parents=True, exist_ok=True)
        with preset_path.open('w') as preset_fp:
            try:
                preset_fp.write(json.dumps(preset_json, indent=4) + '\n')
                return result
            except OSError as e:
                logger.error(f'Failed to write "{preset_path}" to filesystem: {str(e)}')
                return UpdatePresetResult.Error
    except OSError as e:
        logger.error(f'Failed to open {preset_path} for write: {str(e)}')
        return UpdatePresetResult.Error


enable_gem_start_marker = 'set(ENABLED_GEMS'
enable_gem_end_marker = ')'

# The need for `enabled_gems.cmake` is deprecated
# Functionality still exists to retrieve and remove gems from `enabled_gems.cmake`
# but gems should only be added to `project.json` by the o3de CLI

def remove_gem_dependency(cmake_file: pathlib.Path,
                          gem_name: str) -> int:
    """
    removes a gem dependency from a cmake file
    :param cmake_file: path to the cmake file
    :param gem_name: name of the gem
    :return: 0 for success or non 0 failure code
    """
    if not cmake_file.is_file():
        logger.error(f'Failed to locate cmake file {cmake_file}')
        return 1

    # on a line by basis, remove any line with {gem_name}
    t_data = []
    removed = False

    with cmake_file.open('r') as s:
        in_gem_list = False
        for line in s:
            # Strip whitespace from both ends of the line, but keep track of the leading whitespace
            # for indenting the result line
            parsed_line = line.lstrip()
            indent = line[:-len(parsed_line)]
            parsed_line = parsed_line.rstrip()
            result_line = indent
            if parsed_line.startswith(enable_gem_start_marker):
                # Skip pass the 'set(ENABLED_GEMS' marker just in case their are gems declared on the same line
                parsed_line = parsed_line[len(enable_gem_start_marker):]
                result_line += enable_gem_start_marker
                # Set the flag to indicate that we are in the ENABLED_GEMS variable
                in_gem_list = True

            if in_gem_list:
                # Since we are inside the ENABLED_GEMS variable determine if the line has the end_marker of ')'
                if parsed_line.endswith(enable_gem_end_marker):
                    # Strip away the line end marker
                    parsed_line = parsed_line[:-len(enable_gem_end_marker)]
                    # Set the flag to indicate that we are no longer in the ENABLED_GEMS variable after this line
                    in_gem_list = False
                # Split the rest of the line on whitespace just in case there are multiple gems in a line
                # Strip double quotes surround any gem name
                gem_name_list = list(map(lambda gem_name: gem_name.strip('"'), parsed_line.split()))
                while gem_name in gem_name_list:
                    gem_name_list.remove(gem_name)
                    removed = True

                # Append the renaming gems to the line
                result_line += ' '.join(gem_name_list)
                # If the in_gem_list was flipped to false, that means the currently parsed line contained the
                # line end marker, so append that to the result_line
                result_line += enable_gem_end_marker if not in_gem_list else ''
                # Strip of trailing whitespace. This also strips result lines which are empty of the indent
                result_line = result_line.rstrip()
                if result_line:
                    t_data.append(result_line + '\n')
            else:
                t_data.append(line)

    if not removed:
        logger.error(f'Failed to remove {gem_name} from cmake file {cmake_file}')
        return 1

    # write the cmake
    with cmake_file.open('w') as s:
        s.writelines(t_data)

    return 0


def resolve_gem_dependency_paths(
        engine_path:pathlib.Path,
        project_path:pathlib.Path,
        external_subdirectories:str or list or None,
        resolved_gem_dependencies_output_path:pathlib.Path or None):
    """
    Resolves gem dependencies for the given engine and project and
    writes the output to the path provided.  This is used during CMake
    configuration because writing a CMake dependency resolver would be
    difficult and Python already has a solver with unit tests.
    :param engine_path: optional path to the engine, if not provided, the project's engine will be determined
    :param project_path: optional path to the project, if not provided the engine path must be provided
    :param resolved_gem_dependencies_output_path: optional path to a file that will be written
        containing a CMake list of gem names and paths.  If not provided, the list is written to STDOUT.
    :return: 0 for success or non 0 failure code
    """

    if not engine_path and not project_path:
        logger.error(f'project path or engine path are required to resolve dependencies')
        return 1

    if not engine_path:
        engine_path = o3de_object.get_project_engine_path(project_path=project_path)
        if not engine_path:
            engine_path = o3de_object.get_this_engine_path()
            if not engine_path:
                logger.error('Failed to find a valid engine path for the project at '
                             f'"{project_path}" which is required to resolve gem dependencies.')
                return 1

            logger.warning('Failed to determine the correct engine for the project at '
                           f'"{project_path}", falling back to this engine at {engine_path}.')

    engine_json_data = o3de_object.get_engine_json_data(engine_path=engine_path)
    if not engine_json_data:
        logger.error('Failed to retrieve engine json data for the engine at '
                     f'"{engine_path}" which is required to resolve gem dependencies.')
        return 1

    if project_path:
        project_json_data = o3de_object.get_project_json_data(project_path=project_path)
        if not project_json_data:
            logger.error('Failed to retrieve project json data for the project at '
                        f'"{project_path}" which is required to resolve gem dependencies.')
            return 1
        active_gem_names = project_json_data.get('gem_names',[])
        enabled_gems_file = o3de_object.get_enabled_gem_cmake_file(project_path=project_path)
        if enabled_gems_file.is_file():
            active_gem_names.extend(o3de_object.get_enabled_gems(enabled_gems_file))
    else:
        active_gem_names = engine_json_data.get('gem_names',[])

    # some gem name entries will be dictionaries - convert to a set of strings
    gem_names_with_optional_gems = utils.get_gem_names_set(active_gem_names, include_optional=True)
    if not gem_names_with_optional_gems:
        logger.info(f'No gem names were found to use as input to resolve gem dependencies.')
        if resolved_gem_dependencies_output_path:
            with resolved_gem_dependencies_output_path.open('w') as output:
                output.write('')
        return 0

    all_gems_json_data = o3de_object.get_gems_json_data_by_name(engine_path=engine_path,
                                                             project_path=project_path,
                                                             include_manifest_gems=True,
                                                             include_engine_gems=True,
                                                             external_subdirectories=external_subdirectories.split(';') if isinstance(external_subdirectories, str) else external_subdirectories)

    # First try to resolve with optional gems
    results, errors = compatibility.resolve_gem_dependencies(gem_names_with_optional_gems,
                                                             all_gems_json_data,
                                                             engine_json_data,
                                                             include_optional=True)
    if errors:
        logger.warning('Failed to resolve dependencies with optional gems, trying without optional gems.')

        # Try without optional gems
        gem_names_without_optional = utils.get_gem_names_set(active_gem_names, include_optional=False)
        results, errors = compatibility.resolve_gem_dependencies(gem_names_without_optional,
                                                                 all_gems_json_data,
                                                                 engine_json_data,
                                                                 include_optional=False)

    if errors:
        logger.error(f'Failed to resolve dependencies:\n  ' + '\n  '.join(errors))
        return 1

    # make a list of <gem_name>;<gem_path> for cmake
    # Support both legacy (gem_name) and Schema 2.0 (gem.name) formats
    def _gem_name(gem_data):
        return validation.get_object_name(gem_data, 'gem') or gem_data.get('gem_name', '').strip()

    gem_paths = sorted(f"{_gem_name(gem.gem_json_data)};{gem.gem_json_data['path'].resolve().as_posix()}" for _, gem in results.items())
    # use dict to remove duplicates and preserve order so it's easier to read/debug
    gem_paths = list(dict.fromkeys(gem_paths))
    # join everything with a ';' character which is a list entry delimiter in CMake
    # so the keys and values are all list entries
    gem_paths_list = ';'.join(gem_paths)

    if resolved_gem_dependencies_output_path:
        with resolved_gem_dependencies_output_path.open('w') as output:
            output.write(gem_paths_list)
    else:
        print(gem_paths_list)

    return 0

def _resolve_gem_dependency_paths(args: argparse) -> int:
    return resolve_gem_dependency_paths(
                            engine_path=args.engine_path,
                            project_path=args.project_path,
                            external_subdirectories=args.external_subdirectories,
                            resolved_gem_dependencies_output_path=args.gem_paths_output_file
                             )

def _update_project_presets_to_include_engine_presets(args: argparse) -> int:
    project_path = args.project_path
    if not project_path:
        project_path = o3de_object.get_registered(project_name=args.project_name)
        if not project_path:
            logger.error(f'Project with name {args.project_name} is not registered')
            return 1

    # Form the path the CMakePresets.json that will include the engine presets
    preset_path = project_path / PROJECT_ENGINE_PRESET_RELATIVE_PATH

    # Map boolean non-error result to a return code of 0
    return 0 if update_cmake_presets_for_project(
        preset_path=preset_path,
        engine_name=args.engine_name,
        engine_version=args.engine_version,
        engine_path=args.engine_path) != UpdatePresetResult.Error else 1

def add_args(subparsers) -> None:
    """
    add_args is called to add subparsers arguments to each command such that it can be
    a central python file such as o3de.py.
    It can be run from the o3de.py script as follows
    call add_args and execute: python o3de.py resolve-gem-dependencies --pp <path-to-project>
    :param subparsers: the caller instantiates subparsers and passes it in here
    """
    # Add command for resolving gem dependencies
    gem_dependencies_parser = subparsers.add_parser('resolve-gem-dependencies')
    group = gem_dependencies_parser.add_argument_group("resolve gem dependencies")
    group.add_argument('-pp', '--project-path', type=pathlib.Path, required=False,
                       help='The path to the project.')
    group.add_argument('-ep', '--engine-path', type=pathlib.Path, required=False,
                       help='The path to the engine.')
    group.add_argument('-ed', '--external-subdirectories', type=str, required=False, nargs='*',
                       help='Additional list of subdirectories.')
    group.add_argument('-gpof', '--gem-paths-output-file', type=pathlib.Path, required=False,
                       help='The path to the resolved gem paths output file. If not provided, the list will be output to STDOUT.')
    
    gem_dependencies_parser.set_defaults(func=_resolve_gem_dependency_paths)

    # Add command for updating the project presets
    update_cmake_presets_for_project_parser = subparsers.add_parser('update-cmake-presets-for-project')
    project_group = update_cmake_presets_for_project_parser.add_mutually_exclusive_group(required=True)
    project_group.add_argument('--project-path', '-pp', type=pathlib.Path,
                               help='The path to a project.')
    project_group.add_argument('--project-name', '-pn', type=str,
                               help='The name of a project.')

    engine_group = update_cmake_presets_for_project_parser.add_argument_group('engine identifiers')
    # The --engine-path and --engine-name arguments are mutually exclusive and one of the are required
    engine_path_group = engine_group.add_mutually_exclusive_group(required=True)
    engine_path_group.add_argument('--engine-path', '-ep', type=pathlib.Path,
                                   help='The path to the engine.')
    engine_path_group.add_argument('--engine-name', '-en', type=str,
                                   help='The name of the engine use to lookup the engine path.')
    # Add the --engine-version argument directly to the `engine_group` variable
    engine_group.add_argument('--engine-version', '-ev', type=str,
                              help='Version of the engine to query when the --engine-name argument is used')

    update_cmake_presets_for_project_parser.set_defaults(func=_update_project_presets_to_include_engine_presets)
