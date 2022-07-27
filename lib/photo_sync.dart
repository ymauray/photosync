import 'package:flutter/cupertino.dart';

import 'home_page.dart';

class PhotoSync extends StatelessWidget {
  const PhotoSync({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
