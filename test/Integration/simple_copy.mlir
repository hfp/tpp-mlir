// RUN: standalone-opt %s -tpp-compiler="enable-tpp-preconditions" | \
// RUN: mlir-cpu-runner \
// RUN:  -e entry -entry-point-result=void  \
// RUN: -shared-libs=%llvmlirdir/libmlir_c_runner_utils%shlibext | \
// RUN: FileCheck %s
//

// RUN: standalone-opt %s -tpp-compiler | \
// RUN: mlir-cpu-runner \
// RUN:  -e entry -entry-point-result=void  \
// RUN: -shared-libs=%llvmlirdir/libmlir_c_runner_utils%shlibext | \
// RUN: FileCheck %s
//

// TODO: standalone-opt %s -tpp-compiler="enable-xsmm-conversion" | \
// TODO: mlir-cpu-runner \
// TODO:  -e entry -entry-point-result=void  \
// TODO: -shared-libs=%llvmlirdir/libmlir_c_runner_utils%shlibext,%standalonelibdir/libstandalone_c_runner_utils%shlibext | \
// TODO: FileCheck %s
//

#map0 = affine_map<(d0, d1) -> (d0, d1)>

module {

  func.func @copytpp(%A: tensor<4x4xf32>, 
                     %B:tensor<4x4xf32> ) -> tensor<4x4xf32> attributes {llvm.emit_c_interface} {
    %O = linalg.generic { indexing_maps = [#map0, #map0],
                          iterator_types = ["parallel", "parallel"] }
      ins(%A: tensor<4x4xf32>) outs(%B: tensor<4x4xf32>) {
        ^bb0(%a: f32, %b: f32):
          linalg.yield %a: f32
    } -> tensor<4x4xf32>
    return %O: tensor<4x4xf32>
  }

  func.func @entry() {
    %c0 = arith.constant 0 : index
    %d1 = arith.constant -1.0 : f32

    // Initialize various matrices, dense for stress testing,
    // and sparse to verify correct nonzero structure.
    %da = arith.constant dense<[
        [ 1.1, 2.1, 3.1, 4.1 ],
        [ 1.2, 2.2, 3.2, 4.2 ],
        [ 1.3, 2.3, 3.3, 4.3 ],
        [ 1.4, 2.4, 3.4, 4.4 ]
    ]> : tensor<4x4xf32>

    %B = arith.constant dense<0.0> : tensor<4x4xf32>
    %0 = call @copytpp(%da, %B) : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
    
    %m0 = bufferization.to_memref %0 : memref<4x4xf32>
    %v0 = vector.transfer_read %m0[%c0, %c0], %d1 : memref<4x4xf32>, vector<4x4xf32>
    vector.print %v0 : vector<4x4xf32>
    return 
  }

}
