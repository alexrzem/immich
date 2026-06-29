//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CollectionResponseDto {
  /// Returns a new [CollectionResponseDto] instance.
  CollectionResponseDto({
    required this.albumCount,
    this.albumIds = const [],
    required this.childCount,
    required this.createdAt,
    required this.description,
    required this.id,
    required this.name,
    required this.order,
    required this.ownerId,
    required this.parentId,
    required this.thumbnailAssetId,
    required this.updatedAt,
  });

  /// Number of albums directly in this collection
  ///
  /// Minimum value: 0
  /// Maximum value: 9007199254740991
  int albumCount;

  /// IDs of albums directly in this collection
  List<String> albumIds;

  /// Number of direct sub-collections
  ///
  /// Minimum value: 0
  /// Maximum value: 9007199254740991
  int childCount;

  /// Creation date
  DateTime createdAt;

  /// Collection description
  String description;

  /// Collection ID
  String id;

  /// Collection name
  String name;

  /// Manual sort position within the parent
  ///
  /// Minimum value: -9007199254740991
  /// Maximum value: 9007199254740991
  int order;

  /// Owner ID
  String ownerId;

  /// Parent collection ID
  String? parentId;

  /// Thumbnail asset ID
  String? thumbnailAssetId;

  /// Last update date
  DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CollectionResponseDto &&
    other.albumCount == albumCount &&
    _deepEquality.equals(other.albumIds, albumIds) &&
    other.childCount == childCount &&
    other.createdAt == createdAt &&
    other.description == description &&
    other.id == id &&
    other.name == name &&
    other.order == order &&
    other.ownerId == ownerId &&
    other.parentId == parentId &&
    other.thumbnailAssetId == thumbnailAssetId &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (albumCount.hashCode) +
    (albumIds.hashCode) +
    (childCount.hashCode) +
    (createdAt.hashCode) +
    (description.hashCode) +
    (id.hashCode) +
    (name.hashCode) +
    (order.hashCode) +
    (ownerId.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (thumbnailAssetId == null ? 0 : thumbnailAssetId!.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'CollectionResponseDto[albumCount=$albumCount, albumIds=$albumIds, childCount=$childCount, createdAt=$createdAt, description=$description, id=$id, name=$name, order=$order, ownerId=$ownerId, parentId=$parentId, thumbnailAssetId=$thumbnailAssetId, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'albumCount'] = this.albumCount;
      json[r'albumIds'] = this.albumIds;
      json[r'childCount'] = this.childCount;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'description'] = this.description;
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'order'] = this.order;
      json[r'ownerId'] = this.ownerId;
    if (this.parentId != null) {
      json[r'parentId'] = this.parentId;
    } else {
      json[r'parentId'] = null;
    }
    if (this.thumbnailAssetId != null) {
      json[r'thumbnailAssetId'] = this.thumbnailAssetId;
    } else {
      json[r'thumbnailAssetId'] = null;
    }
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [CollectionResponseDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollectionResponseDto? fromJson(dynamic value) {
    upgradeDto(value, "CollectionResponseDto");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return CollectionResponseDto(
        albumCount: mapValueOfType<int>(json, r'albumCount')!,
        albumIds: json[r'albumIds'] is Iterable
            ? (json[r'albumIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        childCount: mapValueOfType<int>(json, r'childCount')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        description: mapValueOfType<String>(json, r'description')!,
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        order: mapValueOfType<int>(json, r'order')!,
        ownerId: mapValueOfType<String>(json, r'ownerId')!,
        parentId: mapValueOfType<String>(json, r'parentId'),
        thumbnailAssetId: mapValueOfType<String>(json, r'thumbnailAssetId'),
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<CollectionResponseDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CollectionResponseDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollectionResponseDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollectionResponseDto> mapFromJson(dynamic json) {
    final map = <String, CollectionResponseDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollectionResponseDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollectionResponseDto-objects as value to a dart map
  static Map<String, List<CollectionResponseDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CollectionResponseDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollectionResponseDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'albumCount',
    'albumIds',
    'childCount',
    'createdAt',
    'description',
    'id',
    'name',
    'order',
    'ownerId',
    'parentId',
    'thumbnailAssetId',
    'updatedAt',
  };
}

