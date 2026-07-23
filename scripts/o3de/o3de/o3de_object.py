#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
"""
Contains functions for data from json files such as the o3de_manifests.json, engine.json, project.json, etc...
"""

from gzip import READ
import json
import logging
import os
import pathlib
import re
import shutil

from o3de.version import O3deNameVersion
import requests
from datetime import datetime, timezone
from collections import deque, namedtuple
from resolvelib import AbstractProvider, BaseReporter
from o3de import utils, cache, schema
import argparse

logging.basicConfig(format=utils.LOG_FORMAT)
logger = logging.getLogger('o3de.o3de_object')
logger.setLevel(logging.INFO)

def topological_sort_dependencies(objects_with_dependencies, get_dependencies_func):
    """
    Performs topological sorting on objects based on their dependencies.
    Dependencies will come before objects that depend on them.
    
    :param objects_with_dependencies: List of objects to sort
    :param get_dependencies_func: Function that takes an object and returns its dependencies
    :return: Topologically sorted list where dependencies come before dependents
    """
    from collections import defaultdict, deque
    
    # Build adjacency list (object -> objects that depend on it)
    graph = defaultdict(list)
    in_degree = defaultdict(int)
    all_objects = set(objects_with_dependencies)
    
    # Initialize in_degree for all objects
    for obj in objects_with_dependencies:
        in_degree[obj] = 0
    
    # Build the dependency graph
    for obj in objects_with_dependencies:
        dependencies = get_dependencies_func(obj)
        if dependencies:
            for dep in dependencies:
                if dep in all_objects:  # Only consider dependencies that are in our list
                    graph[dep].append(obj)  # dep -> obj (dep comes before obj)
                    in_degree[obj] += 1
    
    # Kahn's algorithm for topological sorting
    queue = deque([obj for obj in objects_with_dependencies if in_degree[obj] == 0])
    result = []
    
    while queue:
        current = queue.popleft()
        result.append(current)
        
        # Process all objects that depend on current
        for dependent in graph[current]:
            in_degree[dependent] -= 1
            if in_degree[dependent] == 0:
                queue.append(dependent)
    
    # Check for circular dependencies
    if len(result) != len(objects_with_dependencies):
        logger.warning("Circular dependencies detected in object list. Some objects may not be properly ordered.")
        # Add remaining objects to the end
        remaining = [obj for obj in objects_with_dependencies if obj not in result]
        result.extend(remaining)
    
    return result

def sanitize_uri(uri, expected_file_name):
    """
    Sanitizes the URI by ensuring it ends with the expected file name.
    :param uri: The URI to sanitize
    :param expected_file_name: The expected file name to append if not present
    :return: The sanitized URI
    """
    # sanitize the object_uri
    if is_local(uri):
        uri = pathlib.Path(uri).as_posix()

    uri = uri.strip().rstrip('/')
    # check if URI already ends with file_name
    if not uri.endswith('/' + expected_file_name):
        if not uri.endswith(expected_file_name):
            # Ensure there's a separator before appending
            if not uri.endswith('/'):
                uri += '/'
            uri += expected_file_name

    return uri


def is_relative(uri: str) -> bool:
    """
    Checks if the given URI is a relative path.
    :param uri: The URI to check
    :return: True if the URI is a relative path, False otherwise
    """
    # A relative path does not start with a scheme or an absolute path indicator
    return not is_remote(uri) and not os.path.isabs(uri)


def is_local(uri: str) -> bool:
    """
    Checks if the given URI is a local file path.
    :param uri: The URI to check
    :return: True if the URI is a local file path, False otherwise
    """
    return not is_remote(uri)


def is_remote(uri: str) -> bool:
    """
    Checks if the given URI is a remote URL.
    :param uri: The URI to check
    :return: True if the URI is a remote URL, False otherwise
    """
    # Check if the URI starts with a valid URL scheme
    return str(uri).startswith(('http://', 'https://', 'ftp://', 'ftps://'))


# Directory methods
def get_this_engine_path() -> pathlib.Path:
    # When running from SNAP, __file__ was returning an incorrect (temporary) folder so
    # we manually build the correct path from env variables here when running from snap
    if "SNAP" in os.environ and "SNAP_BUILD" in os.environ:
        return pathlib.Path(os.environ.get('SNAP')) / os.environ.get('SNAP_BUILD')
    else:
        return pathlib.Path(os.path.realpath(__file__)).parents[3].resolve()


def get_user_home_path() -> pathlib.Path:
    return pathlib.Path(os.path.expanduser("~")).resolve()


def get_user_dot_o3de_path() -> pathlib.Path:
    """ Returns the path to the user's .o3de directory."""
    o3de_path = get_user_home_path() / '.o3de'
    o3de_path.mkdir(parents=True, exist_ok=True)
    return o3de_path


def get_user_dot_cmake_path() -> pathlib.Path:
    """ Returns the path to the user's .cmake directory."""
    cmake_path = get_user_home_path() / '.cmake'
    cmake_path.mkdir(parents=True, exist_ok=True)
    return cmake_path


def get_user_cmake_packages_path() -> pathlib.Path:
    """ Returns the path to the user's .cmake/packages directory."""
    packages_path = get_user_dot_cmake_path() / "packages"
    packages_path.mkdir(parents=True, exist_ok=True)
    return packages_path


def get_user_o3de_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE directory."""
    o3de_user_path = get_user_home_path() / 'O3DE'
    o3de_user_path.mkdir(parents=True, exist_ok=True)
    return o3de_user_path


def get_user_o3de_registry_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE registry directory."""
    registry_path = get_user_dot_o3de_path() / 'Registry'
    registry_path.mkdir(parents=True, exist_ok=True)
    return registry_path


def get_user_o3de_cache_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE cache directory."""
    cache_path = get_user_dot_o3de_path() / 'Cache'
    cache_path.mkdir(parents=True, exist_ok=True)
    return cache_path


def get_user_o3de_download_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE download directory."""
    download_path = get_user_dot_o3de_path() / 'Download'
    download_path.mkdir(parents=True, exist_ok=True)
    return download_path


def get_user_o3de_engines_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE engines directory."""
    engines_path = get_user_o3de_path() / 'Engines'
    engines_path.mkdir(parents=True, exist_ok=True)
    return engines_path


def get_user_o3de_projects_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE projects directory."""
    projects_path = get_user_o3de_path() / 'Projects'
    projects_path.mkdir(parents=True, exist_ok=True)
    return projects_path


def get_user_o3de_gems_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE gems directory."""
    gems_path = get_user_o3de_path() / 'Gems'
    gems_path.mkdir(parents=True, exist_ok=True)
    return gems_path


def get_user_o3de_templates_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE templates directory."""
    templates_path = get_user_o3de_path() / 'Templates'
    templates_path.mkdir(parents=True, exist_ok=True)
    return templates_path


def get_user_o3de_restricteds_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE restricteds directory."""
    restricted_path = get_user_o3de_path() / 'Restricteds'
    restricted_path.mkdir(parents=True, exist_ok=True)
    return restricted_path


def get_user_o3de_repos_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE repos directory."""
    repos_path = get_user_o3de_path() / 'Repos'
    repos_path.mkdir(parents=True, exist_ok=True)
    return repos_path


def get_user_o3de_logs_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE logs directory."""
    logs_path = get_user_dot_o3de_path() / 'Logs'
    logs_path.mkdir(parents=True, exist_ok=True)
    return logs_path


def get_user_o3de_third_party_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE third-party directory."""
    third_party_path = get_user_dot_o3de_path() / '3rdParty'
    third_party_path.mkdir(parents=True, exist_ok=True)
    return third_party_path


def get_user_o3de_manifest_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE manifest file."""
    return get_user_dot_o3de_path() / 'o3de_manifest.json'


def get_user_o3de_resolved_manifest_path() -> pathlib.Path:
    """ Returns the path to the user's O3DE resolved manifest file."""
    return get_user_dot_o3de_path() / 'resolved_o3de_manifest.json'


# If the users .o3de/o3de_manifest.json does not exists we can create a default one from this data
def get_default_o3de_manifest_json_data() -> dict:
    """
    Returns dict with default values suitable for storing
    in the o3de_manifests.json
    """
    user_name = os.path.expanduser("~")
    o3de_path = get_user_dot_o3de_path()
    default_registry_path = get_user_o3de_registry_path()
    default_cache_path = get_user_o3de_cache_path()
    default_downloads_path = get_user_o3de_download_path()
    default_logs_path = get_user_o3de_logs_path()
    default_engines_path = get_user_o3de_engines_path()
    default_projects_path = get_user_o3de_projects_path()
    default_gems_path = get_user_o3de_gems_path()
    default_templates_path = get_user_o3de_templates_path()
    default_restricteds_path = get_user_o3de_restricteds_path()
    default_repos_path = get_user_o3de_repos_path()
    default_third_party_path = get_user_o3de_third_party_path()

    manifest_json_data = {
        '$schema': 'https://canonical.o3de.org/o3de-manifest-2.0.0.json',
        '$schemaVersion': '2.0.0',
        'o3de_manifest': {
            'name': f'home.{user_name}.manifest'
        },
        'country': {
            'code': utils.determine_country_code()
        },
        'default': {
            'engines_path': f'{default_engines_path.as_posix()}',
            'projects_path': f'{default_projects_path.as_posix()}',
            'gems_path': f'{default_gems_path.as_posix()}',
            'templates_path': f'{default_templates_path.as_posix()}',
            'repos_path': f'{default_repos_path.as_posix()}',
            'restricteds_path': f'{default_restricteds_path.as_posix()}',
            'third_party_path': f'{default_third_party_path.as_posix()}'
        },
        'children': {
            'engines': [
                f'{sanitize_uri(get_this_engine_path().as_posix(), "engine.json")}'
            ],
            'projects': [],
            'gems': [],
            'templates': [],
            'repos': [],
            'restricteds': []
        },
        'remote': {
            'engines': [],
            'projects': [],
            'gems': [],
            'templates': [],
            'repos': [],
            'restricteds': []
        }
    }

    return manifest_json_data


"""
O3DE Header Class
This class represents an O3DE object, which can be an engine, project, gem, template, repo or restricted.
It provides methods to load, parse, and manage the object data, including its dependencies, compatibilities, and other attributes.
"""
class O3deHeader:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deHeader class.
        :param json_data: JSON data for the object header
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_name(self):
        """Returns the name of the object"""
        return self.json_data.get('name', '')
    
    def get_version(self):
        """Returns the version of the object"""
        return self.json_data.get('version', '0.0.0')
    
    def get_display_name(self):
        """Returns the display name of the object"""
        return self.json_data.get('display_name', '')

    def get_description(self):
        """Returns the description of the object"""
        return self.json_data.get('description', '')

    def get_type(self):
        """Returns the type of the object"""
        return self.json_data.get('type', '')
    
    def get_id(self):
        """Returns the ID of the object"""
        return self.json_data.get('id', '')
    
    def get_copyright_text(self):
        """Returns the full copyright text of the file"""
        return self.json_data.get('copyright_text', '')
    
    def get_copyright_year(self):
        """Returns the copyright year of the file"""
        return self.json_data.get('copyright_year', '')

"""
O3DE Api Versions Class
This class represents the API versions of an O3DE object.
"""
class O3deApiVersions:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deApiVersions class.
        :param json_data: JSON data for the API versions
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_editor(self):
        """Returns the Editor API version"""
        return self.json_data.get('editor', '')
    
    def get_framework(self):
        """Returns the Framework API version"""
        return self.json_data.get('framework', '')
    
    def get_launcher(self):
        """Returns the Launcher API version"""
        return self.json_data.get('launcher', '')
    
    def get_tools(self):
        """Returns the Tools API version"""
        return self.json_data.get('tools', '')

"""
O3DE Country Class
This class represents an O3DE country object
"""
class O3deCountry:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deCountry class.
        :param json_data: JSON data for the object header
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_code(self):
        """Returns the country code"""
        return self.json_data.get('code', '')

    def get_name(self):
        """Returns the name of the object"""
        return self.json_data.get('name', '')

    def get_official_name(self):
        """Returns the official name of the country"""
        return self.json_data.get('official_name', '')

"""
O3DE Objects Lists Class
This class represents a list of O3DE objects, such as engines, projects, gems, templates, repos and restricteds.
It provides methods to retrieve the lists of these objects.
"""    
class O3deObjectsLists:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deObjectsLists class.
        :param json_data: JSON data for the objects lists
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_engines(self):
        """Returns the engines"""
        return self.json_data.get('engines', [])
    
    def get_projects(self):
        """Returns the projects"""
        return self.json_data.get('projects', [])
    
    def get_gems(self):
        """Returns the gems"""
        return self.json_data.get('gems', [])
    
    def get_templates(self):
        """Returns the templates"""
        return self.json_data.get('templates', [])
    
    def get_repos(self):
        """Returns the repos"""
        return self.json_data.get('repos', [])
    
    def get_restricteds(self):
        """Returns the restricteds"""
        return self.json_data.get('restricteds', [])

"""
O3DE Documentation Class
This class represents the documentation of an O3DE object.
It provides methods to retrieve the relative path, URI, and full path of the documentation.
"""
class O3deDocumentation:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deDocumentation class.
        :param json_data: JSON data for the documentation
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_relative_path(self):
        """Returns the relative path of the documentation"""
        return self.json_data.get('relative_path', '')

    def get_uri(self):
        """Returns the URI of the documentation"""
        return self.json_data.get('uri', '')
    
    def get_full_path(self):
        """Returns the full path of the documentation"""
        relative_path = self.get_relative_path()
        if relative_path:
            full_path = pathlib.Path(self.file_name).parent / relative_path
            return full_path.as_posix()

"""
O3DE Downloads Class
This class represents the downloads of an O3DE object.
It provides methods to retrieve the URIs, SHA256 checksums of the source zip, and LFS zip.
"""        
class O3deDownloads:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deDownloads class.
        :param json_data: JSON data for the downloads
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_uris(self):
        """Returns the URIs of the download"""
        return self.json_data.get('uris', '')

    def get_source_zip_sha256(self):
        """Returns the SHA256 of the source zip"""
        return self.json_data.get('source_zip_sha256', '')
    
    def get_lfs_zip_sha256(self):
        """Returns the SHA256 of the LFS zip"""
        return self.json_data.get('lfs_zip_sha256', '')

"""
O3DE Source Control Class
This class represents the source control of an O3DE object.
It provides methods to retrieve the URI, relative path, full path, branch, and tag of the source control.
"""    
class O3deSourceControl:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deSourceControl class.
        :param json_data: JSON data for the source control
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_gitUri(self):
        """Returns the URI of the source control"""
        return self.json_data.get('gitUri', '')
    
    def get_relative_path(self):
        """Returns the relative path of the source control"""
        return self.json_data.get('relative_path', '')
    
    def get_full_path(self):
        """Returns the full path of the source control"""
        relative_path = self.get_relative_path()
        if relative_path:
            full_path = pathlib.Path(self.file_name).parent / relative_path
            return full_path.as_posix()
    
    def get_branch(self):
        """Returns the branch of the source control"""
        return self.json_data.get('branch', '')
    
    def get_tag(self):
        """Returns the tag of the source control"""
        return self.json_data.get('tag', '')

"""
O3DE Release Class
This class represents a release of an O3DE object.
It provides methods to retrieve the version, source control, and download of the release.
"""
class O3deRelease:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deRelease class.
        :param json_data: JSON data for the release
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data
        
        self.source_control = O3deSourceControl(self.json_data.get('source_control', {}))
        self.download = O3deDownloads(self.json_data.get('downloads', {}))

    def get_version(self):
        """Returns the version of the release"""
        return self.json_data.get('version', '')

    def get_source_control(self):
        """Returns the source control of the release"""
        return self.source_control
    
    def get_download(self):
        """Returns the download of the release"""
        return self.download

