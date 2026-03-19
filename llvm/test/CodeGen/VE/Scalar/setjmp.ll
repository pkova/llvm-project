; RUN: llc < %s -mtriple=ve | FileCheck %s

; Verify that @llvm.setjmp produces the same FP/SP stores as the old pattern
; of @llvm.frameaddress + @llvm.stacksave + stores + @llvm.eh.sjlj.setjmp.

@buf = common global [1 x [25 x i64]] zeroinitializer, align 8

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

; Both functions should store FP (s9) to buf[0] and SP (s11) to buf[2].

; CHECK-LABEL: old_setjmp:
; CHECK:       st %s9, (, %s0)
; CHECK:       st %s11, 16(, %s0)
; CHECK-LABEL: new_setjmp:
; CHECK:       st %s9, (, %s0)
; CHECK:       st %s11, 16(, %s0)
