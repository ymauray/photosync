import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoCard extends StatefulWidget {
  const PhotoCard({
    Key? key,
    required AssetEntity picture,
  })  : _picture = picture,
        super(key: key);

  final AssetEntity _picture;

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  var destination = '';
  var _isLoading = false;

  final dateFormatter = DateFormat('yy-MM-dd HH-mm-ss');
  final folderFormatter = DateFormat('yyyy/MM');

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
