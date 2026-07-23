/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */

#include <Atom/RPI.Reflect/Model/ModelAsset.h>
#include <AtomO3deIntegration/CommonFeatures/CoreLights/CoreLightsConstants.h>
#include <AtomO3deIntegration/CommonFeatures/Material/MaterialAssignment.h>
#include <AtomO3deIntegration/CommonFeatures/Material/MaterialAssignmentId.h>
#include <AtomO3deIntegration/CommonFeatures/Mesh/MeshComponentConstants.h>
#include <AzCore/Serialization/EditContext.h>
#include <AzCore/Serialization/EditContextConstants.inl>
#include <AzCore/Serialization/SerializeContext.h>
#include <CommonFeaturesSystemComponent.h>
#include <AzFramework/Translation/TranslationDef.h>

namespace AZ
{
    namespace Render
    {
        void AtomO3deIntegrationCommonFeaturesSystemComponent::Reflect(ReflectContext* context)
        {
            MaterialAssignment::Reflect(context);
            CoreLightConstantsReflect(context);

            if (SerializeContext* serialize = azrtti_cast<SerializeContext*>(context))
            {
                serialize->Class<AtomO3deIntegrationCommonFeaturesSystemComponent, Component>()
                    ->Version(0);

                if (AZ::EditContext* ec = serialize->GetEditContext())
                {
                    ec->Class<AtomO3deIntegrationCommonFeaturesSystemComponent>(QT_TRANSLATE_NOOP("AtomO3deIntegration", "Common"), QT_TRANSLATE_NOOP("AtomO3deIntegration", "[Description of functionality provided by this System Component]"))
                        ->ClassElement(Edit::ClassElements::EditorData, "")
                            ->Attribute(Edit::Attributes::AutoExpand, true)
                        ;
                }
            }
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::GetProvidedServices(ComponentDescriptor::DependencyArrayType& provided)
        {
            provided.push_back(AZ_CRC_CE("LyIntegrationCommonFeaturesService"));
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::GetIncompatibleServices(ComponentDescriptor::DependencyArrayType& incompatible)
        {
            incompatible.push_back(AZ_CRC_CE("LyIntegrationCommonFeaturesService"));
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::GetRequiredServices(ComponentDescriptor::DependencyArrayType& required)
        {
            required.push_back(AZ_CRC_CE("CommonService"));
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::GetDependentServices(ComponentDescriptor::DependencyArrayType& dependent)
        {
            AZ_UNUSED(dependent);
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::Init()
        {
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::Activate()
        {
            auto modelAssetHandler = azrtti_cast<RPI::ModelAssetHandler*>(Data::AssetManager::Instance().GetHandler(azrtti_typeid<RPI::ModelAsset>()));
            modelAssetHandler->m_componentTypeId = EditorMeshComponentTypeId;
        }

        void AtomO3deIntegrationCommonFeaturesSystemComponent::Deactivate()
        {
        }
    } // namespace Render
} // namespace AZ
