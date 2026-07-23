/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */

#include <AzCore/EBus/EBus.h>
#include <AzCore/Math/MathReflection.h>
#include <AzCore/RTTI/BehaviorContext.h>
#include <AzCore/Serialization/SerializeContext.h>
#include <ScriptCanvas/Core/EBusHandler.h>
#include <ScriptCanvas/Core/SubgraphInterfaceUtility.h>
#include <ScriptCanvas/Core/Nodeable.h>
#include <ScriptCanvas/Execution/Interpreted/ExecutionInterpretedAPI.h>
#include <Source/Framework/ScriptCanvasTestFixture.h>
#include <Source/Framework/ScriptCanvasTestNodes.h>
#include <Source/Framework/ScriptCanvasTestUtilities.h>
#include <Source/ScriptCanvasTestBus.h>

using namespace ScriptCanvas;
using namespace ScriptCanvasTests;
using namespace TestNodes;
using namespace ScriptCanvas::Execution;
using namespace ScriptCanvasEditor;

class GlobalHandler : ScriptCanvasTesting::GlobalEBus::Handler
{
public:
    AZ_CLASS_ALLOCATOR(GlobalHandler, AZ::SystemAllocator);

    AZ::Event<> m_zeroParam;
    AZ::Event<AZStd::vector<AZStd::string>&> m_byReference;
    AZ::Event<int, bool, AZStd::string> m_byValue;

    GlobalHandler()
    {
        ScriptCanvasTesting::GlobalEBus::Handler::BusConnect();
    }

    AZStd::string AppendSweet(AZStd::string_view) override
    {
        AZStd::string result{};
        return result;
    }

    int Increment(int ) override
    {
        int result{};
        return result;
    }

    bool Not(bool ) override
    {
        bool result{};
        return result;
    }

    int Sum(int, int ) override
    {
        int result(0);
        return result;
    }

    void Void(AZStd::string_view) override
    {
    }

    AZ::Event<>* GetZeroParamEvent() override
    {
        return &m_zeroParam;
    }

    AZ::Event<AZStd::vector<AZStd::string>&>* GetByReferenceEvent() override
    {
        return &m_byReference;
    }

    AZ::Event<int, bool, AZStd::string>* GetByValueEvent() override
    {
        return &m_byValue;
    }
};

TEST_F(ScriptCanvasTestFixture, DISABLED_EntityIdInputForOnGraphStart)
{
    ExpectParseError("O3DE_SC_UnitTest_EntityIdInputForOnGraphStart");
}

// disabled due to lack of confirming known null on nodes that are not BC method nodes
TEST_F(ScriptCanvasTestFixture, DISABLED_ParseErrorOnKnownNull)
{
    ExpectParseError("O3DE_SC_UnitTest_ParseErrorOnKnownNull");
}

TEST_F(ScriptCanvasTestFixture, UseBehaviorContextClassConstant)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_UseBehaviorContextClassConstant");
}

TEST_F(ScriptCanvasTestFixture, ParseFunctionIfBranchWithConnectedInput)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ParseFunctionIfBranchWithConnectedInput");
}

TEST_F(ScriptCanvasTestFixture, UseRawBehaviorProperties)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_UseRawBehaviorProperties");
}

TEST_F(ScriptCanvasTestFixture, StringSanitization)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_StringSanitization");
}

TEST_F(ScriptCanvasTestFixture, InterpretedReadEnumConstant)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ReadEnumConstant");
}

TEST_F(ScriptCanvasTestFixture, UserBranchSanityCheck)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_UserBranchSanityCheck");
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlerNoDisconnect)
{
    GlobalHandler handler;
    ScriptCanvasEditor::RunSpec runSpec;
    runSpec.m_onPostSimulate = [&handler]()
    {
        AZStd::vector<AZStd::string> reference{ "one", "two", "three" };
        handler.m_byReference.Signal(reference);
        handler.m_byValue.Signal(7, true, "CCC");
        handler.m_zeroParam.Signal();
    };

    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlerNoDisconnect", runSpec);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlerDisconnect)
{
    GlobalHandler handler;
    ScriptCanvasEditor::RunSpec runSpec;
    runSpec.m_onPostSimulate = [&handler]()
    {
        AZStd::vector<AZStd::string> reference{ "one", "two", "three" };
        handler.m_byReference.Signal(reference);
        handler.m_byValue.Signal(7, true, "CCC");
        handler.m_zeroParam.Signal();
    };

    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlerDisconnect", runSpec);
}

TEST_F(ScriptCanvasTestFixture, FunctionLocalStaticsUnique)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_FunctionLocalStaticsUnique");
}

