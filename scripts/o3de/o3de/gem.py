#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import json
import logging
import pathlib
import urllib.parse
import urllib.request
import hashlib
from datetime import datetime, timezone
from o3de import o3de_object, utils, validation, cache, schema, object

logger = logging.getLogger('o3de.gem')
logging.basicConfig(format=utils.LOG_FORMAT)

# Sanitize the gem URI by removing excess whitespace and any trailing slashes
# and appending "gem.json" if it doesn't already exist
def sanitize_gem_uri(gem_uri: str) -> str or None:
    return object.sanitize_object_uri(gem_uri, 'gem.json')


def gem_enabled(gem_json_data:dict) -> bool:
    return object.object_enabled(gem_json_data)


def gem_uri_enabled(gem_uri: str) -> bool:
    # sanitize the gem_uri
    gem_uri = sanitize_gem_uri(gem_uri)
    if not gem_uri:
        return False

    gem_json_cache_file, _ = cache.get_cache_file_uri(gem_uri)

    gem_json_data = o3de_object.get_json_data_file(gem_json_cache_file, "gem", validation.valid_o3de_gem_json)
    if gem_json_data:
        return gem_enabled(gem_json_data)

    return False


def validate_remote_gem(gem_uri: str, validate_contained_objects: bool = False) -> bool:
    # sanitize the gem_uri
    gem_uri = sanitize_gem_uri(gem_uri)
    if not gem_uri:
        return False

    cache_file = object.download_object_manifest(gem_uri)
    if not cache_file:
        logger.error(f'Could not download file at {gem_uri}')
        return False

    if not validation.valid_o3de_gem_json(cache_file):
        logger.error(f'Repository JSON {cache_file} could not be loaded or is missing required values')
        return False

    if validate_contained_objects:
        return object.validate_contained_remote_objects(gem_uri, cache_file)

    return True


def process_add_o3de_gem(file_name: str or pathlib.Path,
                          gem_set: set,
                          download_missing_files_only: bool = False) -> int:
    file_name = pathlib.Path(file_name).resolve()
    if not validation.valid_o3de_gem_json(file_name):
        logger.error(f'Repository JSON {file_name} could not be loaded or is missing required values')
        return 1

    gem_data = {}
    with file_name.open('r') as f:
        try:
            gem_data = json.load(f)
        except json.JSONDecodeError as e:
            logger.error(f'{file_name} failed to load: {str(e)}')
            return 1

    with file_name.open('w') as f:
        try:
            # write the ISO8601 format which includes UTC offset
            # YYYY-MM-DDTHH:MM:SS.mmmmmmTZD  (e.g. 2012-03-29T10:05:45.12345+06:00)
            # TZD (time zone designator may have + or - indicating how far ahead or 
            # behind a time zone is from UTC)
            # because we are writing out UTC dates, the TZD will always be +00:00
            gem_data.update({'last_updated': datetime.now(timezone.utc).isoformat()})
            f.write(json.dumps(gem_data, indent=4) + '\n')
        except Exception as e:
            logger.error(f'{file_name} failed to save: {str(e)}')
            return 1

    if object.download_object_manifests(gem_data, download_missing_files_only) != 0:
        return 1

    # Having a gem is also optional
    gem_list = []
    gem_list.extend(gem_data.get('gems',[]))
    for gem in gem_list:
        if gem not in gem_set:
            gem_uri = sanitize_gem_uri(gem)
            if not gem_uri:
                logger.error(f'Repository URI {gem} is invalid')
                continue
            # add the gem to the set of gems to avoid duplicates                
            gem_set.add(gem_uri)
            
            cache_file, parsed_uri = cache.get_cache_file_uri(gem_uri)
            
            if not cache_file.is_file() or not download_missing_files_only:
                download_file_result = utils.download_file(parsed_uri, cache_file, True)
                if download_file_result != 0:
                    return download_file_result

            return process_add_o3de_gem(cache_file, gem_set, download_missing_files_only)
    return 0


