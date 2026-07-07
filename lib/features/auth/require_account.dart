import 'package:flutter/material.dart';

import '../../services/firebase/auth_service.dart';
import 'auth_sheet.dart';

/// Gate a communal action behind membership. If the visitor is already a
/// member, returns true immediately. Otherwise it presents the account sheet
/// with a contextual reason and returns whether they became a member.
///
///   if (!await requireAccount(context, action: 'pray for others')) return;
Future<bool> requireAccount(
  BuildContext context, {
  required String action,
}) async {
  if (AuthService.instance.isMember) return true;
  return presentAuthSheet(context, reason: 'Create an account to $action.');
}
