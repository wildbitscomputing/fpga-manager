set default-list

[private]
@prepare:
    mkdir -p build

[private]
[working-directory('build')]
@build-target target: prepare
    cmake .. -DCMAKE_BUILD_TYPE=Release
    cmake --build . --target {{target}}

@build: (build-target "fpga_mgr")
@build-b0c: (build-target "fpga_mgr_B0C")
@build-b3b: (build-target "fpga_mgr_B3B")
@build-with-fpga-load: (build-target "fpga_mgr_with_fpga_uf2")

@build-k2-uploader:
    make -C k2

@build-k2-core-manager:
    make -C k2 core-manager

@package-release: build build-k2-core-manager
    python3 tools/package_release.py --build-dir build

@run-k2-uploader:
    make -C k2 pgz
    foenixmgr --target f256k run-pgz k2/k2uploader.pgz

@run-k2-core-manager:
    make -C k2 core-manager
    foenixmgr --target f256k run-pgz k2/k2coremgr.pgz