def get_object_versions_json_data(remote_object_list:list, required_json_key:str = None, required_json_value:str = None) -> list:
    """
    Convert a list of remote objects that may have 'versions_data', into a list
    of object json data with a separate entry for every entry in 'versions_data'
    or a single entry for every remote object that has no 'versions_data' entries
    :param remote_object_list The list of remote object json data
    :param required_json_key Optional required json key to look for in each object
    :param required_json_value Optional required value if required json key is specified
    """
    object_json_data_list = []
    for remote_object_json_data in remote_object_list:
        if required_json_key and remote_object_json_data.get(required_json_key, '') != required_json_value:
            continue

        versions_data = remote_object_json_data.pop('versions_data', None)
        if versions_data:
            version_found = False
            for version_json_data in versions_data:
                if remote_object_json_data.get('version') == version_json_data.get('version'):
                    version_found = True
                object_json_data_list.append(remote_object_json_data | version_json_data)
            if not version_found:
                object_json_data_list.append(remote_object_json_data)
        else:
            object_json_data_list.append(remote_object_json_data)

    return object_json_data_list


def get_object_json_data_from_cached_gem(gem_uri: str, gem_key: str, object_typename: str, object_validator, enabled_only = True) -> list:
    # sanitize the gem_uri
    gem_uri = sanitize_gem_uri(gem_uri)
    cache_file, _ = cache.get_cache_file_uri(gem_uri)

    o3de_object_json_data = list()

    file_name = pathlib.Path(cache_file).resolve()
    if not file_name.is_file():
        logger.info(f'Could not find cached gemsitory json file for {gem_uri}, attempting to download')

        # attempt to download the missing gem.json
        cache_file = object.download_object_manifest(gem_uri)
        if not cache_file:
            logger.error(f'Could not download the gemsitory json file from {gem_uri}')
            return list()
        file_name = pathlib.Path(cache_file).resolve()
        if not file_name.is_file():
            logger.error(f'Could not download the gemsitory json file from {gem_uri}')
            return list() 

    with file_name.open('r') as f:
        try:
            gem_data = json.load(f)
        except json.JSONDecodeError as e:
            logger.error(f'{file_name} failed to load: {str(e)}')
            return list()

        if enabled_only and not gem_enabled(gem_data):
            return list()

        gem_schema_version = schema.get_schema_version(gem_data)
        if gem_schema_version == schema.VERSION_IMPLICIT:

            # Get list of objects, then add all json paths to the list if they exist in the cache
            gem_objects = []
            try:
                gem_objects.append((gem_data[gem_key], object_typename + '.json'))
            except KeyError:
                pass

            for o3de_object_uris, manifest_json in gem_objects:
                for o3de_object_uri in o3de_object_uris:
                    manifest_json_uri = f'{o3de_object_uri}/{manifest_json}'
                    cache_object_json_filepath, _ = cache.get_cache_file_uri(manifest_json_uri)
                    
                    if not cache_object_json_filepath.is_file():
                        # attempt to download the missing file
                        cache_object_json_filepath = object.download_object_manifest(manifest_json_uri)
                        if not cache_object_json_filepath:
                            logger.warning(f'Could not download the missing cached {gem_key} json file {cache_object_json_filepath} from {manifest_json_uri} in gem {gem_uri}')
                            continue

                    json_data = o3de_object.get_json_data_file(cache_object_json_filepath, object_typename, object_validator)
                    # validation errors will be logged via the function above
                    if json_data:
                        o3de_object_json_data.append(json_data)

        elif gem_schema_version == schema.VERSION_1_0_0:
            # the new schema version appends _data to the gem key
            # so it doesn't conflict with version 0.0.0 fields 
            gem_key = gem_key if gem_key.endswith('_data') else (gem_key + '_data')
            o3de_object_json_data.extend(get_object_versions_json_data(gem_data.get(gem_key,[])))

    return o3de_object_json_data


def get_gem_json_data_from_cached_gem(gem_uri: str, enabled_only: bool = True) -> list:
    gems_json_data = get_object_json_data_from_cached_gem(gem_uri, 'gems', 'gem', validation.valid_o3de_gem_json, enabled_only)

    gems_json_data = get_object_json_data_from_cached_gem(gem_uri, 'gems', 'gem', validation.valid_o3de_gem_json, enabled_only)
    for gem_entry in gems_json_data:
       gems_json_data.extend(get_gem_json_data_from_cached_gem(gem_entry['gem_uri'], enabled_only))

    return gems_json_data


def get_gem_json_data_from_all_cached_gems(enabled_only: bool = True) -> list:
    gems_json_data = list()

    for gem_uri in o3de_object.get_manifest_child_gems():
        gems_json_data.extend(get_gem_json_data_from_cached_gem(gem_uri, enabled_only))

    return gems_json_data


