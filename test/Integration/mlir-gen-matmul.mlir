// RUN: mlir-gen --kernel=matmul --seed=0 --float-width=32 --mini-batch=128 --layers=2304,768 --tiles=64,48,64 2>&1 | FileCheck %s --check-prefix=FP32

// FP32: // RUN{{.*}}tpp-run %s -n {{\d*}}
// FP32: // RUN{{.*}}-e entry -entry-point-result=void
// FP32: // BENCH_TOTAL_FLOPS: 452984832
// FP32-DAG: #map = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d2, d3, d5)>
// FP32-DAG: #map1 = affine_map<(d0, d1, d2, d3, d4, d5) -> (d1, d2, d5, d4)>
// FP32-DAG: #map2 = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d3, d4)>
// FP32:     func.func @entry(%arg0: tensor<2x36x64x64xf32>, %arg1: tensor<16x36x64x48xf32>, %arg2: tensor<2x16x64x48xf32>) -> tensor<2x16x64x48xf32>
// FP32-NOT: alloc
// FP32:     linalg.generic {{.*}}iterator_types = ["parallel", "parallel", "reduction", "parallel", "parallel", "reduction"]
// FP32:         arith.mulf
// FP32:         arith.addf
// FP32-NOT: dealloc
