; RUN: llc < %s -mtriple=powerpc64-unknown-linux-gnu -mcpu=pwr7 -verify-machineinstrs | FileCheck %s

; Verify that @llvm.eh.sjlj.setjmp stores FP and SP into the buffer.

@buf = internal global [5 x ptr] zeroinitializer, align 8

declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define i32 @setjmp_test() nounwind "frame-pointer"="all" {
  %r = call i32 @llvm.eh.sjlj.setjmp(ptr @buf)
  ret i32 %r
}

; CHECK-LABEL: setjmp_test:
; CHECK:       std 31, 0(
; CHECK:       std 1, 16(