def get_project_json_data_from_cached_gem(gem_uri: str, enabled_only: bool = True) -> list:
    projects_json_data = get_object_json_data_from_cached_gem(gem_uri, 'projects', 'project', validation.valid_o3de_project_json, enabled_only)

    gems_json_data = get_object_json_data_from_cached_gem(gem_uri, 'gems', 'gem', validation.valid_o3de_gem_json, enabled_only)
    for gem_entry in gems_json_data:
       projects_json_data.extend(get_project_json_data_from_cached_gem(gem_entry['gem_uri'], enabled_only))

    return projects_json_data


def get_project_json_data_from_all_cached_gems(enabled_only: bool = True) -> list:
    projects_json_data = list()

    for gem_uri in o3de_object.get_manifest_child_gems():
        projects_json_data.extend(get_project_json_data_from_cached_gem(gem_uri, enabled_only))

    return projects_json_data


def get_template_json_data_from_cached_gem(gem_uri: str, enabled_only: bool = True) -> list:
    templates_json_data = get_object_json_data_from_cached_gem(gem_uri, 'templates', 'template', validation.valid_o3de_template_json, enabled_only)

    gems_json_data = get_object_json_data_from_cached_gem(gem_uri, 'gems', 'gem', validation.valid_o3de_gem_json, enabled_only)
    for gem_entry in gems_json_data:
       templates_json_data.extend(get_template_json_data_from_cached_gem(gem_entry['gem_uri'], enabled_only))

    return templates_json_data


def get_template_json_data_from_all_cached_gems(enabled_only: bool = True) -> list:
    templates_json_data = list()

    for gem_uri in o3de_object.get_manifest_child_gems():
        templates_json_data.extend(get_template_json_data_from_cached_gem(gem_uri, enabled_only))

    return templates_json_data


def refresh_gem(gem_uri: str,
                 gem_set: set = None,
                 download_missing_files_only: bool = False) -> int:
    #sanitize the gem_uri
    gem_uri = sanitize_gem_uri(gem_uri)
    if not gem_uri:
        logger.error(f'Repository URI {gem_uri} is invalid')
        return 1

    if not gem_uri_enabled(gem_uri):
        logger.info(f'Not refreshing {gem_uri} gem because it is deactivated.')
        return 0

    if not gem_set:
        gem_set = set()

    cache_file, _ = cache.get_cache_file_uri(gem_uri)
    if not cache_file.is_file() or not download_missing_files_only:
        cache_file = object.download_object_manifest(gem_uri)
        if not cache_file:
            logger.error(f'Repo json {gem_uri} could not download.')
            return 1

    if not validation.valid_o3de_gem_json(cache_file):
        logger.error(f'Repo json {gem_uri} is not valid.')
        cache_file.unlink()
        return 1

    return process_add_o3de_gem(cache_file, gem_set, download_missing_files_only)


def refresh_gems(download_missing_files_only: bool = False) -> int:
    result = 0

    # set will stop circular references
    gem_set = set()
    
    # get the list of gems from the manifest 
    for gem_uri in o3de_object.get_manifest_child_gems():
        gem_uri = sanitize_gem_uri(gem_uri)
        if not gem_uri:
            logger.error(f'Repository URI {gem_uri} is invalid')
            continue
        if gem_uri not in gem_set:
            gem_set.add(gem_uri)
            last_failure = refresh_gem(gem_uri, gem_set, download_missing_files_only)
            if last_failure:
                result = last_failure
    
    # only cache the curated and uncurated gems
    curated_gem_uri = 'https://canonical.o3de.org/curated/gem.json'
    curated_cache_file, _ = cache.get_cache_file_uri(curated_gem_uri)
    if not curated_cache_file.is_file() or not download_missing_files_only:
        curated_cache_file = object.download_object_manifest(curated_gem_uri)
        if not curated_cache_file:
            logger.error(f'{curated_gem_uri} could not be downloaded.')
            result = 1
    
    uncurated_gem_uri = 'https://canonical.o3de.org/uncurated/gem.json'
    uncurated_cache_file, _ = cache.get_cache_file_uri(uncurated_gem_uri)
    if not uncurated_cache_file.is_file() or not download_missing_files_only:
        uncurated_cache_file = object.download_object_manifest(uncurated_gem_uri)
        if not uncurated_cache_file:
            logger.error(f'{uncurated_gem_uri} could not be downloaded.')
            result = 1

    return result


