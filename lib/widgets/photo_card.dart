import 'package:flutter/material.dart';

import '../util/asset_entity_wrapper.dart';

class PhotoCard extends StatefulWidget {
  const PhotoCard({
    Key? key,
    required AssetEntityWrapper picture,
  })  : _picture = picture,
        super(key: key);

  final AssetEntityWrapper _picture;

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  final _isLoading = false;

  //final _dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
  //final _folderFormatter = DateFormat('yyyy/MM');

  @override
  void initState() {
    super.initState();
    //widget._picture.file.then((file) {
    //  var folder = _folderFormatter.format(widget._picture.createDateTime);

    //  var id = widget._picture.id;
    //  if (Platform.isIOS) {
    //    var title = widget._picture.title!;
    //    id =
    //        title.substring(title.lastIndexOf('_') + 1, title.lastIndexOf('.'));
    //  }
    //  var filename =
    //      "${_dateFormatter.format(widget._picture.createDateTime)} $id";
    //  var extension =
    //      file!.path.substring(1 + file.path.lastIndexOf(".")).toLowerCase();
    //  setState(() {
    //    _destination = '$folder/$filename.$extension';
    //  });
    //});
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget._picture.destination),
      //subtitle: Text(file),
      //leading: snapshot.data![index].image,
      trailing: _isLoading ? const CircularProgressIndicator() : null,
    );
  }
}
