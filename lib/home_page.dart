import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'util/asset_entity_wrapper.dart';
import 'util/photo_card.dart';

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
                PhotoCard(picture: _pictures[index]),
          ),
        ),
      ),
    );
  }
}
