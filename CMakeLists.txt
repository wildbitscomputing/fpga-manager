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

# Golden images are linked into the manager below the mutable 8 MiB slot bank.
# Context 2 has no core yet, so recovery for it deliberately uses context 1.
set(GOLDEN_CONTEXT1_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/context1.gz)
set(GOLDEN_CONTEXT3_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/context3.gz)
set(GOLDEN_CONTEXT4_DEFAULT ${CMAKE_CURRENT_LIST_DIR}/fpga/context4.gz)
set(GOLDEN_CONTEXT1 ${GOLDEN_CONTEXT1_DEFAULT} CACHE FILEPATH "Golden context 1 gzip image")
set(GOLDEN_CONTEXT3 ${GOLDEN_CONTEXT3_DEFAULT} CACHE FILEPATH "Golden context 3 gzip image")
set(GOLDEN_CONTEXT4 ${GOLDEN_CONTEXT4_DEFAULT} CACHE FILEPATH "Golden context 4 gzip image")
set(GOLDEN_CONTEXT1_LABEL "" CACHE STRING "Golden context 1 display name (empty uses filename)")
set(GOLDEN_CONTEXT3_LABEL "" CACHE STRING "Golden context 3 display name (empty uses filename)")
set(GOLDEN_CONTEXT4_LABEL "" CACHE STRING "Golden context 4 display name (empty uses filename)")
set(GOLDEN_CONTEXT1_DEFAULT_LABEL "CFP95600C.bin.gz")
set(GOLDEN_CONTEXT3_DEFAULT_LABEL "Wildbits_k2_6809_int_wizfi_turbo_v5_20260827.bin.gz")
set(GOLDEN_CONTEXT4_DEFAULT_LABEL "WildbitsK2_2x_B0C_02020103_20260827.bin.gz")
foreach(GOLDEN_IMAGE IN ITEMS GOLDEN_CONTEXT1 GOLDEN_CONTEXT3 GOLDEN_CONTEXT4)
    if(NOT EXISTS "${${GOLDEN_IMAGE}}")
        message(FATAL_ERROR "Missing required recovery image: ${${GOLDEN_IMAGE}}")
    endif()
    file(TO_CMAKE_PATH "${${GOLDEN_IMAGE}}" ${GOLDEN_IMAGE})
endforeach()
foreach(GOLDEN_CONTEXT IN ITEMS 1 3 4)
    if(GOLDEN_CONTEXT${GOLDEN_CONTEXT}_LABEL STREQUAL "")
        if(GOLDEN_CONTEXT${GOLDEN_CONTEXT} STREQUAL
           GOLDEN_CONTEXT${GOLDEN_CONTEXT}_DEFAULT)
            set(GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL
                "${GOLDEN_CONTEXT${GOLDEN_CONTEXT}_DEFAULT_LABEL}")
        else()
            get_filename_component(
                GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL
                "${GOLDEN_CONTEXT${GOLDEN_CONTEXT}}" NAME
            )
        endif()
    else()
        set(GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL
            "${GOLDEN_CONTEXT${GOLDEN_CONTEXT}_LABEL}")
    endif()
    string(LENGTH "${GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL}"
           GOLDEN_CONTEXT_LABEL_LENGTH)
    if(GOLDEN_CONTEXT_LABEL_LENGTH GREATER 191)
        message(FATAL_ERROR
            "Golden context ${GOLDEN_CONTEXT} display name exceeds 191 characters")
    endif()
    if(GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL MATCHES "[\r\n]")
        message(FATAL_ERROR
            "Golden context ${GOLDEN_CONTEXT} display name contains a newline")
    endif()
    # Quote the label for use as an assembler string literal.
    string(REPLACE "\\" "\\\\" GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL
           "${GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL}")
    string(REPLACE "\"" "\\\"" GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL
           "${GOLDEN_CONTEXT${GOLDEN_CONTEXT}_EMBEDDED_LABEL}")
endforeach()
configure_file(golden_images.S.in ${CMAKE_CURRENT_BINARY_DIR}/golden_images.S @ONLY)
set_property(SOURCE ${CMAKE_CURRENT_BINARY_DIR}/golden_images.S APPEND PROPERTY
    OBJECT_DEPENDS
        "${GOLDEN_CONTEXT1};${GOLDEN_CONTEXT3};${GOLDEN_CONTEXT4}"
)
set(GOLDEN_FPGA_TOTAL_SIZE 0)
foreach(GOLDEN_IMAGE IN ITEMS GOLDEN_CONTEXT1 GOLDEN_CONTEXT3 GOLDEN_CONTEXT4)
    file(SIZE "${${GOLDEN_IMAGE}}" GOLDEN_IMAGE_SIZE)
    math(EXPR GOLDEN_FPGA_TOTAL_SIZE "${GOLDEN_FPGA_TOTAL_SIZE} + ${GOLDEN_IMAGE_SIZE}")
endforeach()
if(GOLDEN_FPGA_TOTAL_SIZE GREATER 6291456)
    message(FATAL_ERROR "Golden images total ${GOLDEN_FPGA_TOTAL_SIZE} bytes; maximum is 6 MiB")
