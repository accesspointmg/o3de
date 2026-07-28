"""
Copyright (c) Contributors to the Open 3D Engine Project.
For complete copyright and license terms please see the LICENSE at the root of this distribution.

SPDX-License-Identifier: Apache-2.0 OR MIT

Unit tests for o3de_test_tools.builtin.helpers functions.
"""
import unittest.mock as mock
import os
import pytest

import o3de_test_tools.builtin.helpers
import o3de_test_tools._internal.managers.abstract_resource_locator
import o3de_test_tools._internal.managers.workspace
import o3de_test_tools._internal.managers.platforms.mac
import o3de_test_tools._internal.managers.platforms.windows

from o3de_test_tools._internal.exceptions import O3deTestToolsFrameworkException
from o3de_test_tools import MAC, WINDOWS

pytestmark = pytest.mark.SUITE_smoke


class MockedAbstractResourceLocator(o3de_test_tools._internal.managers.abstract_resource_locator.AbstractResourceLocator):
    def __init__(self, build_directory, project):
        super(MockedAbstractResourceLocator, self).__init__(
            build_directory=build_directory,
            project=project,
        )


class MockedWorkspaceManager(o3de_test_tools._internal.managers.workspace.AbstractWorkspaceManager):
    def __init__(
            self, resource_locator, project, tmp_path, output_path
    ):
        super(MockedWorkspaceManager, self).__init__(
            resource_locator=resource_locator,
            project=project,
            tmp_path=tmp_path,
            output_path=output_path
        )


@mock.patch('o3de_test_tools._internal.managers.abstract_resource_locator._find_project_json',
            mock.MagicMock(return_value=os.path.join("mocked", "path")))
@mock.patch(
    'o3de_test_tools._internal.managers.abstract_resource_locator.AbstractResourceLocator',
    mock.MagicMock(return_value=MockedAbstractResourceLocator)
)
@mock.patch('os.remove', mock.MagicMock(return_value=True))
class TestBuiltinHelpers(object):

    @mock.patch('o3de_test_tools._internal.managers.workspace.AbstractWorkspaceManager',
                mock.MagicMock(return_value=MockedWorkspaceManager))
    @mock.patch('o3de_test_tools.builtin.helpers.WINDOWS', True)
    @mock.patch('os.path.exists', mock.MagicMock(return_value=True))
    def test_CreateBuiltinWorkspace_WindowsOS_ReturnsWindowsWorkspaceManager(self):
        expected_workspace = o3de_test_tools._internal.managers.platforms.windows.WindowsWorkspaceManager

        under_test = o3de_test_tools.builtin.helpers.create_builtin_workspace(
            build_directory='build_directory',
            project='mock_project',
            tmp_path='mock_tmp_path',
            output_path='mock_output_path',
        )

        assert type(under_test) == expected_workspace

    @mock.patch('o3de_test_tools._internal.managers.abstract_resource_locator._find_project_json',
                mock.MagicMock(return_value='mock_project'))
    @mock.patch('o3de_test_tools._internal.managers.workspace.AbstractWorkspaceManager',
                mock.MagicMock(return_value=MockedWorkspaceManager))
    @mock.patch('o3de_test_tools.builtin.helpers.MAC', True)
    @mock.patch('o3de_test_tools.builtin.helpers.WINDOWS', False)
    def test_CreateBuiltinWorkspace_MacOS_ReturnsMacWorkspaceManager(self):
        expected_workspace = o3de_test_tools._internal.managers.platforms.mac.MacWorkspaceManager

        under_test = o3de_test_tools.builtin.helpers.create_builtin_workspace(
            build_directory='build_directory',
            project='mock_project',
            tmp_path='mock_tmp_path',
            output_path='mock_output_path',
        )

        assert type(under_test) == expected_workspace

    @mock.patch('o3de_test_tools._internal.managers.workspace.AbstractWorkspaceManager',
                mock.MagicMock(return_value=MockedWorkspaceManager))
    @mock.patch('o3de_test_tools._internal.pytest_plugin.build_directory', None)
    def test_CreateBuiltinWorkspace_InvalidPlatform_RaisesValueError(self):
        with pytest.raises(ValueError):
            o3de_test_tools.builtin.helpers.create_builtin_workspace(
                build_directory=None,
                project='mock_project',
                tmp_path='mock_tmp_path',
                output_path='mock_output_path',
            )

    @mock.patch('os.path.abspath', mock.MagicMock(return_value='mock_base_dir'))
    @mock.patch('os.path.exists', mock.MagicMock(return_value=True))
    def test_FindEngineRoot_HasRootFile_ReturnsTuple(self):
        under_test = o3de_test_tools._internal.managers.abstract_resource_locator._find_engine_root(
            initial_path='mock_dev_dir')

        assert under_test == ('mock_dev_dir')

    @mock.patch('os.path.abspath', mock.MagicMock(return_value='mock_base_dir'))
    @mock.patch('os.path.exists', mock.MagicMock(return_value=False))
    def test_FindEngineRoot_NoRootFile_RaisesOSError(self):
        with pytest.raises(O3deTestToolsFrameworkException):
            o3de_test_tools._internal.managers.abstract_resource_locator._find_engine_root(
                initial_path='mock_dev_dir')

    @mock.patch('o3de_test_tools._internal.managers.workspace.AbstractWorkspaceManager.teardown')
    @mock.patch('o3de_test_tools._internal.managers.workspace.AbstractWorkspaceManager.setup')
    @mock.patch('o3de_test_tools._internal.managers.artifact_manager.NullArtifactManager', mock.MagicMock())
    @mock.patch('os.path.exists', mock.MagicMock(return_value=True))
    def test_SetupTeardownBuiltinWorkspace_ValidWorkspaceSetup_ReturnsWorkspaceObject(self, mock_setup, mock_teardown):
        mock_test_name = 'mock_test_name'
        mock_test_amount = 10
        mock_workspace = o3de_test_tools.builtin.helpers.create_builtin_workspace(
            build_directory='build_directory',
            project='mock_project',
            tmp_path='mock_tmp_path',
            output_path='mock_output_path',
        )

        setup_test = o3de_test_tools.builtin.helpers.setup_builtin_workspace(
            mock_workspace, mock_test_name, mock_test_amount)

        assert setup_test == mock_workspace
        assert mock_setup.call_count == 1
        mock_workspace.artifact_manager.set_dest_path.assert_called_with(
            test_name=mock_test_name, amount=mock_test_amount)

        # Teardown not tested separately due to patched MockedAbstractResourceLocator creating a StopIteration error on Linux
        teardown_test = o3de_test_tools.builtin.helpers.teardown_builtin_workspace(mock_workspace)

        assert teardown_test == mock_workspace
        assert mock_teardown.call_count == 1
