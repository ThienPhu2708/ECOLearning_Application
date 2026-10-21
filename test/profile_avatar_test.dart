import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecolearning_app/data/models/user.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/presentation/screens/profile/profile_avatar.dart';
import 'package:ecolearning_app/presentation/widgets/user_avatar.dart';

void main() {
  final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aY1sAAAAASUVORK5CYII=');
  User user(String id) => User(id: id, fullName: 'Ngọc', email: '', avatarUrl: '');
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('Đổi ảnh đại diện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }
  testWidgets('cancelled gallery selection leaves existing avatar unchanged', (tester) async {
    final account = user('cancel');
    int uploads = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileAvatar(user: account,
      pickImage: (source) async { expect(source, ImageSource.gallery); return null; },
      upload: (_) async { uploads++; return 'new-url'; },
    ))));
    await choose(tester, 'Chọn từ thư viện');
    expect(uploads, 0);
    expect(AvatarImages.forUser(account.id).value, isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('sample photo updates shared avatar without claiming server save', (tester) async {
    final account = user('sample');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileAvatar(user: account,
      pickImage: (source) async { expect(source, ImageSource.camera); return XFile.fromData(bytes, name: 'avatar.png'); },
    ))));
    await choose(tester, 'Chụp ảnh mới');
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(AvatarImages.forUser(account.id).value, bytes);
    expect(find.text('Đã đổi ảnh trong phiên dùng thử này.'), findsOneWidget);
  });
  testWidgets('upload failure preserves previous avatar and permits retry', (tester) async {
    final account = user('fail');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileAvatar(user: account,
      pickImage: (_) async => XFile.fromData(bytes, name: 'avatar.png'),
      upload: (_) async => throw const ApiException(message: 'Chưa tải được ảnh.'),
    ))));
    await choose(tester, 'Chọn từ thư viện');
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(AvatarImages.forUser(account.id).value, isNull);
    expect(find.text('Chưa tải được ảnh.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