TEST_F(ScriptCanvasTestFixture, FunctionContainerInputTest)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_FunctionContainerInputTest");
}

TEST_F(ScriptCanvasTestFixture, InterpretedFixBoundMultipleResults)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_FixBoundMultipleResults");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedDetectSelfDeactivation)
{
    ExpectParseError("O3DE_SC_UnitTest_DetectSelfDeactivation");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedDetectSelfDeactivationSequence)
{
    ExpectParseError("O3DE_SC_UnitTest_DetectSelfDeactivationSequence");
}

TEST_F(ScriptCanvasTestFixture, InterpretedEraseFrontUntilEmpty)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EraseFrontUntilEmpty");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllAABBNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllAABBNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllCRC32Nodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllCRC32Nodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllColorNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllColorNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllMatrix3x3Nodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllMatrix3x3Nodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllMatrix4x4Nodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllMatrix4x4Nodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllNumberNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllNumberNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllOBBNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllOBBNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllPlaneNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllPlaneNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllQuaternionNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllQuaternionNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllRandomNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllRandomNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllTransformNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllTransformNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllTrigonometryNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllTrigonometryNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllVector2Nodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllVector2Nodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllVector3Nodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllVector3Nodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathRunAllVector4Nodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RunAllVector4Nodes");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedSelfDeactivateParseError1)
{
    ExpectParseError("O3DE_SC_UnitTest_SelfDeactivateParseError");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedSelfDeactivateParseErrorFromHandler2)
{
    ExpectParseError("O3DE_SC_UnitTest_SelfDeactivateParseErrorFromHandler");
}

TEST_F(ScriptCanvasTestFixture, InterpretedSelfDeactivateParse3)
{
    ExpectParse("O3DE_SC_UnitTest_SelfDeactivateParse");
}

TEST_F(ScriptCanvasTestFixture, InterpretedSelfDeactivateParseFromHandler4)
{
    ExpectParse("O3DE_SC_UnitTest_SelfDeactivateParseFromHandler");
}

TEST_F(ScriptCanvasTestFixture, InterpretedAddMatrix)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_AddMatrix");
}

TEST_F(ScriptCanvasTestFixture, InterpretedContainerEraseCheck)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ContainerEraseCheck");
}

TEST_F(ScriptCanvasTestFixture, InterpretedChainedInfiniteLoop)
{
    ScriptCanvasEditor::RunSpec spec;
    spec.release = false;
    spec.expectRuntimeFailure = true;
    RunUnitTestGraph("O3DE_SC_UnitTest_ChainedInfiniteLoop", spec);
}

TEST_F(ScriptCanvasTestFixture, InterpretedGetTimeAtCurrentTickRegression)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_GetTimeAtCurrentTickRegression");
}

TEST_F(ScriptCanvasTestFixture, InterpretedUnhandledEventReturnValueTypeChange)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_UnhandledEventReturnValueTypeChange");
}

TEST_F(ScriptCanvasTestFixture, InterpretedUnhandledEventReturnValueTypeChangeTuple)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_UnhandledEventReturnValueTypeChangeTuple");
}

TEST_F(ScriptCanvasTestFixture, NodeableDurationFunction)
{
    ExpectParse("O3DE_SC_UnitTest_NodeableDurationFunction");
}

TEST_F(ScriptCanvasTestFixture, LatentCallOfPureUserFunction)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_LatentCallOfPureUserFunction", ExecutionMode::Interpreted, DurationSpec::Ticks(3));
}

TEST_F(ScriptCanvasTestFixture, LatentCallOfNotPureUserFunction)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_LatentCallOfNotPureUserFunction", ExecutionMode::Interpreted, DurationSpec::Ticks(3));
}

TEST_F(ScriptCanvasTestFixture, NodeableDurationSubgraph)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableDurationSubgraph", ExecutionMode::Interpreted, DurationSpec::Ticks(3));
}
 
TEST_F(ScriptCanvasTestFixture, NodeableDurationFunctionDirectExposeOut)
{
    ExpectParse("O3DE_SC_UnitTest_NodeableDurationFunctionDirectExposeOut");
}

