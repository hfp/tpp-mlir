// RUN: standalone-opt %s | standalone-opt | FileCheck %s

// CHECK-LABEL: @myfunc
func.func @myfunc(%arg0: memref<2x2xf32>, 
                  %arg1: memref<2x2xf32>, %arg2: memref<2x2xf32>) -> memref<2x2xf32> {

  xsmm.ternary_call @libxsmm_matmul(%arg0, %arg1, %arg2) 
    : (memref<2x2xf32>, memref<2x2xf32>, memref<2x2xf32>) -> ()

  xsmm.binary_call @libxsmm_add(%arg0, %arg1)
    : (memref<2x2xf32>, memref<2x2xf32>) -> ()

  xsmm.unary_call @libxsmm_relu(%arg0)
    : (memref<2x2xf32>) -> ()

  xsmm.void_call @libxsmm_init

  return %arg2: memref<2x2xf32>
}