"""
O3DE Releases Class
This class represents a list of releases of an O3DE object.
It provides methods to retrieve the releases.
"""
class O3deReleases:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deReleases class.
        :param json_data: JSON data for the releases
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data
    
        self.licenses = []
        for item in self.json_data:
            if isinstance(item, dict):
                license_obj = O3deRelease(item)
                self.licenses.append(license_obj)
            else:
                logger.warning(f"Invalid release item: {item}")

    def get(self):
        """Returns the releases"""
        return self.json_data

"""
O3DE Icon Class
This class represents the icon of an O3DE object.
It provides methods to retrieve the relative path, URI, and full path of the icon.
"""
class O3deIcon:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deIcon class.
        :param json_data: JSON data for the icon
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_relative_path(self):
        """Returns the relative path of the icon"""
        return self.json_data.get('relative_path', '')

    def get_uri(self):
        """Returns the URI of the icon"""
        return self.json_data.get('uri', '')
    
    def get_full_path(self):
        """Returns the full path of the icon"""
        relative_path = self.get_relative_path()
        if relative_path:
            full_path = pathlib.Path(self.file_name).parent / relative_path
            return full_path.as_posix()

"""
O3DE License Class
This class represents a license of an O3DE object.
It provides methods to retrieve the license identifier, URI, display name, relative path, full path, comments, scopes, and files of the license.
"""
class O3deLicense:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deLicense class.
        :param json_data: JSON data for the license
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_license_identifier(self):
        """Returns the license identifier"""
        return self.json_data.get('license_identifier', '')

    def get_uri(self):
        """Returns the license URI"""
        return self.json_data.get('uri', '')
    
    def get_display_name(self):
        """Returns the display name of the license"""
        return self.json_data.get('display_name', '')
    
    def get_relative_path(self):
        """Returns the relative path of the license"""
        return self.json_data.get('relative_path', '')
    
    def get_full_path(self):
        """Returns the full path of the license"""
        relative_path = self.get_relative_path()
        if relative_path:
            full_path = pathlib.Path(self.file_name).parent / relative_path
            return full_path.as_posix()

    def get_comments(self):
        """Returns the comments of the license"""
        return self.json_data.get('comments', '')
    
    def get_scopes(self):
        """Returns the scopes of the license"""
        return self.json_data.get('scopes', [])
    
    def get_files(self):
        """Returns the files of the license"""
        return self.json_data.get('files', [])

"""
O3DE Licenses Class
This class represents a list of licenses of an O3DE object.
It provides methods to retrieve the licenses.
"""    
class O3deLicenses:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deLicenses class.
        :param json_data: JSON data for the licenses
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data
    
        self.licenses = []
        for item in self.json_data:
            if isinstance(item, dict):
                license_obj = O3deLicense(item)
                self.licenses.append(license_obj)
            else:
                logger.warning(f"Invalid license item: {item}")

    def get(self):
        """Returns the licenses"""
        return self.json_data

"""
O3DE File Class
This class represents a file of an O3DE object.
It provides methods to retrieve the relative path, full path, attributions, checksums, comments, copyright, and notice of the file.
"""    
class O3deFile:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deFile class.
        :param json_data: JSON data for the file
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_relative_path(self):
        """Returns the relative path of the file"""
        return self.json_data.get('relative_path', '')
    
    def get_full_path(self):
        """Returns the full path of the file"""
        relative_path = self.get_relative_path()
        if relative_path:
            full_path = pathlib.Path(self.file_name).parent / relative_path
            return full_path.as_posix()
        
    def get_attributions(self):
        """Returns the attributions of the file"""
        return self.json_data.get('attributions', [])
    
    def get_checksums(self):
        """Returns the checksums of the file"""
        return self.json_data.get('checksums', [])
    
    def get_comments(self):
        """Returns the comments of the file"""
        return self.json_data.get('comments', [])
    
    def get_copyright(self):
        """Returns the copyright of the file"""
        return self.json_data.get('copyright', '')
    
    def get_notice(self):
        """Returns the notice of the file"""
        return self.json_data.get('notice', [])

"""
O3DE Origin Class
This class represents the origin of an O3DE object.
It provides methods to retrieve the name and URI of the origin.
"""
class O3deOrigin:
    def __init__(self, json_data: dict = None):
        """
        Constructor for O3deOrigin class.
        :param json_data: JSON data for the origin
        """
        if json_data is None:
            self.json_data = {}
        else:
            self.json_data = json_data

    def get_name(self):
        """Returns the name of the origin"""
        return self.json_data.get('name', '')

    def get_uri(self):
        """Returns the URI of the origin"""
        return self.json_data.get('uri', '')
    
