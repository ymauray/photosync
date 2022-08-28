import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'photo_sync.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: PhotoSync()));
}

void main2() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PhotoSync2());
}

Future<bool> init() async {
  // await storage.write(key: 'username', value: 'yannick');
  // await storage.write(
  //   key: 'password',
  //   value:
  //       'gvlH2fSwpPvjZIf4vgwHQts4GOSaLibBsjJz98bTK371W9neE8zs9iQI3nBcKEdrmIWyUR7d',
  // );
  // await storage.write(key: 'server', value: 'https://cloud.my-nanuq.com');
  var storage = const FlutterSecureStorage();
  String? username = await storage.read(key: 'user');
  //debugPrint("All done");

  //final PermissionState ps = await PhotoManager.requestPermissionExtend();
  //final dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
  //final folderFormatter = DateFormat('yyyy/MM');

  //if (ps.isAuth) {
  //  final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
  //  final picturesFolder = paths.where((path) => path.name == 'Pictures').first;
  //  final List<AssetEntity> pictures =
  //      await picturesFolder.getAssetListPaged(page: 0, size: 100);
  //  for (var picture in pictures) {
  //    var mimeType = await picture.mimeTypeAsync;
  //    var title = await picture.titleAsync;
  //    var folder = folderFormatter.format(picture.createDateTime);
  //    var file =
  //        "${dateFormatter.format(picture.createDateTime)} ${picture.id}";
  //    var destination = '$folder/$file.jpg';

  //    debugPrint("id : ${picture.id}, "
  //        "width: ${picture.width}, "
  //        "height: ${picture.height}, "
  //        "createDateTime: ${dateFormatter.format(picture.createDateTime)}, "
  //        "destination: $destination, "
  //        "title: $title, "
  //        "mimeType: $mimeType, ");
  //  }
  //} else {
  //  debugPrint("Permission denied");
  //}

  return username != null && username.isNotEmpty;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PhotoSync',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: WebView(
        userAgent: 'PhotoSync',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (webViewController) {
          //widget.controller.complete(webViewController);
          webViewController.loadUrl(
            'https://cloud.my-nanuq.com/index.php/login/flow',
            headers: {
              'User-Agent': 'PhotoSync',
              'Ocs-ApiRequest': 'true',
            },
          );
        },
        navigationDelegate: (navigation) {
          debugPrint("navigationDelegate : ${navigation.toString()}");
          var uri = Uri.parse(navigation.url);
          if (uri.scheme == 'nc' && uri.host == 'login') {
            _navigatorKey.currentState?.pushNamed('/login');
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}
