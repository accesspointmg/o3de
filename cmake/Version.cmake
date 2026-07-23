#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

#! o3de_get_name_and_version_specifier: Parse the dependency name, and optional version
# operator and version from the supplied input string. Supports both single and compound specifiers.
# 
# Single specifier examples: o3de==1.0.0, o3de>=1.2.3, o3de~=1.0.0
# Compound specifier examples: o3de>=1.0.0<2.0.0, o3de>=1.0.0<=2.0.0, o3de~=1.0.0<=3.0.0
# 
# \arg:input - the input string with package name and version specifier
# \arg:package - output variable for the package name (left of version specifier)
# \arg:operator - output variable for the primary version operator (==, >=, <=, >, <, ~=)
# \arg:version - output variable for the version specification (for compound specifiers, includes full range)
function(o3de_get_name_and_version_specifier input package operator version)
    # First try to match compound specifiers with upper limits
    if("${input}" MATCHES "^(.*)(~=|==|<=|>=|<|>)(.+)(<=|<)(.+)$")
        if(${CMAKE_MATCH_COUNT} GREATER_EQUAL 1)
            string(STRIP ${CMAKE_MATCH_1} _package_name)
            set(${package} ${_package_name} PARENT_SCOPE)
        endif()
        if(${CMAKE_MATCH_COUNT} GREATER_EQUAL 2)
            # For compound specifiers, return the primary operator
            set(${operator} ${CMAKE_MATCH_2} PARENT_SCOPE)
        endif()
        if(${CMAKE_MATCH_COUNT} GREATER_EQUAL 3)
            # For compound specifiers, return the full version range
            string(STRIP "${CMAKE_MATCH_3}${CMAKE_MATCH_4}${CMAKE_MATCH_5}" _version)
            set(${version} ${_version} PARENT_SCOPE)
        endif()
    elseif("${input}" MATCHES "^(.*)(~=|==|<=|>=|<|>)(.*)$")
        if(${CMAKE_MATCH_COUNT} GREATER_EQUAL 1)
            string(STRIP ${CMAKE_MATCH_1} _package_name)
            set(${package} ${_package_name} PARENT_SCOPE)
        endif()
        if(${CMAKE_MATCH_COUNT} GREATER_EQUAL 2)
            set(${operator} ${CMAKE_MATCH_2} PARENT_SCOPE)
        endif()
        if(${CMAKE_MATCH_COUNT} GREATER_EQUAL 3)
            string(STRIP ${CMAKE_MATCH_3} _version)
            set(${version} ${_version} PARENT_SCOPE)
        endif()
    else()
        # format unknown, assume it's just the dependency name
        set(${package} ${input} PARENT_SCOPE)
    endif()
endfunction()

