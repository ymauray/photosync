import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photosync/authentication_page.dart';
import 'package:provider/provider.dart';

import 'main_test_page.dart';

class PhotoSync extends StatelessWidget {
  const PhotoSync({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: MainTestPage(),
    );
  }
}

class PhotoSync2 extends StatelessWidget {
  const PhotoSync2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FlutterSecureStorage>(
          create: (context) => const FlutterSecureStorage(),
        ),
      ],
      child: const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: AuthenticationPage(),
      ),
    );
  }
}