TEST_F(ScriptCanvasTestFixture, NodeableDurationSubgraphDirectExposedOut)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableDurationSubgraphDirectExposedOut", ExecutionMode::Interpreted, DurationSpec::Ticks(3));
}

TEST_F(ScriptCanvasTestFixture, DISABLED_ForEachNodeNoInputParseError)
{
    ExpectParseError("O3DE_SC_UnitTest_ForEachNodeNoInputParseError");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedCycleDetectError)
{
    ExpectParseError("O3DE_SC_UnitTest_CycleDetectError");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedCycleDetectSimple)
{
    ExpectParseError("O3DE_SC_UnitTest_CycleDetectSimple");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedMultipleOutDataFlowParseError)
{
    ExpectParseError("O3DE_SC_UnitTest_MultipleOutDataFlowParseError");
}

TEST_F(ScriptCanvasTestFixture, InterpretedAnyAsTailNoOp)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_AnyAsTailNoOp");
}

TEST_F(ScriptCanvasTestFixture, InterpretedConstructionVariableOrder)
{
     RunUnitTestGraph("O3DE_SC_UnitTest_ConstructionVariableOrder", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCycleDetectCleanGraph)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CycleDetectCleanGraph", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, DISABLED_ParseErrorCycleDetectErrorPastIfBranch)
{
    ExpectParseError("O3DE_SC_UnitTest_CycleDetectErrorPastIfBranch");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_ParseErrorCycleDetectErrorPastOnce)
{
    ExpectParseError("O3DE_SC_UnitTest_CycleDetectErrorPastOnce");
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedCycleDetectErrorPostLatent)
{
    ExpectParseError("O3DE_SC_UnitTest_CycleDetectErrorPostLatent");
}

TEST_F(ScriptCanvasTestFixture, InterpretedCycleDetectCleanGraphSequenceVersion)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CycleDetectCleanGraphSequenceVersion", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCycleDetectWorksWithSequence)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CycleDetectWorksWithSequence", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedAndBranch)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_AndBranch", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedAny)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Any", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCompareEqual)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompareEqual", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCompareGreater)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompareGreater", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCompareGreaterEqual)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompareGreaterEqual", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCompareLess)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompareLess", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCompareLessEqual)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompareLessEqual", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCompareNotEqual)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompareNotEqual", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedContainerBasicOperators)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ContainerBasicOperators", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCycle)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Cycle", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedCycleData)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CycleData", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedDataConversionsBooleanNumber)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_DataConversionsBooleanNumber", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedDataConversionsColor)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_DataConversionsColor", ExecutionMode::Interpreted);
}

// restore this test after conversions are restored
//
// TEST_F(ScriptCanvasTestFixture, InterpretedDataConversionsMatrix)
// {
//     RunUnitTestGraph("O3DE_SC_UnitTest_DataConversionsMatrix", ExecutionMode::Interpreted);
// }
// 
//  TEST_F(ScriptCanvasTestFixture, InterpretedDataConversionsString)
//  { 
//      RunUnitTestGraph("O3DE_SC_UnitTest_DataConversionsString", ExecutionMode::Interpreted);
//  }
// 
//  TEST_F(ScriptCanvasTestFixture, InterpretedDataConversionsTransformQuaternion)
//  {
//      RunUnitTestGraph("O3DE_SC_UnitTest_DataConversionsTransformQuaternion", ExecutionMode::Interpreted);
//  }

TEST_F(ScriptCanvasTestFixture, InterpretedDataConversionsVector)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_DataConversionsVector", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedDisabledNode)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_DisabledNode", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandling)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandling", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingAddressUpdate)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingAddressUpdate", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingAddressUpdateReference)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingAddressUpdateReference", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingDataConversion)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingDataConversion", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingDataOnly)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingDataOnly", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingDetectInfiniteLoop)
{
    ScriptCanvasEditor::RunSpec spec;
    spec.release = false;
    spec.expectRuntimeFailure = true;
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingDetectInfiniteLoop", spec);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingLocal)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingLocal", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingLocalAddressByConnection)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingLocalAddressByConnection", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingLocalVoid)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingLocalVoid", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedEventHandlingVoid)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_EventHandlingVoid", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedScriptEventGlobal)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_GlobalScriptEvent", ExecutionMode::Interpreted, "globalscriptevents");
}

