import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/data/repositories/review_repository.dart';
import 'package:ecolearning_app/presentation/screens/learning/review_flow.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';

class Details extends CourseRepository {
  final Course course;
  Details(this.course);
  @override
  Future<Course> detail(String id) async => course;
}
class Reviews extends ReviewRepository {
  int deletes = 0;
  bool fail = true;
  @override
  Future<void> delete(String id) async {
    deletes++;
    if (fail) throw const ApiException(message: 'Không xóa được', code: 'OFFLINE');
  }
}
void main() {
  testWidgets('review view has no delete action', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final course = Course.fromJson({'id':'c', 'title':'Course', 'canReview':true, 'myReview':{'rating':5,'comment':'Tốt'}});
    final repo = Reviews();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => openCourseReview(context, course, courses: Details(course), reviews: repo), child: const Text('Mở'))))));
    await tester.tap(find.text('Mở')); await tester.pumpAndSettle();
    expect(find.text('Xóa đánh giá'), findsNothing);
    expect(find.text('Sửa đánh giá'), findsOneWidget);
    expect(find.text('Tốt'), findsOneWidget);
    expect(repo.deletes, 0);
    await tester.tap(find.text('Đóng')); await tester.pumpAndSettle();
    expect(course.myReviewRating, 5);
  });
}
