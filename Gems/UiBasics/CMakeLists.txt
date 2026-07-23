#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_gem_setup()

# This will export its "SourcePaths" to the generated "cmake_dependencies.<project>.assetbuilder.setreg"
o3de_create_alias(NAME UiBasics.Builders NAMESPACE Gem)
o3de_create_alias(NAME UiBasics.Tools NAMESPACE Gem)
