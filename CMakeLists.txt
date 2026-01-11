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
# Reserve top 8MB for external FPGA blobs (app uses first 8MB).
set(PICO_FLASH_SIZE_BYTES 8388608 CACHE STRING "Flash size for application")

# Generated Cmake Pico project file

cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initalize pico_sdk from installed location
# (note this can come from environment, CMake cache etc)
#set(PICO_SDK_PATH "/home/carlk/pi/pico/pico-sdk")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(fpga_mgr C CXX ASM)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

add_subdirectory(FatFs_SPI build)

# Add executable. Default name is the project name, version 0.1
add_executable(fpga_mgr
    fpga_mgr.cpp
    hw_config.c
    miniz.c
    miniz_tinfl.c
    miniz_tdef.c
    lz4.c
)

# Generate PIO header for FPGA data+clock output.
pico_generate_pio_header(fpga_mgr ${CMAKE_CURRENT_LIST_DIR}/fpga_out.pio)

# Add the standard library and FatFS/SPI to the build
target_link_libraries(fpga_mgr
    pico_stdlib
    hardware_dma
    hardware_pio
    FatFs_SPI
)

add_custom_target(mk_lz4_blocks
    COMMAND cc -O2 -I${CMAKE_CURRENT_LIST_DIR}
            -o ${CMAKE_CURRENT_BINARY_DIR}/mk_lz4_blocks
            ${CMAKE_CURRENT_LIST_DIR}/tools/mk_lz4_blocks.c
            ${CMAKE_CURRENT_LIST_DIR}/lz4.c
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    COMMENT "Building host mk_lz4_blocks tool"
)

find_package(Python3 COMPONENTS Interpreter)

set(PICOTOOL_EXECUTABLE ${USERHOME}/.pico-sdk/picotool/${picotoolVersion}/picotool/picotool)
if (NOT EXISTS ${PICOTOOL_EXECUTABLE})
    find_program(PICOTOOL_EXECUTABLE picotool)
endif()

set(FPGA_LZ4_0 ${CMAKE_CURRENT_LIST_DIR}/fpga/CFP95600C.bin.lz4)
set(FPGA_LZ4_2 ${CMAKE_CURRENT_LIST_DIR}/fpga/f256k2t9.bin.lz4)
set(FPGA_LZ4_3 ${CMAKE_CURRENT_LIST_DIR}/fpga/foenix138.bin.lz4)
set(FPGA_UF2_0 ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot0.uf2)
set(FPGA_UF2_2 ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot2.uf2)
set(FPGA_UF2_3 ${CMAKE_CURRENT_BINARY_DIR}/fpga_slot3.uf2)
set(COMBINED_UF2 ${CMAKE_CURRENT_BINARY_DIR}/fpga_mgr_with_fpga.uf2)

if (PICOTOOL_EXECUTABLE AND Python3_Interpreter_FOUND)
    add_custom_command(
        OUTPUT ${FPGA_UF2_0} ${FPGA_UF2_2} ${FPGA_UF2_3} ${COMBINED_UF2}
        COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10800000 -t bin ${FPGA_LZ4_0} ${FPGA_UF2_0} --family rp2040
        COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10C00000 -t bin ${FPGA_LZ4_2} ${FPGA_UF2_2} --family rp2040
        COMMAND ${PICOTOOL_EXECUTABLE} uf2 convert --offset 0x10E00000 -t bin ${FPGA_LZ4_3} ${FPGA_UF2_3} --family rp2040
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/tools/concat_uf2.py
                ${COMBINED_UF2}
                ${CMAKE_CURRENT_BINARY_DIR}/fpga_mgr.uf2
                ${FPGA_UF2_0}
                ${FPGA_UF2_2}
                ${FPGA_UF2_3}
        DEPENDS fpga_mgr ${FPGA_LZ4_0} ${FPGA_LZ4_2} ${FPGA_LZ4_3}
        COMMENT "Building combined UF2 with FPGA LZ4 blobs"
    )
    add_custom_target(fpga_mgr_with_fpga_uf2 DEPENDS ${COMBINED_UF2})
endif()
#pico_set_binary_type(fpga_mgr no_flash)
pico_set_program_name(fpga_mgr "fpga_mgr")
pico_set_program_version(fpga_mgr "0.1")

# Choose source and destination for standard input and output:
#   See 4.1. Serial input and output on Raspberry Pi Pico in Getting started with Raspberry Pi Pico (https://datasheets.raspberrypi.org/pico/getting-started-with-pico.pdf)
#   and 2.7.1. Standard Input/Output (stdio) Support in Raspberry Pi Pico C/C++ SDK (https://datasheets.raspberrypi.org/pico/raspberry-pi-pico-c-sdk.pdf):
#pico_enable_stdio_uart(fpga_mgr 1)
pico_enable_stdio_usb(fpga_mgr 1)
pico_add_extra_outputs(fpga_mgr)

target_include_directories(fpga_mgr PRIVATE ${CMAKE_CURRENT_LIST_DIR})
