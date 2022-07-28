import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'util/asset_entity_wrapper.dart';
import 'widgets/photo_card.dart';

final _dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
final _folderFormatter = DateFormat('yyyy/MM');

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

final folderNameFormatter = DateFormat('yyyy/MM');
final fileNameFormatter = DateFormat('yy-MM-dd HH-mm-ss');

class _HomePageState extends State<HomePage> {
  var page = 0;
  var pageSize = 100;
  var _pictures = <AssetEntityWrapper>[];

  @override
  initState() {
    super.initState();
    _loadPhotos().then(
      (pictures) {
        setState(() => _pictures = pictures);
      },
    );
    FlutterNativeSplash.remove();
  }

  Future<List<AssetEntityWrapper>> _loadPhotos() async {
    var permission = await PhotoManager.requestPermissionExtend();
    var pictures = <AssetEntityWrapper>[];
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

      pictures = wrappedAssets.where((e) => !e.deleteFlag).toList();
      //        //image: AssetEntityImage(
      //        //  picture,
      //        //  isOriginal: false, // Defaults to `true`.
      //        //  thumbnailSize:
      //        //      const ThumbnailSize.square(200), // Preferred value.
      //        //  thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
      //        //),

      for (var picture in pictures) {
        var file = await picture.entity.file;
        picture.folder = _folderFormatter.format(picture.entity.createDateTime);

        var id = picture.entity.id;
        if (Platform.isIOS) {
          var title = picture.entity.title!;
          id = title.substring(
              title.lastIndexOf('_') + 1, title.lastIndexOf('.'));
        }
        var filename =
            "${_dateFormatter.format(picture.entity.createDateTime)} $id";
        var extension =
            file!.path.substring(1 + file.path.lastIndexOf(".")).toLowerCase();
        picture.filename = "$filename.$extension";
        picture.destination = '${picture.folder}/$filename.$extension';
      }
    }
    return pictures;
  }

  @override
  Widget build(BuildContext context) {
    _processImages();
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

  Future<void> _processImages() async {
    if (_pictures.isNotEmpty) {
      await _upload(_pictures.first);
      setState(() => _pictures.removeAt(0));
    }
  }

  Future<void> _upload(AssetEntityWrapper picture) async {
    var token = '';
    var user = '';

    var file = await picture.entity.file;
    var length = await file?.length() ?? -1;

    if (mounted && length > 0) {
      var storage = context.read<FlutterSecureStorage>();
      user = (await storage.read(key: 'user'))!;
      var password = await storage.read(key: 'password');
      token = base64.encode(latin1.encode('$user:$password')).trim();

      var parts = picture.folder.split("/");
      var path = '';
      for (var part in parts) {
        path += '/$part';
        final response = await _send('MKCOL',
            'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path',
            localHeaders: {
              HttpHeaders.authorizationHeader: 'Basic $token',
            });
        debugPrint("folder: $path, statusCode : ${response.statusCode}");
      }

      debugPrint(
        "Checking if file exists : /Photos/photosync$path/${picture.filename}",
      );

      var response = await _send('PROPFIND',
          'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path/${picture.filename}',
          localHeaders: {
            HttpHeaders.authorizationHeader: 'Basic $token',
          });

      if (response.statusCode == 404) {
        debugPrint("File ${picture.destination} does not exist, uploading");
        var fileStream = file!.openRead();
        var response = await _send(
          'PUT',
          'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path/${picture.filename}',
          localHeaders: {
            HttpHeaders.authorizationHeader: 'Basic $token',
            HttpHeaders.contentTypeHeader: 'application/octet-stream',
            HttpHeaders.contentLengthHeader: length.toString(),
          },
          data: fileStream,
        );
        debugPrint("response: ${response.statusCode}");
        //var tempFolder = UniqueKey().toString().substring(2, 7);

        //response = await _send(
        //  'MKCOL',
        //  'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path/$tempFolder',
        //  localHeaders: {
        //    HttpHeaders.authorizationHeader: 'Basic $token',
        //  },
        //);

        //var fileStream = file!.openRead();
        //var start = 0;
        //var end = -1;
        //await for (var chunk in fileStream) {
        //  start = end + 1;
        //  debugPrint("Got a chuck of size ${chunk.length}");
        //  end = start + chunk.length - 1;
        //  var tempFile =
        //      "${"$start".padLeft(15, '0')}-${"$end".padLeft(15, '0')}";
        //  debugPrint("tempFile : $tempFile");

        //  response = await _send(
        //    'PUT',
        //    'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path/$tempFolder/$tempFile',
        //    localHeaders: {
        //      HttpHeaders.authorizationHeader: 'Basic $token',
        //      HttpHeaders.contentTypeHeader: 'application/octet-stream',
        //      HttpHeaders.contentLengthHeader: chunk.length.toString(),
        //    },
        //    data: Stream.value(chunk),
        //  );
        //  debugPrint("response: ${response.statusCode}");
        //}
        //debugPrint(
        //  "Stream is now closed, reconstructing file /Photos/photosync$path/${picture.filename} from /Photos/photosync$path/$tempFolder/.file",
        //);
        //response = await _send(
        //  'MOVE',
        //  'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path/$tempFolder/.file',
        //  localHeaders: {
        //    HttpHeaders.authorizationHeader: 'Basic $token',
        //    'Destination':
        //        'https://cloud.my-nanuq.com/remote.php/dav/files/$user/Photos/photosync$path/${picture.filename}',
        //  },
        //);
        //debugPrint("response: ${response.statusCode}");
      } else {
        debugPrint("File ${picture.destination} already exists, skipping");
      }

      //var bodyBytes = Uint8List.fromList((await response.toList())
      //    .reduce((final value, final element) => [...value, ...element]));
      //var body = utf8.decode(bodyBytes);
      //debugPrint("body: $body");

      //debugPrint(
      //  "tempFolder: $tempFolder, statusCode : ${response.statusCode}",
      //);
    }

    return Future.delayed(const Duration(seconds: 1));
  }

  Future<HttpClientResponse> _send(
    String command,
    String url, {
    Map<String, String>? localHeaders,
    Stream<List<int>>? data,
  }) async {
    var httpClient = HttpClient();
    final request = await httpClient.openUrl(command, Uri.parse(url))
      ..followRedirects = false
      ..persistentConnection = true;

    for (final header in {
      HttpHeaders.contentTypeHeader: 'application/xml',
      if (localHeaders != null) ...localHeaders,
    }.entries) {
      request.headers.add(header.key, header.value);
    }

    //var props = '<?xml version="1.0" encoding="UTF-8"?>'
    //    '<d:propfind xmlns:d="DAV:">'
    //    ' <d:prop xmlns:oc="http://owncloud.org/ns">'
    //    '   <d:getlastmodified/>'
    //    '   <d:getcontentlength/>'
    //    '   <d:getcontenttype/>'
    //    '   <oc:permissions/>'
    //    '   <d:resourcetype/>'
    //    '   <d:getetag/>'
    //    ' </d:prop>'
    //    '</d:propfind>';
    //var stream = Stream.value(Uint8List.fromList(utf8.encode(props)));
    if (data != null) await request.addStream(data);
    await request.flush();
    final response = await request.close();
    return response;
  }
}
