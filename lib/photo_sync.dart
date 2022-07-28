import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photosync/authentication_page.dart';
import 'package:provider/provider.dart';

class PhotoSync extends StatelessWidget {
  const PhotoSync({Key? key}) : super(key: key);

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
