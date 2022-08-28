import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'item.dart';

final tokenProvider = FutureProvider<String>((ref) async {
  const storage = FlutterSecureStorage();
  var username = await storage.read(key: 'user');
  var password = await storage.read(key: 'password');
  var token = base64.encode(latin1.encode('$username:$password')).trim();

  return token;
});

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<Item>>((ref) => ItemsNotifier());
