; RUN: llc < %s -mtriple=s390x-linux-gnu | FileCheck %s

; Verify that @llvm.eh.sjlj.setjmp stores IP, SP, and FP into the buffer.

@buf = global [20 x ptr] zeroinitializer, align 8

declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define void @setjmp_test() nounwind {
  %r = tail call i32 @llvm.eh.sjlj.setjmp(ptr nonnull @buf)
  ret void
}

; CHECK-LABEL: setjmp_test:
; CHECK:       stg %r0, 8(%r1)
; CHECK:       stg %r15, 24(%r1)
