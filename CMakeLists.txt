# == DO NOT EDIT THE FOLLOWING LINES for the Raspberry Pi Pico VS Code Extension to work ==
if(WIN32)
    set(USERHOME $ENV{USERPROFILE})
else()
    set(USERHOME $ENV{HOME})
endif()
set(sdkVersion 2.2.0)
set(toolchainVersion 14_2_Rel1)
set(picotoolVersion 2.2.0-a4)
set(picoVscode ${USERHOME}/.pico-sdk/cmake/pico-vscode.cmake)
if (EXISTS ${picoVscode})
    include(${picoVscode})
endif()
# ====================================================================================
set(PICO_BOARD pico CACHE STRING "Board type")
# The application occupies the low part of a 16 MiB device. The upper 8 MiB
# contains four fixed 2 MiB FPGA image slots.
set(PICO_FLASH_SIZE_BYTES 16777216 CACHE STRING "Physical flash size")

# Generated Cmake Pico project file

cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initalize pico_sdk from installed location
# (note this can come from environment, CMake cache etc)
#set(PICO_SDK_PATH "/home/carlk/pi/pico/pico-sdk")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(fpga_mgr VERSION 1.13 LANGUAGES C CXX ASM)

if(PROJECT_VERSION_MAJOR GREATER 255 OR PROJECT_VERSION_MINOR GREATER 255)
    message(FATAL_ERROR "Supervisor protocol version components must fit in one byte")
endif()
configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/fpga_manager_version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/fpga_manager_version.h
    @ONLY
)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

# Golden images are linked into each board-specific manager below the mutable
# 8 MiB slot bank. FPGA bitstreams are not interchangeable between RevB0C and
# RevB3B, so one CMake build always emits both explicitly named variants.
set(K2_BOARD_REVISIONS B0C B3B)

set(GOLDEN_B0C_CONTEXT1_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/B0C/context1.gz)
set(GOLDEN_B0C_CONTEXT3_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/B0C/context3.gz)
set(GOLDEN_B0C_CONTEXT4_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/B0C/context4.gz)
set(GOLDEN_B3B_CONTEXT1_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/B3B/context1.gz)
# There is not yet a RevB3B build of the 6809 core. Use the known-good RevB3B
# context-1 image as context-3 recovery rather than embedding a B0C bitstream.
set(GOLDEN_B3B_CONTEXT3_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/B3B/context1.gz)
set(GOLDEN_B3B_CONTEXT4_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/B3B/context4.gz)

set(GOLDEN_B0C_CONTEXT1_DEFAULT_LABEL "CFP95600C_B0C.bin.gz")
set(GOLDEN_B0C_CONTEXT3_DEFAULT_LABEL
    "Wildbits_k2_6809_int_wizfi_turbo_v5_B0C_20260827.bin.gz")
set(GOLDEN_B0C_CONTEXT4_DEFAULT_LABEL
    "WildbitsK2_2x_B0C_02020103_20260827.bin.gz")
set(GOLDEN_B3B_CONTEXT1_DEFAULT_LABEL "CFP95600C_B3B.bin.gz")
set(GOLDEN_B3B_CONTEXT3_DEFAULT_LABEL
    "CFP95600C_B3B.bin.gz (context 3 recovery fallback)")
set(GOLDEN_B3B_CONTEXT4_DEFAULT_LABEL
    "WildbitsK2_2x_B3B_02020103_20260827.bin.gz")

set(GOLDEN_B0C_CONTEXT1_SOURCE_CONTEXT 1)
set(GOLDEN_B0C_CONTEXT3_SOURCE_CONTEXT 3)
set(GOLDEN_B0C_CONTEXT4_SOURCE_CONTEXT 4)
set(GOLDEN_B3B_CONTEXT1_SOURCE_CONTEXT 1)
set(GOLDEN_B3B_CONTEXT3_SOURCE_CONTEXT 1)
set(GOLDEN_B3B_CONTEXT4_SOURCE_CONTEXT 4)

