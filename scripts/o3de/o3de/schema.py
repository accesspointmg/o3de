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
from o3de import o3de_object, utils, validation, cache, version

logger = logging.getLogger('o3de.schema')
logging.basicConfig(format=utils.LOG_FORMAT)

VERSION_IMPLICIT = "0.0.0"
VERSION_1_0_0 = "1.0.0"
VERSION_2_0_0 = "2.0.0"

# get schema version from the object json
def get_schema_version(object_data: dict):
    return SchemaVersion(object_data.get("$schemaVersion", VERSION_IMPLICIT))

class SchemaVersion:
    """Class for handling schema version comparisons using packaging.version.Version"""
    
    def __init__(self, version_str):
        from packaging.version import Version
        
        if not version_str:
            version_str = "0.0.0"
        
        # Normalize version string for schema versions
        normalized_version = self._normalize_schema_version_string(version_str)
        
        try:
            self._version = Version(normalized_version)
        except Exception:
            self._version = Version("0.0.0")
        
        # For backward compatibility, provide major, minor, patch attributes
        version_parts = str(self._version).split('.')
        try:
            self.major = int(version_parts[0])
            self.minor = int(version_parts[1]) if len(version_parts) > 1 else 0
            self.patch = int(version_parts[2]) if len(version_parts) > 2 else 0
        except ValueError:
            self.major = self.minor = self.patch = 0
    
    def _normalize_schema_version_string(self, version_str):
        """Normalize schema version string for packaging.version.Version compatibility"""
        if not version_str:
            return "0.0.0"
        
        # Handle schema-specific version formats
        parts = version_str.split('.')
        normalized_parts = []
        
        for part in parts:
            # Extract numeric part
            import re
            numeric_match = re.match(r'^(\d+)', part)
            if numeric_match:
                normalized_parts.append(numeric_match.group(1))
            else:
                normalized_parts.append('0')
        
        # Ensure at least 3 parts
        while len(normalized_parts) < 3:
            normalized_parts.append('0')
        
        return '.'.join(normalized_parts[:3])
    
    def __lt__(self, other):
        return self._version < self._get_version_object(other)
    
    def __eq__(self, other):
        return self._version == self._get_version_object(other)
    
    def __gt__(self, other):
        return self._version > self._get_version_object(other)
    
    def __le__(self, other):
        return self._version <= self._get_version_object(other)
    
    def __ge__(self, other):
        return self._version >= self._get_version_object(other)
    
    def __hash__(self):
        return hash(self._version)
    
    def _get_version_object(self, other):
        from packaging.version import Version
        
        if isinstance(other, SchemaVersion):
            return other._version
        elif isinstance(other, Version):
            return other
        elif isinstance(other, str):
            try:
                return Version(self._normalize_schema_version_string(other))
            except Exception:
                return Version("0.0.0")
        else:
            return Version("0.0.0")
    
    def __str__(self):
        return str(self._version)
    
    def __repr__(self):
        return f"SchemaVersion('{self._version}')"