import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photosync/home_page.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  Future<bool> _authenticated() async {
    var user = await context.read<FlutterSecureStorage>().read(key: 'user');
    return (user ?? '').isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authenticated(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        if (snapshot.data!) {
          Future.delayed(const Duration(seconds: 1)).then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          });
          return Container();
        } else {
          FlutterNativeSplash.remove();
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('PhotoSync'),
            ),
            child: SafeArea(
              child: WebView(
                userAgent: 'PhotoSync',
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (webViewController) {
                  webViewController.loadUrl(
                    'https://cloud.my-nanuq.com/index.php/login/flow',
                    headers: {
                      'User-Agent': 'PhotoSync',
                      'Ocs-ApiRequest': 'true',
                    },
                  );
                },
                navigationDelegate: (navigation) async {
                  var uri = Uri.parse(navigation.url);
                  if (uri.scheme == 'nc' && uri.host == 'login') {
                    var path = uri.path;
                    var regex =
                        RegExp(r'^/server:(.*)&user:(.*)&password:(.*)$');
                    var match = regex.firstMatch(path);
                    var server = match!.group(1);
                    var user = match.group(2);
                    var password = match.group(3);
                    var storage = const FlutterSecureStorage();
                    await storage.write(key: 'user', value: user);
                    await storage.write(key: 'password', value: password);
                    await storage.write(key: 'server', value: server);
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        CupertinoPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    }
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            ),
          );
        }
      },
    );
  }
}
