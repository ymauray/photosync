import 'package:exif/exif.dart';
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
    required this.image,
  });

  final String title;
  final String destination;
  final int createDateSecond;
  final Widget image;
}

class _HomePageState extends State<HomePage> {
  final dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
  final folderFormatter = DateFormat('yyyy/MM');

  Future<List<PhotoMeta>> init() async {
    var permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      var output = <PhotoMeta>[];
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        ),
      );

      final List<AssetEntity> pictures =
          await paths.first.getAssetListPaged(page: 0, size: 100);

      for (var picture in pictures) {
        if (await picture.isLocallyAvailable()) {
          var file = await picture.file;
          var data = await readExifFromBytes(file!.readAsBytesSync());
          debugPrint(data.toString());
          var folder = folderFormatter.format(picture.createDateTime);
          var filename =
              "${dateFormatter.format(picture.createDateTime)} ${picture.id}";
          var title = await picture.titleAsync;
          var extension =
              title.substring(1 + title.lastIndexOf(".")).toLowerCase();
          var destination = '$folder/$filename.$extension';
          output.add(
            PhotoMeta(
              title: title,
              destination: destination,
              createDateSecond: picture.createDateSecond ?? 0,
              image: AssetEntityImage(
                picture,
                isOriginal: false, // Defaults to `true`.
                thumbnailSize:
                    const ThumbnailSize.square(200), // Preferred value.
                thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
              ),
            ),
          );
        }
      }

      //output.sort((a, b) {
      //  if ((a.destination == '<folder>') && (b.destination == '<folder>')) {
      //    return a.title.compareTo(b.title);
      //  } else if (a.destination == '<folder>') {
      //    return -1;
      //  } else if (b.destination == '<folder>') {
      //    return 1;
      //  } else {
      //    return a.createDateSecond - b.createDateSecond;
      //  }
      //});

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
          return snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData
              ? Material(
                  child: CupertinoScrollbar(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(snapshot.data![index].title),
                        subtitle: Text(snapshot.data![index].destination),
                        leading: snapshot.data![index].image,
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