#! o3de_get_version_compatible: Check if the input version is compatible based on
# the operator and specifier version provided. Supports all O3DE version operators
# including exact match, ranges, and compatible release semantics.
#
# Basic Examples:
#   version=1.0.0, op="==", specifier=1.0.0 -> TRUE (exact match)
#   version=1.0.0, op="==", specifier=1.0.1 -> FALSE (not exact match)
#   version=1.5.0, op=">=", specifier=1.0.0 -> TRUE (greater than or equal)
#   version=0.9.0, op=">=", specifier=1.0.0 -> FALSE (less than minimum)
#   version=1.0.0, op="<=", specifier=2.0.0 -> TRUE (less than or equal)
#   version=2.1.0, op="<=", specifier=2.0.0 -> FALSE (greater than maximum)
#   version=1.5.0, op=">", specifier=1.0.0  -> TRUE (strictly greater)
#   version=1.0.0, op=">", specifier=1.0.0  -> FALSE (not strictly greater)
#   version=0.9.0, op="<", specifier=1.0.0  -> TRUE (strictly less)
#   version=1.0.0, op="<", specifier=1.0.0  -> FALSE (not strictly less)
#
# Compatible Release (~=) Examples:
#   version=1.0.5, op="~=", specifier=1.0.0 -> TRUE (same major.minor, any patch)
#   version=1.1.0, op="~=", specifier=1.0.0 -> FALSE (different minor version)
#   version=2.0.0, op="~=", specifier=1.0.0 -> FALSE (different major version)
#   version=1.5.0, op="~=", specifier=1.5   -> TRUE (same major.minor when 2-part specifier)
#   version=1.6.0, op="~=", specifier=1.5   -> TRUE (same major when 2-part specifier: >=1.5,<2.0)
#   version=2.0.0, op="~=", specifier=1.5   -> FALSE (different major when 2-part specifier)
#
# Edge Cases:
#   version=1.0, op="~=", specifier=1 -> TRUE (single part comparison, no truncation needed)
#   version=1.0.0.0, op="~=", specifier=1.0.0 -> TRUE (handles extra version parts)
#   version=1.0.0, op="~=", specifier=1.0.0.0 -> TRUE (handles mismatched part counts)
#   version=1.0.0, op="unknown", specifier=1.0.0 -> FALSE (unrecognized operators)
#
# Compatible Release (~=) Logic:
#   ~= implements "compatible release" semantics similar to Python's ~= operator
#   ~=X.Y.Z allows >=X.Y.Z but <X.(Y+1).0 (same major.minor, any patch)
#   ~=X.Y allows >=X.Y but <(X+1).0 (same major, any minor.patch)
#   The function truncates the last component of the specifier for comparison
#
# \arg:version - input version to check  e.g. 1.0.0
# \arg:op - the version specifier operator e.g. ==, >=, <=, >, <, ~=
# \arg:specifier_version - the version part of the version specifier  e.g. 1.2.0
# \arg:is_compatible - TRUE if version is compatible otherwise FALSE 
function(o3de_get_version_compatible version op specifier_version is_compatible)
    set(contains_version FALSE)

    if(op STREQUAL "==" AND version VERSION_EQUAL specifier_version)
        set(contains_version TRUE)
    elseif(op STREQUAL "<=" AND version VERSION_LESS_EQUAL specifier_version)
        set(contains_version TRUE)
    elseif(op STREQUAL ">=" AND version VERSION_GREATER_EQUAL specifier_version)
        set(contains_version TRUE)
    elseif(op STREQUAL "<" AND version VERSION_LESS specifier_version)
        set(contains_version TRUE)
    elseif(op STREQUAL ">" AND version VERSION_GREATER specifier_version)
        set(contains_version TRUE)
    elseif(op STREQUAL "~=")
        # compatible versions have an equivalent combination of >= and == 
        # e.g. ~=2.2 is equivalent to >=2.2,==2.*
        if(version VERSION_GREATER_EQUAL specifier_version)
            string(REPLACE "." ";" specifier_version_part_list ${specifier_version})
            list(LENGTH specifier_version_part_list list_length)
            if(list_length LESS 2)
                # truncating would leave nothing to compare 
                set(contains_version TRUE)
            else()
                # trim the last version part because CMake doesn't support '*'
                math(EXPR truncated_length "${list_length} - 1")
                list(SUBLIST specifier_version_part_list 0 ${truncated_length} specifier_version)
                string(REPLACE ";" "." specifier_version "${specifier_version}")
                string(REPLACE "." ";" version_part_list ${version})
                list(SUBLIST version_part_list 0 ${truncated_length} version)
                string(REPLACE ";" "." version "${version}")

                # compare the truncated versions
                if(version VERSION_EQUAL specifier_version)
                    set(contains_version TRUE)
                endif()
            endif()
        endif()
    endif()

    set(${is_compatible} ${contains_version} PARENT_SCOPE)
endfunction()

#! o3de_versions_set_major_minor_patch: Set the major, minor and patch version
# from the input version string and store them in global properties
# \arg:major - major version part
# \arg:minor - minor version part
# \arg:patch - patch version part
# \arg:output_version - output version string in the format "major.minor.patch"
function(o3de_versions_set_major_minor_patch major minor patch output_version)
    string(JOIN "." version "${major}" "${minor}" "${patch}")
    set(${output_version} "${version}" PARENT_SCOPE)
endfunction()

#! o3de_version_get_major_minor_patch: Get the major, minor and patch from a version
# \arg:output_major - output variable for major version part
# \arg:output_minor - output variable for minor version part
# \arg:output_patch - output variable for patch version part
function(o3de_version_get_major_minor_patch version output_major output_minor output_patch)
    string(REPLACE "." ";" version_list ${version})
    list(GET version_list 0 ${output_major})
    list(GET version_list 1 ${output_minor})
    list(GET version_list 2 ${output_patch})
    set(${output_major} ${${output_major}} PARENT_SCOPE)
    set(${output_minor} ${${output_minor}} PARENT_SCOPE)
    set(${output_patch} ${${output_patch}} PARENT_SCOPE)
endfunction()

