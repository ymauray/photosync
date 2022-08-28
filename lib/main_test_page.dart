import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'nextcloud.dart';

class MainTestPage extends StatelessWidget {
  const MainTestPage({Key? key}) : super(key: key);

  Future<bool> isLoggedIn() async {
    const storage = FlutterSecureStorage();
    String? username = await storage.read(key: 'user');
    if (username == null) {
      return false;
    }
    var password = await storage.read(key: 'password');
    var token = base64.encode(latin1.encode('$username:$password')).trim();

    final response = await nextcloudSend(
      'PROPFIND',
      'https://cloud.my-nanuq.com/remote.php/dav/files/$username/',
      localHeaders: {
        HttpHeaders.authorizationHeader: 'Basic $token',
      },
    );

    return response.statusCode == 207;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        } else {
          FlutterNativeSplash.remove();
          return (snapshot.data ?? false)
              ? const HomePage()
              : const LoginPage();
        }
      },
    );
    // debugPrint("MainTestPage.build");
    // (() async {
    //   var permission = await PhotoManager.requestPermissionExtend();
    //   if (permission.isAuth) {
    //     final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
    //       onlyAll: true,
    //       filterOption: FilterOptionGroup(
    //         orders: [
    //           const OrderOption(
    //             type: OrderOptionType.createDate,
    //             asc: true,
    //           ),
    //         ],
    //         imageOption: const FilterOption(needTitle: true),
    //       ),
    //     );
    //     for (final path in paths) {
    //       debugPrint("path: ${path.name}");
    //       final List<AssetEntity> assets = await path.getAssetListPaged(
    //         page: 0,
    //         size: 20,
    //       );
    //       for (final asset in assets) {
    //         var title = asset.title;
    //         File? file;
    //         if (title == null || title.isEmpty) {
    //           file = await asset.fileWithSubtype;
    //         }
    //         debugPrint("asset: $title, ${file?.path} ${asset.createDateTime}");
    //       }
    //     }
    //     PhotoManager.clearFileCache();
    //   }
    // })();
    //return Container();
  }
}
