; ModuleID = 'src/bubblesort.c'
source_filename = "src/bubblesort.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@arr = dso_local local_unnamed_addr global [1024 x i32] zeroinitializer, align 16
@.str = private unnamed_addr constant [23 x i8] c"arr[0]=%d arr[N-1]=%d\0A\00", align 1

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @bubble_sort(ptr nocapture noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add i32 %1, -1
  %4 = icmp sgt i32 %1, 1
  br i1 %4, label %5, label %11

5:                                                ; preds = %2, %12
  %6 = phi i32 [ %14, %12 ], [ %3, %2 ]
  %7 = phi i32 [ %13, %12 ], [ 0, %2 ]
  %8 = icmp sgt i32 %3, %7
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = zext i32 %6 to i64
  br label %16

11:                                               ; preds = %12, %2
  ret void

12:                                               ; preds = %25, %5
  %13 = add nuw nsw i32 %7, 1
  %14 = add i32 %6, -1
  %15 = icmp eq i32 %13, %3
  br i1 %15, label %11, label %5, !llvm.loop !5

16:                                               ; preds = %9, %25
  %17 = phi i64 [ 0, %9 ], [ %20, %25 ]
  %18 = getelementptr inbounds nuw i32, ptr %0, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !8
  %20 = add nuw nsw i64 %17, 1
  %21 = getelementptr inbounds nuw i32, ptr %0, i64 %20
  %22 = load i32, ptr %21, align 4, !tbaa !8
  %23 = icmp sgt i32 %19, %22
  br i1 %23, label %24, label %25

24:                                               ; preds = %16
  store i32 %22, ptr %18, align 4, !tbaa !8
  store i32 %19, ptr %21, align 4, !tbaa !8
  br label %25

25:                                               ; preds = %16, %24
  %26 = icmp eq i64 %20, %10
  br i1 %26, label %12, label %16, !llvm.loop !12
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 {
  br label %23

1:                                                ; preds = %23, %4
  %2 = phi i64 [ %6, %4 ], [ 1023, %23 ]
  %3 = phi i32 [ %5, %4 ], [ 0, %23 ]
  br label %8

4:                                                ; preds = %17
  %5 = add nuw nsw i32 %3, 1
  %6 = add nsw i64 %2, -1
  %7 = icmp eq i32 %5, 1023
  br i1 %7, label %19, label %1, !llvm.loop !5

8:                                                ; preds = %17, %1
  %9 = phi i64 [ 0, %1 ], [ %12, %17 ]
  %10 = getelementptr inbounds nuw i32, ptr @arr, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !8
  %12 = add nuw nsw i64 %9, 1
  %13 = getelementptr inbounds nuw i32, ptr @arr, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !8
  %15 = icmp sgt i32 %11, %14
  br i1 %15, label %16, label %17

16:                                               ; preds = %8
  store i32 %14, ptr %10, align 4, !tbaa !8
  store i32 %11, ptr %13, align 4, !tbaa !8
  br label %17

17:                                               ; preds = %16, %8
  %18 = icmp eq i64 %12, %2
  br i1 %18, label %4, label %8, !llvm.loop !12

19:                                               ; preds = %4
  %20 = load i32, ptr @arr, align 16, !tbaa !8
  %21 = load i32, ptr getelementptr inbounds nuw (i8, ptr @arr, i64 4092), align 4, !tbaa !8
  %22 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %20, i32 noundef %21)
  ret i32 0

23:                                               ; preds = %0, %23
  %24 = phi i64 [ 0, %0 ], [ %28, %23 ]
  %25 = getelementptr inbounds nuw [1024 x i32], ptr @arr, i64 0, i64 %24
  %26 = trunc i64 %24 to i32
  %27 = sub i32 1024, %26
  store i32 %27, ptr %25, align 4, !tbaa !8
  %28 = add nuw nsw i64 %24, 1
  %29 = icmp eq i64 %28, 1024
  br i1 %29, label %1, label %23, !llvm.loop !13
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 20.1.8 (++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132)"}
!5 = distinct !{!5, !6, !7}
!6 = !{!"llvm.loop.mustprogress"}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = distinct !{!12, !6, !7}
!13 = distinct !{!13, !6, !7}
