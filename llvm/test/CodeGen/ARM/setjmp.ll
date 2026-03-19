; RUN: llc < %s -mtriple=armv7-apple-ios | FileCheck --check-prefix=ARM %s
; RUN: llc < %s -mtriple=thumbv7-apple-ios | FileCheck --check-prefix=THUMB2 %s

; Verify that @llvm.setjmp produces the same FP/SP stores as the old pattern
; of @llvm.frameaddress + @llvm.stacksave + stores + @llvm.eh.sjlj.setjmp.

@buf = internal global [5 x ptr] zeroinitializer

; --- Old pattern (frameaddress + stacksave + stores + eh.sjlj.setjmp) ---

declare ptr @llvm.frameaddress(i32) nounwind readnone
declare ptr @llvm.stacksave() nounwind
declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define i32 @old_setjmp() nounwind "frame-pointer"="all" {
  %fp = call ptr @llvm.frameaddress(i32 0)
  store ptr %fp, ptr @buf, align 16
  %sp = call ptr @llvm.stacksave()
  store ptr %sp, ptr getelementptr inbounds ([5 x ptr], ptr @buf, i64 0, i64 2), align 16
  %r = call i32 @llvm.eh.sjlj.setjmp(ptr @buf)
  ret i32 %r
}

; --- New pattern (@llvm.setjmp) ---

declare i32 @llvm.setjmp(ptr) nounwind

define i32 @new_setjmp() nounwind "frame-pointer"="all" {
  %r = call i32 @llvm.setjmp(ptr @buf)
  ret i32 %r
}

; Both functions should store FP (r7) to buf[0] and SP to buf[2].

; ARM-LABEL: _old_setjmp:
; ARM:       str r7, [r0]
; ARM:       str sp, [r0, #8]
; ARM-LABEL: _new_setjmp:
; ARM:       str r7, [r0]
; ARM:       str sp, [r0, #8]

; THUMB2-LABEL: _old_setjmp:
; THUMB2:       str r7, [r0]
; THUMB2:       str.w sp, [r0, #8]
; THUMB2-LABEL: _new_setjmp:
; THUMB2:       str r7, [r0]
; THUMB2:       str.w sp, [r0, #8]
