; RUN: llc < %s -mtriple=powerpc64-unknown-linux-gnu -mcpu=pwr7 -verify-machineinstrs | FileCheck %s

; Verify that @llvm.setjmp produces the same FP/SP stores as the old pattern
; of @llvm.frameaddress + @llvm.stacksave + stores + @llvm.eh.sjlj.setjmp.

@buf = internal global [5 x ptr] zeroinitializer, align 8

; --- Old pattern (frameaddress + stacksave + stores + eh.sjlj.setjmp) ---

declare ptr @llvm.frameaddress(i32) nounwind readnone
declare ptr @llvm.stacksave() nounwind
declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define i32 @old_setjmp() nounwind "frame-pointer"="all" {
  %fp = call ptr @llvm.frameaddress(i32 0)
  store ptr %fp, ptr @buf, align 8
  %sp = call ptr @llvm.stacksave()
  store ptr %sp, ptr getelementptr inbounds (ptr, ptr @buf, i64 2), align 8
  %r = call i32 @llvm.eh.sjlj.setjmp(ptr @buf)
  ret i32 %r
}

; --- New pattern (@llvm.setjmp) ---

declare i32 @llvm.setjmp(ptr) nounwind

define i32 @new_setjmp() nounwind "frame-pointer"="all" {
  %r = call i32 @llvm.setjmp(ptr @buf)
  ret i32 %r
}

; Both functions should store FP (r31) to buf[0] and SP (r1) to buf[2] (offset 16).

; CHECK-LABEL: old_setjmp:
; CHECK:       std 31, buf@toc@l(
; CHECK:       std 1, 16(
; CHECK-LABEL: new_setjmp:
; CHECK:       std 31, 0(
; CHECK:       std 1, 16(