#! o3de_version_specifier_to_cmake_format: Convert O3DE version specifiers to CMake find_package format
# Supports single operators (==, >=, <=, >, <, ~=) and compound specifiers with upper limits
# Note in non EXACT cases cmake will select the highest version found that satisfies the specifier
#
# Basic Examples:
#   name==1.0.0        -> EXACT match for 1.0.0
#   name>=1.0.0        -> 1.0.0 or higher
#   name>=1.0.0<2.0.0  -> 1.0.0...1.999.999 (range from 1.0.0 to before 2.0.0)
#   name>=1.0.0<=2.0.0 -> 1.0.0...2.0.0 (range from 1.0.0 to 2.0.0 inclusive)
#   name>1.0.0<=2.0.0  -> 1.0.1...2.0.0 (range from after 1.0.0 to 2.0.0 inclusive)
#   name~=1.0.0        -> 1.0.0...1.1.0 (compatible release: >=1.0.0,<1.1.0)
#   name~=1.0.0<=3.0.0 -> 1.0.0...1.1.0 (compatible release intersected with upper limit)
#
# Edge Cases and Error Handling:
#   name<0.0.0         -> FATAL_ERROR (impossible constraint)
#   name>=2.0.0<1.0.0  -> FATAL_ERROR (invalid range: lower > upper)
#   name==1.0.0<1.0.0  -> FATAL_ERROR (exact version violates upper bound)
#   name~=1.0.0<1.0.1  -> 1.0.0...1.0.0 (compatible release with very tight upper limit)
#
# The function validates version ranges and throws FATAL_ERROR for impossible constraints
# with clear error messages explaining the problem.
#
# Compatible Release (~=) Operator:
#   ~=X.Y.Z is equivalent to >=X.Y.Z,<X.(Y+1).0 (same major.minor, any patch)
#   ~=X.Y is equivalent to >=X.Y,<(X+1).0 (same major, any minor/patch)
#   When combined with upper limits, the function computes the intersection of ranges.
#
# CMake Version Requirements:
#   - CMake 3.19+ required for version ranges (uses ... syntax)
#   - Older CMake versions fall back to single version with warnings
#
# \arg:version_with_specifier - input version specifier string
# \arg:output_name - output variable for package name
# \arg:output_version - output variable for CMake version specification
# \arg:output_cmake_args - output variable for additional CMake arguments (e.g., "EXACT")
function(o3de_version_specifier_to_cmake_format version_with_specifier output_name output_version output_cmake_args)
    # Parse the version specifier format: name==1.0.0, name>=1.2.3, name>=1.0.0<2.0.0, etc.
    # First check for compound specifiers with optional upper limit
    string(REGEX MATCH "^(.+)(==|>=|<=|>|<|~=)(.+)(<=|<)(.+)$" compound_match "${version_with_specifier}")
    
    if(compound_match)
        # Compound specifier with upper limit: name>=1.0.0<2.0.0
        set(cmake_package "${CMAKE_MATCH_1}")
        set(spec_op "${CMAKE_MATCH_2}")
        set(spec_version "${CMAKE_MATCH_3}")
        set(upper_op "${CMAKE_MATCH_4}")
        set(upper_version "${CMAKE_MATCH_5}")
        set(has_upper_limit TRUE)
    else()
        # Single specifier: name==1.0.0, name>=1.2.3, etc.
        string(REGEX MATCH "^(.+)(==|>=|<=|>|<|~=)(.+)$" match_result "${version_with_specifier}")
        
        if(match_result)
            set(cmake_package "${CMAKE_MATCH_1}")
            if(CMAKE_MATCH_2)
                set(spec_op "${CMAKE_MATCH_2}")
            else()
                set(spec_op ">=")
            endif()
            if(CMAKE_MATCH_3)
                set(spec_version "${CMAKE_MATCH_3}")
            else()
                set(spec_version "0.0.0")
            endif()
            set(has_upper_limit FALSE)
        elseif(version_with_specifier MATCHES "^[A-Za-z0-9_.\\-]+$")
            # Bare object name with no version constraint — matches any
            # version (same semantics as the Python resolver)
            set(cmake_package "${version_with_specifier}")
            set(spec_op ">=")
            set(spec_version "0.0.0")
            set(has_upper_limit FALSE)
        else()
            message(FATAL_ERROR "Invalid version specifier format: '${version_with_specifier}'. Expected format: name, name==1.0.0, name>=1.2.3, name>=1.0.0<2.0.0, etc.")
        endif()
    endif()
    
    # Helper macro to validate that lower bound <= upper bound in version ranges
    # Returns FALSE if the range is invalid (lower > upper), TRUE otherwise
    macro(validate_version_range lower_ver upper_ver is_valid_var)
        if("${lower_ver}" VERSION_GREATER "${upper_ver}")
            set(${is_valid_var} FALSE)
        else()
            set(${is_valid_var} TRUE)
        endif()
    endmacro()
    
    # Convert O3DE specifier to CMake find_package format
    if(has_upper_limit)
        # Handle compound specifiers with upper limits
        if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
            # Determine the effective upper bound
            if(upper_op STREQUAL "<")
                # Less than: decrement the version for upper bound
                string(REPLACE "." ";" upper_parts "${upper_version}")
                list(LENGTH upper_parts num_parts)
                
                if(num_parts EQUAL 3)
                    list(GET upper_parts 0 major)
                    list(GET upper_parts 1 minor)
                    list(GET upper_parts 2 patch)
                    if(patch GREATER 0)
                        math(EXPR prev_patch "${patch} - 1")
                        set(effective_upper "${major}.${minor}.${prev_patch}")
                    else()
                        # patch is 0, so decrement minor and set patch to 999
                        if(minor GREATER 0)
                            math(EXPR prev_minor "${minor} - 1")
                            set(effective_upper "${major}.${prev_minor}.999")
                        else()
                            # minor is also 0, decrement major and set minor/patch to 999
                            if(major GREATER 0)
                                math(EXPR prev_major "${major} - 1")
                                set(effective_upper "${prev_major}.999.999")
                            else()
                                # Cannot decrement anything - this means no valid versions exist
                                message(FATAL_ERROR "Version constraint '<${upper_version}' results in no valid versions. No packages can satisfy this constraint.")
                            endif()
                        endif()
                    endif()
                elseif(num_parts EQUAL 2)
                    list(GET upper_parts 0 major)
                    list(GET upper_parts 1 minor)
                    if(minor GREATER 0)
                        math(EXPR prev_minor "${minor} - 1")
                        set(effective_upper "${major}.${prev_minor}.999")
                    else()
                        # minor is 0, decrement major
                        if(major GREATER 0)
                            math(EXPR prev_major "${major} - 1")
                            set(effective_upper "${prev_major}.999")
                        else()
                            message(FATAL_ERROR "Version constraint '<${upper_version}' results in no valid versions. No packages can satisfy this constraint.")
                        endif()
                    endif()
                else()
                    set(effective_upper "${upper_version}")
                    message(WARNING "Cannot process upper bound for '<' with version '${upper_version}'. Using as-is.")
                endif()
            else()
                # Less than or equal: use as-is
                set(effective_upper "${upper_version}")
            endif()
            
            # Handle special case for ~= operator with upper limit
            if(spec_op STREQUAL "~=")
                # ~= means compatible version: >=spec_version,<next_major/minor
                string(REPLACE "." ";" version_parts "${spec_version}")
                list(LENGTH version_parts num_parts)
                
                if(num_parts EQUAL 3)
                    list(GET version_parts 0 major)
                    list(GET version_parts 1 minor)
                    math(EXPR next_minor "${minor} + 1")
                    set(compatible_upper "${major}.${next_minor}.0")
                elseif(num_parts EQUAL 2)
                    list(GET version_parts 0 major)
                    math(EXPR next_major "${major} + 1")
                    set(compatible_upper "${next_major}.0")
                else()
                    set(compatible_upper "${spec_version}")
                    message(WARNING "Cannot determine compatible version range for '~=' with version '${spec_version}'.")
                endif()
                
                # Use the minimum of the compatible upper bound and the specified upper bound
                if("${compatible_upper}" VERSION_LESS "${effective_upper}")
                    set(final_upper "${compatible_upper}")
                else()
                    set(final_upper "${effective_upper}")
                endif()
                
                # For ~= with upper limit, still use the original spec_version as lower bound
                validate_version_range("${spec_version}" "${final_upper}" is_valid)
                if(is_valid)
                    set(cmake_version "${spec_version}...${final_upper}")
                    set(cmake_args "")
                else()
                    message(FATAL_ERROR "Invalid version range: '${spec_version}...${final_upper}'. Lower bound is greater than upper bound.")
                endif()
            else()
                # Determine the effective lower bound based on primary operator
                if(spec_op STREQUAL "==")
                    # For exact match with upper limit, check if it's within the upper bound
                    validate_version_range("${spec_version}" "${effective_upper}" is_valid)
                    if(is_valid)
                        set(cmake_version "${spec_version}...${effective_upper}")
                        set(cmake_args "")
                    else()
                        message(FATAL_ERROR "Exact version '${spec_version}' violates upper bound '${upper_op}${upper_version}'. No packages can satisfy this constraint.")
                    endif()
                elseif(spec_op STREQUAL ">=")
                    # Greater than or equal with upper limit
                    validate_version_range("${spec_version}" "${effective_upper}" is_valid)
                    if(is_valid)
                        set(cmake_version "${spec_version}...${effective_upper}")
                        set(cmake_args "")
                    else()
                        message(FATAL_ERROR "Invalid version range: '>=${spec_version}' with upper bound '${upper_op}${upper_version}'. No packages can satisfy this constraint.")
                    endif()
                elseif(spec_op STREQUAL ">")
                    # Greater than: increment patch version for lower bound
                    string(REPLACE "." ";" version_parts "${spec_version}")
                    list(LENGTH version_parts num_parts)
                    
                    if(num_parts EQUAL 3)
                        list(GET version_parts 0 major)
                        list(GET version_parts 1 minor) 
                        list(GET version_parts 2 patch)
                        math(EXPR next_patch "${patch} + 1")
                        set(effective_lower "${major}.${minor}.${next_patch}")
                    elseif(num_parts EQUAL 2)
                        list(GET version_parts 0 major)
                        list(GET version_parts 1 minor)
                        set(effective_lower "${major}.${minor}.1")
                    else()
                        set(effective_lower "${spec_version}")
                        message(WARNING "Cannot increment version '${spec_version}' for '>' specifier. Using '>=' instead.")
                    endif()
                    
                    validate_version_range("${effective_lower}" "${effective_upper}" is_valid)
                    if(is_valid)
                        set(cmake_version "${effective_lower}...${effective_upper}")
                        set(cmake_args "")
                    else()
                        message(FATAL_ERROR "Invalid version range: '>${spec_version}' with upper bound '${upper_op}${upper_version}'. No packages can satisfy this constraint.")
                    endif()
                else()
                    # Other operators with upper limit 
                    validate_version_range("${spec_version}" "${effective_upper}" is_valid)
                    if(is_valid)
                        set(cmake_version "${spec_version}...${effective_upper}")
                        set(cmake_args "")
                        message(WARNING "Operator '${spec_op}' with upper limit may not behave as expected. Using range format.")
                    else()
                        message(FATAL_ERROR "Invalid version range: '${spec_op}${spec_version}' with upper bound '${upper_op}${upper_version}'. No packages can satisfy this constraint.")
                    endif()
                endif()
            endif()
        else()
            # Fallback for older CMake: ignore upper limit and warn
            set(cmake_version "${spec_version}")
            set(cmake_args "")
            message(WARNING "CMake version ${CMAKE_VERSION} does not support version ranges. Ignoring upper limit '${upper_op}${upper_version}'.")
        endif()
    elseif(spec_op STREQUAL "==")
        # Exact match: use EXACT keyword
        set(cmake_version "${spec_version}")
        set(cmake_args "EXACT")
    elseif(spec_op STREQUAL ">=")
        # Greater than or equal: default CMake behavior
        set(cmake_version "${spec_version}")
        set(cmake_args "")
    elseif(spec_op STREQUAL "<=")
        # Less than or equal: use version range from 0.0.0 to specified version
        # Note: This requires CMake 3.19+
        if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
            set(cmake_version "0.0.0...${spec_version}")
            set(cmake_args "")
        else()
            # Fallback: use exact match and warn
            set(cmake_version "${spec_version}")
            set(cmake_args "EXACT")
            message(WARNING "CMake version ${CMAKE_VERSION} does not support version ranges. Using EXACT match for '<=' specifier.")
        endif()
    elseif(spec_op STREQUAL ">")
        # Greater than: increment patch version and use >=
        # Parse version components
        string(REPLACE "." ";" version_parts "${spec_version}")
        list(LENGTH version_parts num_parts)
        
        if(num_parts EQUAL 3)
            list(GET version_parts 0 major)
            list(GET version_parts 1 minor) 
            list(GET version_parts 2 patch)
            math(EXPR next_patch "${patch} + 1")
            set(cmake_version "${major}.${minor}.${next_patch}")
            set(cmake_args "")
        elseif(num_parts EQUAL 2)
            list(GET version_parts 0 major)
            list(GET version_parts 1 minor)
            set(cmake_version "${major}.${minor}.1")
            set(cmake_args "")
        else()
            # Fallback: use original version with >= behavior
            set(cmake_version "${spec_version}")
            set(cmake_args "")
            message(WARNING "Cannot increment version '${spec_version}' for '>' specifier. Using '>=' instead.")
        endif()
    elseif(spec_op STREQUAL "<")
        # Less than: use version range from 0.0.0 to previous patch version
        if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
            # Parse version and decrement patch
            string(REPLACE "." ";" version_parts "${spec_version}")
            list(LENGTH version_parts num_parts)
            
            if(num_parts EQUAL 3)
                list(GET version_parts 0 major)
                list(GET version_parts 1 minor)
                list(GET version_parts 2 patch)
                if(patch GREATER 0)
                    math(EXPR prev_patch "${patch} - 1")
                    set(cmake_version "0.0.0...${major}.${minor}.${prev_patch}")
                else()
                    # patch is 0, decrement minor
                    if(minor GREATER 0)
                        math(EXPR prev_minor "${minor} - 1")
                        set(cmake_version "0.0.0...${major}.${prev_minor}.999")
                    else()
                        # minor is also 0, decrement major
                        if(major GREATER 0)
                            math(EXPR prev_major "${major} - 1")
                            set(cmake_version "0.0.0...${prev_major}.999.999")
                        else()
                            # Cannot decrement from 0.0.0 - no valid versions exist
                            message(FATAL_ERROR "Version constraint '<${spec_version}' results in no valid versions. No packages can satisfy this constraint.")
                        endif()
                    endif()
                endif()
            elseif(num_parts EQUAL 2)
                list(GET version_parts 0 major)
                list(GET version_parts 1 minor)
                if(minor GREATER 0)
                    math(EXPR prev_minor "${minor} - 1")
                    set(cmake_version "0.0.0...${major}.${prev_minor}.999")
                else()
                    if(major GREATER 0)
                        math(EXPR prev_major "${major} - 1")
                        set(cmake_version "0.0.0...${prev_major}.999")
                    else()
                        message(FATAL_ERROR "Version constraint '<${spec_version}' results in no valid versions. No packages can satisfy this constraint.")
                    endif()
                endif()
            else()
                set(cmake_version "0.0.0...${spec_version}")
            endif()
            set(cmake_args "")
        else()
            # Fallback for older CMake
            set(cmake_version "${spec_version}")
            set(cmake_args "EXACT")
            message(WARNING "CMake version ${CMAKE_VERSION} does not support version ranges. Using EXACT match for '<' specifier.")
        endif()
    elseif(spec_op STREQUAL "~=")
        # Compatible version: use version range within same major.minor
        if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
            string(REPLACE "." ";" version_parts "${spec_version}")
            list(LENGTH version_parts num_parts)
            
            if(num_parts EQUAL 3)
                list(GET version_parts 0 major)
                list(GET version_parts 1 minor)
                math(EXPR next_minor "${minor} + 1")
                set(cmake_version "${spec_version}...${major}.${next_minor}.0")
            elseif(num_parts EQUAL 2)
                list(GET version_parts 0 major)
                list(GET version_parts 1 minor)
                math(EXPR next_major "${major} + 1")
                set(cmake_version "${spec_version}...${next_major}.0")
            else()
                set(cmake_version "${spec_version}")
                message(WARNING "Cannot create compatible version range for '~=' with version '${spec_version}'. Using exact match.")
            endif()
            set(cmake_args "")
        else()
            # Fallback: use >= behavior
            set(cmake_version "${spec_version}")
            set(cmake_args "")
            message(WARNING "CMake version ${CMAKE_VERSION} does not support version ranges. Using '>=' for '~=' specifier.")
        endif()
    else()
        # Unknown specifier, fallback to >= behavior
        set(cmake_version "${spec_version}")
        set(cmake_args "")
        message(WARNING "Unknown version specifier '${spec_op}'. Using default '>=' behavior.")
    endif()
    
    # Return values to parent scope
    set(${output_name} "${cmake_package}" PARENT_SCOPE)
    set(${output_version} "${cmake_version}" PARENT_SCOPE)
    set(${output_cmake_args} "${cmake_args}" PARENT_SCOPE)
endfunction()