TEST_F(ScriptCanvasTestFixture, InterpretedScriptEventLocal)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_LocalScriptEvent", ExecutionMode::Interpreted, "localscriptevents");
}

TEST_F(ScriptCanvasTestFixture, InterpretedScriptEventAddressUpdate)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ScriptEventAddressUpdate", ExecutionMode::Interpreted, "localscriptevents");
}

TEST_F(ScriptCanvasTestFixture, InterpretedScriptEventAddressUpdateReference)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ScriptEventAddressUpdateReference", ExecutionMode::Interpreted, "localscriptevents");
}

TEST_F(ScriptCanvasTestFixture, InterpretedScriptEventLocalAddressByConnection)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ScriptEventLocalAddressByConnection", ExecutionMode::Interpreted, "localscriptevents");
}

TEST_F(ScriptCanvasTestFixture, InterpretedExplicitOverloadDivideByNumber)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ExplicitOverloadDivideByNumber", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedExplicitOverloadLength)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ExplicitOverloadLength", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedForEachIterationArray)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ForEachIterationArray", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedForEachIterationArrayUseValueAsInputAfterBreak)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ForEachIterationArrayUseValueAsInputAfterBreak", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedForEachIterationArrayUseValueAsInputAfterBreakNested)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ForEachIterationArrayUseValueAsInputAfterBreakNested", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedForEachIterationMap)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ForEachIterationMap", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedGetElementMap)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_GetElementMap", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedIfBranch)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_IfBranch", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedIsEmptyMap)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_IsEmptyMap", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedIsNull)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_IsNull", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedLerpBetween)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_LerpBetween", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMathExpression)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MathExpression", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleOut)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleOut", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleOutDataFlow)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleOutDataFlow", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleOutInputBugFix)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleOutInputBugFix", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleOutFromIf)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleOutFromIf", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleOutFromRoot)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleOutFromRoot", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleOutSyntaxSugar)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleOutSyntaxSugar", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleReturnResults)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleReturnResults", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleReturnResultsByValue)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleReturnResultsByValue", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleReturnSameTypeResults)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleReturnSameTypeResults", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedMultipleStartNodes)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_MultipleStartNodes");
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableDuration)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableDuration", ExecutionMode::Interpreted, DurationSpec::Seconds(1.1f));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableDelay)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableDelay", ExecutionMode::Interpreted, DurationSpec::Seconds(3.1f));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableDelayWithLooping)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableDelayWithLooping", ExecutionMode::Interpreted, DurationSpec::Seconds(3.1f));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableTimer)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableTimer", ExecutionMode::Interpreted, DurationSpec::Ticks(6));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableTimeDelay)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableTimeDelay", ExecutionMode::Interpreted, DurationSpec::Ticks(6));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableHeartBeat)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableHeartBeat", ExecutionMode::Interpreted, DurationSpec::Ticks(31));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableRepeater)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableRepeater", ExecutionMode::Interpreted, DurationSpec::Ticks(11));
}

TEST_F(ScriptCanvasTestFixture, InterpretedNotBranch)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NotBranch", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOnce)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Once", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOperatorAdd)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_OperatorAdd", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOperatorDiv)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_OperatorDiv", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOperatorMul)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_OperatorMul", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOperatorSub)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_OperatorSub", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOrBranch)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_OrBranch", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedOrderedSequencer)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_OrderedSequencer", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedPerformance)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Performance", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedPrint)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Print", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedPrintConnectedInput)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PrintConnectedInput", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedPrintFormatEmptyValue)
{
    ExpectParseError("O3DE_SC_UnitTest_PrintFormatEmptyValue");
}

TEST_F(ScriptCanvasTestFixture, InterpretedProperties)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Properties", ExecutionMode::Interpreted);
}
 
TEST_F(ScriptCanvasTestFixture, InterpretedPropertiesLiteReference)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PropertiesLite", ExecutionMode::Interpreted);
}
 
TEST_F(ScriptCanvasTestFixture, InterpretedPropertiesLiteConnection)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PropertiesByConnection", ExecutionMode::Interpreted);
}
 
TEST_F(ScriptCanvasTestFixture, InterpretedPropertiesRecursion)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PropertiesRecursion", ExecutionMode::Interpreted);
}
 
TEST_F(ScriptCanvasTestFixture, InterpretedPropertiesSet)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PropertiesSet", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedRandomSignal)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_RandomSignal", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedStringFormat)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_StringFormat", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedStringFormatEmptyValue)
{
    ExpectParseError("O3DE_SC_UnitTest_StringFormatEmptyValue");
}

