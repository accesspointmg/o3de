#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
"""Tests for Schema 2.0 validation in validation.py"""

import json
import pathlib
import pytest
import tempfile

from o3de import validation


class TestIsSchema2:
    def test_detects_2_0_0(self):
        assert validation._is_schema_2({"$schemaVersion": "2.0.0"})

    def test_rejects_1_0_0(self):
        assert not validation._is_schema_2({"$schemaVersion": "1.0.0"})

    def test_rejects_missing(self):
        assert not validation._is_schema_2({"engine_name": "o3de"})


class TestValid20Header:
    def test_valid_engine(self):
        data = {"$schemaVersion": "2.0.0", "engine": {"name": "o3de", "version": "2.0.0"}}
        assert validation._valid_2_0_header(data, "engine")

    def test_valid_gem(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"name": "TestGem", "version": "1.0.0"}}
        assert validation._valid_2_0_header(data, "gem")

    def test_missing_name(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"version": "1.0.0"}}
        assert not validation._valid_2_0_header(data, "gem")

    def test_missing_version(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"name": "TestGem"}}
        assert not validation._valid_2_0_header(data, "gem")

    def test_missing_header_key(self):
        data = {"$schemaVersion": "2.0.0"}
        assert not validation._valid_2_0_header(data, "gem")

    def test_header_not_dict(self):
        data = {"$schemaVersion": "2.0.0", "gem": "not_a_dict"}
        assert not validation._valid_2_0_header(data, "gem")

    def test_empty_name(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"name": "", "version": "1.0.0"}}
        assert not validation._valid_2_0_header(data, "gem")


class TestGemValidation20:
    def test_valid_gem_data(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"name": "Atom", "version": "1.0.0"}}
        assert validation.valid_o3de_gem_json_data(data)

    def test_invalid_gem_data(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"name": "Atom"}}
        assert not validation.valid_o3de_gem_json_data(data)

    def test_legacy_gem_still_works(self):
        data = {"gem_name": "LegacyGem"}
        assert validation.valid_o3de_gem_json_data(data)

    def test_legacy_gem_missing_name(self):
        data = {"something_else": "foo"}
        assert not validation.valid_o3de_gem_json_data(data)

    def test_gem_json_file(self, tmp_path):
        gem_data = {"$schemaVersion": "2.0.0", "gem": {"name": "FileGem", "version": "2.0.0"}}
        gem_file = tmp_path / "gem.json"
        gem_file.write_text(json.dumps(gem_data))
        assert validation.valid_o3de_gem_json(gem_file)


class TestEngineValidation20:
    def test_valid_engine_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0", "engine": {"name": "o3de", "version": "2.0.0"}}
        f = tmp_path / "engine.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_engine_json(f)

    def test_invalid_engine_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0", "engine": {"name": "o3de"}}
        f = tmp_path / "engine.json"
        f.write_text(json.dumps(data))
        assert not validation.valid_o3de_engine_json(f)

    def test_legacy_engine_file(self, tmp_path):
        data = {"engine_name": "o3de"}
        f = tmp_path / "engine.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_engine_json(f)


class TestProjectValidation20:
    def test_valid_project_data(self):
        data = {"$schemaVersion": "2.0.0", "project": {"name": "MyProject", "version": "0.1.0"}}
        assert validation.valid_o3de_project_json_data(data)

    def test_invalid_project_data(self):
        data = {"$schemaVersion": "2.0.0", "project": {"version": "0.1.0"}}
        assert not validation.valid_o3de_project_json_data(data)

    def test_legacy_project_still_works(self):
        data = {"project_name": "LegacyProject"}
        assert validation.valid_o3de_project_json_data(data)

    def test_valid_project_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0", "project": {"name": "MyProject", "version": "0.1.0"}}
        f = tmp_path / "project.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_project_json(f)


class TestTemplateValidation20:
    def test_valid_template_data(self):
        data = {"$schemaVersion": "2.0.0", "template": {"name": "Default", "version": "1.0.0"}}
        assert validation.valid_o3de_template_json_data(data)

    def test_invalid_template_data(self):
        data = {"$schemaVersion": "2.0.0"}
        assert not validation.valid_o3de_template_json_data(data)

    def test_legacy_template_still_works(self):
        data = {"template_name": "LegacyTemplate"}
        assert validation.valid_o3de_template_json_data(data)


class TestRepoValidation20:
    def test_valid_repo_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0", "repo": {"name": "TestRepo", "version": "1.0.0"}}
        f = tmp_path / "repo.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_repo_json(f)

    def test_invalid_repo_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0", "repo": {"name": "TestRepo"}}
        f = tmp_path / "repo.json"
        f.write_text(json.dumps(data))
        assert not validation.valid_o3de_repo_json(f)

    def test_legacy_repo_still_works(self, tmp_path):
        data = {"repo_name": "LegacyRepo", "origin": "https://example.com"}
        f = tmp_path / "repo.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_repo_json(f)


class TestRestrictedValidation20:
    def test_valid_restricted_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0", "restricted": {"name": "TestRestricted", "version": "1.0.0"}}
        f = tmp_path / "restricted.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_restricted_json(f)

    def test_invalid_restricted_file(self, tmp_path):
        data = {"$schemaVersion": "2.0.0"}
        f = tmp_path / "restricted.json"
        f.write_text(json.dumps(data))
        assert not validation.valid_o3de_restricted_json(f)

    def test_legacy_restricted_still_works(self, tmp_path):
        data = {"restricted_name": "LegacyRestricted"}
        f = tmp_path / "restricted.json"
        f.write_text(json.dumps(data))
        assert validation.valid_o3de_restricted_json(f)


class TestGetObjectName:
    def test_legacy_engine(self):
        data = {"engine_name": "o3de"}
        assert validation.get_object_name(data, "engine") == "o3de"

    def test_20_engine(self):
        data = {"$schemaVersion": "2.0.0", "engine": {"name": "o3de", "version": "2.0.0"}}
        assert validation.get_object_name(data, "engine") == "o3de"

    def test_legacy_gem(self):
        data = {"gem_name": "Atom"}
        assert validation.get_object_name(data, "gem") == "Atom"

    def test_20_gem(self):
        data = {"$schemaVersion": "2.0.0", "gem": {"name": "Atom", "version": "1.0.0"}}
        assert validation.get_object_name(data, "gem") == "Atom"

    def test_missing_returns_empty(self):
        assert validation.get_object_name({}, "engine") == ""

    def test_20_missing_header_returns_empty(self):
        data = {"$schemaVersion": "2.0.0"}
        assert validation.get_object_name(data, "engine") == ""


class TestGetObjectVersion:
    def test_legacy_version(self):
        data = {"engine_name": "o3de", "version": "1.5.0"}
        assert validation.get_object_version(data, "engine") == "1.5.0"

    def test_20_version(self):
        data = {"$schemaVersion": "2.0.0", "engine": {"name": "o3de", "version": "2.0.0"}}
        assert validation.get_object_version(data, "engine") == "2.0.0"

    def test_legacy_missing_returns_empty(self):
        data = {"engine_name": "o3de"}
        assert validation.get_object_version(data, "engine") == ""

    def test_20_missing_header_returns_empty(self):
        data = {"$schemaVersion": "2.0.0"}
        assert validation.get_object_version(data, "engine") == ""