foreach(K2_BOARD_REVISION IN LISTS K2_BOARD_REVISIONS)
    set(GOLDEN_FPGA_TOTAL_SIZE 0)
    set(GOLDEN_IMAGE_DEPENDENCIES "")
    foreach(GOLDEN_CONTEXT IN ITEMS 1 3 4)
        set(GOLDEN_IMAGE_VARIABLE
            "GOLDEN_${K2_BOARD_REVISION}_CONTEXT${GOLDEN_CONTEXT}")
        set(GOLDEN_DEFAULT_VARIABLE "${GOLDEN_IMAGE_VARIABLE}_DEFAULT")
        set(GOLDEN_LABEL_VARIABLE "${GOLDEN_IMAGE_VARIABLE}_LABEL")
        set(GOLDEN_DEFAULT_LABEL_VARIABLE
            "${GOLDEN_IMAGE_VARIABLE}_DEFAULT_LABEL")

        set(${GOLDEN_IMAGE_VARIABLE} "${${GOLDEN_DEFAULT_VARIABLE}}"
            CACHE FILEPATH
            "Rev${K2_BOARD_REVISION} golden context ${GOLDEN_CONTEXT} gzip image")
        set(${GOLDEN_LABEL_VARIABLE} "" CACHE STRING
            "Rev${K2_BOARD_REVISION} golden context ${GOLDEN_CONTEXT} display name")

        if(NOT EXISTS "${${GOLDEN_IMAGE_VARIABLE}}")
            message(FATAL_ERROR
                "Missing Rev${K2_BOARD_REVISION} recovery image: ${${GOLDEN_IMAGE_VARIABLE}}")
        endif()
        file(TO_CMAKE_PATH "${${GOLDEN_IMAGE_VARIABLE}}" GOLDEN_IMAGE_PATH)
        set(GOLDEN_CONTEXT${GOLDEN_CONTEXT} "${GOLDEN_IMAGE_PATH}")
        list(APPEND GOLDEN_IMAGE_DEPENDENCIES "${GOLDEN_IMAGE_PATH}")

        if("${${GOLDEN_LABEL_VARIABLE}}" STREQUAL "")
            if("${${GOLDEN_IMAGE_VARIABLE}}" STREQUAL
               "${${GOLDEN_DEFAULT_VARIABLE}}")
                set(GOLDEN_EMBEDDED_LABEL
                    "${${GOLDEN_DEFAULT_LABEL_VARIABLE}}")
            else()
                get_filename_component(GOLDEN_EMBEDDED_LABEL
                    "${${GOLDEN_IMAGE_VARIABLE}}" NAME)
            endif()
        else()
            set(GOLDEN_EMBEDDED_LABEL "${${GOLDEN_LABEL_VARIABLE}}")
        endif()
        string(LENGTH "${GOLDEN_EMBEDDED_LABEL}" GOLDEN_CONTEXT_LABEL_LENGTH)
        if(GOLDEN_CONTEXT_LABEL_LENGTH GREATER 191)
            message(FATAL_ERROR
                "Rev${K2_BOARD_REVISION} golden context ${GOLDEN_CONTEXT} display name exceeds 191 characters")
        endif()
        if(GOLDEN_EMBEDDED_LABEL MATCHES "[\r\n]")
            message(FATAL_ERROR
                "Rev${K2_BOARD_REVISION} golden context ${GOLDEN_CONTEXT} display name contains a newline")
        endif()
        string(REPLACE "\\" "\\\\" GOLDEN_EMBEDDED_LABEL
               "${GOLDEN_EMBEDDED_LABEL}")
        string(REPLACE "\"" "\\\"" GOLDEN_EMBEDDED_LABEL
               "${GOLDEN_EMBEDDED_LABEL}")
        set(GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL
            "${GOLDEN_EMBEDDED_LABEL}")

        file(SIZE "${GOLDEN_IMAGE_PATH}" GOLDEN_IMAGE_SIZE)
        math(EXPR GOLDEN_FPGA_TOTAL_SIZE
             "${GOLDEN_FPGA_TOTAL_SIZE} + ${GOLDEN_IMAGE_SIZE}")
    endforeach()

    if(GOLDEN_FPGA_TOTAL_SIZE GREATER 6291456)
        message(FATAL_ERROR
            "Rev${K2_BOARD_REVISION} golden images total ${GOLDEN_FPGA_TOTAL_SIZE} bytes; maximum is 6 MiB")
    endif()

    set(GOLDEN_ASSEMBLY
        ${CMAKE_CURRENT_BINARY_DIR}/golden_images_${K2_BOARD_REVISION}.S)
    configure_file(golden_images.S.in ${GOLDEN_ASSEMBLY} @ONLY)
    set_property(SOURCE ${GOLDEN_ASSEMBLY} APPEND PROPERTY
        OBJECT_DEPENDS "${GOLDEN_IMAGE_DEPENDENCIES}")
    set(GOLDEN_ASSEMBLY_${K2_BOARD_REVISION} ${GOLDEN_ASSEMBLY})
