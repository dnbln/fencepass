; ModuleID = 'src/matrix_mul.c'
source_filename = "src/matrix_mul.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@A = dso_local local_unnamed_addr global [64 x [64 x double]] zeroinitializer, align 16
@B = dso_local local_unnamed_addr global [64 x [64 x double]] zeroinitializer, align 16
@C = dso_local local_unnamed_addr global [64 x [64 x double]] zeroinitializer, align 16
@.str = private unnamed_addr constant [14 x i8] c"C[0][0] = %f\0A\00", align 1

; Function Attrs: nofree norecurse nosync nounwind memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local void @matmul() local_unnamed_addr #0 {
  br label %1

1:                                                ; preds = %0, %6
  %2 = phi i64 [ 0, %0 ], [ %7, %6 ]
  br label %4

3:                                                ; preds = %6
  ret void

4:                                                ; preds = %1, %9
  %5 = phi i64 [ 0, %1 ], [ %11, %9 ]
  br label %13

6:                                                ; preds = %9
  %7 = add nuw nsw i64 %2, 1
  %8 = icmp eq i64 %7, 64
  br i1 %8, label %3, label %1, !llvm.loop !5

9:                                                ; preds = %13
  %10 = getelementptr inbounds nuw [64 x [64 x double]], ptr @C, i64 0, i64 %2, i64 %5
  store double %20, ptr %10, align 8, !tbaa !8
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 64
  br i1 %12, label %6, label %4, !llvm.loop !12

13:                                               ; preds = %4, %13
  %14 = phi i64 [ 0, %4 ], [ %21, %13 ]
  %15 = phi double [ 0.000000e+00, %4 ], [ %20, %13 ]
  %16 = getelementptr inbounds nuw [64 x [64 x double]], ptr @A, i64 0, i64 %2, i64 %14
  %17 = load double, ptr %16, align 8, !tbaa !8
  %18 = getelementptr inbounds nuw [64 x [64 x double]], ptr @B, i64 0, i64 %14, i64 %5
  %19 = load double, ptr %18, align 8, !tbaa !8
  %20 = tail call double @llvm.fmuladd.f64(double %17, double %19, double %15)
  %21 = add nuw nsw i64 %14, 1
  %22 = icmp eq i64 %21, 64
  br i1 %22, label %9, label %13, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #2 {
  br label %1

1:                                                ; preds = %0, %27
  %2 = phi i64 [ 0, %0 ], [ %28, %27 ]
  br label %30

3:                                                ; preds = %27, %7
  %4 = phi i64 [ %8, %7 ], [ 0, %27 ]
  br label %5

5:                                                ; preds = %10, %3
  %6 = phi i64 [ 0, %3 ], [ %12, %10 ]
  br label %14

7:                                                ; preds = %10
  %8 = add nuw nsw i64 %4, 1
  %9 = icmp eq i64 %8, 64
  br i1 %9, label %24, label %3, !llvm.loop !5

10:                                               ; preds = %14
  %11 = getelementptr inbounds nuw [64 x [64 x double]], ptr @C, i64 0, i64 %4, i64 %6
  store double %21, ptr %11, align 8, !tbaa !8
  %12 = add nuw nsw i64 %6, 1
  %13 = icmp eq i64 %12, 64
  br i1 %13, label %7, label %5, !llvm.loop !12

14:                                               ; preds = %14, %5
  %15 = phi i64 [ 0, %5 ], [ %22, %14 ]
  %16 = phi double [ 0.000000e+00, %5 ], [ %21, %14 ]
  %17 = getelementptr inbounds nuw [64 x [64 x double]], ptr @A, i64 0, i64 %4, i64 %15
  %18 = load double, ptr %17, align 8, !tbaa !8
  %19 = getelementptr inbounds nuw [64 x [64 x double]], ptr @B, i64 0, i64 %15, i64 %6
  %20 = load double, ptr %19, align 8, !tbaa !8
  %21 = tail call double @llvm.fmuladd.f64(double %18, double %20, double %16)
  %22 = add nuw nsw i64 %15, 1
  %23 = icmp eq i64 %22, 64
  br i1 %23, label %10, label %14, !llvm.loop !13

24:                                               ; preds = %7
  %25 = load double, ptr @C, align 16, !tbaa !8
  %26 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, double noundef %25)
  ret i32 0

27:                                               ; preds = %30
  %28 = add nuw nsw i64 %2, 1
  %29 = icmp eq i64 %28, 64
  br i1 %29, label %3, label %1, !llvm.loop !14

30:                                               ; preds = %1, %30
  %31 = phi i64 [ 0, %1 ], [ %40, %30 ]
  %32 = add nuw nsw i64 %31, %2
  %33 = trunc nuw nsw i64 %32 to i32
  %34 = uitofp nneg i32 %33 to double
  %35 = getelementptr inbounds nuw [64 x [64 x double]], ptr @A, i64 0, i64 %2, i64 %31
  store double %34, ptr %35, align 8, !tbaa !8
  %36 = sub nsw i64 %2, %31
  %37 = trunc nsw i64 %36 to i32
  %38 = sitofp i32 %37 to double
  %39 = getelementptr inbounds nuw [64 x [64 x double]], ptr @B, i64 0, i64 %2, i64 %31
  store double %38, ptr %39, align 8, !tbaa !8
  %40 = add nuw nsw i64 %31, 1
  %41 = icmp eq i64 %40, 64
  br i1 %41, label %27, label %30, !llvm.loop !15
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

attributes #0 = { nofree norecurse nosync nounwind memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!9 = !{!"double", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = distinct !{!12, !6, !7}
!13 = distinct !{!13, !6, !7}
!14 = distinct !{!14, !6, !7}
!15 = distinct !{!15, !6, !7}
