; ModuleID = 'src/fibonacci.c'
source_filename = "src/fibonacci.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@fib = dso_local local_unnamed_addr global [100 x i64] zeroinitializer, align 16
@.str = private unnamed_addr constant [16 x i8] c"fib[90] = %lld\0A\00", align 1

; Function Attrs: nofree norecurse nosync nounwind memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local void @compute_fib(i32 noundef %0) local_unnamed_addr #0 {
  store i64 0, ptr @fib, align 16, !tbaa !5
  store i64 1, ptr getelementptr inbounds nuw (i8, ptr @fib, i64 8), align 8, !tbaa !5
  %2 = icmp slt i32 %0, 2
  br i1 %2, label %7, label %3

3:                                                ; preds = %1
  %4 = add nuw i32 %0, 1
  %5 = zext i32 %4 to i64
  %6 = load i64, ptr getelementptr inbounds nuw (i8, ptr @fib, i64 8), align 8
  br label %8

7:                                                ; preds = %8, %1
  ret void

8:                                                ; preds = %3, %8
  %9 = phi i64 [ %6, %3 ], [ %14, %8 ]
  %10 = phi i64 [ 2, %3 ], [ %16, %8 ]
  %11 = add nsw i64 %10, -2
  %12 = getelementptr inbounds [100 x i64], ptr @fib, i64 0, i64 %11
  %13 = load i64, ptr %12, align 8, !tbaa !5
  %14 = add nsw i64 %13, %9
  %15 = getelementptr inbounds nuw [100 x i64], ptr @fib, i64 0, i64 %10
  store i64 %14, ptr %15, align 8, !tbaa !5
  %16 = add nuw nsw i64 %10, 1
  %17 = icmp eq i64 %16, %5
  br i1 %17, label %7, label %8, !llvm.loop !9
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 {
  store i64 0, ptr @fib, align 16, !tbaa !5
  store i64 1, ptr getelementptr inbounds nuw (i8, ptr @fib, i64 8), align 8, !tbaa !5
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i64 [ 1, %0 ], [ %7, %1 ]
  %3 = phi i64 [ 2, %0 ], [ %9, %1 ]
  %4 = add nsw i64 %3, -2
  %5 = getelementptr inbounds [100 x i64], ptr @fib, i64 0, i64 %4
  %6 = load i64, ptr %5, align 8, !tbaa !5
  %7 = add nsw i64 %6, %2
  %8 = getelementptr inbounds nuw [100 x i64], ptr @fib, i64 0, i64 %3
  store i64 %7, ptr %8, align 8, !tbaa !5
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 91
  br i1 %10, label %11, label %1, !llvm.loop !9

11:                                               ; preds = %1
  %12 = load i64, ptr getelementptr inbounds nuw (i8, ptr @fib, i64 720), align 16, !tbaa !5
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %12)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

attributes #0 = { nofree norecurse nosync nounwind memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"long long", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