"""
O3DE Object Class
This class represents an O3DE object, which can be an engine, project, gem, template, repo or restricted.
It provides methods to load, parse, and manage the object data, including its dependencies, compatibilities, and other attributes.
"""    
class O3deObject:

    def __init__(self, type, object_uri : str, traversed: set = None, json_data=None):
        """
        Constructor for O3deObject class.
        :param type: The type of the object (e.g., 'engine', 'project', etc.)
        :param object_uri: The URI of the object
        :param traversed: A set of traversed URIs to avoid circular references
        :param json_data: Optional JSON data for the object
        """
        # these are collections of child classes
        self.childEngineObjects = []
        self.childProjectObjects = []
        self.childGemObjects = []
        self.childTemplateObjects = []
        self.childRepoObjects = []
        self.childRestrictedObjects = []

        self.remoteEngineObjects = []
        self.remoteProjectObjects = []
        self.remoteGemObjects = []
        self.remoteTemplateObjects = []
        self.remoteRepoObjects = []
        self.remoteRestrictedObjects = []
        
        # traversed is a set of traversed URIs to avoid circular references
        if traversed is None:
            traversed = set()
        traversed.add(object_uri)

        # type is the type of the object (e.g., 'engine', 'project', etc.)        
        self.type = type
        
        # the file name is just the type with .json extension
        self.file_name = f'{type}.json'
        
        # sanitize the object_uri
        self.object_uri = sanitize_uri(object_uri, self.file_name)
        
        # get the cache_file name for this uri and the parsed uri
        self.cache_file, self.parsed_uri = cache.get_cache_file_uri(self.object_uri)

        # allow the git provider to alter the parsed uri
        self.git_provider = utils.get_git_provider(self.parsed_uri)
        if self.git_provider:
            self.parsed_uri = self.git_provider.get_specific_file_uri(self.parsed_uri)

        # get the object json data
        # if the json data was supplied we dont need to load it from the cache
        if json_data:
            self.json_data = json_data
        else:
            # if this object is local refresh the cache file
            if self.is_local():
                #remove the cache file if it exists
                if self.cache_file.is_file():
                    self.cache_file.unlink()
                #copy the object_uri file over to cache
                if pathlib.Path(self.object_uri).is_file():
                    # ensure the cache directory exists
                    pathlib.Path(self.cache_file).parent.mkdir(parents=True, exist_ok=True)
                    # copy the file to the cache
                    shutil.copyfile(self.object_uri, self.cache_file)
            else:
                # download the parsed uri to the cache_file
                if pathlib.Path(self.cache_file).is_file():
                    # check if the file is older than 1 day
                    if (datetime.now(timezone.utc) - datetime.fromtimestamp(self.cache_file.stat().st_mtime, timezone.utc)).days > 1:
                        # download the file again
                        utils.download_file(self.parsed_uri, self.cache_file, True, self.object_uri)
                else:
                    # download the file
                    utils.download_file(self.parsed_uri, self.cache_file, True, self.object_uri)

            # load the object json data from the cache file
            if pathlib.Path(self.cache_file).is_file():
                with pathlib.Path(self.cache_file).open('r') as f:
                    try:
                        self.json_data = json.load(f)
                    except json.JSONDecodeError as e:
                        logger.error(f'{self.cache_file} failed to load: {str(e)}')

        # A missing or unparseable object json must not abort the crawl —
        # fall back to empty data so the object is simply treated as invalid.
        if not hasattr(self, 'json_data') or self.json_data is None:
            logger.warning(f'No valid json data for {self.object_uri}; treating as empty object')
            self.json_data = {}

        # get the schema version
        self.schema_version = schema.get_schema_version(self.json_data)

        # upgrade the object if needed
        if self.schema_version < schema.VERSION_2_0_0:
            if self.upgrade_to_2_0_0(False) == 1:
                logger.error(f"Failed to upgrade object schema: {self.object_uri}")

        # header
        self.header = O3deHeader(self.json_data.get(self.type, {}))
                                              
        # origin
        self.origin = O3deOrigin(self.json_data.get('origin', {}))

        # licenses
        self.licenses = O3deLicenses(self.json_data.get('licenses', {}))

        # children
        self.children = O3deObjectsLists(self.json_data.get('children', {}))

        # remotes
        self.remote = O3deObjectsLists(self.json_data.get('remote', {}))

        # dependent
        self.dependent = O3deObjectsLists(self.json_data.get('dependent', {}))

        # icon
        self.icon = O3deIcon(self.json_data.get('icon', {}))

        # documentation
        self.documentation = O3deDocumentation(self.json_data.get('documentation', {}))

        # downloads
        self.downloads = O3deDownloads(self.json_data.get('downloads', {}))

        # releases
        self.releases = O3deReleases(self.json_data.get('releases', {}))

        # download and cache the licenses
        for license in self.licenses.get():
            if isinstance(license, O3deLicense):
                if self._download_resource(license.get_uri()) == 1:
                    logger.error(f"Failed to download license: {license.get_uri()}")

        # download and cache the remote icon uri
        if self._download_resource(self.icon.get_uri()) == 1:
            logger.error(f"Failed to download icon: {self.icon.get_uri()}")
        
        # download and cache the remote documentation uri
        if self._download_resource(self.documentation.get_uri()) == 1:
            logger.error(f"Failed to download documentation: {self.documentation.get_uri()}")

        """Process child objects based on the object type."""
        local_object_types = {
            'engines': ('engine.json', self.childEngineObjects, O3deEngine),
            'projects': ('project.json', self.childProjectObjects, O3deProject),
            'gems': ('gem.json', self.childGemObjects, O3deGem),
            'templates': ('template.json', self.childTemplateObjects, O3deTemplate),
            'repos': ('repo.json', self.childRepoObjects, O3deRepo),
            'restricteds': ('restricted.json', self.childRestrictedObjects, O3deRestricted)
        }
        
        # Process children section
        children = self.json_data.get('children', {})
        for obj_key, (file_name, collection, class_type) in local_object_types.items():
            for uri in children.get(obj_key, []):
                full_path = pathlib.Path(self.object_uri).parent / sanitize_uri(uri, file_name)
                full_path = full_path.as_posix()
                if full_path not in traversed:
                    traversed.add(full_path)
                    collection.append(class_type(full_path, traversed))

        # Process local section (Schema 2.0 manifest: registered local
        # objects live under 'local', not 'children').  Treat them as
        # children for discovery purposes.
        local = self.json_data.get('local', {})
        for obj_key, (file_name, collection, class_type) in local_object_types.items():
            for uri in local.get(obj_key, []):
                full_path = pathlib.Path(self.object_uri).parent / sanitize_uri(uri, file_name)
                full_path = full_path.as_posix()
                if full_path not in traversed:
                    traversed.add(full_path)
                    collection.append(class_type(full_path, traversed))

        # Process remote objects and add them to the appropriate collections
        remote_object_types = {
            'engines': ('engine.json', self.remoteEngineObjects, O3deEngine),
            'projects': ('project.json', self.remoteProjectObjects, O3deProject),
            'gems': ('gem.json', self.remoteGemObjects, O3deGem),
            'templates': ('template.json', self.remoteTemplateObjects, O3deTemplate),
            'repos': ('repo.json', self.remoteRepoObjects, O3deRepo),
            'restricteds': ('restricted.json', self.remoteRestrictedObjects, O3deRestricted)
        }
        
        # Process remote section
        remote = self.json_data.get('remote', {})
        for obj_key, (file_name, collection, class_type) in remote_object_types.items():
            for uri in remote.get(obj_key, []):
                url = sanitize_uri(uri, file_name)
                if url not in traversed:
                    traversed.add(url)
                    collection.append(class_type(url, traversed)) 


    def print(self, verbose=0, recurse=False, traversed=None, level=0):
        """ Prints the child object details, including its children and remote objects.
        :param recurse: Whether to print child objects recursively
        :param traversed: A set of traversed URIs to avoid circular references
        :param level: The current level of indentation for printing
        """
        if traversed is None:
            traversed = set()
        traversed.add(self.object_uri)

        if verbose == 0:
            print(self.type)
            for i in range(level):
                print('  ', end='')
            print(self.get_object_uri())
        elif verbose == 1:
            print(json.dumps(self.get_json_data(), indent=4))
        elif verbose > 1:
            print(f'## {self.type} ########################################\n')
            print(self.get_object_uri())
            print(json.dumps(self.get_json_data(), indent=4))
            print(f'##################################################\n')
             
        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects,

                self.remoteEngineObjects,
                self.remoteProjectObjects,
                self.remoteGemObjects,
                self.remoteTemplateObjects,
                self.remoteRepoObjects,
                self.remoteRestrictedObjects
            ]
            
            # Print objects            
            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        item.print(verbose, True, traversed, level + 1)

    def print_child(self, verbose=0, recurse=False, traversed=None, level=0):
        """ Prints the child object details, including its children and remote objects.
        :param recurse: Whether to print child objects recursively
        :param traversed: A set of traversed URIs to avoid circular references
        :param level: The current level of indentation for printing
        """
        if traversed is None:
            traversed = set()
        traversed.add(self.object_uri)

        if verbose == 0:
            print(self.type)
            for i in range(level):
                print('  ', end='')
            print(self.get_object_uri())
        elif verbose == 1:
            print(json.dumps(self.get_json_data(), indent=4))
        elif verbose > 1:
            print(f'## {self.type} ########################################\n')
            print(json.dumps(self.get_json_data(), indent=4))
            print(f'##################################################\n')
             
        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]
            
            # Print child objects            
            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        item.print(verbose, True, traversed, level + 1)
        
    def print_remote(self, verbose=0, recurse=False, traversed=None, level=0):
        """ Prints the remote object details, including its children and remote objects.
        :param recurse: Whether to print child objects recursively
        :param traversed: A set of traversed URIs to avoid circular references
        :param level: The current level of indentation for printing
        """
        if traversed is None:
            traversed = set()
        traversed.add(self.object_uri)

        if verbose == 0:
            print(self.type)
            for i in range(level):
                print('  ', end='')
            print(self.get_object_uri())
        elif verbose == 1:
            print(json.dumps(self.get_json_data(), indent=4))
        elif verbose > 1:
            print(f'## {self.type} ########################################\n')
            print(json.dumps(self.get_json_data(), indent=4))
            print(f'##################################################\n')
             
        if recurse:
            collections = [
                self.remoteEngineObjects,
                self.remoteProjectObjects,
                self.remoteGemObjects,
                self.remoteTemplateObjects,
                self.remoteRepoObjects,
                self.remoteRestrictedObjects,
                self.remoteExtensionObjects
            ]
            
            # Print child objects            
            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        item.print(verbose, True, traversed, level + 1)


    def save(self, save_children=False, traversed=None):
        """Saves the object JSON data and updates the cache file."""
        
        # traversed is a set of traversed URIs to avoid circular references
        if traversed is None:
            traversed = set()
        traversed.add(self.object_uri)

        # only save local objects and update the cache
        if self.is_local():
            with self.object_uri.open('w') as s:
                try:
                    s.write(json.dumps(self.json_data, indent=4) + '\n')
                except OSError as e:
                    logger.error(f'Manifest json failed to save: {str(e)}')
                    return False
            
            # ensure the cache directory exists
            self.cache_file.parent.mkdir(parents=True, exist_ok=True)

            # copy the file to the cache
            shutil.copyfile(self.object_uri, self.cache_file)

            if save_children:
                # save the child objects
                collections = [
                    self.childEngineObjects,
                    self.childProjectObjects,
                    self.childGemObjects,
                    self.childTemplateObjects,
                    self.childRepoObjects,
                    self.childRestrictedObjects
                ]

                for collection in collections:
                    for item in collection:
                        if item not in traversed:
                            traversed.add(item.get_object_uri())
                            if item.save(True) == False:
                                logger.error(f'Failed to save {item.get_type()}: {item.get_object_uri()}')
                                return False
        return True


    def is_local(self):
        """
        Determines if a URI points to a local resource.
        :param uri: The URI to check
        :return: True if the URI is local, False otherwise
        """
        return is_local(self.get_object_uri())
    

    def is_remote(self):
        """
        Determines if a URI points to a remote resource.
        :param uri: The URI to check
        :return: True if the URI is remote, False otherwise
        """
        return is_remote(self.get_object_uri())
    

    def get_json_data(self, recurse=False, traversed=None):
        """Returns the JSON data of the object"""
        if recurse == False:
            return self.json_data

        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        json_datas = [self.json_data]

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]

        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    extended_datas = item.get_json_data(True, traversed)
                    if extended_datas:
                        json_datas.extend(extended_datas)
        return json_datas


    def get_header(self, recurse=False, traversed=None):
        """Returns the header of the object"""
        if recurse == False:
            return self.header
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        headers = [self.header]

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]

        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    extended_headers = item.get_header(True, traversed)
                    if extended_headers:
                        headers.extend(extended_headers)
        return headers


    def get_object_uri(self, recurse=False, traversed=None):
        """Returns the URI of the object"""
        if recurse == False:
            return self.object_uri

        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)
        
        object_uris = [self.object_uri]

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]

        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    extended_object_uris = item.get_object_uri(True, traversed)
                    for extended_object_uri in extended_object_uris:
                        if extended_object_uri not in object_uris:
                            object_uris.append(extended_object_uri)
        return object_uris


    def get_version(self, recurse=False, traversed=None):
        """Returns the version of the object"""
        if recurse == False:
            return self.get_header().get_version()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        versions = [self.get_header().get_version()]

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]

        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    extended_versions = item.get_version(True, traversed)
                    for extended_version in extended_versions:
                        if extended_version not in versions:
                            versions.append(extended_version)
        return versions


    def get_display_name(self, recurse=False, traversed=None):
        """Returns the display name of the object"""
        if recurse == False:
            return self.get_header().get_display_name()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        display_names = [self.get_header().get_display_name()]

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]

        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    extended_display_names = item.get_display_name(True, traversed)
                    for extended_display_name in extended_display_names:
                        if extended_display_name not in display_names:
                            display_names.append(extended_display_name)

        return display_names

    def get_summaries(self, recurse=False, traversed=None):
        """Returns the summary of the object"""
        if recurse == False:
            return self.get_header().get_summary()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        summaries = [self.get_header().get_summary()]

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]

        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    extended_summaries = item.get_summary(True, traversed)
                    for extended_summary in extended_summaries:
                        if extended_summary not in summaries:
                            summaries.append(extended_summary)
        return summaries

    def get_restricted(self, recurse=False, traversed=None):
        """Returns the restricted objects of the object"""
        if recurse == False:
            return self.json_data.get('restricted', [])
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        restricted_objects = [self.json_data.get('restricted', [])]

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects
            ]

            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_restricted_objects = item.get_restricted(True, traversed)
                        for extended_restricted_object in extended_restricted_objects:
                            if extended_restricted_object not in restricted_objects:
                                restricted_objects.append(extended_restricted_object)
        return restricted_objects

    def get_dependent(self, recurse=False, traversed=None):
        """Returns the dependencies of the object"""
        if recurse == False:
            return self.dependent
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependencies = [self.dependent]

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependencies = item.get_dependent(True, traversed)
                        for extended_dependency in extended_dependencies:
                            if extended_dependency not in dependencies:
                                dependencies.append(extended_dependency)
        return dependencies
  
    def get_canonical_tags(self, recurse=False, traversed=None):
        """Returns the canonical tags of the object"""
        if recurse == False:
            return self.json_data.get('canonical_tags', [])
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        canonical_tags = self.json_data.get('canonical_tags', [])

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_tags = item.get_canonical_tags(True, traversed)
                        for extended_tag in extended_tags:
                            if extended_tag not in canonical_tags:
                                canonical_tags.append(extended_tag)
        return canonical_tags

    def get_user_tags(self, recurse=False, traversed=None):
        """Returns the user tags of the object"""
        if recurse == False:
            return self.json_data.get('user_tags', [])

        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        user_tags = self.json_data.get('user_tags', [])

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_tags = item.get_user_tags(True, traversed)
                        for extended_tag in extended_tags:
                            if extended_tag not in user_tags:
                                user_tags.append(extended_tag)
        return user_tags
    

    def get_platforms(self, recurse=False, traversed=None):
        """Returns the platforms of the object"""
        if recurse == False:
            return self.json_data.get('platforms', [])

        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        platforms = self.json_data.get('platforms', [])

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item.get_object_uri() not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_tags = item.get_platforms(True, traversed)
                        for extended_tag in extended_tags:
                            if extended_tag not in platforms:
                                platforms.append(extended_tag)
        return platforms

    def get_parent(self, recurse=False):
        """Returns the parent of the object"""
        parent_paths = []
        parent_objects = []
        manifest_object_paths, manifest_child_objects = manifest.get_all_child_objects()
        all_manifest_object_paths, all_manifest_child_objects = manifest.get_all_child_objects(True)

        if self.object_uri in manifest_object_paths:
            parent_paths.append(manifest.get_object_uri())
            parent_objects.append(manifest)
            return parent_paths, parent_objects

        parent_path = pathlib.Path(self.get_object_uri()).parent
        parent_path = parent_path.parent
        
        while True:
            engine_parent_path = parent_path / 'engine.json'
            project_parent_path = parent_path / 'project.json'
            gem_parent_path = parent_path / 'gem.json'
            template_parent_path = parent_path / 'template.json'
            repo_parent_path = parent_path / 'repo.json'
            restricted_parent_path = parent_path / 'restricted.json'
       
            if engine_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == engine_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            elif project_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == project_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            elif gem_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == gem_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            elif template_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == template_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            elif template_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == template_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            elif repo_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == repo_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            elif restricted_parent_path.exists():
                for full_path, object in zip(all_manifest_object_paths, all_manifest_child_objects):
                    if full_path == restricted_parent_path.as_posix():
                        parent_paths.append(full_path)
                        parent_objects.append(object)
                        if recurse:
                            parent_ancestor_paths, parent_ancestor_objects = object.get_parent(True)
                            parent_paths.extend(parent_ancestor_paths)
                            parent_objects.extend(parent_ancestor_objects)
                        return parent_paths, parent_objects

            else:
                 if parent_path in manifest_object_paths:
                    parent_paths.append(manifest.get_object_uri())
                    parent_objects.append(manifest)
                    return parent_paths, parent_objects
                 else:
                     parent_path = parent_path.parent


    def get_dependent_engines(self, recurse=False, traversed=None):
        """Returns the engine names of the object"""
        if recurse == False:
            return self.get_dependent().get_engines()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependent_engines = self.get_dependent().get_engines()

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependent_engines = item.get_dependent_engines(True, traversed)
                        for extended_dependent_engine in extended_dependent_engines:
                            if extended_dependent_engine not in dependent_engines:
                                dependent_engines.append(extended_dependent_engine)
        return dependent_engines
    

    def get_dependent_engines_sorted(self, recurse=False, traversed=None):
        #get the dependent engines. 
        dependent_engines = self.get_dependent_engines(recurse, traversed)

        #Iterate over each engine entry and make sure that if that engine has a dependent object that all dependencies appear before the object that has the dependency
        if not dependent_engines:
            return []
        
        for i in range(len(dependent_engines)):
            dependent_engine = dependent_engines[i]
            #get the dependent object for this engine
            dependent_object = self._find_child_object('engine', dependent_engine, recurse, traversed)
            if dependent_object:
                #if the dependent object is not None, then we need to make sure that all dependencies appear before this object
                for j in range(i + 1, len(dependent_engines)):
                    if dependent_engines[j] == dependent_object.get_object_uri():
                        #swap the two entries
                        dependent_engines[i], dependent_engines[j] = dependent_engines[j], dependent_engines[i]
                        break
       
        return dependent_engines


    def get_dependent_projects(self, recurse=False, traversed=None):
        """Returns the project names of the object"""
        if recurse == False:
            return self.get_dependent().get_projects()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependent_projects = self.get_dependent().get_projects()

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependent_projects = item.get_dependent_projects(True, traversed)
                        for extended_dependent_project in extended_dependent_projects:
                            if extended_dependent_project not in dependent_projects:
                                dependent_projects.append(extended_dependent_project)
        return dependent_projects


    def get_dependent_gems(self, recurse=False, traversed=None):
        """Returns the gem names of the object"""
        if recurse == False:
            return self.get_dependent().get_gems()

        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependent_gems = self.get_dependent().get_gems()

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependent_gems = item.get_dependent_gems(True, traversed)
                        for extended_dependent_gem in extended_dependent_gems:
                            if extended_dependent_gem not in dependent_gems:
                                dependent_gems.append(extended_dependent_gem)
        return dependent_gems
    

    def get_dependent_templates(self, recurse=False, traversed=None):
        """Returns the template names of the object"""
        if recurse == False:
            return self.get_dependent().get_templates()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependent_templates = self.get_dependent().get_templates()

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependent_templates = item.get_dependent_templates(True, traversed)
                        for extended_dependent_template in extended_dependent_templates:
                            if extended_dependent_template not in dependent_templates:
                                dependent_templates.append(extended_dependent_template)
        return dependent_templates
    
    def get_dependent_repos(self, recurse=False, traversed=None):
        """Returns the repo names of the object"""
        if recurse == False:
            return self.get_dependent().get_repos()

        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependent_repos = self.get_dependent().get_repos()

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependent_repos = item.get_dependent_repos(True, traversed)
                        for extended_dependent_repo in extended_dependent_repos:
                            if extended_dependent_repo not in dependent_repos:
                                dependent_repos.append(extended_dependent_repo)
        return dependent_repos

    def get_dependent_restricteds(self, recurse=False, traversed=None):
        """Returns the restricted names of the object"""
        if recurse == False:
            return self.get_dependent().get_restricteds()
        
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)

        dependent_restricteds = self.get_dependent().get_restricteds()

        if recurse:
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]

            for collection in collections:
                for item in collection:
                    if item not in traversed:
                        traversed.add(item.get_object_uri())
                        extended_dependent_restricteds = item.get_dependent_restricteds(True, traversed)
                        for extended_dependent_restricted in extended_dependent_restricteds:
                            if extended_dependent_restricted not in dependent_restricteds:
                                dependent_restricteds.append(extended_dependent_restricted)
        return dependent_restricteds


    def _find_child_object(self, object_type, object_name, recurse=False, traversed=None):
        """
        Find a child object of the specified type with the given name.
        
        :param object_type: Type of object to find ('engine', 'project', 'gem', etc.)
        :param object_name: Name of the object to find
        :param recurse: Whether to search recursively
        :param traversed: Set of traversed URIs to avoid circular references
        :return: Tuple of (object_uri, class object) or ('', None) if not found
        """
        if not traversed:
            traversed = set()
        traversed.add(self.object_uri)
        
        
        # Map object types to their collections
        collections = {
            'engine': self.childEngineObjects,
            'project': self.childProjectObjects,
            'gem': self.childGemObjects,
            'template': self.childTemplateObjects,
            'repo': self.childRepoObjects,
            'restricted': self.childRestrictedObjects
        }
        
        # First check the primary collection for the requested type
        for item in collections.get(object_type, []):
            if item.get_object_uri() not in traversed:
                traversed.add(item.get_object_uri())
                header = item.get_header()
                if header and header.get_name() == object_name:
                    return item.get_object_uri(), item
        
        # If recursive search is requested, check all collections
        if recurse:
            for collection_type, items in collections.items():
                for item in items:
                    full_path, o3de_object = item._find_child_object(object_type, object_name, True, traversed)
                    if full_path:
                        return full_path, o3de_object
                        
        return '', None


    def find_child_engine_object(self, engine_name, recurse=False, traversed=None):
        return self._find_child_object('engine', engine_name, recurse, traversed)


    def find_child_project_object(self, project_name, recurse=False, traversed=None):
        return self._find_child_object('project', project_name, recurse, traversed)


    def find_child_gem_object(self, gem_name, recurse=False, traversed=None):
        return self._find_child_object('gem', gem_name, recurse, traversed)


    def find_child_template_object(self, template_name, recurse=False, traversed=None):
        return self._find_child_object('template', template_name, recurse, traversed)


    def find_child_repo_object(self, repo_name, recurse=False, traversed=None):
        return self._find_child_object('repo', repo_name, recurse, traversed)


    def find_child_restricted_object(self, restricted_name, recurse=False, traversed=None):
        return self._find_child_object('restricted', restricted_name, recurse, traversed)


    def find_this_engine_object(self):
        """
        Find the current engine object based on the path of this script.
        :return: Tuple of (object_uri, engine_object) or ('', None) if not found
        """
        this_engine_path = get_this_engine_path()
        _, engine_objects = self.get_child_engines()
        
        for engine in engine_objects:
            # Check if the path matches the current engine path
            if engine.get_object_uri() == this_engine_path:               
                # Return the object URI and JSON data
                return engine.get_object_uri(), engine
            
        # If no matching engine found, return empty string and None                            
        return '', None


    def _find_remote_object(self, object_type, object_name, recurse=False, traversed=None):
        """
        Find a remote object of the specified type with the given name.
        
        :param object_type: Type of object to find ('engine', 'project', 'gem', etc.)
        :param object_name: Name of the object to find
        :param recurse: Whether to search recursively
        :param traversed: Set of traversed URIs to avoid circular references
        :return: Tuple of (object_uri, json_data) or ('', None) if not found
        """
        if not traversed:
            traversed = set()
        
        # Map object types to their collections
        collections = {
            'engine': self.remoteEngineObjects,
            'project': self.remoteProjectObjects,
            'gem': self.remoteGemObjects,
            'template': self.remoteTemplateObjects,
            'repo': self.remoteRepoObjects,
            'restricted': self.remoteRestrictedObjects
        }
        
        # First check the primary collection for the requested type
        for item in collections.get(object_type, []):
            if item.get_object_uri() not in traversed:
                traversed.add(item.get_object_uri())
                header = item.get_header()
                if header and header.get_name() == object_name:
                    return item.get_object_uri(), item
        
        # If recursive search is requested, check all collections
        if recurse:
            for collection_type, items in collections.items():
                for item in items:
                    full_path, o3de_object = item._find_remote_object(object_type, object_name, True, traversed)
                    if full_path:
                        return full_path, o3de_object
                        
        return '', None


    def find_remote_engine_object(self, engine_name, recurse=False, traversed=None):
        return self._find_remote_object('engine', engine_name, recurse, traversed)


    def find_remote_project_object(self, project_name, recurse=False, traversed=None):
        return self._find_remote_object('project', project_name, recurse, traversed)


    def find_remote_gem_object(self, gem_name, recurse=False, traversed=None):
        return self._find_remote_object('gem', gem_name, recurse, traversed)


    def find_remote_template_object(self, template_name, recurse=False, traversed=None):
        return self._find_remote_object('template', template_name, recurse, traversed)


    def find_remote_repo_object(self, repo_name, recurse=False, traversed=None):
        return self._find_remote_object('repo', repo_name, recurse, traversed)


    def find_remote_restricted_object(self, restricted_name, recurse=False, traversed=None):
        return self._find_remote_object('restricted', restricted_name, recurse, traversed)


    def find_engine_object(self, engine_name, recurse=False, traversed=None):
        engine = self._find_child_object('engine', engine_name, recurse, traversed)
        if not engine:
            engine = self._find_remote_object('engine', engine_name, recurse, traversed)
        return engine


    def find_project_object(self, project_name, recurse=False, traversed=None):
        project = self._find_child_object('project', project_name, recurse, traversed)
        if not project:
            project = self._find_remote_object('project', project_name, recurse, traversed)
        return project


    def find_gem_object(self, gem_name, recurse=False, traversed=None):
        gem = self._find_child_object('gem', gem_name, recurse, traversed)
        if not gem:
            gem = self._find_remote_object('gem', gem_name, recurse, traversed)
        return gem


    def find_template_object(self, template_name, recurse=False, traversed=None):
        template = self._find_child_object('template', template_name, recurse, traversed)
        if not template:
            template = self._find_remote_object('template', template_name, recurse, traversed)
        return template


    def find_repo_object(self, repo_name, recurse=False, traversed=None):
        repo = self._find_child_object('repo', repo_name, recurse, traversed)
        if not repo:
            repo = self._find_remote_object('repo', repo_name, recurse, traversed)
        return repo


    def find_restricted_object(self, restricted_name, recurse=False, traversed=None):
        restricted = self._find_child_object('restricted', restricted_name, recurse, traversed)
        if not restricted:
            restricted = self._find_remote_object('restricted', restricted_name, recurse, traversed)
        return restricted





    def add_child_engine(self, engine_path):
        """Add a child engine."""
        if 'children' not in self.json_data:
            self.json_data['children'] = {}
        if 'engines' not in self.json_data['children']:
            self.json_data['children']['engines'] = []
        self.json_data['children']['engines'].append(engine_path)


    def add_child_project(self, project_path):
        """Add a child project."""
        if 'children' not in self.json_data:
            self.json_data['children'] = {}
        if 'projects' not in self.json_data['children']:
            self.json_data['children']['projects'] = []
        self.json_data['children']['projects'].append(project_path)


    def add_child_gem(self, gem_path):
        """Add a child gem."""
        if 'children' not in self.json_data:
            self.json_data['children'] = {}
        if 'gems' not in self.json_data['children']:
            self.json_data['children']['gems'] = []
        self.json_data['children']['gems'].append(gem_path)


    def add_child_template(self, template_path):
        """Add a child template."""
        if 'children' not in self.json_data:
            self.json_data['children'] = {}
        if 'templates' not in self.json_data['children']:
            self.json_data['children']['templates'] = []
        self.json_data['children']['templates'].append(template_path)


    def add_child_repo(self, repo_path):
        """Add a child repo."""
        if 'children' not in self.json_data:
            self.json_data['children'] = {}
        if 'repos' not in self.json_data['children']:
            self.json_data['children']['repos'] = []
        self.json_data['children']['repos'].append(repo_path)


    def add_child_restricted(self, restricted_path):
        """Add a child restricted."""
        if 'children' not in self.json_data:
            self.json_data['children'] = {}
        if 'restricted' not in self.json_data['children']:
            self.json_data['children']['restricted'] = []
        self.json_data['children']['restricted'].append(restricted_path)


    def add_remote_engine(self, engine_uri):
        """Add a remote engine."""
        if 'remote' not in self.json_data:
            self.json_data['remote'] = {}
        if 'engines' not in self.json_data['remote']:
            self.json_data['remote']['engines'] = []
        self.json_data['remote']['engines'].append(engine_uri)


    def add_remote_project(self, project_uri):
        """Add a remote project."""
        if 'remote' not in self.json_data:
            self.json_data['remote'] = {}
        if 'projects' not in self.json_data['remote']:
            self.json_data['remote']['projects'] = []
        self.json_data['remote']['projects'].append(project_uri)


    def add_remote_gem(self, gem_uri):
        """Add a remote gem."""
        if 'remote' not in self.json_data:
            self.json_data['remote'] = {}
        if 'gems' not in self.json_data['remote']:
            self.json_data['remote']['gems'] = []
        self.json_data['remote']['gems'].append(gem_uri)


    def add_remote_template(self, template_uri):
        """Add a remote template."""
        if 'remote' not in self.json_data:
            self.json_data['remote'] = {}
        if 'templates' not in self.json_data['remote']:
            self.json_data['remote']['templates'] = []
        self.json_data['remote']['templates'].append(template_uri)


    def add_remote_repo(self, repo_uri):
        """Add a remote repo."""
        if 'remote' not in self.json_data:
            self.json_data['remote'] = {}
        if 'repos' not in self.json_data['remote']:
            self.json_data['remote']['repos'] = []
        self.json_data['remote']['repos'].append(repo_uri)


    def add_remote_restricted(self, restricted_uri):
        """Add a remote restricted."""
        if 'remote' not in self.json_data:
            self.json_data['remote'] = {}
        if 'restricted' not in self.json_data['remote']:
            self.json_data['remote']['restricted'] = []
        self.json_data['remote']['restricted'].append(restricted_uri)




    def get_children(self):
        """get the children json data of the object"""
        return self.json_data.get('children', [])


    def _get_child_objects(self, object_type, recurse=False, traversed=None):
        """Get the list of child objects of the specified type.
        
        :param object_type: Type of objects to get ('engine', 'project', 'gem', etc.)
        :param recurse: Whether to search recursively
        :param traversed: Set of traversed URIs to avoid circular references
        :return: Tuple of (object_URIs_list, json_data_list)
        """
        if not traversed:
            traversed = set()
    
        # Map object types to their collections
        collections = {
            'engine': self.childEngineObjects,
            'project': self.childProjectObjects,
            'gem': self.childGemObjects,
            'template': self.childTemplateObjects,
            'repo': self.childRepoObjects,
            'restricted': self.childRestrictedObjects
        }
    
        full_paths = []
        o3de_objects = []
        for item in collections.get(object_type, []):
            if item.get_object_uri() not in traversed:
                traversed.add(item.get_object_uri())
                full_paths.append(item.get_object_uri())
                o3de_objects.append(item)      
    
        if recurse:
            # Get all child objects of this type from all collections
            for collection_name, items in collections.items():
                for item in items:
                    method_name = f'get_child_{object_type}_objects'
                    if hasattr(item, method_name) and callable(getattr(item, method_name)):
                        child_paths, child_objects = getattr(item, method_name)(True, traversed)
                        for child_path, child_object in zip(child_paths, child_objects):
                            if child_path not in full_paths:
                                full_paths.append(child_path)
                                o3de_objects.append(child_object)

        return full_paths, o3de_objects

    def get_child_engine_objects(self, recurse=False, traversed=None):
        """Get the list of child engines."""
        return self._get_child_objects('engine', recurse, traversed)


    def get_child_project_objects(self, recurse=False, traversed=None):
        """Get the list of child projects."""
        return self._get_child_objects('project', recurse, traversed)


    def get_child_gem_objects(self, recurse=False, traversed=None):
        """Get the list of child gems."""
        return self._get_child_objects('gem', recurse, traversed)


    def get_child_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates."""
        return self._get_child_objects('template', recurse, traversed)


    def get_child_repo_objects(self, recurse=False, traversed=None):
        """Get the list of child repos."""
        return self._get_child_objects('repo', recurse, traversed)


    def get_child_restricted_objects(self, recurse=False, traversed=None):
        """Get the list of child restricteds."""
        return self._get_child_objects('restricted', recurse, traversed)
    
    def get_all_child_objects(self, recurse=False, traversed=None):
        """Get all child objects of all types."""
        if not traversed:
            traversed = set()
        
        full_paths = []
        o3de_objects = []

        collections = [
            self.childEngineObjects,
            self.childProjectObjects,
            self.childGemObjects,
            self.childTemplateObjects,
            self.childRepoObjects,
            self.childRestrictedObjects
        ]
        
        for collection in collections:
            for item in collection:
                if item.get_object_uri() not in traversed:
                    traversed.add(item.get_object_uri())
                    full_paths.append(item.get_object_uri())
                    o3de_objects.append(item)
        
        if recurse:
            for item in o3de_objects:
                child_full_paths, child_objects = item.get_all_child_objects(True, traversed)
                full_paths.extend(child_full_paths)
                o3de_objects.extend(child_objects)

        return full_paths, o3de_objects


    def get_remote(self):
        """get the remote json data of the object"""
        return self.json_data.get('remote', [])
    

    def _get_remote_objects(self, object_type, recurse=False, traversed=None):
        """Get the list of remote objects of the specified type.
        :param object_type: Type of objects to get ('engine', 'project', 'gem', etc.)
        :param recurse: Whether to search recursively
        :param traversed: Set of traversed URIs to avoid circular references
        :return: List of object URIs
        """
        if not traversed:
            traversed = set()
        
        # Map object types to their collections
        collections = {
            'engine': self.remoteEngineObjects,
            'project': self.remoteProjectObjects,
            'gem': self.remoteGemObjects,
            'template': self.remoteTemplateObjects,
            'repo': self.remoteRepoObjects,
            'restricted': self.remoteRestrictedObjects
        }
        
        uris = []
        o3de_objects = []
        for item in collections.get(object_type, []):
            if item.get_object_uri() not in traversed:
                traversed.add(item.get_object_uri())
                uris.append(item.get_object_uri())
                o3de_objects.append(item)   
        
        if recurse:
            # Get all remote objects of this type from all collections
            for collection_name, items in collections.items():
                for item in items:
                    method_name = f'get_remote_{object_type}_objects'
                    if hasattr(item, method_name) and callable(getattr(item, method_name)):
                        child_uris, child_objects = getattr(item, method_name)(True, traversed)
                        for child_uri, child_object in zip(child_uris, child_objects):
                            if child_uri not in uris:
                                uris.append(child_uri)
                                o3de_objects.append(child_object)

        return uris, o3de_objects

    def get_remote_engine_objects(self, recurse=False, traversed=None):
        """Get the list of remote engines."""
        return self._get_remote_objects('engine', recurse, traversed)


    def get_remote_project_objects(self, recurse=False, traversed=None):
        """Get the list of remote projects."""
        return self._get_remote_objects('project', recurse, traversed)


    def get_remote_gem_objects(self, recurse=False, traversed=None):
        """Get the list of remote gems."""
        return self._get_remote_objects('gem', recurse, traversed)


    def get_remote_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates."""
        return self._get_remote_objects('template', recurse, traversed)


    def get_remote_repo_objects(self, recurse=False, traversed=None):
        """Get the list of remote repos."""
        return self._get_remote_objects('repo', recurse, traversed)


    def get_remote_restricted_objects(self, recurse=False, traversed=None):
        """Get the list of remote restricteds."""
        return self._get_remote_objects('restricted', recurse, traversed)


    def _get_child_template_objects_by_type(self, template_type, file_marker, recurse=False, traversed=None):
        """Get the list of child templates that make objects of the specified type.
        
        :param template_type: Type of template to filter by ('engine', 'project', etc.)
        :param file_marker: File to look for in copyFiles (e.g., 'engine.json')
        :param recurse: Whether to search recursively
        :param traversed: Set of traversed URIs to avoid circular references
        :return: List of template URIs
        """
        if not traversed:
            traversed = set()
        
        full_paths = []
        o3de_objects = []
        for item in self.childTemplateObjects:
            if item.get_object_uri() not in traversed:
                if item.get_type() == template_type:
                    traversed.add(item.get_object_uri())
                    full_paths.append(item.get_object_uri())
                    o3de_objects.append(item)
                else:
                    for copyFile in item.get_copy_files():
                        if copyFile['file'] == file_marker:
                            traversed.add(item.get_object_uri())
                            full_paths.append(item.get_object_uri())
                            o3de_objects.append(item)
                            break
        if recurse:
            # Collect from all child collections recursively
            collections = [
                self.childEngineObjects,
                self.childProjectObjects,
                self.childGemObjects,
                self.childTemplateObjects,
                self.childRepoObjects,
                self.childRestrictedObjects
            ]
            
            for collection in collections:
                for item in collection:
                    method_name = f'get_child_{template_type}_template_objects'
                    if hasattr(item, method_name) and callable(getattr(item, method_name)):
                        child_full_paths, child_objects = getattr(item, method_name)(True, traversed)
                        for child_full_path, child_object in zip(child_full_paths, child_objects):
                            if child_full_path not in full_paths:
                                full_paths.append(child_full_path)
                                o3de_objects.append(child_object)

        return full_paths, o3de_objects

    def get_child_engine_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates that make engines."""
        return self._get_child_templates_by_type('engine', 'engine.json', recurse, traversed)


    def get_child_project_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates that make projects."""
        return self._get_child_templates_by_type('project', 'project.json', recurse, traversed)


    def get_child_gem_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates that make gems."""
        return self._get_child_templates_by_type('gem', 'gem.json', recurse, traversed)


    def get_child_repo_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates that make repos."""
        return self._get_child_templates_by_type('repo', 'repo.json', recurse, traversed)


    def get_child_restricted_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates that make restricteds."""
        return self._get_child_templates_by_type('restricted', 'restricted.json', recurse, traversed)


    def get_child_generic_template_objects(self, recurse=False, traversed=None):
        """Get the list of child templates that make generic templates."""
        if not traversed:
            traversed = set()
        
        full_paths = []
        o3de_objects = []
        for item in self.childTemplateObjects:
            if item.get_object_uri() not in traversed:
                if item.get_type() == 'generic':
                    traversed.add(item.get_object_uri())
                    if item.get_object_uri() not in full_paths:
                        full_paths.append(item.get_object_uri())
                        o3de_objects.append(item)
                else:
                    for copyFile in item.get_copy_files():
                        if copyFile['file'] != 'engine.json' and \
                            copyFile['file'] != 'project.json' and \
                            copyFile['file'] != 'gem.json' and \
                            copyFile['file'] != 'repo.json' and \
                            copyFile['file'] != 'restricted.json':
                            traversed.add(item.get_object_uri())
                            if item.get_object_uri() not in full_paths:
                                full_paths.append(item.get_object_uri())
                                o3de_objects.append(item)
                            break
        if recurse:
            for item in self.childEngineObjects:
                child_full_paths, child_objects = item.get_child_generic_templates(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.childProjectObjects:
                child_full_paths, child_objects = item.get_child_generic_templates(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.childGemObjects:
                child_full_paths, child_objects = item.get_child_generic_templates(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.childTemplateObjects:
                child_full_paths, child_objects = item.get_child_generic_templates(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.childRepoObjects:
                child_full_paths, child_objects = item.get_child_generic_templates(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.childRestrictedObjects:
                child_full_paths, child_objects = item.get_child_generic_templates(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)

        return full_paths, o3de_objects


    def _get_remote_template_objects_by_type(self, template_type, file_marker, recurse=False, traversed=None):
        """Get the list of remote templates that make objects of the specified type.
        
        :param template_type: Type of template to filter by ('engine', 'project', etc.)
        :param file_marker: File to look for in copyFiles (e.g., 'engine.json')
        :param recurse: Whether to search recursively
        :param traversed: Set of traversed URIs to avoid circular references
        :return: List of template URIs
        """
        if not traversed:
            traversed = set()
        
        full_paths = []
        o3de_objects = []
        for item in self.remoteTemplateObjects:
            if item.get_object_uri() not in traversed:
                if item.get_type() == template_type:
                    traversed.add(item.get_object_uri())
                    if item.get_object_uri() not in full_paths:
                        full_paths.append(item.get_object_uri())
                        o3de_objects.append(item)
                else:
                    for copyFile in item.get_copy_files():
                        if copyFile['file'] == file_marker:
                            traversed.add(item.get_object_uri())
                            if item.get_object_uri() not in full_paths:
                                full_paths.append(item.get_object_uri())
                                o3de_objects.append(item)
                            break
        if recurse:
            # Collect from all remote collections recursively
            collections = [
                self.remoteEngineObjects,
                self.remoteProjectObjects,
                self.remoteGemObjects,
                self.remoteTemplateObjects,
                self.remoteRepoObjects,
                self.remoteRestrictedObjects,
                self.remoteExtensionObjects
            ]
            
            for collection in collections:
                for item in collection:
                    method_name = f'get_remote_{template_type}_template_objects'
                    if hasattr(item, method_name) and callable(getattr(item, method_name)):
                        child_full_paths, child_objects = getattr(item, method_name)(True, traversed)
                        for child_full_path, child_object in zip(child_full_paths, child_objects):
                            if child_full_path not in full_paths:
                                full_paths.append(child_full_path)
                                o3de_objects.append(child_object)

        return full_paths, o3de_objects

    def get_remote_engine_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates that make engines."""
        return self._get_remote_template_objects_by_type('engine', 'engine.json', recurse, traversed)


    def get_remote_project_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates that make projects."""
        return self._get_remote_template_objects_by_type('project', 'project.json', recurse, traversed)


    def get_remote_gem_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates that make gems."""
        return self._get_remote_template_objects_by_type('gem', 'gem.json', recurse, traversed)


    def get_remote_repo_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates that make repos."""
        return self._get_remote_template_objects_by_type('repo', 'repo.json', recurse, traversed)


    def get_remote_restricted_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates that make restricteds."""
        return self._get_remote_template_objects_by_type('restricted', 'restricted.json', recurse, traversed)


    def get_remote_generic_template_objects(self, recurse=False, traversed=None):
        """Get the list of remote templates that make generic templates."""
        if not traversed:
            traversed = set()
        
        full_paths = []
        o3de_objects = []
        for item in self.remoteTemplateObjects:
            if item.get_object_uri() not in traversed:
                if item.get_type() == 'generic':
                    traversed.add(item.get_object_uri())
                    if item.get_object_uri() not in full_paths:
                        full_paths.append(item.get_object_uri())
                        o3de_objects.append(item)
                else:
                    for copyFile in item.get_copy_files():
                        if copyFile['file'] != 'engine.json' and \
                            copyFile['file'] != 'project.json' and \
                            copyFile['file'] != 'gem.json' and \
                            copyFile['file'] != 'repo.json' and \
                            copyFile['file'] != 'restricted.json':
                            traversed.add(item.get_object_uri())
                            if item.get_object_uri() not in full_paths:
                                full_paths.append(item.get_object_uri())
                                o3de_objects.append(item)
                            break
        if recurse:
            for item in self.remoteEngineObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.remoteProjectObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.remoteGemObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.remoteTemplateObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.remoteRepoObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.remoteRestrictedObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)
            for item in self.remoteExtensionObjects:
                child_full_paths, child_objects = item.get_remote_generic_template_objects(True, traversed)
                for child_full_path, child_object in zip(child_full_paths, child_objects):
                    if child_full_path not in full_paths:
                        full_paths.append(child_full_path)
                        o3de_objects.append(child_object)

        return full_paths, o3de_objects


    def get_engine_template_objects(self, recurse=False, traversed=None):
        """Get engine templates, both local and remote."""
        if not traversed:
            traversed = set()

        full_paths, o3de_objects = self.get_child_engine_template_objects(recurse, traversed)
        remote_full_paths, remote_o3de_objects = self.get_remote_engine_template_objects(recurse, traversed)

        for remote_full_path, remote_o3de_object in zip(remote_full_paths, remote_o3de_objects):
            if remote_full_path not in full_paths:
                full_paths.append(remote_full_path)
                o3de_objects.append(remote_o3de_object)

        return full_paths, o3de_objects


    def get_project_template_objects(self, recurse=False, traversed=None):
        """Get project templates, both local and remote."""
        if not traversed:
            traversed = set()

        full_paths, o3de_objects = self.get_child_project_template_objects(recurse, traversed)
        remote_full_paths, remote_o3de_objects = self.get_remote_project_template_objects(recurse, traversed)
        for remote_full_path, remote_o3de_object in zip(remote_full_paths, remote_o3de_objects):
            if remote_full_path not in full_paths:
                full_paths.append(remote_full_path)
                o3de_objects.append(remote_o3de_object)

        return full_paths, o3de_objects


    def get_gem_template_objects(self, recurse=False, traversed=None):
        """Get gem templates, both local and remote."""
        if not traversed:
            traversed = set()

        full_paths, o3de_objects = self.get_child_gem_template_objects(recurse, traversed)
        remote_full_paths, remote_o3de_objects = self.get_remote_gem_template_objects(recurse, traversed)
        for remote_full_path, remote_o3de_object in zip(remote_full_paths, remote_o3de_objects):
            if remote_full_path not in full_paths:
                full_paths.append(remote_full_path)
                o3de_objects.append(remote_o3de_object)
                
        return full_paths, o3de_objects


    def get_repo_template_objects(self, recurse=False, traversed=None):
        """Get repo templates, both local and remote."""
        if not traversed:
            traversed = set()

        full_paths, o3de_objects = self.get_child_repo_template_objects(recurse, traversed)
        remote_full_paths, remote_o3de_objects = self.get_remote_repo_template_objects(recurse, traversed)
        for remote_full_path, remote_o3de_object in zip(remote_full_paths, remote_o3de_objects):
            if remote_full_path not in full_paths:
                full_paths.append(remote_full_path)
                o3de_objects.append(remote_o3de_object)

        return full_paths, o3de_objects


    def get_restricted_template_objects(self, recurse=False, traversed=None):
        """Get restricted templates, both local and remote."""
        if not traversed:
            traversed = set()

        full_paths, o3de_objects = self.get_child_restricted_template_objects(recurse, traversed)
        remote_full_paths, remote_o3de_objects = self.get_remote_restricted_template_objects(recurse, traversed)
        for remote_full_path, remote_o3de_object in zip(remote_full_paths, remote_o3de_objects):
            if remote_full_path not in full_paths:
                full_paths.append(remote_full_path)
                o3de_objects.append(remote_o3de_object)
        
        return full_paths, o3de_objects


    def get_generic_template_objects(self, recurse=False, traversed=None):
        """Get generic templates, both local and remote."""
        if not traversed:
            traversed = set()

        full_paths, o3de_objects = self.get_child_generic_template_objects(recurse, traversed)
        remote_full_paths, remote_o3de_objects = self.get_remote_generic_template_objects(recurse, traversed)
        for remote_full_path, remote_o3de_object in zip(remote_full_paths, remote_o3de_objects):
            if remote_full_path not in full_paths:
                full_paths.append(remote_full_path)
                o3de_objects.append(remote_o3de_object)

        return full_paths, o3de_objects


    def _download_resource(self, resource_uri):
        """Download and cache a resource from its URI."""
        if not resource_uri:
            return
            
        cache_file, parsed_uri = cache.get_cache_file_uri(resource_uri)
        git_provider = utils.get_git_provider(parsed_uri)
        if git_provider:
            parsed_uri = git_provider.get_specific_file_uri(parsed_uri)

        # Download if cache doesn't exist or is outdated
        if cache_file.is_file():
            if (datetime.now(timezone.utc) - datetime.fromtimestamp(cache_file.stat().st_mtime, timezone.utc)).days > 1:
                utils.download_file(parsed_uri, cache_file, True, resource_uri)
        else:
            utils.download_file(parsed_uri, cache_file, True, resource_uri)


    def upgrade_to_1_0_0(self, upgrade_children = False):
        """
        Upgrades the object's JSON data (and possibly all its children) to schema version 1.0.0.
        Original file is kept untouched the upgraded version is written to a new file
        with name.1-0-0.json format (e.g., gem.1-0-0.json).
        
        :return: 0 if upgrade was successful for this object, False otherwise
        """
        try:
            # Skip processing for remote objects
            if self.is_remote():
                # For remote files, just return success without modifying anything
                return 0
                
            from o3de import upgrade_schema
            import pathlib
            import json
            
            # Only local files are processed beyond this point
            original_file_path = pathlib.Path(self.object_uri)
            
            # Create a path for the NEW file with name.NEW.extension format
            stem = original_file_path.stem  # Get filename without extension
            suffix = original_file_path.suffix  # Get extension with dot
            new_file_path = original_file_path.with_name(f"{stem}.1-0-0{suffix}")
            
            # If the new file doesn't exist upgrade to it from the original file
            result = 0
            if new_file_path.exists() == False:
                # Call the upgrade function, writing to the NEW file
                result = upgrade_schema.upgrade_to_1_0_0(
                    input_json_path=original_file_path, 
                    output_json_path=new_file_path
                )

            # Load the new file and update the json_data             
            if result == 0:
                # We need to update json_data from the NEW file
                with open(new_file_path, 'r') as f:
                    self.json_data = json.load(f)
                self.schema_version = schema.SchemaVersion(schema.VERSION_1_0_0)
            else:
                logger.error(f"Failed to upgrade object schema to 1.0.0: {self.object_uri}")
            
            # We need to update the cache
            # Get the cache_file name for the original uri
            cache_file, _ = cache.get_cache_file_uri(original_file_path)

            # Remove the original cache file if it exists
            if cache_file.is_file():
                cache_file.unlink()

            # Copy the upgraded file over the original cache file
            pathlib.Path(cache_file).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(new_file_path, cache_file)

            if upgrade_children:
                # Also upgrade all local children
                child_collections = [
                    self.childEngineObjects,
                    self.childProjectObjects,
                    self.childGemObjects,
                    self.childTemplateObjects,
                    self.childRepoObjects,
                    self.childRestrictedObjects
                ]
                
                # Upgrade each local child
                for collection in child_collections:
                    for child in collection:
                        if child.upgrade_to_1_0_0(upgrade_children) == 1:
                            logger.error(f"Failed to upgrade child object to 1.0.0: {child.object_uri}")
                            return 1
            return 0
                
        except Exception as e:
            logger.error(f"Failed to upgrade object schema to 1.0.0: {str(e)}")
            return 1
    

    def upgrade_to_2_0_0(self, upgrade_children = False):
        """
        Upgrades the object's JSON data (and possibly all its children) to schema version 2.0.0.
        Original file is kept untouched the upgraded version is written to a new file
        with name.2-0-0.json format (e.g., gem.2-0-0.json).
        
        :return: 0 if upgrade was successful for this object, False otherwise
        """
        try:
            # Skip processing for remote objects
            if self.is_remote():
                # For remote files, just return success without modifying anything
                return 0
                
            from o3de import upgrade_schema
            import pathlib
            import json
            
            # Only local files are processed beyond this point
            original_file_path = pathlib.Path(self.object_uri)
            
            # Create a path for the new file with type.2-0-0.json format
            stem = original_file_path.stem  # Get filename without extension
            suffix = original_file_path.suffix  # Get extension with dot
            new_file_path = original_file_path.with_name(f"{stem}.2-0-0{suffix}")
                        
            # If the new file doesn't exist upgrade to it from the original file
            result = 0
            if new_file_path.exists() == False:
                # Call the upgrade function, writing to the type.2-0-0.json file
                result = upgrade_schema.upgrade_to_2_0_0(
                    input_json_path=original_file_path,
                    output_json_path=new_file_path
                )

            # Load the new file and update the json_data
            if result == 0:
                # We need to update json_data from the NEW file
                with open(new_file_path, 'r') as f:
                    self.json_data = json.load(f)
                self.schema_version = schema.SchemaVersion(schema.VERSION_2_0_0)
            else:
                logger.error(f"Failed to upgrade object schema to 2.0.0: {self.object_uri}")
        
            # We need to update the cache
            # Get the cache_file name for the original uri
            cache_file, _ = cache.get_cache_file_uri(original_file_path)

            # Remove the original cache file if it exists
            if cache_file.is_file():
                cache_file.unlink()

            # Copy the upgraded file over the original cache file
            pathlib.Path(cache_file).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(new_file_path, cache_file)
                            
            if upgrade_children:
                # Also upgrade all local children only
                child_collections = [
                    self.childEngineObjects,
                    self.childProjectObjects,
                    self.childGemObjects,
                    self.childTemplateObjects,
                    self.childRepoObjects,
                    self.childRestrictedObjects
                ]
                
                # Upgrade each local child
                for collection in child_collections:
                    for child in collection:
                        if child.upgrade_to_2_0_0() == 1:
                            logger.error(f"Failed to upgrade child object to 2.0.0: {child.object_uri}")
                            return 1
            return 0
                
        except Exception as e:
            logger.error(f"Failed to upgrade object schema to 2.0.0: {str(e)}")
            return 1

