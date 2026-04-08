; ModuleID = 'src/quicksort.c'
source_filename = "src/quicksort.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@arr = dso_local global [2048 x i32] zeroinitializer, align 16
@.str = private unnamed_addr constant [23 x i8] c"arr[0]=%d arr[N-1]=%d\0A\00", align 1

; Function Attrs: nofree nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @quicksort(ptr noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  br label %4

4:                                                ; preds = %14, %3
  %5 = phi i32 [ %1, %3 ], [ %20, %14 ]
  %6 = icmp slt i32 %5, %2
  br i1 %6, label %7, label %36

7:                                                ; preds = %4
  %8 = sext i32 %2 to i64
  %9 = getelementptr inbounds i32, ptr %0, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !5
  %11 = add nsw i32 %5, -1
  %12 = sext i32 %5 to i64
  %13 = sext i32 %2 to i64
  br label %21

14:                                               ; preds = %32
  %15 = sext i32 %33 to i64
  %16 = getelementptr i32, ptr %0, i64 %15
  %17 = getelementptr i8, ptr %16, i64 4
  %18 = load i32, ptr %17, align 4, !tbaa !5
  %19 = load i32, ptr %9, align 4, !tbaa !5
  store i32 %19, ptr %17, align 4, !tbaa !5
  store i32 %18, ptr %9, align 4, !tbaa !5
  tail call void @quicksort(ptr noundef %0, i32 noundef %5, i32 noundef %33)
  %20 = add nsw i32 %33, 2
  br label %4

21:                                               ; preds = %7, %32
  %22 = phi i64 [ %12, %7 ], [ %34, %32 ]
  %23 = phi i32 [ %11, %7 ], [ %33, %32 ]
  %24 = getelementptr inbounds i32, ptr %0, i64 %22
  %25 = load i32, ptr %24, align 4, !tbaa !5
  %26 = icmp sgt i32 %25, %10
  br i1 %26, label %32, label %27

27:                                               ; preds = %21
  %28 = add nsw i32 %23, 1
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds i32, ptr %0, i64 %29
  %31 = load i32, ptr %30, align 4, !tbaa !5
  store i32 %25, ptr %30, align 4, !tbaa !5
  store i32 %31, ptr %24, align 4, !tbaa !5
  br label %32

32:                                               ; preds = %21, %27
  %33 = phi i32 [ %28, %27 ], [ %23, %21 ]
  %34 = add nsw i64 %22, 1
  %35 = icmp eq i64 %34, %13
  br i1 %35, label %14, label %21, !llvm.loop !9

36:                                               ; preds = %4
  ret void
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 {
  br label %5

1:                                                ; preds = %5
  tail call void @quicksort(ptr noundef nonnull @arr, i32 noundef 0, i32 noundef 2047)
  %2 = load i32, ptr @arr, align 16, !tbaa !5
  %3 = load i32, ptr getelementptr inbounds nuw (i8, ptr @arr, i64 8188), align 4, !tbaa !5
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %2, i32 noundef %3)
  ret i32 0

5:                                                ; preds = %0, %5
  %6 = phi i64 [ 0, %0 ], [ %10, %5 ]
  %7 = getelementptr inbounds nuw [2048 x i32], ptr @arr, i64 0, i64 %6
  %8 = trunc i64 %6 to i32
  %9 = sub i32 2048, %8
  store i32 %9, ptr %7, align 4, !tbaa !5
  %10 = add nuw nsw i64 %6, 1
  %11 = icmp eq i64 %10, 2048
  br i1 %11, label %1, label %5, !llvm.loop !12
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

attributes #0 = { nofree nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
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
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
