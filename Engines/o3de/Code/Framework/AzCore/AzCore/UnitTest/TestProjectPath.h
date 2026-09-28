/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */
#pragma once

#include <AzCore/IO/Path/Path.h>
#include <AzCore/IO/SystemFile.h>
#include <AzCore/Serialization/Json/JsonUtils.h>
#include <AzCore/std/string/string_view.h>

namespace UnitTest
{
    //! Locate a test project for an engine by name.
    //! A project nested in the engine is found at <engine>/<name>. Otherwise the project is looked up in the
    //! engine's engine.json "projects" list, whose paths are relative to the engine root and may point outside it
    //! (e.g. ../../Projects/<name> when projects sit beside the engine). Falls back to <engine>/<name>.
    inline AZ::IO::FixedMaxPath GetTestProjectPath(AZ::IO::PathView enginePath, AZStd::string_view projectName)
    {
        const AZ::IO::FixedMaxPath engineRoot{ enginePath };
        const AZ::IO::FixedMaxPath nested = engineRoot / projectName;
        if (AZ::IO::SystemFile::Exists((nested / "project.json").c_str()))
        {
            return nested;
        }

        if (auto engineJson = AZ::JsonSerializationUtils::ReadJsonFile((engineRoot / "engine.json").Native());
            engineJson.IsSuccess())
        {
            const rapidjson::Document& document = engineJson.GetValue();
            if (auto projects = document.FindMember("projects"); projects != document.MemberEnd() && projects->value.IsArray())
            {
                for (const auto& entry : projects->value.GetArray())
                {
                    if (!entry.IsString())
                    {
                        continue;
                    }
                    const AZ::IO::FixedMaxPath candidate = (engineRoot / entry.GetString()).LexicallyNormal();
                    if (candidate.Filename() == AZ::IO::PathView(projectName) &&
                        AZ::IO::SystemFile::Exists((candidate / "project.json").c_str()))
                    {
                        return candidate;
                    }
                }
            }
        }
        return nested;
    }
} // namespace UnitTest
