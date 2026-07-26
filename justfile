set default-list

[private]
@prepare:
    mkdir -p build

[private]
[working-directory('build')]
@build-target target: prepare
    cd build
    cmake ..
    cmake --build . --target {{target}}

@build: (build-target "fpga_mgr")
@build-with-fpga-load: (build-target "fpga_mgr_with_fpga_uf2")
