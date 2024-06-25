#!bin/bash

echo -e "NVBLAS_CPU_BLAS_LIB /path/to/libopenblas.so \n\nNVBLAS_GPU_LIST ALL \n\nNVBLAS_TILE_DIM 2048 \n\nNVBLAS_AUTOPIN_MEM_ENABLED" > nvblas.conf | mv nvblas.conf ../Common/include/linear_algebra


