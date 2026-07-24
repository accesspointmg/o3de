/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */

#include <AssetBuilderSDK/AssetBuilderSDK.h>

#include <RHI.Builders/ShaderPlatformInterfaceSystemComponent.h>

#include <Atom/RHI.Edit/ShaderPlatformInterfaceBus.h>
#include <AzCore/Serialization/EditContext.h>
#include <AzCore/Serialization/SerializeContext.h>

#include <Atom/RHI.Reflect/DX12/Base.h>

namespace AZ
{
    namespace DX12
    {
        void ShaderPlatformInterfaceSystemComponent::Reflect(AZ::ReflectContext* context)
        {
            if (SerializeContext* serialize = azrtti_cast<SerializeContext*>(context))
            {
                serialize->Class<ShaderPlatformInterfaceSystemComponent, Component>()
                    ->Version(0)
                    ->Attribute(Edit::Attributes::SystemComponentTags, AZStd::vector<Crc32>({ AssetBuilderSDK::ComponentTags::AssetBuilder }))
                    ;
            }
        }

        void ShaderPlatformInterfaceSystemComponent::GetDependentServices(AZ::ComponentDescriptor::DependencyArrayType& dependent)
        {
            dependent.push_back(AZ_CRC_CE("AzslShaderBuilderService"));
        }

        void ShaderPlatformInterfaceSystemComponent::Activate()
        {
            m_shaderPlatformInterfaces.emplace_back(AZStd::make_unique<DX12::ShaderPlatformInterface>(APIUniqueIndex));

            for (auto& shaderPlatformInterface : m_shaderPlatformInterfaces)
            {
                RHI::ShaderPlatformInterfaceRegisterBus::Broadcast(
                    &RHI::ShaderPlatformInterfaceRegister::RegisterShaderPlatformHandler,
                    shaderPlatformInterface.get());
            }
        }

        void ShaderPlatformInterfaceSystemComponent::Deactivate()
        {
            for (auto& shaderPlatformInterface : m_shaderPlatformInterfaces)
            {
                RHI::ShaderPlatformInterfaceRegisterBus::Broadcast(
                    &RHI::ShaderPlatformInterfaceRegister::UnregisterShaderPlatformHandler,
                    shaderPlatformInterface.get());
                shaderPlatformInterface = nullptr;
            }
        }

    } // namespace DX12
} // namespace AZ