def search_gem(manifest_json_data: dict,
                engine_name: str = None,
                project_name: str = None,
                gem_name: str = None,
                template_name: str = None,
                restricted_name: str = None) -> dict or None:

    # don't search this gem if it isn't enabled
    if not gem_enabled(manifest_json_data):
        return None

    o3de_object = None

    gem_schema_version = schema.get_schema_version(manifest_json_data)

    if gem_schema_version == schema.VERSION_IMPLICIT:        
        if isinstance(engine_name, str):
            o3de_object = search_o3de_manifest_for_object(manifest_json_data, 'engines', 'engine.json', 'engine_name', engine_name)
        elif isinstance(project_name, str):
            o3de_object = search_o3de_manifest_for_object(manifest_json_data, 'projects', 'project.json', 'project_name', project_name)
        elif isinstance(gem_name, str):
            o3de_object = search_o3de_manifest_for_object(manifest_json_data, 'gems', 'gem.json', 'gem_name', gem_name)
        elif isinstance(template_name, str):
            o3de_object = search_o3de_manifest_for_object(manifest_json_data, 'templates', 'template.json', 'template_name', template_name)
        elif isinstance(restricted_name, str):
            o3de_object = search_o3de_manifest_for_object(manifest_json_data, 'restricted', 'restricted.json', 'restricted_name', restricted_name)
        else:
            return None
        
    elif gem_schema_version == schema.VERSION_1_0_0:
        #search for the o3de object from inside gems object 
        if isinstance(engine_name, str):
            o3de_object = search_o3de_gem_for_object(manifest_json_data, 'engines_data', 'engine_name', engine_name)
        elif isinstance(project_name, str):
            o3de_object = search_o3de_gem_for_object(manifest_json_data, 'projects_data', 'project_name', project_name)
        elif isinstance(gem_name, str):
            o3de_object = search_o3de_gem_for_object(manifest_json_data, 'gems_data', 'gem_name', gem_name)
        elif isinstance(template_name, str):
            o3de_object = search_o3de_gem_for_object(manifest_json_data, 'templates_data', 'template_name', template_name)
        elif isinstance(restricted_name, str):
            o3de_object = search_o3de_gem_for_object(manifest_json_data, 'restricted_data', 'restricted_name', restricted_name)
        else:
            return None
        
    if o3de_object:
        o3de_object['gem_name'] = manifest_json_data['gem_name']
        return o3de_object
    # recurse into the gems object to search for the o3de object
    o3de_object_uris = []
    try:
        o3de_object_uris = manifest_json_data['gems']
    except KeyError:
        pass

    manifest_json = 'gem.json'
    search_func = lambda manifest_json_data: search_gem(manifest_json_data, engine_name, project_name, gem_name, template_name)
    return search_o3de_object(manifest_json, o3de_object_uris, search_func)


def search_o3de_gem_for_object(gem_json_data: dict, manifest_attribute:str, target_json_key:str, target_name: str):
    remote_candidates = gem_json_data.get(manifest_attribute, [])

    target_name_without_version_specifier, _ = utils.get_object_name_and_optional_version_specifier(target_name)

    # merge all versioned data into a list of candidates
    versioned_candidates = get_object_versions_json_data(remote_candidates, target_json_key, target_name_without_version_specifier)

    return o3de_object.get_most_compatible_object(object_name=target_name, name_key=target_json_key, objects=versioned_candidates)


def search_o3de_manifest_for_object(manifest_json_data: dict, manifest_attribute: str, target_manifest_json: str, target_json_key: str, target_name: str):
    o3de_object_uris = manifest_json_data.get(manifest_attribute, [])

    # load all the .json files and then find the most compatible object
    candidates = []
    for o3de_object_uri in o3de_object_uris:
        manifest_uri = f'{o3de_object_uri}/{target_manifest_json}'
        cache_file, _ = cache.get_cache_file_uri(manifest_uri)
        if cache_file.is_file():
            with cache_file.open('r') as f:
                try:
                    manifest_json_data = json.load(f)
                except json.JSONDecodeError as e:
                    logger.warning(f'{cache_file} failed to load: {str(e)}')
                else:
                    candidates.append(manifest_json_data)

    return o3de_object.get_most_compatible_object(object_name=target_name, name_key=target_json_key, objects=candidates)


