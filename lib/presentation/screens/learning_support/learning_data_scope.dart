import 'package:flutter/widgets.dart';
import '../../../data/repositories/learning_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';

/// Repository injection for widget tests; production uses API repositories.
class LearningDataScope extends InheritedWidget {
  final LearningRepository learning;
  final QuizRepository quiz;
  final FavoriteRepository favorites;
  final OrderRepository orders;
  final CourseRepository? courses;
  final ReviewRepository? reviews;
  const LearningDataScope({
    super.key,
    required this.learning,
    required this.quiz,
    required this.favorites,
    required this.orders,
    this.courses,
    this.reviews,
    required super.child,
  });
  static LearningDataScope? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LearningDataScope>();
  @override
  bool updateShouldNotify(LearningDataScope oldWidget) =>
      learning != oldWidget.learning ||
      quiz != oldWidget.quiz ||
      favorites != oldWidget.favorites ||
      orders != oldWidget.orders ||
      courses != oldWidget.courses ||
      reviews != oldWidget.reviews;
}
