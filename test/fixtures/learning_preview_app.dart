import 'package:flutter/material.dart';
import 'package:ecolearning_app/core/theme/app_theme.dart';
import 'package:ecolearning_app/presentation/screens/main_navigation.dart';
import 'package:ecolearning_app/presentation/screens/learning_support/learning_data_scope.dart';
import 'preview_repositories.dart';
import 'package:provider/provider.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'mock_data.dart';

void main() => runApp(const LearningPreviewApp());

/// The complete existing app shell, using sample learning data until the API is ready.
class LearningPreviewApp extends StatefulWidget {
  const LearningPreviewApp({super.key});
  @override
  State<LearningPreviewApp> createState() => _LearningPreviewAppState();
}

class _LearningPreviewAppState extends State<LearningPreviewApp> {
  final quiz = PreviewQuizRepository(persistent: true);
  final auth = FixtureAuth()..updateUser(MockData.currentUser);
  late final learning = PreviewLearningRepository(
    quiz: quiz,
    publicVideo: true,
  );
  final favorites = PreviewFavoriteRepository();
  final orders = PreviewOrderRepository();
  late final courses = PreviewCourseRepository(learning, quiz);
  late final reviews = PreviewReviewRepository(learning, quiz);
  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: LearningDataScope(
          learning: learning,
          quiz: quiz,
          favorites: favorites,
          orders: orders,
          courses: courses,
          recommendations: PreviewRecommendationRepository(),
          reviews: reviews,
          child: MaterialApp(
            title: 'ECOLearning',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const MainNavigationScreen(),
          ),
        ),
      );
}

class FixtureAuth extends AuthProvider {
  @override
  bool get isLoggedIn => true;
}
