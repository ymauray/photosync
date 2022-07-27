import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class PhotoMeta {
  PhotoMeta({
    required this.title,
    required this.destination,
    required this.createDateSecond,
  });

  final String title;
  final String destination;
  final int createDateSecond;
}

class _HomePageState extends State<HomePage> {
  final dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
  final folderFormatter = DateFormat('yyyy/MM');

  Future<List<PhotoMeta>> init() async {
    var permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      var output = <PhotoMeta>[];
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
      output.addAll(
        paths.map(
          (path) => PhotoMeta(
            title: path.name,
            destination: '<folder>',
            createDateSecond: 0,
          ),
        ),
      );

      if (paths.any((path) => path.name == 'Pictures')) {
        var picturesFolder =
            paths.where((path) => path.name == 'Pictures').first;
        final List<AssetEntity> pictures =
            await picturesFolder.getAssetListPaged(page: 0, size: 100);

        for (var picture in pictures) {
          var folder = folderFormatter.format(picture.createDateTime);
          var file =
              "${dateFormatter.format(picture.createDateTime)} ${picture.id}";
          var title = await picture.titleAsync;
          var extension =
              title.substring(1 + title.lastIndexOf(".")).toLowerCase();
          var destination = '$folder/$file.$extension';
          output.add(
            PhotoMeta(
              title: title,
              destination: destination,
              createDateSecond: picture.createDateSecond ?? 0,
            ),
          );
        }
        output.sort((a, b) {
          if ((a.destination == '<folder>') && (b.destination == '<folder>')) {
            return a.title.compareTo(b.title);
          } else if (a.destination == '<folder>') {
            return -1;
          } else if (b.destination == '<folder>') {
            return 1;
          } else {
            return a.createDateSecond - b.createDateSecond;
          }
        });
      }

      return output;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('PhotoSync'),
      ),
      child: FutureBuilder<List<PhotoMeta>>(
        future: init(),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? Material(
                  child: CupertinoScrollbar(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(snapshot.data![index].title),
                        subtitle: Text(snapshot.data![index].destination),
                      ),
                    ),
                  ),
                )
              : Container();
        },
      ),
    );
  }
}
