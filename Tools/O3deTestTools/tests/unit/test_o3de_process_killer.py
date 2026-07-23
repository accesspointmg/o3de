"""
Copyright (c) Contributors to the Open 3D Engine Project.
For complete copyright and license terms please see the LICENSE at the root of this distribution.

SPDX-License-Identifier: Apache-2.0 OR MIT

Unit tests for o3de_test_tools._internal.managers.o3de_process_killer
"""

import unittest.mock as mock

import pytest

import o3de_test_tools._internal.managers.o3de_process_killer

pytestmark = pytest.mark.SUITE_smoke


class TestProcessKiller(object):

    @mock.patch('o3de_test_tools.environment.process_utils.process_exists')
    def test_DetectLumberyardProcesses_ValidProcessesList_ReturnsDetectedProcessesList(self, mock_process_exists):
        mock_process_exists.side_effect = [True, False]
        mock_process_list = ['foo', 'bar']

        under_test = o3de_test_tools._internal.managers.o3de_process_killer.detect_lumberyard_processes(
            processes_list=mock_process_list)

        assert under_test == ['foo']

    def test_KillProcesses_ProcessesListIsNotList_RaisesLyProcessKillerException(self):

        with pytest.raises(o3de_test_tools._internal.managers.o3de_process_killer.LyProcessKillerException):
            o3de_test_tools._internal.managers.o3de_process_killer.kill_processes(processes_list={})
