; RUN: llc < %s -mtriple=s390x-linux-gnu | FileCheck %s

; Verify that @llvm.setjmp produces the same IP/SP stores as the old pattern
; of @llvm.frameaddress + @llvm.stacksave + stores + @llvm.eh.sjlj.setjmp.
; SystemZ's eh.sjlj.setjmp already stores IP and SP internally, so
; the old and new patterns should produce identical output.

@buf = global [20 x ptr] zeroinitializer, align 8

; --- Old pattern (eh.sjlj.setjmp, which already stores IP+SP on SystemZ) ---

declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define void @old_setjmp() nounwind {
  %r = tail call i32 @llvm.eh.sjlj.setjmp(ptr nonnull @buf)
  ret void
}

; --- New pattern (@llvm.setjmp) ---

declare i32 @llvm.setjmp(ptr) nounwind

define void @new_setjmp() nounwind {
  %r = tail call i32 @llvm.setjmp(ptr nonnull @buf)
  ret void
}

; Both should store IP to buf[1] (offset 8) and SP to buf[3] (offset 24).

; CHECK-LABEL: old_setjmp:
; CHECK:       stg %r0, 8(%r1)
; CHECK:       stg %r15, 24(%r1)
; CHECK-LABEL: new_setjmp:
; CHECK:       stg %r0, 8(%r1)
; CHECK:       stg %r15, 24(%r1)