endforeach()

add_subdirectory(FatFs_SPI build)

# Disable select warnings on third-party code
get_target_property(FATFS_SPI_SOURCES FatFs_SPI INTERFACE_SOURCES)
set_property(
    SOURCE ${FATFS_SPI_SOURCES}
    APPEND PROPERTY COMPILE_OPTIONS
        -Wno-unused-variable
)

set_property(
    SOURCE miniz.c
    APPEND PROPERTY COMPILE_OPTIONS
        -Wno-type-limits
)

option(FPGA_MGR_UART_DEBUG "Mirror manager stdio to the K2 FTDI UART" OFF)

set(FPGA_MGR_SOURCES
    boot_config.cpp
    boot_log.cpp
    fpga_mgr.cpp
    golden_images.cpp
    hw_config.c
    miniz.c
    miniz_tinfl.c
    miniz_tdef.c
    supervisor_service.cpp
)

function(add_fpga_manager_variant K2_BOARD_REVISION)
    set(FPGA_MGR_TARGET fpga_mgr_${K2_BOARD_REVISION})
    add_executable(${FPGA_MGR_TARGET}
        ${FPGA_MGR_SOURCES}
        ${GOLDEN_ASSEMBLY_${K2_BOARD_REVISION}}
    )

    target_compile_options(${FPGA_MGR_TARGET} PRIVATE
        -Wall
        -Wextra
        -Wformat=2
        -Werror=format
        -Wno-unused-function
    )
    target_compile_definitions(${FPGA_MGR_TARGET} PRIVATE
        K2_BOARD_REVISION="${K2_BOARD_REVISION}"
        GOLDEN_CONTEXT1_SOURCE_CONTEXT=${GOLDEN_${K2_BOARD_REVISION}_CONTEXT1_SOURCE_CONTEXT}
        GOLDEN_CONTEXT3_SOURCE_CONTEXT=${GOLDEN_${K2_BOARD_REVISION}_CONTEXT3_SOURCE_CONTEXT}
        GOLDEN_CONTEXT4_SOURCE_CONTEXT=${GOLDEN_${K2_BOARD_REVISION}_CONTEXT4_SOURCE_CONTEXT}
    )

    set(PIO_HEADER_DIR
        ${CMAKE_CURRENT_BINARY_DIR}/generated/${FPGA_MGR_TARGET})
    pico_generate_pio_header(${FPGA_MGR_TARGET}
        ${CMAKE_CURRENT_LIST_DIR}/fpga_out.pio
        OUTPUT_DIR ${PIO_HEADER_DIR})
    pico_generate_pio_header(${FPGA_MGR_TARGET}
        ${CMAKE_CURRENT_LIST_DIR}/supervisor_spi.pio
        OUTPUT_DIR ${PIO_HEADER_DIR})

    target_link_libraries(${FPGA_MGR_TARGET}
        pico_stdlib
        hardware_dma
        hardware_pio
        hardware_adc
        hardware_flash
        hardware_watchdog
        FatFs_SPI
    )

    pico_set_program_name(${FPGA_MGR_TARGET} "${FPGA_MGR_TARGET}")
    pico_set_program_version(${FPGA_MGR_TARGET} "${PROJECT_VERSION}")

    if(FPGA_MGR_UART_DEBUG)
        target_compile_definitions(${FPGA_MGR_TARGET} PRIVATE
            PICO_DEFAULT_UART=1
            PICO_DEFAULT_UART_TX_PIN=24
            PICO_DEFAULT_UART_RX_PIN=25
            PICO_DEFAULT_UART_BAUD_RATE=115200
        )
        pico_enable_stdio_uart(${FPGA_MGR_TARGET} 1)
    else()
        pico_enable_stdio_uart(${FPGA_MGR_TARGET} 0)
    endif()
    pico_enable_stdio_usb(${FPGA_MGR_TARGET} 1)
    pico_add_extra_outputs(${FPGA_MGR_TARGET})

    target_include_directories(${FPGA_MGR_TARGET} PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
        ${PIO_HEADER_DIR}
    )
