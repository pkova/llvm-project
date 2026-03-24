; RUN: llc < %s -mtriple=armv7-apple-ios | FileCheck --check-prefix=ARM %s
; RUN: llc < %s -mtriple=thumbv7-apple-ios | FileCheck --check-prefix=THUMB2 %s

; Verify that @llvm.eh.sjlj.setjmp stores FP and SP into the buffer.

@buf = internal global [5 x ptr] zeroinitializer

declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define i32 @setjmp_test() nounwind "frame-pointer"="all" {
  %r = call i32 @llvm.eh.sjlj.setjmp(ptr @buf)
  ret i32 %r
}

; ARM-LABEL: _setjmp_test:
; ARM:       str r7, [r0]
; ARM:       str sp, [r0, #8]

; THUMB2-LABEL: _setjmp_test:
; THUMB2:       str r7, [r0]
; THUMB2:       str.w sp, [r0, #8]