"""
O3DE Object Classes
These classes represent the various objects in the O3DE manifest.
Each class inherits from O3deObject and provides specific methods for accessing properties and child objects.
"""
class O3deManifest(O3deObject):

    def __init__(self, manifest_uri: str = None, traversed: set = None, manifest_json_data: dict = None):
        """
        Initialize the O3DE manifest object.
        :param manifest_uri: URI of the manifest file, if not supplied then it
          will try to load the user manifest from the default location. If that
          fails, a new manifest file will be created with default values.
        :param traversed: Set of traversed URIs
        :param manifest_json_data: JSON data of the manifest object
        """
        if manifest_uri is None:
            manifest_uri = get_user_o3de_manifest_path().as_posix()
            if pathlib.Path(manifest_uri).is_file() == False:
                with open(manifest_uri, 'w') as f:
                    json.dump({get_default_o3de_manifest_json_data()}, f)
                
        super().__init__('o3de_manifest', manifest_uri, traversed, manifest_json_data)

        self.country = O3deCountry(self.json_data.get('country', {}))

    def get_country(self):
        """Returns the country for o3de_manifest"""
        return self.country

    def get_default_engines_path(self):
        """Returns the default engines path for o3de_manifest"""
        return self.json_data['default']['engines_path']
    
    def get_default_projects_path(self):
        """Returns the default projects path for o3de_manifest"""
        return self.json_data['default']['projects_path']

    def get_default_gems_path(self):
        """Returns the default gems path for o3de_manifest"""
        return self.json_data['default']['gems_path']

    def get_default_templates_path(self):
        """Returns the default templates path for o3de_manifest"""
        return self.json_data['default']['templates_path']

    def get_default_repos_path(self):
        """Returns the default repos path for o3de_manifest"""
        return self.json_data['default']['repos_path']
    
    def get_default_restricteds_path(self):
        """Returns the default restricteds path for o3de_manifest.

        Restricted objects are deprecated in Schema 2.0 (superseded by
        overlays); newer manifests may not carry this key.
        """
        return self.json_data['default'].get('restricteds_path', '')

    def get_default_third_party_path(self):
        """Returns the default third party path for o3de_manifest"""
        return self.json_data['default']['third_party_path']
    

