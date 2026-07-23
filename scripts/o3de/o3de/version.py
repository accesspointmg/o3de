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

logger = logging.getLogger('o3de.version')
logging.basicConfig(format='[%(levelname)s] %(name)s: %(message)s')

class O3deNameVersion:
    """Class for handling O3DE object names and versions with flexible specifier support
    
    This class can handle any number of version specifiers including:
    ==, >=, >, <=, <, ~=, !=
    
    Examples:
    - "org.o3de.gem.mygem>=1.0.0"
    - "org.o3de.gem.mygem>=1.0.0,<2.0.0,!=1.5.0" (comma-separated)
    - "org.o3de.gem.mygem>=1.0.0<2.0.0!=1.5.0" (comma-free)
    - "org.o3de.gem.mygem~=1.4.0"
    """
    
    def __init__(self, name='', specifier_string=''):
        """
        Initialize O3deNameVersion with name and version specifiers
        
        :param name: The package name (e.g., "org.o3de.gem.mygem")
        :param specifier_string: Version specifier string (e.g., ">=1.0.0,<2.0.0,!=1.5.0")
        """
        from packaging.specifiers import SpecifierSet
        
        self.name = name
        self.specifier_set = SpecifierSet(specifier_string) if specifier_string else SpecifierSet("")
    
    @classmethod
    def from_string(cls, input_str):
        """Parse a version string into an O3deNameVersion object
        
        Supports formats like:
        - "org.o3de.gem.mygem" (no version constraint)
        - "org.o3de.gem.mygem>=1.0.0" (single constraint)
        - "org.o3de.gem.mygem>=1.0.0,<2.0.0,!=1.5.0" (comma-separated constraints)
        - "org.o3de.gem.mygem>=1.0.0<2.0.0!=1.5.0" (comma-free constraints)
        """
        import re
        
        if not input_str:
            return cls()
        
        input_str = input_str.strip()
        
        # Updated pattern to capture name and all version specifiers
        # Matches package names and captures everything after as version specifiers
        pattern = r'^([a-zA-Z][a-zA-Z0-9._-]*(?:\.[a-zA-Z][a-zA-Z0-9._-]*)*)(.*)$'
        
        match = re.match(pattern, input_str)
        if not match:
            logger.warning(f"Invalid format for O3deNameVersion: {input_str}")
            return cls()
        
        name = match.group(1).strip()
        specifier_part = match.group(2).strip()
        
        # Handle comma-free format by adding commas between operators
        if specifier_part and ',' not in specifier_part and len(specifier_part) > 0:
            # Use regex to find all version operators and insert commas between them
            # This regex finds patterns like ">=1.0.0<2.0.0!=1.5.0" and converts to ">=1.0.0,<2.0.0,!=1.5.0"
            specifier_part = re.sub(r'([0-9]+(?:\.[0-9]+)*(?:\.[a-zA-Z][a-zA-Z0-9]*)*(?:\+[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+)*)?)\s*(?=[><=!~])', r'\1,', specifier_part)
        
        return cls(name, specifier_part)
    
    def add_specifier(self, operator, version):
        """Add a new version specifier to this object
        
        :param operator: Version operator (==, >=, >, <=, <, ~=, !=)
        :param version: Version string or packaging.version.Version
        """
        from packaging.specifiers import SpecifierSet
        
        # Create new specifier string
        new_spec = f"{operator}{version}"
        
        # Combine with existing specifiers
        if str(self.specifier_set):
            combined_spec = f"{self.specifier_set},{new_spec}"
        else:
            combined_spec = new_spec
        
        # Update the specifier set
        self.specifier_set = SpecifierSet(combined_spec)

    def compatible_with(self, arg, version=None):
        """Check if this O3deNameVersion is compatible with another version specification"""
        if isinstance(arg, str) and version is None:
            # Handle string input like "org.o3de.gem.core>=1.0.0"
            return self._compatible_with_string(arg)
        elif isinstance(arg, O3deNameVersion):
            # Handle O3deNameVersion object
            return self._compatible_with_object(arg)
        elif isinstance(arg, str) and version is not None:
            # Handle separate name and version
            return self._compatible_with_name_version(arg, version)
        else:
            return False

    def _compatible_with_string(self, nameVersionString: str):
        """Check if this O3deNameVersion is compatible with a name version string"""
        if not nameVersionString:
            return False
        
        # Parse the input string
        other_version = O3deNameVersion.from_string(nameVersionString)
        if not other_version or not other_version.name:
            return False
        
        # If it's just a name with no version constraints, extract version from our own constraints
        # This is a simplified compatibility check for backward compatibility
        if not other_version.specifier_set:
            # If the other has no constraints, just check if names match
            return self.name == other_version.name
        
        # For now, assume compatibility means the names match
        # TODO: In the future, this could do more sophisticated constraint intersection
        return self.name == other_version.name

    def _compatible_with_object(self, other_version):
        """Check if this O3deNameVersion is compatible with another O3deNameVersion"""
        if not isinstance(other_version, O3deNameVersion):
            return False

        # For now, assume compatibility means the names match
        # TODO: In the future, this could do constraint intersection
        return self.name == other_version.name

    def _compatible_with_name_version(self, name, version):
        """Check if this O3deNameVersion is compatible with the given name and version
        
        Uses the internal SpecifierSet for comprehensive version constraint checking
        """
        from packaging.version import Version
        
        if self.name != name:
            return False
        
        # If no specifiers, any version is compatible
        if not self.specifier_set:
            return True
        
        # Convert version to packaging.version.Version if needed
        if isinstance(version, str):
            try:
                version = Version(version) if version else Version("0.0.0")
            except Exception:
                version = Version("0.0.0")
        elif not isinstance(version, Version):
            try:
                version = Version(str(version))
            except Exception:
                version = Version("0.0.0")
        
        # Use SpecifierSet to check all constraints at once
        try:
            return version in self.specifier_set
        except Exception as e:
            logger.warning(f"Version constraint check failed for {name} {version}: {e}")
            return False
    
    def get_specifier_set(self) -> tuple:
        """Convert this O3deNameVersion to a tuple of (name, SpecifierSet)
        
        Returns:
            tuple: (package_name, SpecifierSet) where SpecifierSet contains the version constraints
        """
        if not self.name:
            return "", self.specifier_set
        
        return self.name, self.specifier_set
