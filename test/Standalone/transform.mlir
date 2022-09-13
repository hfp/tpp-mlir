// RUN: standalone-opt -transform-dialect-interpreter -split-input-file %s | FileCheck %s

transform.with_pdl_patterns {
^bb0(%arg0: !pdl.operation):
  sequence %arg0 failures(propagate) {
    ^bb0(%arg1: !pdl.operation):
      %0 = transform.structured.match ops{["linalg.matmul"]} in %arg1
      %1, %loops:3 = transform.structured.tile %0 [4, 4, 4]
  }
}

// CHECK-LABEL: func @tile_linalg_matmul(
// CHECK-SAME:    %[[TA:[0-9a-z]+]]: tensor<128x128xf32>
// CHECK-SAME:    %[[TB:[0-9a-z]+]]: tensor<128x128xf32>
// CHECK-SAME:    %[[TC:[0-9a-z]+]]: tensor<128x128xf32>
// CHECK-SAME:  -> tensor<128x128xf32> {
func.func @tile_linalg_matmul(
  %arg0: tensor<128x128xf32>, %arg1: tensor<128x128xf32>, %arg2: tensor<128x128xf32>)
    -> tensor<128x128xf32> {
//      CHECK: %[[TD0:.*]] = scf.for {{.*}} to {{.*}} step {{.*}} iter_args(%[[TC0:.*]] = %[[TC]]) -> (tensor<128x128xf32>) {
//      CHECK:   %[[TD1:.*]] = scf.for {{.*}} to {{.*}} step {{.*}} iter_args(%[[TC1:.*]] = %[[TC0]]) -> (tensor<128x128xf32>) {
//      CHECK:     %[[TD2:.*]] = scf.for {{.*}} to {{.*}} step {{.*}} iter_args(%[[TC2:.*]] = %[[TC1]]) -> (tensor<128x128xf32>) {
//      CHECK:       %[[sTA:.*]] = tensor.extract_slice %[[TA]][{{.*}}] : tensor<128x128xf32> to tensor<4x4xf32>
//      CHECK:       %[[sTB:.*]] = tensor.extract_slice %[[TB]][{{.*}}] : tensor<128x128xf32> to tensor<4x4xf32>
//      CHECK:       %[[sTC:.*]] = tensor.extract_slice %[[TC2]][{{.*}}] : tensor<128x128xf32> to tensor<4x4xf32>
//      CHECK:       %[[sTD:.*]] = linalg.matmul ins(%[[sTA]], %[[sTB]] : tensor<4x4xf32>, tensor<4x4xf32>)
// CHECK-SAME:                                   outs(%[[sTC]] : tensor<4x4xf32>)  -> tensor<4x4xf32>
//      CHECK:       %[[TD:.*]] = tensor.insert_slice %[[sTD]] into %[[TC2]][{{.*}}]  : tensor<4x4xf32> into tensor<128x128xf32>
//      CHECK:       scf.yield %[[TD]] : tensor<128x128xf32>
//      CHECK:     scf.yield %[[TD2]] : tensor<128x128xf32>
//      CHECK:   scf.yield %[[TD1]] : tensor<128x128xf32>
  %0 = linalg.matmul  ins(%arg0, %arg1: tensor<128x128xf32>, tensor<128x128xf32>)
                     outs(%arg2: tensor<128x128xf32>)
    -> tensor<128x128xf32>

//      CHECK: return %[[TD0]] : tensor<128x128xf32>
  return %0 : tensor<128x128xf32>
}

// -----

transform.with_pdl_patterns {
^bb0(%arg0: !pdl.operation):
  transform.sequence %arg0 failures(propagate) {
    ^bb0(%arg1: !pdl.operation):
      %0 = transform.structured.match ops{["linalg.matmul"]} in %arg1
      %1 = transform.structured.blocking %0 { blocking_factors = [32, 32] }
  }
}

// CHECK-DAG: #[[MAP0:.*]] = affine_map<(d0, d1, d2, d3) -> (d0 * 32 + d2, d1 * 32 + d3)>
// CHECK-DAG: #[[MAP1:.*]] = affine_map<(d0, d1, d2, d3) -> (d0, d1, d2, d3)>
// CHECK-DAG: #[[MAP2:.*]] = affine_map<(d0, d1, d2, d3) -> (d1 * 32 + d2, d0 * 32 + d3)>
// CHECK-DAG: #[[MAP3:.*]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d2, d3, d5)>
// CHECK-DAG: #[[MAP4:.*]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d1, d2, d5, d4)>
// CHECK-DAG: #[[MAP5:.*]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d3, d4)>

// CHECK-LABEL: func @block_linalg_matmul(
// CHECK-SAME:    %[[TA:[0-9a-z]+]]: tensor<128x128xf32>
// CHECK-SAME:    %[[TB:[0-9a-z]+]]: tensor<128x128xf32>
// CHECK-SAME:    %[[TC:[0-9a-z]+]]: tensor<128x128xf32>
// CHECK-SAME:  -> tensor<128x128xf32> {
func.func @block_linalg_matmul(
  %arg0: tensor<128x128xf32>, %arg1: tensor<128x128xf32>, %arg2: tensor<128x128xf32>)
    -> tensor<128x128xf32> {
  // CHECK: %[[BBufA:.*]] = linalg.init_tensor [4, 4, 32, 32] : tensor<4x4x32x32xf32>
  // CHECK: %[[BA:.*]] = linalgx.relayout ins(%[[TA]] : tensor<128x128xf32>, #[[MAP0]]) outs(%[[BBufA]] : tensor<4x4x32x32xf32>, #[[MAP1]]) -> tensor<4x4x32x32xf32>
  // CHECK: %[[BBufB:.*]] = linalg.init_tensor [4, 4, 32, 32] : tensor<4x4x32x32xf32>
  // CHECK: %[[BB:.*]] = linalgx.relayout ins(%[[TB]] : tensor<128x128xf32>, #[[MAP2]]) outs(%[[BBufB]] : tensor<4x4x32x32xf32>, #[[MAP1]]) -> tensor<4x4x32x32xf32>
  // CHECK: %[[BBufC:.*]] = linalg.init_tensor [4, 4, 32, 32] : tensor<4x4x32x32xf32>
  // CHECK: %[[BC:.*]] = linalgx.relayout ins(%[[TC]] : tensor<128x128xf32>, #[[MAP0]]) outs(%[[BBufC]] : tensor<4x4x32x32xf32>, #[[MAP1]]) -> tensor<4x4x32x32xf32>
  // CHECK: %[[res:.*]] = linalg.generic {indexing_maps = [#[[MAP3]], #[[MAP4]], #[[MAP5]]], iterator_types = ["parallel", "parallel", "reduction", "parallel", "parallel", "reduction"]} ins(%[[BA]], %[[BB]] : tensor<4x4x32x32xf32>, tensor<4x4x32x32xf32>) outs(%[[BC]] : tensor<4x4x32x32xf32>)
  // CHECK: %[[Ur:.*]] = linalgx.relayout ins(%[[res]] : tensor<4x4x32x32xf32>, #[[MAP1]]) outs(%[[TC]] : tensor<128x128xf32>, #[[MAP0]]) -> tensor<128x128xf32>
  // CHECK: return %[[Ur]] : tensor<128x128xf32>
  %0 = linalg.matmul  ins(%arg0, %arg1: tensor<128x128xf32>, tensor<128x128xf32>)
                     outs(%arg2: tensor<128x128xf32>)
    -> tensor<128x128xf32>
  return %0 : tensor<128x128xf32>
}
