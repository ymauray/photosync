import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Photosync - Nextcloud login'),
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
              var regex = RegExp(r'^/server:(.*)&user:(.*)&password:(.*)$');
              var match = regex.firstMatch(path);
              var server = match!.group(1);
              var user = match.group(2);
              var password = match.group(3);
              var storage = const FlutterSecureStorage();
              await storage.write(key: 'user', value: user);
              await storage.write(key: 'password', value: password);
              await storage.write(key: 'server', value: server);
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      ),
    );
  }
}
