//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateCollectionDto {
  /// Returns a new [CreateCollectionDto] instance.
  CreateCollectionDto({
    this.description = const Optional.absent(),
    required this.name,
    this.order = const Optional.absent(),
    this.parentId = const Optional.absent(),
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
  String name;

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

  /// Parent collection ID (omit or null for a root collection)
  Optional<String?> parentId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateCollectionDto &&
    other.description == description &&
    other.name == name &&
    other.order == order &&
    other.parentId == parentId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (description == null ? 0 : description!.hashCode) +
    (name.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode);

  @override
  String toString() => 'CreateCollectionDto[description=$description, name=$name, order=$order, parentId=$parentId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
      json[r'name'] = this.name;
    if (this.order.isPresent) {
      final value = this.order.value;
      json[r'order'] = value;
    }
    if (this.parentId.isPresent) {
      final value = this.parentId.value;
      json[r'parentId'] = value;
    }
    return json;
  }

  /// Returns a new [CreateCollectionDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateCollectionDto? fromJson(dynamic value) {
    upgradeDto(value, "CreateCollectionDto");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return CreateCollectionDto(
        description: json.containsKey(r'description') ? Optional.present(mapValueOfType<String>(json, r'description')) : const Optional.absent(),
        name: mapValueOfType<String>(json, r'name')!,
        order: json.containsKey(r'order') ? Optional.present(json[r'order'] == null ? null : int.parse('${json[r'order']}')) : const Optional.absent(),
        parentId: json.containsKey(r'parentId') ? Optional.present(mapValueOfType<String>(json, r'parentId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateCollectionDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateCollectionDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateCollectionDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateCollectionDto> mapFromJson(dynamic json) {
    final map = <String, CreateCollectionDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateCollectionDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateCollectionDto-objects as value to a dart map
  static Map<String, List<CreateCollectionDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateCollectionDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateCollectionDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

