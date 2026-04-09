; ModuleID = '../test-files/a2.bc'
source_filename = "../test-files/a.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @f(i32 noundef %a, i32 noundef %b) #0 {
entry:
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  %n = alloca i32, align 4
  store i32 %a, ptr %a.addr, align 4
  store i32 %b, ptr %b.addr, align 4
  store i32 0, ptr %n, align 4
  fence seq_cst
  %0 = load i32, ptr %a.addr, align 4
  fence seq_cst
  %cmp = icmp eq i32 %0, 2
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %1 = load i32, ptr %a.addr, align 4
  fence seq_cst
  store i32 %1, ptr %n, align 4
  br label %if.end3

if.else:                                          ; preds = %entry
  %2 = load i32, ptr %b.addr, align 4
  %cmp1 = icmp eq i32 %2, 3
  br i1 %cmp1, label %if.then2, label %if.end

if.then2:                                         ; preds = %if.else
  fence seq_cst
  %3 = load i32, ptr %a.addr, align 4
  fence seq_cst
  %4 = load i32, ptr %b.addr, align 4
  fence seq_cst
  %add = add nsw i32 %3, %4
  store i32 %add, ptr %n, align 4
  br label %if.end

if.end:                                           ; preds = %if.then2, %if.else
  br label %if.end3

if.end3:                                          ; preds = %if.end, %if.then
  fence seq_cst
  %5 = load i32, ptr %n, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  %call = call i32 @f(i32 noundef 2, i32 noundef 3)
  ret i32 %call
}

attributes #0 = { noinline nounwind optnone ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 4}
!4 = !{!"clang version 22.1.2"}
