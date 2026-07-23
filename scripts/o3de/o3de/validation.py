#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
"""
This file validating o3de object json files
"""
import json
import pathlib
import uuid
from o3de import utils


def always_valid(json_data: dict) -> bool:
    return True


def valid_o3de_json_dict(json_data: dict, key: str) -> bool:
    return key in json_data


# ── Schema 2.0 validation helpers ──────────────────────────────────

def _is_schema_2(json_data: dict) -> bool:
    """Check if the JSON data uses Schema 2.0.0."""
    return json_data.get("$schemaVersion") == "2.0.0"


def _valid_2_0_header(json_data: dict, object_key: str) -> bool:
    """Validate a Schema 2.0 object header.
    
    Schema 2.0 objects have a nested header under the object type key:
    {"$schemaVersion": "2.0.0", "<object_key>": {"name": "...", "version": "..."}}
    """
    obj = json_data.get(object_key)
    if not isinstance(obj, dict):
        return False
    if not obj.get("name"):
        return False
    if not obj.get("version"):
        return False
    return True


def get_object_name(json_data: dict, object_type: str) -> str:
    """Extract an object's name from either legacy or Schema 2.0 format.
    
    Legacy:  {"engine_name": "o3de"}  → "o3de"
    2.0:     {"engine": {"name": "o3de", ...}} → "o3de"
    """
    if _is_schema_2(json_data):
        header = json_data.get(object_type, {})
        return header.get("name", "") if isinstance(header, dict) else ""
    return json_data.get(f"{object_type}_name", "")


def get_object_version(json_data: dict, object_type: str) -> str:
    """Extract an object's version from either legacy or Schema 2.0 format.
    
    Legacy:  {"version": "1.0.0"}  → "1.0.0"
    2.0:     {"engine": {"version": "2.0.0", ...}} → "2.0.0"
    """
    if _is_schema_2(json_data):
        header = json_data.get(object_type, {})
        return header.get("version", "") if isinstance(header, dict) else ""
    return json_data.get("version", "")


def valid_o3de_repo_json(file_name: str or pathlib.Path) -> bool:
    file_name = pathlib.Path(file_name).resolve()
    if not file_name.is_file():
        return False

    with file_name.open('r') as f:
        try:
            json_data = json.load(f)
            if _is_schema_2(json_data):
                return _valid_2_0_header(json_data, "repo")
            _ = json_data['repo_name']
            _ = json_data['origin']
        except (json.JSONDecodeError, KeyError):
            return False
    return True


def valid_o3de_engine_json(file_name: str or pathlib.Path) -> bool:
    file_name = pathlib.Path(file_name).resolve()
    if not file_name.is_file():
        return False

    with file_name.open('r') as f:
        try:
            json_data = json.load(f)
            if _is_schema_2(json_data):
                return _valid_2_0_header(json_data, "engine")
            _ = json_data['engine_name']
        except (json.JSONDecodeError, KeyError):
            return False
    return True


def valid_o3de_project_json_data(json_data: dict, generate_uuid: bool = True) -> bool:
    try:
        if _is_schema_2(json_data):
            return _valid_2_0_header(json_data, "project")
        _ = json_data['project_name']
        if 'compatible_engines' in json_data:
            if not utils.validate_version_specifier_list(json_data['compatible_engines']):
                return False
        if not generate_uuid:
            _ = json_data['project_id']
    except (KeyError):
        return False
    return True


def valid_o3de_project_json(file_name: str or pathlib.Path, generate_uuid: bool = True) -> bool:
    file_name = pathlib.Path(file_name).resolve()
    if not file_name.is_file():
        return False

    with file_name.open('r') as f:
        try:
            json_data = json.load(f)
            valid_o3de_project_json_data(json_data, generate_uuid)
            if generate_uuid:
                test = json_data.get('project_id', 'No ID')
                generate_new_id = test == 'No ID'

        except (json.JSONDecodeError, KeyError):
            return False
    # Generate a random uuid for the project json if it is missing instead of failing if generate_uuid is true
    if generate_uuid and generate_new_id:
        with file_name.open('w') as f:
            new_uuid = '{' + str(uuid.uuid4()) + '}'
            json_data.update({'project_id': new_uuid})
            f.write(json.dumps(json_data, indent=4) + '\n')
    return True


def valid_o3de_gem_json_data(json_data: dict) -> bool:
    try:
        if _is_schema_2(json_data):
            return _valid_2_0_header(json_data, "gem")
        _ = json_data['gem_name']

        if 'compatible_engines' in json_data:
            if not utils.validate_version_specifier_list(json_data['compatible_engines']):
                return False

    except (KeyError):
        return False
    return True

def valid_o3de_gem_json(file_name: str or pathlib.Path) -> bool:
    file_name = pathlib.Path(file_name).resolve()
    if not file_name.is_file():
        return False

    # all return paths are encapsulated within scope. File path was pre-validated
    # open will raise an OSError, so there is no need for a default return path
    with file_name.open('r') as f:
        try:
            return valid_o3de_gem_json_data(json.load(f))
        except json.JSONDecodeError:
            return False
    


def valid_o3de_template_json_data(json_data: dict) -> bool:
    try:
        if _is_schema_2(json_data):
            return _valid_2_0_header(json_data, "template")
        _ = json_data['template_name']
    except (KeyError):
        return False
    return True

def valid_o3de_template_json(file_name: str or pathlib.Path) -> bool:
    file_name = pathlib.Path(file_name).resolve()
    if not file_name.is_file():
        return False

    #all return paths are encapsulated within scope. File path was pre-validated
    with file_name.open('r') as f:
        try:
            return valid_o3de_template_json_data(json.load(f))
        except json.JSONDecodeError:
            return False