endfunction()

foreach(K2_BOARD_REVISION IN LISTS K2_BOARD_REVISIONS)
    add_fpga_manager_variant(${K2_BOARD_REVISION})
endforeach()

add_custom_target(fpga_mgr DEPENDS fpga_mgr_B0C fpga_mgr_B3B)

find_package(Python3 COMPONENTS Interpreter)

set(_PICO_VSCODE_PICOTOOL ${USERHOME}/.pico-sdk/picotool/${picotoolVersion}/picotool/picotool)
if (EXISTS ${_PICO_VSCODE_PICOTOOL})
    set(PICOTOOL_EXECUTABLE ${_PICO_VSCODE_PICOTOOL})
else()
    unset(PICOTOOL_EXECUTABLE CACHE)
    unset(PICOTOOL_EXECUTABLE)
    find_program(PICOTOOL_EXECUTABLE picotool)
endif()

if (PICOTOOL_EXECUTABLE AND Python3_Interpreter_FOUND)
    foreach(K2_BOARD_REVISION IN LISTS K2_BOARD_REVISIONS)
        set(FPGA_GZIP_0 ${GOLDEN_${K2_BOARD_REVISION}_CONTEXT1})
        set(FPGA_GZIP_2 ${GOLDEN_${K2_BOARD_REVISION}_CONTEXT3})
        set(FPGA_GZIP_3 ${GOLDEN_${K2_BOARD_REVISION}_CONTEXT4})
        set(FPGA_UF2_0
            ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot0_${K2_BOARD_REVISION}.uf2)
        set(FPGA_UF2_2
            ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot2_${K2_BOARD_REVISION}.uf2)
        set(FPGA_UF2_3
            ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot3_${K2_BOARD_REVISION}.uf2)
        set(COMBINED_UF2
            ${CMAKE_CURRENT_BINARY_DIR}/fpga_mgr_${K2_BOARD_REVISION}_with_fpga.uf2)

        add_custom_command(
            OUTPUT ${FPGA_UF2_0} ${FPGA_UF2_2} ${FPGA_UF2_3} ${COMBINED_UF2}
            COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10800000 -t bin ${FPGA_GZIP_0} ${FPGA_UF2_0} --family rp2040
            COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10C00000 -t bin ${FPGA_GZIP_2} ${FPGA_UF2_2} --family rp2040
            COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10E00000 -t bin ${FPGA_GZIP_3} ${FPGA_UF2_3} --family rp2040
            COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/tools/concat_uf2.py
                    ${COMBINED_UF2}
                    ${CMAKE_CURRENT_BINARY_DIR}/fpga_mgr_${K2_BOARD_REVISION}.uf2
                    ${FPGA_UF2_0}
                    ${FPGA_UF2_2}
                    ${FPGA_UF2_3}
            DEPENDS fpga_mgr_${K2_BOARD_REVISION}
                    ${FPGA_GZIP_0} ${FPGA_GZIP_2} ${FPGA_GZIP_3}
            COMMENT "Building Rev${K2_BOARD_REVISION} combined UF2 with FPGA gzip blobs"
            VERBATIM
        )
        add_custom_target(fpga_mgr_${K2_BOARD_REVISION}_with_fpga_uf2
            DEPENDS ${COMBINED_UF2})
    endforeach()
    add_custom_target(fpga_mgr_with_fpga_uf2
        DEPENDS fpga_mgr_B0C_with_fpga_uf2 fpga_mgr_B3B_with_fpga_uf2)
else()
    set(_FPGA_UF2_MISSING "")
    if (NOT PICOTOOL_EXECUTABLE)
        string(APPEND _FPGA_UF2_MISSING " picotool")
    endif()
    if (NOT Python3_Interpreter_FOUND)
        string(APPEND _FPGA_UF2_MISSING " Python3")
    endif()

    message(STATUS
        "Skipping fpga_mgr_with_fpga_uf2 generation; missing prerequisites:${_FPGA_UF2_MISSING}")

    add_custom_target(fpga_mgr_with_fpga_uf2
        COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --red
                "Cannot build fpga_mgr_with_fpga_uf2. Missing prerequisites:${_FPGA_UF2_MISSING}"
        COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --yellow
                "Install missing tools, then re-run cmake configure."
        COMMAND ${CMAKE_COMMAND} -E false
        VERBATIM
    )
endif()
