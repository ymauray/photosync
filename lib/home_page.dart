import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

final dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
final folderFormatter = DateFormat('yyyy/MM');

class AssetEntityWrapper {
  AssetEntityWrapper(this.entity);

  final AssetEntity entity;
  bool deleteFlag = false;
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var page = 0;
  var pageSize = 100;
  var _pictures = <AssetEntity>[];

  @override
  initState() {
    super.initState();
    _loadPhotos().then((pictures) => setState(() => _pictures = pictures));
  }

  Future<List<AssetEntity>> _loadPhotos() async {
    var permission = await PhotoManager.requestPermissionExtend();
    var pictures = <AssetEntity>[];
    if (permission.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
          imageOption: const FilterOption(needTitle: true),
        ),
      );

      final rootPath = paths.first;

      var assets = await rootPath.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      var wrappedAssets = assets
          .where((e) => (e.title ?? '').toLowerCase().startsWith("img_"))
          .map((asset) => AssetEntityWrapper(asset));

      for (var wrappedAsset in wrappedAssets) {
        var locallyAvailable = await wrappedAsset.entity.isLocallyAvailable();
        if (!locallyAvailable || wrappedAsset.entity.title == null) {
          wrappedAsset.deleteFlag = true;
        }
      }

      pictures = wrappedAssets
          .where((e) => !e.deleteFlag)
          .map((e) => e.entity)
          .toList();
      //        //image: AssetEntityImage(
      //        //  picture,
      //        //  isOriginal: false, // Defaults to `true`.
      //        //  thumbnailSize:
      //        //      const ThumbnailSize.square(200), // Preferred value.
      //        //  thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
      //        //),
    }
    return pictures;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('PhotoSync'),
      ),
      child: Material(
        child: CupertinoScrollbar(
          child: ListView.builder(
            itemCount: _pictures.length,
            itemBuilder: (context, index) =>
                _PhotoCard(picture: _pictures[index]),
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatefulWidget {
  const _PhotoCard({
    Key? key,
    required AssetEntity picture,
  })  : _picture = picture,
        super(key: key);

  final AssetEntity _picture;

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  var destination = '';
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    var title = widget._picture.title!;
    var folder = folderFormatter.format(widget._picture.createDateTime);
    var id = widget._picture.id;
    if (Platform.isIOS) {
      id = title.substring(title.lastIndexOf('_') + 1, title.lastIndexOf('.'));
    }
    var filename =
        "${dateFormatter.format(widget._picture.createDateTime)} $id";
    var extension = title.substring(1 + title.lastIndexOf(".")).toLowerCase();
    destination = '$folder/$filename.$extension';

    Future.delayed(Duration(seconds: Random.secure().nextInt(5)), () {
      setState(() {
        _isLoading = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: widget._picture.file,
      builder: (context, snapshot) {
        var path = snapshot.data?.path ?? '';
        var file = path.substring(path.lastIndexOf('/') + 1);
        return ListTile(
          title: Text(widget._picture.title!),
          subtitle: Text(file),
          //leading: snapshot.data![index].image,
          trailing: _isLoading ? const CircularProgressIndicator() : null,
        );
      },
    );
  }
}
