// RUN: standalone-opt %s -convert-tpp-to-xsmm -split-input-file | FileCheck %s

// CHECK-LABEL: @identity_to_xsmm(
// CHECK-SAME: %[[arg:.*]]: memref<3x3xf32>) {
func.func @identity_to_xsmm(%arg0: memref<3x3xf32>) {
  // CHECK: %[[cst:.*]] = arith.constant 0.000000e+00 : f32
  %cst = arith.constant 0.000000e+00 : f32

  // m = 3
  // n = 3
  // ldi = 1
  // ldo = 3
  // input_type = 1 (F32)
  // output_type = 1 (F32)
  // compute_type = 1 (F32)
  // b_cast = 3 (bcast scalar)
 
  // CHECK: xsmm.dispatch @xsmm_identity_dispatch
  // CHECK: xsmm.unary @xsmm_identity_invoke
  tpp.identity ins(%cst: f32) out(%arg0: memref<3x3xf32>)
  return 
}

// -----

// CHECK-LABEL: @identity_to_xsmm(
// CHECK-SAME: %[[arg_zero:.*]]: memref<3x3xf32>, %[[arg_one:.*]]: memref<3x3xf32>)
func.func @identity_to_xsmm(%arg0: memref<3x3xf32>, %arg1: memref<3x3xf32>) {

  // m = 3
  // n = 3
  // ldi = 3
  // ldo = 3
  // input_type = 1 (F32)
  // output_type = 1 (F32)
  // compute_type = 1 (F32)
  // b_cast = 0 (bcast none)

  // CHECK: xsmm.dispatch @xsmm_identity_dispatch
  // CHECK: xsmm.unary @xsmm_identity_invoke
  tpp.identity ins(%arg0: memref<3x3xf32>) out(%arg1: memref<3x3xf32>)
  return 
}

// -----

// CHECK-LABEL: @identity_to_xsmm(
func.func @identity_to_xsmm(%arg0: memref<5x1xf32>, %arg1: memref<5x6xf32>) {

  // m = 5
  // n = 6
  // ldi = 5
  // ldo = 6
  // input_type = 1 (F32)
  // output_type = 1 (F32)
  // compute_type = 1 (F32)
  // b_cast = 1 (bcast row)

  // CHECK: xsmm.dispatch @xsmm_identity_dispatch
  // CHECK: xsmm.unary @xsmm_identity_invoke
  tpp.identity ins(%arg0: memref<5x1xf32>) out(%arg1: memref<5x6xf32>)
  return 
}

// -----

// CHECK-LABEL: @identity_to_xsmm(
func.func @identity_to_xsmm(%arg0: memref<1x5xf32>, %arg1: memref<5x5xf32>) {

  // m = 5
  // n = 5
  // ldi = 5
  // ldo = 5
  // input_type = 1 (F32)
  // output_type = 1 (F32)
  // compute_type = 1 (F32)
  // b_cast = 2 (bcast col)

  // CHECK: xsmm.dispatch @xsmm_identity_dispatch
  // CHECK: xsmm.unary @xsmm_identity_invoke
  tpp.identity ins(%arg0: memref<1x5xf32>) out(%arg1: memref<5x5xf32>)
  return 
}

// -----

// CHECK-LABEL: @matmul_to_xsmm(
// CHECK-SAME: %[[arg_zero:.*]]: memref<3x3xf32>, %[[arg_one:.*]]: memref<3x3xf32>, %[[arg_two:.*]]: memref<3x3xf32>)
func.func @matmul_to_xsmm(%arg0: memref<3x3xf32>, %arg1: memref<3x3xf32>, %arg2: memref<3x3xf32>) {
  // CHECK: %[[cst:.*]] = arith.constant 3 : i32
  // CHECK: %[[dispatch:.*]] = xsmm.dispatch @xsmm_matmul_dispatch
  // CHECK: xsmm.ternary @xsmm_matmul_invoke(%[[dispatch]], %[[arg_zero]], %[[arg_one]], %[[arg_two]]) : (i64, memref<3x3xf32>, memref<3x3xf32>, memref<3x3xf32>) -> ()
  tpp.matmul ins(%arg0: memref<3x3xf32>, %arg1: memref<3x3xf32>) out(%arg2: memref<3x3xf32>)
  return 
}