endif()

add_subdirectory(FatFs_SPI build)

# Add executable.
add_executable(fpga_mgr
    boot_config.cpp
    boot_log.cpp
    fpga_mgr.cpp
    golden_images.cpp
    hw_config.c
    miniz.c
    miniz_tinfl.c
    miniz_tdef.c
    supervisor_service.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/golden_images.S
)

# Enable stricter-than-default compile-time warnings and checks
target_compile_options(fpga_mgr PRIVATE
    -Wall
    -Wextra
    -Wformat=2
    -Werror=format
    -Wno-unused-function
)

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

# Generate PIO header for FPGA data+clock output.
pico_generate_pio_header(fpga_mgr ${CMAKE_CURRENT_LIST_DIR}/fpga_out.pio)
pico_generate_pio_header(fpga_mgr ${CMAKE_CURRENT_LIST_DIR}/supervisor_spi.pio)

# Add the standard library and FatFS/SPI to the build
target_link_libraries(fpga_mgr
    pico_stdlib
    hardware_dma
    hardware_pio
    hardware_adc
    hardware_flash
    hardware_watchdog
    FatFs_SPI
)

find_package(Python3 COMPONENTS Interpreter)

set(_PICO_VSCODE_PICOTOOL ${USERHOME}/.pico-sdk/picotool/${picotoolVersion}/picotool/picotool)
if (EXISTS ${_PICO_VSCODE_PICOTOOL})
    set(PICOTOOL_EXECUTABLE ${_PICO_VSCODE_PICOTOOL})
else()
    unset(PICOTOOL_EXECUTABLE CACHE)
    unset(PICOTOOL_EXECUTABLE)
    find_program(PICOTOOL_EXECUTABLE picotool)
endif()

set(FPGA_GZIP_0 ${CMAKE_CURRENT_LIST_DIR}/fpga/context1.gz)
set(FPGA_GZIP_2 ${CMAKE_CURRENT_LIST_DIR}/fpga/context3.gz)
set(FPGA_GZIP_3 ${CMAKE_CURRENT_LIST_DIR}/fpga/context4.gz)
set(FPGA_UF2_0 ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot0.uf2)
set(FPGA_UF2_2 ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot2.uf2)
set(FPGA_UF2_3 ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot3.uf2)
set(COMBINED_UF2 ${CMAKE_CURRENT_BINARY_DIR}/fpga_mgr_with_fpga.uf2)

if (PICOTOOL_EXECUTABLE AND Python3_Interpreter_FOUND)
    add_custom_command(
        OUTPUT ${FPGA_UF2_0} ${FPGA_UF2_2} ${FPGA_UF2_3} ${COMBINED_UF2}
        COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10800000 -t bin ${FPGA_GZIP_0} ${FPGA_UF2_0} --family rp2040
        COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10C00000 -t bin ${FPGA_GZIP_2} ${FPGA_UF2_2} --family rp2040
        COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10E00000 -t bin ${FPGA_GZIP_3} ${FPGA_UF2_3} --family rp2040
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/tools/concat_uf2.py
                ${COMBINED_UF2}
                ${CMAKE_CURRENT_BINARY_DIR}/fpga_mgr.uf2
                ${FPGA_UF2_0}
                ${FPGA_UF2_2}
                ${FPGA_UF2_3}
        DEPENDS fpga_mgr ${FPGA_GZIP_0} ${FPGA_GZIP_2} ${FPGA_GZIP_3}
        COMMENT "Building combined UF2 with FPGA gzip blobs"
    )
    add_custom_target(fpga_mgr_with_fpga_uf2 DEPENDS ${COMBINED_UF2})
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
#pico_set_binary_type(fpga_mgr no_flash)
pico_set_program_name(fpga_mgr "fpga_mgr")
pico_set_program_version(fpga_mgr "${PROJECT_VERSION}")

# Choose source and destination for standard input and output:
#   See 4.1. Serial input and output on Raspberry Pi Pico in Getting started with Raspberry Pi Pico (https://datasheets.raspberrypi.org/pico/getting-started-with-pico.pdf)
#   and 2.7.1. Standard Input/Output (stdio) Support in Raspberry Pi Pico C/C++ SDK (https://datasheets.raspberrypi.org/pico/raspberry-pi-pico-c-sdk.pdf):
option(FPGA_MGR_UART_DEBUG "Mirror manager stdio to the K2 FTDI UART" OFF)
if(FPGA_MGR_UART_DEBUG)
    target_compile_definitions(fpga_mgr PRIVATE
        PICO_DEFAULT_UART=1
        PICO_DEFAULT_UART_TX_PIN=24
        PICO_DEFAULT_UART_RX_PIN=25
        PICO_DEFAULT_UART_BAUD_RATE=115200
    )
    pico_enable_stdio_uart(fpga_mgr 1)
else()
    pico_enable_stdio_uart(fpga_mgr 0)
endif()
pico_enable_stdio_usb(fpga_mgr 1)
pico_add_extra_outputs(fpga_mgr)

target_include_directories(fpga_mgr PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)
