//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateCollectionDto {
  /// Returns a new [UpdateCollectionDto] instance.
  UpdateCollectionDto({
    this.description = const Optional.absent(),
    this.name = const Optional.absent(),
    this.order = const Optional.absent(),
    this.parentId = const Optional.absent(),
    this.thumbnailAssetId = const Optional.absent(),
  });

  /// Collection description
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Optional<String?> description;

  /// Collection name
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Optional<String?> name;

  /// Manual sort position within the parent
  ///
  /// Minimum value: -9007199254740991
  /// Maximum value: 9007199254740991
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Optional<int?> order;

  /// New parent collection ID. Pass null to move to the root, omit to leave unchanged.
  Optional<String?> parentId;

  /// Collection thumbnail asset ID
  Optional<String?> thumbnailAssetId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateCollectionDto &&
    other.description == description &&
    other.name == name &&
    other.order == order &&
    other.parentId == parentId &&
    other.thumbnailAssetId == thumbnailAssetId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (description == null ? 0 : description!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (thumbnailAssetId == null ? 0 : thumbnailAssetId!.hashCode);

  @override
  String toString() => 'UpdateCollectionDto[description=$description, name=$name, order=$order, parentId=$parentId, thumbnailAssetId=$thumbnailAssetId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.order.isPresent) {
      final value = this.order.value;
      json[r'order'] = value;
    }
    if (this.parentId.isPresent) {
      final value = this.parentId.value;
      json[r'parentId'] = value;
    }
    if (this.thumbnailAssetId.isPresent) {
      final value = this.thumbnailAssetId.value;
      json[r'thumbnailAssetId'] = value;
    }
    return json;
  }

  /// Returns a new [UpdateCollectionDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateCollectionDto? fromJson(dynamic value) {
    upgradeDto(value, "UpdateCollectionDto");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return UpdateCollectionDto(
        description: json.containsKey(r'description') ? Optional.present(mapValueOfType<String>(json, r'description')) : const Optional.absent(),
        name: json.containsKey(r'name') ? Optional.present(mapValueOfType<String>(json, r'name')) : const Optional.absent(),
        order: json.containsKey(r'order') ? Optional.present(json[r'order'] == null ? null : int.parse('${json[r'order']}')) : const Optional.absent(),
        parentId: json.containsKey(r'parentId') ? Optional.present(mapValueOfType<String>(json, r'parentId')) : const Optional.absent(),
        thumbnailAssetId: json.containsKey(r'thumbnailAssetId') ? Optional.present(mapValueOfType<String>(json, r'thumbnailAssetId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateCollectionDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateCollectionDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateCollectionDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateCollectionDto> mapFromJson(dynamic json) {
    final map = <String, UpdateCollectionDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateCollectionDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateCollectionDto-objects as value to a dart map
  static Map<String, List<UpdateCollectionDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateCollectionDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateCollectionDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

