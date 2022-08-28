// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

@immutable
class Item {
  String title;
  DateTime date;

  Item({
    required this.title,
    required this.date,
  });

  Item copyWith({
    String? title,
    DateTime? date,
  }) {
    return Item(
      title: title ?? this.title,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      title: map['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) =>
      Item.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Item(title: $title, date: $date)';

  @override
  bool operator ==(covariant Item other) {
    if (identical(this, other)) return true;

    return other.title == title && other.date == date;
  }

  @override
  int get hashCode => title.hashCode ^ date.hashCode;
}

class ItemsNotifier extends StateNotifier<List<Item>> {
  ItemsNotifier() : super(const []) {
    _init();
  }

  Future<void> _init() async {
    var permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: true,
            ),
          ],
          imageOption: const FilterOption(needTitle: true),
        ),
      );
      final path = paths.first;
      final List<AssetEntity> assets = await path.getAssetListPaged(
        page: 0,
        size: 20,
      );
      var items = <Item>[];
      for (var asset in assets) {
        var title = asset.title;
        if (title == null || title.isEmpty) {
          title = (await asset.file)?.path;
          if (title != null && title.isNotEmpty) {
            title = "IMG_${title.split("_IMG_")[1]}";
          }
        }
        items = [
          ...items,
          Item(
            title: title ?? '<unknown>',
            date: asset.createDateTime,
          ),
        ];
      }
      state = items;
    }
  }
}
