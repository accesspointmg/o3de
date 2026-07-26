#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

#! o3de_add_autogen: adds a code generation step to the specified target.
#
# \arg:NAME name of the target
# \arg:OUTPUT_NAME (optional) overrides the name of the output target. If not specified, the name will be used.
# \arg:INCLUDE_DIRECTORIES list of directories to use as include paths
# \arg:AUTOGEN_RULES a set of AutoGeneration rules to be passed to the AzAutoGen expansion system
# \arg:ALLFILES list of all source files contained by the target
function(o3de_add_autogen)

    set(options)
    set(oneValueArgs NAME)
    set(multiValueArgs INCLUDE_DIRECTORIES AUTOGEN_RULES ALLFILES)
    cmake_parse_arguments(o3de_add_autogen "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(o3de_add_autogen_AUTOGEN_RULES)
        set(AZCG_INPUTFILES ${o3de_add_autogen_ALLFILES})
        list(FILTER AZCG_INPUTFILES INCLUDE REGEX ".*\.(xml|json|jinja)$")
        # Writes AzAutoGen input files into tmp ${o3de_add_autogen_NAME}_input_files.txt file to avoid long command error
        set(input_files_path "${CMAKE_CURRENT_BINARY_DIR}/Azcg/Temp/${o3de_add_autogen_NAME}_input_files.txt")
        file(CONFIGURE OUTPUT "${input_files_path}" CONTENT [[@AZCG_INPUTFILES@]] @ONLY)
        get_target_property(target_type ${o3de_add_autogen_NAME} TYPE)
        if (target_type STREQUAL INTERFACE_LIBRARY)
            target_include_directories(${o3de_add_autogen_NAME} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/Azcg/Generated/${o3de_add_autogen_NAME}")
        else()
            target_include_directories(${o3de_add_autogen_NAME} PUBLIC "${CMAKE_CURRENT_BINARY_DIR}/Azcg/Generated/${o3de_add_autogen_NAME}")
        endif()
        execute_process(
            COMMAND ${O3DE_PYTHON_CMD} "${O3DE_ENGINE_PATH}/cmake/AzAutoGen.py" "${o3de_add_autogen_NAME}" "${CMAKE_BINARY_DIR}/Azcg/TemplateCache/" "${CMAKE_CURRENT_BINARY_DIR}/Azcg/Generated/${o3de_add_autogen_NAME}/" "${CMAKE_CURRENT_SOURCE_DIR}" "${input_files_path}" "${o3de_add_autogen_AUTOGEN_RULES}" "-n"
            OUTPUT_VARIABLE AUTOGEN_OUTPUTS
        )
        string(STRIP "${AUTOGEN_OUTPUTS}" AUTOGEN_OUTPUTS)
        set(AZCG_DEPENDENCIES ${AZCG_INPUTFILES})
        list(APPEND AZCG_DEPENDENCIES "${O3DE_ENGINE_PATH}/cmake/AzAutoGen.py")
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${AZCG_DEPENDENCIES})
        add_custom_command(
            OUTPUT ${AUTOGEN_OUTPUTS}
            DEPENDS ${AZCG_DEPENDENCIES}
            COMMAND ${O3DE_PYTHON_CMD} "${O3DE_ENGINE_PATH}/cmake/AzAutoGen.py" "--prune" "${o3de_add_autogen_NAME}" "${CMAKE_BINARY_DIR}/Azcg/TemplateCache/" "${CMAKE_CURRENT_BINARY_DIR}/Azcg/Generated/${o3de_add_autogen_NAME}/" "${CMAKE_CURRENT_SOURCE_DIR}" "${input_files_path}" "${o3de_add_autogen_AUTOGEN_RULES}"
            COMMENT "Running AutoGen for ${o3de_add_autogen_NAME}"
            VERBATIM
        )
        set_target_properties(${o3de_add_autogen_NAME} PROPERTIES AUTOGEN_INPUT_FILES "${AZCG_INPUTFILES}")
        set_target_properties(${o3de_add_autogen_NAME} PROPERTIES AUTOGEN_OUTPUT_FILES "${AUTOGEN_OUTPUTS}")
        target_sources(${o3de_add_autogen_NAME} PRIVATE ${AUTOGEN_OUTPUTS})
    endif()

endfunction()