"""
O3deEngine Class
This class represents an O3DE engine object.
It inherits from O3deObject and provides specific methods for accessing engine properties.
"""
class O3deEngine(O3deObject):

    def __init__(self, engine_uri: str, traversed: set, engine_json_data: dict = None):
        """
        Initialize the O3DE engine object.
        :param engine_uri: URI of the engine file
        :param traversed: Set of traversed URIs
        :param engine_json_data: JSON data of the engine object
        """
        super().__init__('engine', engine_uri, traversed, engine_json_data)
        self.api_versions = O3deApiVersions(self.get_api_versions())

    def get_o3de_version(self):
        """Returns the O3DE version for the engine"""
        return self.json_data.get('O3DEVersion', '')

    def get_o3de_build_number(self):
        """Returns the O3DE build number for the engine"""
        return self.json_data.get('O3DEBuildNumber', '')

    def get_display_version(self):
        """Returns the display version for the engine"""
        return self.json_data.get('display_version', '')
    
    def get_file_version(self):
        """Returns the file version for the engine"""
        return self.json_data.get('file_version', '')
    
    def get_build(self):
        """Returns the build number for the engine"""
        return self.json_data.get('build', '')
    
    def get_api_versions(self):
        """Returns the API versions for the engine"""
        return self.json_data.get('api_versions', {})

