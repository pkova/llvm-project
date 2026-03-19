; RUN: llc < %s -mtriple=i386-pc-linux | FileCheck --check-prefix=X86 %s
; RUN: llc < %s -mtriple=x86_64-pc-linux | FileCheck --check-prefix=X64 %s
; RUN: llc < %s -mtriple=x86_64-windows-gnu | FileCheck --check-prefix=WIN64 %s

; Verify that @llvm.setjmp produces the same output as the old pattern of
; @llvm.frameaddress + @llvm.stacksave + stores + @llvm.eh.sjlj.setjmp.

@buf = internal global [5 x ptr] zeroinitializer

; --- Old pattern (frameaddress + stacksave + stores + eh.sjlj.setjmp) ---

declare ptr @llvm.frameaddress(i32) nounwind readnone
declare ptr @llvm.stacksave() nounwind
declare i32 @llvm.eh.sjlj.setjmp(ptr) nounwind

define i32 @old_setjmp() nounwind "frame-pointer"="all" {
  %fp = tail call ptr @llvm.frameaddress(i32 0)
  store ptr %fp, ptr @buf, align 16
  %sp = tail call ptr @llvm.stacksave()
  store ptr %sp, ptr getelementptr inbounds ([5 x ptr], ptr @buf, i64 0, i64 2), align 16
  %r = tail call i32 @llvm.eh.sjlj.setjmp(ptr @buf)
  ret i32 %r
}

; --- New pattern (@llvm.setjmp) ---

declare i32 @llvm.setjmp(ptr) nounwind

define i32 @new_setjmp() nounwind "frame-pointer"="all" {
  %r = tail call i32 @llvm.setjmp(ptr @buf)
  ret i32 %r
}

; Both functions should store FP to buf[0], SP to buf[2], IP to buf[1].

; X86-LABEL: old_setjmp:
; X86:       movl %ebp, buf
; X86:       movl %esp, buf+8
; X86-LABEL: new_setjmp:
; X86:       movl %ebp, buf
; X86:       movl %esp, buf+8

; X64-LABEL: old_setjmp:
; X64:       movq %rbp, buf(%rip)
; X64:       movq %rsp, buf+16(%rip)
; X64-LABEL: new_setjmp:
; X64:       movq %rbp, buf(%rip)
; X64:       movq %rsp, buf+16(%rip)

; On WIN64, the old pattern stores an adjusted address from @llvm.frameaddress
; (which is wrong on WindowsCFI targets). The new @llvm.setjmp stores %rbp
; directly, which is the correct fix.
; WIN64-LABEL: new_setjmp:
; WIN64:       movq %rbp, buf(%rip)
; WIN64:       movq %rsp, buf+16(%rip)
