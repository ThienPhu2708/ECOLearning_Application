import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../data/models/user.dart';
import '../providers/auth_provider.dart';

User? currentUser(BuildContext context, {bool listen = false}) {
  return Provider.of<AuthProvider?>(context, listen: listen)?.user;
}