"""
O3deProject Class
This class represents an O3DE project object.
It inherits from O3deObject and provides specific methods for accessing project properties.
"""
class O3deProject(O3deObject):

    def __init__(self, project_uri: str, traversed: set, project_json_data: dict = None):
        """
        Initialize the O3DE project object.
        :param project_uri: URI of the project file
        :param traversed: Set of traversed URIs
        :param project_json_data: JSON data of the project object
        """
        super().__init__('project', project_uri, traversed, project_json_data)
    
    def get_product_name(self):
        """Returns the product name for project"""
        return self.json_data.get('product_name', '')
    
    def get_executable_name(self):
        """Returns the executable name for project"""
        return self.json_data.get('executable_name', '')
    
    def get_modules(self):
        """Returns the modules for project"""
        return self.json_data.get('modules', [])
    
    def get_engine(self):
        """Returns the engine for project"""
        return self.json_data.get('engine', '')

"""
O3deGem Class
This class represents an O3DE gem object.
It inherits from O3deObject and provides specific methods for accessing gem properties.
"""    
class O3deGem(O3deObject):

    def __init__(self, gem_uri: str, traversed: set, gem_json_data: dict = None):
        """
        Initialize the O3DE gem object.
        :param gem_uri: URI of the gem file
        :param traversed: Set of traversed URIs
        :param gem_json_data: JSON data of the gem object
        """
        super().__init__('gem', gem_uri, traversed, gem_json_data)

    def get_cmake_relative_path(self):
        """Returns the CMake relative path for the gem"""
        return self.json_data.get('cmake_relative_path', 'cmake')

"""
O3deTemplate Class
This class represents an O3DE template object.
It inherits from O3deObject and provides specific methods for accessing template properties.
"""
class O3deTemplate(O3deObject):
    def __init__(self, template_uri: str, traversed: set, template_json_data: dict = None):
        """
        Initialize the O3DE template object.
        :param template_uri: URI of the template file
        :param traversed: Set of traversed URIs
        :param template_json_data: JSON data of the template object
        """
        super().__init__('template', template_uri, traversed, template_json_data)

    def get_copy_files(self):
        """Returns the copyFiles for template"""
        return self.json_data.get('copyFiles', [])
    
    def get_create_directories(self):
        """Returns the createDirectories for template"""
        return self.json_data.get('createDirectories', [])

"""
O3deRepo Class
This class represents an O3DE repo object.
It inherits from O3deObject and provides specific methods for accessing repo properties.
"""
class O3deRepo(O3deObject):
    def __init__(self, repo_uri: str, traversed: set, repo_json_data: dict = None):
        """
        Initialize the O3DE repo object.
        :param repo_uri: URI of the repo file
        :param traversed: Set of traversed URIs
        :param repo_json_data: JSON data of the repo object
        """
        super().__init__('repo', repo_uri, traversed, repo_json_data)

"""
O3deRestricted Class
This class represents an O3DE restricted object.
It inherits from O3deObject and provides specific methods for accessing restricted properties.
"""
class O3deRestricted(O3deObject):
    def __init__(self, restricted_uri: str, traversed: set, restricted_json_data: dict = None):
        """
        Initialize the O3DE restricted object.
        :param restricted_uri: URI of the restricted file
        :param traversed: Set of traversed URIs
        :param restricted_json_data: JSON data of the restricted object
        """
        super().__init__('restricted', restricted_uri, traversed, restricted_json_data)

    def get_extends(self):
        """Returns what object this restricted extends"""
        return self.json_data['extends']
    
    def get_precedence(self):
        """Returns the precedence for the restricted object"""
        return self.json_data.get('precedence', 0)

    def get_platform_maps(self):
        """Returns the platform maps for the restricted object"""
        return self.json_data.get('platform_maps', [])

    def get_platform_wart_maps(self):
        """Returns the platform wart maps for the restricted object"""
        return self.json_data.get('platform_wart_maps', [])


# Load the o3de manifest
manifest = O3deManifest()        

class ResolveDependencies:
    """
    O3DE Dependency Resolution System using ResolveLib
    
    This class handles dependency resolution for O3DE objects, supporting:
    - Per-root resolution (Engines and Projects as roots)
    - Advanced version constraints with O3deNameVersion
    - Comprehensive conflict detection and reporting
    """
    
    def __init__(self):
        """
        Initialize the dependency resolver
        """
        from o3de import compatibility
        from o3de.version import O3deNameVersion
        from packaging.version import Version
        from packaging.specifiers import SpecifierSet
        from resolvelib import AbstractProvider, BaseReporter, Resolver, ResolutionImpossible
        from collections import namedtuple
        import logging
               
        self.logger = logging.getLogger('o3de.dependency_resolution')
        
        # Import dependencies for later use
        self.O3deNameVersion = O3deNameVersion
        self.Version = Version
        self.SpecifierSet = SpecifierSet
        self.AbstractProvider = AbstractProvider
        self.BaseReporter = BaseReporter
        self.Resolver = Resolver
        self.ResolutionImpossible = ResolutionImpossible
        self.namedtuple = namedtuple
        
        self.object_groups = {}  # Store objects by type
        self.candidates = []
        self.parsing_errors = []
    
    def add_objects(self, object_type: str, objects: list):
        """
        Add objects of a specific type to the resolver
        
        :param object_type: The type of objects (e.g., 'engine', 'project', 'gem', etc.)
        :param objects: List of objects of this type
        """
        if object_type not in self.object_groups:
            self.object_groups[object_type] = []
        
        self.object_groups[object_type].extend(objects)
    
    def build_candidates(self):
        """Build candidates from a specific list of O3DE objects"""
        self.candidates = []
        self.parsing_errors = []

        # Build candidates for all object groups
        for object_type, object_list in self.object_groups.items():
            for object in object_list.values():
                obj_type = object_type
                obj_header = object.get_header()
                name = obj_header.get_name()
                version_str = obj_header.get_version() or "0.0.0"
                version = self.Version(version_str)
                
                # Get dependencies and convert to requirements using O3deNameVersion
                requirements = []
                
                # Get dependencies for each type
                dependency_types = [
                    ("Engine", object.get_dependent_engines()),
                    ("Project", object.get_dependent_projects()),
                    ("Gem", object.get_dependent_gems()),
                    ("Template", object.get_dependent_templates()),
                    ("Repo", object.get_dependent_repos()),
                    ("Restricted", object.get_dependent_restricteds())
                ]
                
                for dep_type, deps in dependency_types:
                    for dep in deps:
                        # Parse dependency directly using O3deNameVersion for enhanced parsing
                        # This supports comma-free formats, unlimited specifiers, and != operator
                        try:
                            if not dep:
                                continue
                            
                            name_version = self.O3deNameVersion.from_string(dep.strip())
                            if name_version and name_version.name:
                                dep_name, dep_specifier = name_version.get_specifier_set()
                                # Create requirement using parsed data from O3deNameVersion
                                requirements.append(self.O3deRequirement(dep_type, dep_name.strip(), dep_specifier))
                            else:
                                # Track parsing failures for debugging
                                self.parsing_errors.append(f"Failed to parse dependency: '{dep}' from {obj_type}.{name}")
                        except Exception as e:
                            # Track parsing failures for debugging
                            self.parsing_errors.append(f"Failed to parse dependency: '{dep}' from {obj_type}.{name} - {str(e)}")
                
                # Create candidate
                candidate = self.O3deCandidate(
                    object_type=obj_type,
                    name=name,
                    version=version,
                    requirements=requirements,
                    obj_data=object
                )
                self.candidates.append(candidate)
            
            # Report parsing errors if any
            if self.parsing_errors:
                for error in self.parsing_errors[-3:]:  # Show last 3 errors to avoid spam
                    self.logger.warning(error)
        
    
    @property
    def O3deRequirement(self):
        """Requirement class for O3DE dependencies"""
        if not hasattr(self, '_O3deRequirement'):
            self._O3deRequirement = self.namedtuple("O3deRequirement", ["object_type", "name", "specifier"])
            
            # Add methods to the requirement class
            def __repr__(self):
                return f'<{self.object_type}Requirement({self.name}{self.specifier if self.specifier else ""})>'
            
            def identify(self):
                return f"{self.object_type}:{self.name}"
            
            def failure_reason(self, object_name):
                return f'{object_name} requires {self.object_type}.{self.name}{self.specifier if self.specifier else ""}'
            
            self._O3deRequirement.__repr__ = __repr__
            self._O3deRequirement.identify = identify
            self._O3deRequirement.failure_reason = failure_reason
            
        return self._O3deRequirement
    
    @property
    def O3deCandidate(self):
        """Candidate class for O3DE objects"""
        if not hasattr(self, '_O3deCandidate'):
            self._O3deCandidate = self.namedtuple("O3deCandidate", ["object_type", "name", "version", "requirements", "obj_data"])
            
            # Add methods to the candidate class
            def __repr__(self):
                return f"<{self.object_type} {self.name}=={self.version}>"
            
            def identify(self):
                return f"{self.object_type}:{self.name}"
            
            def __hash__(self):
                return hash((self.object_type, self.name, self.version))
            
            self._O3deCandidate.__repr__ = __repr__
            self._O3deCandidate.identify = identify
            self._O3deCandidate.__hash__ = __hash__
            
        return self._O3deCandidate
    
    def create_provider(self):
        """Create the dependency provider for ResolveLib"""
        class O3deDependencyProvider(self.AbstractProvider):
            def __init__(self, candidates, resolver_instance):
                self.candidates = candidates
                self.resolver = resolver_instance
            
            def identify(self, requirement_or_candidate):
                return requirement_or_candidate.identify()
            
            def get_preference(self, identifier, resolutions, candidates, information, **_):
                # Prefer engines > projects > gems > templates > repos > restricteds
                if "Engine:" in identifier:
                    return 1000
                elif "Project:" in identifier:
                    return 800
                elif "Gem:" in identifier:
                    return 600
                elif "Template:" in identifier:
                    return 400
                elif "Repo:" in identifier:
                    return 200
                elif "Restricted:" in identifier:
                    return 100
                return 0
            
            def find_matches(self, identifier, requirements, incompatibilities):
                # Return candidates that satisfy requirements, sorted by version (highest first)
                matching_candidates = []
                for candidate in self.candidates:
                    if candidate.identify() == identifier:
                        satisfies_all = True
                        for req in requirements:
                            if not self.is_satisfied_by(req, candidate):
                                satisfies_all = False
                                break
                        if satisfies_all:
                            matching_candidates.append(candidate)
                
                # Sort by version (highest first)
                try:
                    return sorted(matching_candidates, key=lambda c: c.version, reverse=True)
                except Exception:
                    # Fallback to string sort if version comparison fails
                    return sorted(matching_candidates, key=lambda c: str(c.version), reverse=True)
            
            def is_satisfied_by(self, requirement, candidate):
                if requirement.object_type != candidate.object_type:
                    return False
                
                if requirement.name != candidate.name:
                    return False
                
                # Check version constraint using enhanced O3deNameVersion logic
                if requirement.specifier is None or not str(requirement.specifier):
                    return True  # No version constraint means any version is acceptable
                
                try:
                    # Use SpecifierSet to check if candidate version satisfies requirement
                    return candidate.version in requirement.specifier
                except Exception:
                    # If version checking fails, be permissive
                    return True
            
            def get_dependencies(self, candidate):
                return candidate.requirements
        
        return O3deDependencyProvider(self.candidates, self)
    
    def resolve_root_dependencies(self, root_object) -> tuple:
        """
        Resolve dependencies for a single O3DE root object (Engine or Project)
        
        :param root_object: The root O3DE object (Engine or Project) to resolve dependencies for
        :return: Tuple of (resolved_dependencies_dict, conflicts_list)
        """
        # Set up resolver
        provider = self.create_provider()
        reporter = self.BaseReporter()
        resolver = self.Resolver(provider=provider, reporter=reporter)
        
        # Create initial requirements from the root object
        root_header = root_object.get_header()
        root_type = root_object.type.capitalize() if root_object.type else "Unknown"
        root_name = root_header.get_name()
        root_version_str = root_header.get_version() or "0.0.0"
        
        try:
            root_version = self.Version(root_version_str)
        except Exception:
            root_version = self.Version("0.0.0")
        
        # Create initial requirements - start from the root object (no version constraint to ensure it matches)
        initial_requirements = [self.O3deRequirement(root_type, root_name, self.SpecifierSet(""))]
        
        try:
            # Resolve dependencies starting from the root
            result = resolver.resolve(initial_requirements, max_rounds=1000)
            
            # Extract solution
            resolved_dependencies = {}
            for identifier, candidate in result.mapping.items():
                resolved_dependencies[f"{candidate.object_type}.{candidate.name}"] = {
                    'version': str(candidate.version),
                    'object_uri': candidate.obj_data.get_object_uri(),
                    'object_type': candidate.object_type.lower()
                }
            
            return resolved_dependencies, []
            
        except self.ResolutionImpossible as e:
            # Extract conflict information
            conflicts = []
            for cause in e.causes:
                conflicts.append(f"Cannot resolve {cause.requirement}: conflicting requirements")
            
            return {}, conflicts
        
        except Exception as e:
            return {}, [f"Resolution failed: {str(e)}"]
    
    def resolve_all_roots(self, engines, projects) -> dict:
        """
        Resolve dependencies for all root objects (Engines and Projects)
        
        :param engines: List of engine objects
        :param projects: List of project objects  
        :return: Dictionary of root resolutions
        """
        root_resolutions = {}
        
        # Process each Engine as a root
        for engine in engines:
            engine_name = engine.get_header().get_name()
            resolved_deps, conflicts = self.resolve_root_dependencies(engine)
            root_resolutions[f"engine:{engine_name}"] = {
                'type': 'engine',
                'name': engine_name,
                'resolved_packages': resolved_deps,
                'conflicts': conflicts
            }
        
        # Process each Project as a root
        for project in projects:
            project_name = project.get_header().get_name()
            resolved_deps, conflicts = self.resolve_root_dependencies(project)
            root_resolutions[f"project:{project_name}"] = {
                'type': 'project',
                'name': project_name,
                'resolved_packages': resolved_deps,
                'conflicts': conflicts
            }
        
        return root_resolutions
    
    # Extended candidate and requirement classes for all O3DE object types
    class O3deRequirement(namedtuple("O3deRequirement", ["object_type", "name", "specifier"])):
        def __repr__(self):
            return f'<{self.object_type}Requirement({self.name}{self.specifier if self.specifier else ""})>'
        
        def identify(self):
            return f"{self.object_type}Requirement:{self.name}"
        
        def failure_reason(self, object_name):
            return f'{object_name} requires {self.object_type}.{self.name}{self.specifier if self.specifier else ""}'
    
    class O3deCandidate(namedtuple("O3deCandidate", ["object_type", "name", "version", "requirements", "obj_data"])):
        def __repr__(self):
            return f"<{self.object_type} {self.name}=={self.version}>"
        
        def identify(self):
            return repr(self)
        
        def __hash__(self) -> int:
            return hash((self.object_type, self.name, self.version))
    
    class O3deDependencyProvider(AbstractProvider):
        def __init__(self, candidates):
            self.candidates = candidates
        
        def identify(self, requirement_or_candidate):
            return requirement_or_candidate.identify()
        
        def get_preference(self, identifier, resolutions, candidates, information, **_):
            # Prefer engines > projects > gems > templates > repos > restricteds
            if "Engine" in identifier:
                return 1000
            elif "Project" in identifier:
                return 800
            elif "Gem" in identifier:
                return 600
            elif "Template" in identifier:
                return 400
            elif "Repo" in identifier:
                return 200
            elif "Restricted" in identifier:
                return 100
            return 0
        
        def find_matches(self, identifier, requirements, incompatibilities):
            # Return candidates that satisfy requirements, sorted by version (highest first)
            matching_candidates = []
            for candidate in self.candidates:
                if candidate.identify() == identifier:
                    # Check if candidate satisfies all requirements
                    satisfies_all = all(
                        self.is_satisfied_by(req, candidate) 
                        for req_list in requirements.values() 
                        for req in req_list
                        if req.identify() == identifier
                    )
                    
                    # Check against incompatibilities
                    not_incompatible = all(
                        candidate.version != incomp.version
                        for incomp_list in incompatibilities.values()
                        for incomp in incomp_list
                    )
                    
                    if satisfies_all and not_incompatible:
                        matching_candidates.append(candidate)
            
            # Sort by version (highest first)
            try:
                return sorted(matching_candidates, key=lambda c: c.version, reverse=True)
            except Exception:
                # Fallback to string sort if version comparison fails
                return sorted(matching_candidates, key=lambda c: str(c.version), reverse=True)
        
        def is_satisfied_by(self, requirement, candidate):
            if requirement.object_type != candidate.object_type:
                return False
            
            if requirement.name != candidate.name:
                return False
            
            # Check version constraint using enhanced O3deNameVersion logic
            if requirement.specifier is None or not str(requirement.specifier):
                return True
            
            try:
                # Use SpecifierSet for comprehensive constraint checking
                return candidate.version in requirement.specifier
            except Exception:
                # Fallback: exact match if constraint parsing fails
                return str(candidate.version) == str(requirement.specifier)
        
        def get_dependencies(self, candidate):
            return candidate.requirements
    