def search_o3de_object(manifest_json, o3de_object_uris, search_func):
    # Search for the o3de object based on the supplied object name in the current gem
    for o3de_object_uri in o3de_object_uris:
        manifest_uri = f'{o3de_object_uri}/{manifest_json}'
        cache_file, _ = cache.get_cache_file_uri(manifest_uri)

        if cache_file.is_file():
            with cache_file.open('r') as f:
                try:
                    manifest_json_data = json.load(f)
                except json.JSONDecodeError as e:
                    logger.warning(f'{cache_file} failed to load: {str(e)}')
                else:
                    result_json_data = search_func(manifest_json_data)
                    if result_json_data:
                        return result_json_data
    return None


def set_gem_enabled(gem_uri:str, enabled:bool) -> int:
    #sanitize the gem_uri
    gem_uri = sanitize_gem_uri(gem_uri)
    if not gem_uri:
        logger.error(f'Repository URI {gem_uri} is invalid')
        return 1

    # avoid downloading if the file already exists and is valid
    gem_json_cache_file, _ = cache.get_cache_file_uri(gem_uri)
    gem_json_data = o3de_object.get_json_data_file(gem_json_cache_file, "gem", validation.valid_o3de_gem_json)
    if not gem_json_data:
        # attempt to download the gem.json 
        gem_json_cache_file = object.download_object_manifest(gem_uri)
        if not gem_json_cache_file.is_file():
            logger.error(f'{gem_json_cache_file} could not be downloaded')
            return 1

        gem_json_data = o3de_object.get_json_data_file(gem_json_cache_file, "gem", validation.valid_o3de_gem_json)
        if not gem_json_data:
            logger.error(f'Repository JSON {gem_json_cache_file} could not be loaded or is missing required values')
            gem_json_cache_file.unlink()
            return 1

    with gem_json_cache_file.open('w') as f:
        try:
            # write the ISO8601 format which includes UTC offset
            # YYYY-MM-DDTHH:MM:SS.mmmmmmTZD  (e.g. 2012-03-29T10:05:45.12345+06:00)
            # TZD (time zone designator may have + or - indicating how far ahead or 
            # behind a time zone is from UTC)
            # because we are writing out UTC dates, the TZD will always be +00:00
            gem_json_data.update({'last_updated': datetime.now(timezone.utc).isoformat()})
            gem_json_data.update({'enabled': enabled})
            f.write(json.dumps(gem_json_data, indent=4) + '\n')
        except Exception as e:
            logger.error(f'{gem_json_cache_file} failed to save: {str(e)}')
            return 1

    return 0


def _run_gem(args: argparse) -> int:
    if args.refresh_gem:
        return refresh_gem(args.refresh_gem)
    elif args.refresh_all_gems:
        return refresh_gems()
    elif args.activate_gem:
        return set_gem_enabled(args.activate_gem, True)
    elif args.deactivate_gem:
        return set_gem_enabled(args.deactivate_gem, False)

    return 1 
    
def add_args(subparsers) -> None:
    """
    add_args is called to add subparsers arguments to each command such that it can be
    a central python file such as o3de.py.
    It can be run from the o3de.py script as follows
    call add_args and execute: python o3de.py gem --refresh https://path/to/remote/gem

    :param subparsers: the caller instantiates subparsers and passes it in here
    """
    gem_subparser = subparsers.add_parser('gem')

    group = gem_subparser.add_mutually_exclusive_group(required=False)
    group.add_argument('-ar', '--activate-gem', type=str, required=False,
                       help='Activate the specified remote gemsitory, allowing searching and downloading of objects in it')
    group.add_argument('-dr', '--deactivate-gem', type=str, required=False,
                       help='Deactivate the specified remote gemsitory, preventing searching or downloading any objects in it')
    group.add_argument('-r', '--refresh-gem', type=str, required=False,
                       help='Fetch the latest meta data the specified remote gemsitory')
    group.add_argument('-ra', '--refresh-all-gems', action='store_true', required=False, default=False,
                       help='Fetch the latest meta data from all known remote gemsitory')

    gem_subparser.set_defaults(func=_run_gem)