TEST_F(ScriptCanvasTestFixture, InterpretedStringFormatWithRepeatedValueName)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_StringFormatWithRepeatedValueName", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedSwitch)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Switch", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedVariableChangeEvent)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_VariableChangeEvent", ExecutionMode::Interpreted);
}
 
TEST_F(ScriptCanvasTestFixture, InterpretedVariableChangeEventConnectionControl)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_VariableChangeEventConnectionControl", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedVariableChangeEventWithCheck)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_VariableChangeEventWithCheck", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, DISABLED_InterpretedVariableChangeEventInfiniteLoopCheckError)
{
    ExpectParseError("O3DE_SC_UnitTest_VariableChangeEventInfiniteLoopCheckError");
}

TEST_F(ScriptCanvasTestFixture, InterpretedVariableReferences)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_VariableReferences", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedVariableReferenceChangeEventWithCheck)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_VariableReferenceChangeEventWithCheck", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedVector)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_Vector", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedWhile)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_While", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedWhileDetectInfiniteLoop)
{
    ScriptCanvasEditor::RunSpec spec;
    spec.release = false;
    spec.expectRuntimeFailure = true;
    RunUnitTestGraph("O3DE_SC_UnitTest_WhileDetectInfiniteLoop", spec);
}

TEST_F(ScriptCanvasTestFixture, InterpretedWhileBreak)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_WhileBreak", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedDivideByNumber)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_DivideByNumber");
}

// move to in-editor test, where (required) assetids are available
// TEST_F(ScriptCanvasTestFixture, InterpretedUseLocallyDefinedFunction)
// {
//     RunUnitTestGraph("O3DE_SC_UnitTest_UseLocallyDefinedFunction", ExecutionMode::Interpreted);
//}

TEST_F(ScriptCanvasTestFixture, InterpretedPathologicalFlowOfControl)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PathologicalFlowOfControl");
}

TEST_F(ScriptCanvasTestFixture, InterpretedPathologicalFlowOfControlFixSwitchLite)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PathologicalFlowOfControlFixSwitchLite");
}

TEST_F(ScriptCanvasTestFixture, InterpretedPathologicalFlowOfControlFixSwitch)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PathologicalFlowOfControlFixSwitch");
}

TEST_F(ScriptCanvasTestFixture, InterpretedInputValuePointerReferenceType)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_InputValuePointerReferenceType");
}

TEST_F(ScriptCanvasTestFixture, InterpretedReturnValuePointerReferenceType)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ReturnValuePointerReferenceType");
}

TEST_F(ScriptCanvasTestFixture, InterpretedBranchInputValuePointerReferenceType)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_BranchInputValuePointerReferenceType");
}

// \todo formal support of shared slots
// TEST_F(ScriptCanvasTestFixture, InterpretedNodeableBranchMethodSharedDataSlot)
// {
//     RunUnitTestGraph("O3DE_SC_UnitTest_NodeableBranchMethodSharedDataSlot", ExecutionMode::Interpreted);
// }

TEST_F(ScriptCanvasTestFixture, InterpretedNodeableInputMethodSharedDataSlot)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_NodeableInputMethodSharedDataSlot", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, InterpretedExecutionOutPerformance)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_ExecutionOutPerformance", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, PromotedUserVariables)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_PromotedUserVariables", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, UseClassWithDefaultOut)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_UseClassWithDefaultOut", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, GlobalMethodsCheckedOperation)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_GlobalMethodsCheckedOperation", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, GlobalMultipleReturnResults)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_GlobalMultipleReturnResults", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, GlobalMultipleReturnResultsByValue)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_GlobalMultipleReturnResultsByValue", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, StringFormatSquareBracketTranslation)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_StringFormatSquareBracketTranslation", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, AutoGenFunctions)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_AutoGenFunctions", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, CompactNodeBasicOperators)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompactNodeBasicOperators", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, CompactNodeMathematicalFunctions)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompactNodeMathematicalFunctions", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, CompactNodeTrigonometry)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompactNodeTrigonometry", ExecutionMode::Interpreted);
}

TEST_F(ScriptCanvasTestFixture, CompactNodeChain)
{
    RunUnitTestGraph("O3DE_SC_UnitTest_CompactNodeChain", ExecutionMode::Interpreted);
}