def _resolve(args: argparse) -> int:
    """
    resolve everything the configure step needs
    :param args: Parsed command line arguments
    """

    # query all objects from the root manifest
    manifest_all_child_engine_json_paths, manifest_all_child_engine_objects = manifest.get_child_engine_objects(True)
    manifest_all_child_project_json_paths, manifest_all_child_project_objects = manifest.get_child_project_objects(True)
    manifest_all_child_gem_json_paths, manifest_all_child_gem_objects = manifest.get_child_gem_objects(True)
    manifest_all_child_template_json_paths, manifest_all_child_template_objects = manifest.get_child_template_objects(True)
    manifest_all_child_repo_json_paths, manifest_all_child_repo_objects = manifest.get_child_repo_objects(True)
    manifest_all_child_restricted_json_paths, manifest_all_child_restricted_objects = manifest.get_child_restricted_objects(True)

    manifest_all_engine_names = []
    for engine in manifest_all_child_engine_objects:
        name = engine.get_header().get_name()
        version = engine.get_header().get_version()
        name_with_version = f'{name}=={version}'        
        manifest_all_engine_names.append(name_with_version)

    manifest_all_project_names = []
    for project in manifest_all_child_project_objects:
        name = project.get_header().get_name()
        version = project.get_header().get_version()
        name_with_version = f'{name}=={version}'
        manifest_all_project_names.append(name_with_version)

    manifest_all_gem_names = []
    for gem in manifest_all_child_gem_objects:
        name = gem.get_header().get_name()
        version = gem.get_header().get_version()
        name_with_version = f'{name}=={version}'
        manifest_all_gem_names.append(name_with_version)

    manifest_all_template_names = []
    for template in manifest_all_child_template_objects:
        name = template.get_header().get_name()
        version = template.get_header().get_version()
        name_with_version = f'{name}=={version}'
        manifest_all_template_names.append(name_with_version)

    manifest_all_repo_names = []
    for repo in manifest_all_child_repo_objects:
        name = repo.get_header().get_name()
        version = repo.get_header().get_version()
        name_with_version = f'{name}=={version}'
        manifest_all_repo_names.append(name_with_version)

    manifest_all_restricted_names = []
    for restricted in manifest_all_child_restricted_objects:
        name = restricted.get_header().get_name()
        version = restricted.get_header().get_version()
        name_with_version = f'{name}=={version}'
        manifest_all_restricted_names.append(name_with_version)

    # ==== ADVANCED DEPENDENCY RESOLUTION USING RESOLVELIB ====
    print("Resolving dependency constraints using ResolveLib...")
    
    # Import O3DE's ResolveLib infrastructure
    from o3de import compatibility
    
    # Resolve dependencies for each root object (Engines and Projects)
    root_resolutions = {}
    
    try:
        # Create resolver instance
        resolver = ResolveDependencies()
        
        # Add all object types to the resolver
        resolver.add_objects('engine', manifest_all_child_engine_objects)
        resolver.add_objects('project', manifest_all_child_project_objects) 
        resolver.add_objects('gem', manifest_all_child_gem_objects)
        resolver.add_objects('template', manifest_all_child_template_objects)
        resolver.add_objects('repo', manifest_all_child_repo_objects)
        resolver.add_objects('restricted', manifest_all_child_restricted_objects)
        
        # Process each Engine as a root
        for engine in manifest_all_child_engine_objects:
            engine_name = engine.get_header().get_name()
            print(f"  Resolving dependencies for Engine: {engine_name}")
            
            resolved_deps, conflicts = resolver.resolve_root_dependencies(engine)
            root_resolutions[f"engine:{engine_name}"] = {
                'type': 'engine',
                'name': engine_name,
                'resolved_packages': resolved_deps,
                'conflicts': conflicts
            }
            
            if conflicts:
                print(f"    ⚠️  {len(conflicts)} conflicts detected for Engine {engine_name}")
                for conflict in conflicts[:2]:  # Show first 2 conflicts
                    print(f"      - {conflict}")
                if len(conflicts) > 2:
                    print(f"      - ... and {len(conflicts) - 2} more conflicts")
            else:
                print(f"    ✅ Successfully resolved {len(resolved_deps)} packages for Engine {engine_name}")
                # Show breakdown by type
                type_counts = {}
                for pkg_info in resolved_deps.values():
                    obj_type = pkg_info['object_type']
                    type_counts[obj_type] = type_counts.get(obj_type, 0) + 1
                if type_counts:
                    breakdown = ', '.join([f"{count} {obj_type}{'s' if count > 1 else ''}" for obj_type, count in type_counts.items()])
                    print(f"      ({breakdown})")
        
        # Process each Project as a root
        for project in manifest_all_child_project_objects:
            project_name = project.get_header().get_name()
            print(f"  Resolving dependencies for Project: {project_name}")
            
            resolved_deps, conflicts = resolver.resolve_root_dependencies(project)
            root_resolutions[f"project:{project_name}"] = {
                'type': 'project',
                'name': project_name,
                'resolved_packages': resolved_deps,
                'conflicts': conflicts
            }
            
            if conflicts:
                print(f"    ⚠️  {len(conflicts)} conflicts detected for Project {project_name}")
                for conflict in conflicts[:2]:  # Show first 2 conflicts
                    print(f"      - {conflict}")
                if len(conflicts) > 2:
                    print(f"      - ... and {len(conflicts) - 2} more conflicts")
            else:
                print(f"    ✅ Successfully resolved {len(resolved_deps)} packages for Project {project_name}")
                # Show breakdown by type
                type_counts = {}
                for pkg_info in resolved_deps.values():
                    obj_type = pkg_info['object_type']
                    type_counts[obj_type] = type_counts.get(obj_type, 0) + 1
                if type_counts:
                    breakdown = ', '.join([f"{count} {obj_type}{'s' if count > 1 else ''}" for obj_type, count in type_counts.items()])
                    print(f"      ({breakdown})")
        
        # Summary
        total_roots = len(manifest_all_child_engine_objects) + len(manifest_all_child_project_objects)
        print(f"Dependency resolution completed for {total_roots} root objects.")
        
    except Exception as e:
        print(f"Dependency resolution failed: {e}")
        root_resolutions = {}

    #create the object everything is stored in
    resolved = {}
    
    # Add per-root dependency resolution results to resolved manifest
    resolved['dependency_resolution'] = {
        'root_resolutions': root_resolutions,
        'solver_version': 'resolvelib-2.0.0',
        'total_roots': len(root_resolutions)
    }
    
    resolved['country_code'] = manifest.get_country().get_code()
    resolved['default_engines_path'] = manifest.get_default_engines_path()
    resolved['default_projects_path'] = manifest.get_default_projects_path()
    resolved['default_gems_path'] = manifest.get_default_gems_path()
    resolved['default_templates_path'] = manifest.get_default_templates_path()
    resolved['default_repos_path'] = manifest.get_default_repos_path()
    resolved['default_restricteds_path'] = manifest.get_default_restricteds_path()
    resolved['default_third_party_path'] = manifest.get_default_third_party_path()

    resolved['all_engine_paths'] = manifest_all_child_engine_json_paths
    resolved['all_project_paths'] = manifest_all_child_project_json_paths
    resolved['all_gem_paths'] = manifest_all_child_gem_json_paths
    resolved['all_template_paths'] = manifest_all_child_template_json_paths
    resolved['all_repo_paths'] = manifest_all_child_repo_json_paths
    resolved['all_restricted_paths'] = manifest_all_child_restricted_json_paths

    resolved['all_engine_names'] = manifest_all_engine_names
    resolved['all_project_names'] = manifest_all_project_names
    resolved['all_gem_names'] = manifest_all_gem_names
    resolved['all_template_names'] = manifest_all_template_names
    resolved['all_repo_names'] = manifest_all_repo_names
    resolved['all_restricted_names'] = manifest_all_restricted_names

    # query all objects from the the point of view of the engine object
    for engine in manifest_all_child_engine_objects:
        child_engine_json_paths, child_engine_objects = engine.get_child_engine_objects(True)
        child_project_json_paths, child_project_objects = engine.get_child_project_objects(True)
        child_gem_json_paths, child_gem_objects = engine.get_child_gem_objects(True)
        child_template_json_paths, child_template_objects = engine.get_child_template_objects(True)
        child_repo_json_paths, child_repo_objects = engine.get_child_repo_objects(True)
        child_restricted_json_paths, child_restricted_objects = engine.get_child_restricted_objects(True)

        parent_json_paths, parent_objects = engine.get_parent(True)

        dependent_engines = engine.get_dependent_engines(True)
        dependent_projects = engine.get_dependent_projects(True)
        dependent_gems = engine.get_dependent_gems(True)
        dependent_templates = engine.get_dependent_templates(True)
        dependent_repos = engine.get_dependent_repos(True)
        dependent_restricteds = engine.get_dependent_restricteds(True)

        # Get all restricted objects that are compatible with this object and all its parents
        restricteds = []
        restricteds_precedence = []
        restricteds_json_paths = []
        restricteds_object_json_paths = []
        compatible_objects = [engine]
        compatible_objects.extend(parent_objects)
        for restricted in manifest_all_child_restricted_objects:
            extends = O3deNameVersion()
            extends.from_string(restricted.get_extends())
            for compatible_object in compatible_objects:
                if extends.compatible_with(compatible_object.get_header().get_name(), compatible_object.get_header().get_version()):
                    restricteds_object_json_paths.append(compatible_object.get_object_uri())
                    restricteds_json_paths.append(restricted.get_object_uri())
                    restricteds_precedence.append(restricted.get_precedence())
        # Sort restricted arrays based on precedence
        if restricteds_precedence:
            sorted_data = sorted(zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths), reverse=True)
            sorted_precedence, sorted_json_paths, sorted_object_json_paths = zip(*sorted_data)
            restricteds_precedence = list(sorted_precedence)
            restricteds_json_paths = list(sorted_json_paths)
            restricteds_object_json_paths = list(sorted_object_json_paths)
            for restricted_precedence, restricted_json_path, restricted_object_json_path in zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths):
                restricteds.append({
                    'restricted_precedence': restricted_precedence,
                    'restricted_object_json_path': restricted_object_json_path,
                    'restricted_json_path': restricted_json_path,
                })

        resolved[engine.get_object_uri()] = {
            'name': engine.get_header().get_name(),
            'version': engine.get_header().get_version(),
            'display_name': engine.get_header().get_display_name(),
            'description': engine.get_header().get_description(),
            'type': engine.get_header().get_type(),
            'id': engine.get_header().get_id(),
            'copyright_year': engine.get_header().get_copyright_year(),
            'copyright_text': engine.get_header().get_copyright_text(),

            'O3DEVersion': engine.get_o3de_version(),
            'O3DEBuildNumber': engine.get_o3de_build_number(),
            'display_version': engine.get_display_version(),
            'file_version': engine.get_file_version(),
            'build': engine.get_build(),

            'api_version_editor': engine.api_versions.get_editor(),
            'api_version_framework': engine.api_versions.get_framework(),
            'api_version_launcher': engine.api_versions.get_launcher(),
            'api_version_tools': engine.api_versions.get_tools(),

            'canonical_tags': engine.get_canonical_tags(),
            'user_tags': engine.get_user_tags(),
            'platforms': engine.get_platforms(),

            'restricteds': restricteds,

            'child_engine_json_paths': child_engine_json_paths,
            'child_project_json_paths': child_project_json_paths,
            'child_gem_json_paths': child_gem_json_paths,
            'child_template_json_paths': child_template_json_paths,
            'child_repo_json_paths': child_repo_json_paths,
            'child_restricted_json_paths': child_restricted_json_paths,

            'parent_json_paths': parent_json_paths,

            'dependent_engines': dependent_engines,
            'dependent_projects': dependent_projects,
            'dependent_gems': dependent_gems,
            'dependent_templates': dependent_templates,
            'dependent_repos': dependent_repos,
            'dependent_restricteds': dependent_restricteds,
        }

    # query all objects from the the point of view of the project object
    for project in manifest_all_child_project_objects:
        child_engine_json_paths, child_engine_objects = project.get_child_engine_objects(True)
        child_project_json_paths, child_project_objects = project.get_child_project_objects(True)
        child_gem_json_paths, child_gem_objects = project.get_child_gem_objects(True)
        child_template_json_paths, child_template_objects = project.get_child_template_objects(True)
        child_repo_json_paths, child_repo_objects = project.get_child_repo_objects(True)
        child_restricted_json_paths, child_restricted_objects = project.get_child_restricted_objects(True)

        parent_json_paths, parent_objects = project.get_parent(True)

        dependent_engines = project.get_dependent_engines(True)
        dependent_projects = project.get_dependent_projects(True)
        dependent_gems = project.get_dependent_gems(True)
        dependent_templates = project.get_dependent_templates(True)
        dependent_repos = project.get_dependent_repos(True)
        dependent_restricteds = project.get_dependent_restricteds(True)

        # Get all restricted objects that are compatible with this object and all its parents
        restricteds = []
        restricteds_precedence = []
        restricteds_json_paths = []
        restricteds_object_json_paths = []
        compatible_objects = [project]
        compatible_objects.extend(parent_objects)
        for restricted in manifest_all_child_restricted_objects:
            extends = O3deNameVersion()
            extends.from_string(restricted.get_extends())
            for compatible_object in compatible_objects:
                if extends.compatible_with(compatible_object.get_header().get_name(), compatible_object.get_header().get_version()):
                    restricteds_object_json_paths.append(compatible_object.get_object_uri())
                    restricteds_json_paths.append(restricted.get_object_uri())
                    restricteds_precedence.append(restricted.get_precedence())
        # Sort restricted arrays based on precedence
        if restricteds_precedence:
            sorted_data = sorted(zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths), reverse=True)
            sorted_precedence, sorted_json_paths, sorted_object_json_paths = zip(*sorted_data)
            restricteds_precedence = list(sorted_precedence)
            restricteds_json_paths = list(sorted_json_paths)
            restricteds_object_json_paths = list(sorted_object_json_paths)
            for restricted_precedence, restricted_json_path, restricted_object_json_path in zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths):
                restricteds.append({
                    'restricted_precedence': restricted_precedence,
                    'restricted_object_json_path': restricted_object_json_path,
                    'restricted_json_path': restricted_json_path,
                })

        resolved[project.get_object_uri()] = {
            'name': project.get_header().get_name(),
            'version': project.get_header().get_version(),
            'display_name': project.get_header().get_display_name(),
            'description': project.get_header().get_description(),
            'type': project.get_header().get_type(),
            'id': project.get_header().get_id(),
            'copyright_year': project.get_header().get_copyright_year(),
            'copyright_text': project.get_header().get_copyright_text(),

            'canonical_tags': gem.get_canonical_tags(),
            'user_tags': gem.get_user_tags(),
            'platforms': gem.get_platforms(),

            'product_name': project.get_product_name(),
            'executable_name': project.get_executable_name(),           
            'engine': project.get_engine(),

            'restricteds': restricteds,

            'child_engine_json_paths': child_engine_json_paths,
            'child_project_json_paths': child_project_json_paths,
            'child_gem_json_paths': child_gem_json_paths,
            'child_template_json_paths': child_template_json_paths,
            'child_repo_json_paths': child_repo_json_paths,
            'child_restricted_json_paths': child_restricted_json_paths,

            'parent_json_paths': parent_json_paths,

            'dependent_engines': dependent_engines,
            'dependent_projects': dependent_projects,
            'dependent_gems': dependent_gems,
            'dependent_templates': dependent_templates,
            'dependent_repos': dependent_repos,
            'dependent_restricteds': dependent_restricteds
        }

    # query all objects from the the point of view of the gem object
    for gem in manifest_all_child_gem_objects:
        child_engine_json_paths, child_engine_objects = gem.get_child_engine_objects(True)
        child_project_json_paths, child_project_objects = gem.get_child_project_objects(True)
        child_gem_json_paths, child_gem_objects = gem.get_child_gem_objects(True)
        child_template_json_paths, child_template_objects = gem.get_child_template_objects(True)
        child_repo_json_paths, child_repo_objects = gem.get_child_repo_objects(True)
        child_restricted_json_paths, child_restricted_objects = gem.get_child_restricted_objects(True)

        parent_json_paths, parent_objects = gem.get_parent(True)

        dependent_engines = gem.get_dependent_engines(True)
        dependent_projects = gem.get_dependent_projects(True)
        dependent_gems = gem.get_dependent_gems(True)
        dependent_templates = gem.get_dependent_templates(True)
        dependent_repos = gem.get_dependent_repos(True)
        dependent_restricteds = gem.get_dependent_restricteds(True)

        # Get all restricted objects that are compatible with this object and all its parents
        restricteds = []
        restricteds_precedence = []
        restricteds_json_paths = []
        restricteds_object_json_paths = []
        compatible_objects = [gem]
        compatible_objects.extend(parent_objects)
        for restricted in manifest_all_child_restricted_objects:
            extends = O3deNameVersion()
            extends.from_string(restricted.get_extends())
            for compatible_object in compatible_objects:
                if extends.compatible_with(compatible_object.get_header().get_name(), compatible_object.get_header().get_version()):
                    restricteds_object_json_paths.append(compatible_object.get_object_uri())
                    restricteds_json_paths.append(restricted.get_object_uri())
                    restricteds_precedence.append(restricted.get_precedence())
        # Sort restricted arrays based on precedence
        if restricteds_precedence:
            sorted_data = sorted(zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths), reverse=True)
            sorted_precedence, sorted_json_paths, sorted_object_json_paths = zip(*sorted_data)
            restricteds_precedence = list(sorted_precedence)
            restricteds_json_paths = list(sorted_json_paths)
            restricteds_object_json_paths = list(sorted_object_json_paths)
            for restricted_precedence, restricted_json_path, restricted_object_json_path in zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths):
                restricteds.append({
                    'restricted_precedence': restricted_precedence,
                    'restricted_object_json_path': restricted_object_json_path,
                    'restricted_json_path': restricted_json_path,
                })

        resolved[gem.get_object_uri()] = {
            'name': gem.get_header().get_name(),
            'version': gem.get_header().get_version(),
            'display_name': gem.get_header().get_display_name(),
            'description': gem.get_header().get_description(),
            'type': gem.get_header().get_type(),
            'id': gem.get_header().get_id(),
            'copyright_year': gem.get_header().get_copyright_year(),
            'copyright_text': gem.get_header().get_copyright_text(),

            'canonical_tags': gem.get_canonical_tags(),
            'user_tags': gem.get_user_tags(),
            'platforms': gem.get_platforms(),

            'restricteds': restricteds,

            'child_engine_json_paths': child_engine_json_paths,
            'child_project_json_paths': child_project_json_paths,
            'child_gem_json_paths': child_gem_json_paths,
            'child_template_json_paths': child_template_json_paths,
            'child_repo_json_paths': child_repo_json_paths,
            'child_restricted_json_paths': child_restricted_json_paths,

            'parent_json_paths': parent_json_paths,

            'dependent_engines': dependent_engines,
            'dependent_projects': dependent_projects,
            'dependent_gems': dependent_gems,
            'dependent_templates': dependent_templates,
            'dependent_repos': dependent_repos,
            'dependent_restricteds': dependent_restricteds
        }

    # query all objects from the the point of view of the template object
    for template in manifest_all_child_template_objects:
        child_engine_json_paths, child_engine_objects = template.get_child_engine_objects(True)
        child_project_json_paths, child_project_objects = template.get_child_project_objects(True)
        child_gem_json_paths, child_gem_objects = template.get_child_gem_objects(True)
        child_template_json_paths, child_template_objects = template.get_child_template_objects(True)
        child_repo_json_paths, child_repo_objects = template.get_child_repo_objects(True)
        child_restricted_json_paths, child_restricted_objects = template.get_child_restricted_objects(True)

        parent_json_paths, parent_objects = template.get_parent(True)

        dependent_engines = template.get_dependent_engines(True)
        dependent_projects = template.get_dependent_projects(True)
        dependent_gems = template.get_dependent_gems(True)
        dependent_templates = template.get_dependent_templates(True)
        dependent_repos = template.get_dependent_repos(True)
        dependent_restricteds = template.get_dependent_restricteds(True)

        # Get all restricted objects that are compatible with this object and all its parents
        restricteds = []
        restricteds_precedence = []
        restricteds_json_paths = []
        restricteds_object_json_paths = []
        compatible_objects = [template]
        compatible_objects.extend(parent_objects)
        for restricted in manifest_all_child_restricted_objects:
            extends = O3deNameVersion()
            extends.from_string(restricted.get_extends())
            for compatible_object in compatible_objects:
                if extends.compatible_with(compatible_object.get_header().get_name(), compatible_object.get_header().get_version()):
                    restricteds_object_json_paths.append(compatible_object.get_object_uri())
                    restricteds_json_paths.append(restricted.get_object_uri())
                    restricteds_precedence.append(restricted.get_precedence())
        # Sort restricted arrays based on precedence
        if restricteds_precedence:
            sorted_data = sorted(zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths), reverse=True)
            sorted_precedence, sorted_json_paths, sorted_object_json_paths = zip(*sorted_data)
            restricteds_precedence = list(sorted_precedence)
            restricteds_json_paths = list(sorted_json_paths)
            restricteds_object_json_paths = list(sorted_object_json_paths)
            for restricted_precedence, restricted_json_path, restricted_object_json_path in zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths):
                restricteds.append({
                    'restricted_precedence': restricted_precedence,
                    'restricted_object_json_path': restricted_object_json_path,
                    'restricted_json_path': restricted_json_path,
                })

        resolved[template.get_object_uri()] = {
            'name': template.get_header().get_name(),
            'version': template.get_header().get_version(),
            'display_name': template.get_header().get_display_name(),
            'description': template.get_header().get_description(),
            'type': template.get_header().get_type(),
            'id': template.get_header().get_id(),
            'copyright_year': template.get_header().get_copyright_year(),
            'copyright_text': template.get_header().get_copyright_text(),

            'canonical_tags': template.get_canonical_tags(),
            'user_tags': template.get_user_tags(),
            'platforms': template.get_platforms(),

            'restricteds': restricteds,

            'child_engine_json_paths': child_engine_json_paths,
            'child_project_json_paths': child_project_json_paths,
            'child_gem_json_paths': child_gem_json_paths,
            'child_template_json_paths': child_template_json_paths,
            'child_repo_json_paths': child_repo_json_paths,
            'child_restricted_json_paths': child_restricted_json_paths,

            'parent_json_paths': parent_json_paths,

            'dependent_engines': dependent_engines,
            'dependent_projects': dependent_projects,
            'dependent_gems': dependent_gems,
            'dependent_templates': dependent_templates,
            'dependent_repos': dependent_repos,
            'dependent_restricteds': dependent_restricteds
        }

    # query all objects from the the point of view of the repo object
    for repo in manifest_all_child_repo_objects:
        child_engine_json_paths, child_engine_objects = repo.get_child_engine_objects(True)
        child_project_json_paths, child_project_objects = repo.get_child_project_objects(True)
        child_gem_json_paths, child_gem_objects = repo.get_child_gem_objects(True)
        child_template_json_paths, child_template_objects = repo.get_child_template_objects(True)
        child_repo_json_paths, child_repo_objects = repo.get_child_repo_objects(True)
        child_restricted_json_paths, child_restricted_objects = repo.get_child_restricted_objects(True)

        parent_json_paths, parent_objects = repo.get_parent(True)

        dependent_engines = repo.get_dependent_engines(True)
        dependent_projects = repo.get_dependent_projects(True)
        dependent_gems = repo.get_dependent_gems(True)
        dependent_templates = repo.get_dependent_templates(True)
        dependent_repos = repo.get_dependent_repos(True)
        dependent_restricteds = repo.get_dependent_restricteds(True)

        # Get all restricted objects that are compatible with this object and all its parents
        restricteds = []
        restricteds_precedence = []
        restricteds_json_paths = []
        restricteds_object_json_paths = []
        compatible_objects = [repo]
        compatible_objects.extend(parent_objects)
        for restricted in manifest_all_child_restricted_objects:
            extends = O3deNameVersion()
            extends.from_string(restricted.get_extends())
            for compatible_object in compatible_objects:
                if extends.compatible_with(compatible_object.get_header().get_name(), compatible_object.get_header().get_version()):
                    restricteds_object_json_paths.append(compatible_object.get_object_uri())
                    restricteds_json_paths.append(restricted.get_object_uri())
                    restricteds_precedence.append(restricted.get_precedence())
        # Sort restricted arrays based on precedence
        if restricteds_precedence:
            sorted_data = sorted(zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths), reverse=True)
            sorted_precedence, sorted_json_paths, sorted_object_json_paths = zip(*sorted_data)
            restricteds_precedence = list(sorted_precedence)
            restricteds_json_paths = list(sorted_json_paths)
            restricteds_object_json_paths = list(sorted_object_json_paths)
            for restricted_precedence, restricted_json_path, restricted_object_json_path in zip(restricteds_precedence, restricteds_json_paths, restricteds_object_json_paths):
                restricteds.append({
                    'restricted_precedence': restricted_precedence,
                    'restricted_object_json_path': restricted_object_json_path,
                    'restricted_json_path': restricted_json_path,
                })

        resolved[repo.get_object_uri()] = {
            'name': repo.get_header().get_name(),
            'version': repo.get_header().get_version(),
            'display_name': repo.get_header().get_display_name(),
            'description': repo.get_header().get_description(),
            'type': repo.get_header().get_type(),
            'id': repo.get_header().get_id(),
            'copyright_year': repo.get_header().get_copyright_year(),
            'copyright_text': repo.get_header().get_copyright_text(),

            'canonical_tags': repo.get_canonical_tags(),
            'user_tags': repo.get_user_tags(),
            'platforms': repo.get_platforms(),

            'restricteds': restricteds,

            'child_engine_json_paths': child_engine_json_paths,
            'child_project_json_paths': child_project_json_paths,
            'child_gem_json_paths': child_gem_json_paths,
            'child_template_json_paths': child_template_json_paths,
            'child_repo_json_paths': child_repo_json_paths,
            'child_restricted_json_paths': child_restricted_json_paths,

            'parent_json_paths': parent_json_paths,

            'dependent_engines': dependent_engines,
            'dependent_projects': dependent_projects,
            'dependent_gems': dependent_gems,
            'dependent_templates': dependent_templates,
            'dependent_repos': dependent_repos,
            'dependent_restricteds': dependent_restricteds
        }

    # query all objects from the the point of view of the restricted object
    for restricted in manifest_all_child_restricted_objects:
        child_engine_json_paths, child_engine_objects = restricted.get_child_engine_objects(True)
        child_project_json_paths, child_project_objects = restricted.get_child_project_objects(True)
        child_gem_json_paths, child_gem_objects = restricted.get_child_gem_objects(True)
        child_template_json_paths, child_template_objects = restricted.get_child_template_objects(True)
        child_repo_json_paths, child_repo_objects = restricted.get_child_repo_objects(True)
        child_restricted_json_paths, child_restricted_objects = restricted.get_child_restricted_objects(True)

        parent_json_paths, parent_objects = restricted.get_parent(True)

        dependent_engines = restricted.get_dependent_engines(True)
        dependent_projects = restricted.get_dependent_projects(True)
        dependent_gems = restricted.get_dependent_gems(True)
        dependent_templates = restricted.get_dependent_templates(True)
        dependent_repos = restricted.get_dependent_repos(True)
        dependent_restricteds = restricted.get_dependent_restricteds(True)

        resolved[restricted.get_object_uri()] = {
            'name': restricted.get_header().get_name(),
            'version': restricted.get_header().get_version(),
            'display_name': restricted.get_header().get_display_name(),
            'description': restricted.get_header().get_description(),
            'type': restricted.get_header().get_type(),
            'id': restricted.get_header().get_id(),
            'copyright_year': restricted.get_header().get_copyright_year(),
            'copyright_text': restricted.get_header().get_copyright_text(),

            'extends': restricted.get_extends(),
            'precedence': restricted.get_precedence(),

            'canonical_tags': restricted.get_canonical_tags(),
            'user_tags': restricted.get_user_tags(),
            'platforms': restricted.get_platforms(),
            'platform_maps': restricted.get_platform_maps(),
            'platform_wart_maps': restricted.get_platform_wart_maps(),

            'child_engine_json_paths': child_engine_json_paths,
            'child_project_json_paths': child_project_json_paths,
            'child_gem_json_paths': child_gem_json_paths,
            'child_template_json_paths': child_template_json_paths,
            'child_repo_json_paths': child_repo_json_paths,
            'child_restricted_json_paths': child_restricted_json_paths,

            'parent_json_paths': parent_json_paths,

            'dependent_engines': dependent_engines,
            'dependent_projects': dependent_projects,
            'dependent_gems': dependent_gems,
            'dependent_templates': dependent_templates,
            'dependent_repos': dependent_repos,
            'dependent_restricteds': dependent_restricteds,
        }

    # write the resolved dictionary to a JSON file
    # get the manifest file path
    manifest_file_path = manifest.get_object_uri()
    # replace the o3de_manifest.json resolved_o3de_manifest.json
    resolved_manifest_file_path = manifest_file_path.replace("o3de_manifest.json", "resolved_o3de_manifest.json")
    #if the file exists remove it
    if pathlib.Path(resolved_manifest_file_path).is_file():
        pathlib.Path(resolved_manifest_file_path).unlink()
    # write the resolved dictionary to the resolved manifest file
    with open(resolved_manifest_file_path, 'w') as f:
        json.dump(resolved, f, indent=4, sort_keys=False)

    return 0


def add_args(subparsers) -> None:
    resolve_parser = subparsers.add_parser('resolve')
    resolve_parser.set_defaults(func=_resolve)
