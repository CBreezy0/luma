// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPhotoRecordCollection on Isar {
  IsarCollection<PhotoRecord> get photoRecords => this.collection();
}

const PhotoRecordSchema = CollectionSchema(
  name: r'PhotoRecord',
  id: 3083817705269518407,
  properties: {
    r'activeVersionId': PropertySchema(
      id: 0,
      name: r'activeVersionId',
      type: IsarType.string,
    ),
    r'albumTagsJson': PropertySchema(
      id: 1,
      name: r'albumTagsJson',
      type: IsarType.string,
    ),
    r'aperture': PropertySchema(
      id: 2,
      name: r'aperture',
      type: IsarType.double,
    ),
    r'captureDateMs': PropertySchema(
      id: 3,
      name: r'captureDateMs',
      type: IsarType.long,
    ),
    r'captureIdentifier': PropertySchema(
      id: 4,
      name: r'captureIdentifier',
      type: IsarType.string,
    ),
    r'colorLabel': PropertySchema(
      id: 5,
      name: r'colorLabel',
      type: IsarType.string,
    ),
    r'editedFilePath': PropertySchema(
      id: 6,
      name: r'editedFilePath',
      type: IsarType.string,
    ),
    r'focalLength': PropertySchema(
      id: 7,
      name: r'focalLength',
      type: IsarType.double,
    ),
    r'format': PropertySchema(id: 8, name: r'format', type: IsarType.string),
    r'hasEdits': PropertySchema(id: 9, name: r'hasEdits', type: IsarType.bool),
    r'height': PropertySchema(id: 10, name: r'height', type: IsarType.long),
    r'importedDateMs': PropertySchema(
      id: 11,
      name: r'importedDateMs',
      type: IsarType.long,
    ),
    r'isEdited': PropertySchema(id: 12, name: r'isEdited', type: IsarType.bool),
    r'isFavorite': PropertySchema(
      id: 13,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'isImported': PropertySchema(
      id: 14,
      name: r'isImported',
      type: IsarType.bool,
    ),
    r'isRaw': PropertySchema(id: 15, name: r'isRaw', type: IsarType.bool),
    r'iso': PropertySchema(id: 16, name: r'iso', type: IsarType.double),
    r'lastEditedAtMs': PropertySchema(
      id: 17,
      name: r'lastEditedAtMs',
      type: IsarType.long,
    ),
    r'lens': PropertySchema(id: 18, name: r'lens', type: IsarType.string),
    r'location': PropertySchema(
      id: 19,
      name: r'location',
      type: IsarType.string,
    ),
    r'originalFilePath': PropertySchema(
      id: 20,
      name: r'originalFilePath',
      type: IsarType.string,
    ),
    r'photoId': PropertySchema(id: 21, name: r'photoId', type: IsarType.string),
    r'rating': PropertySchema(id: 22, name: r'rating', type: IsarType.long),
    r'resolution': PropertySchema(
      id: 23,
      name: r'resolution',
      type: IsarType.string,
    ),
    r'shutterSpeed': PropertySchema(
      id: 24,
      name: r'shutterSpeed',
      type: IsarType.string,
    ),
    r'simulationId': PropertySchema(
      id: 25,
      name: r'simulationId',
      type: IsarType.string,
    ),
    r'thumbnailPath': PropertySchema(
      id: 26,
      name: r'thumbnailPath',
      type: IsarType.string,
    ),
    r'versionsJson': PropertySchema(
      id: 27,
      name: r'versionsJson',
      type: IsarType.string,
    ),
    r'width': PropertySchema(id: 28, name: r'width', type: IsarType.long),
  },
  estimateSize: _photoRecordEstimateSize,
  serialize: _photoRecordSerialize,
  deserialize: _photoRecordDeserialize,
  deserializeProp: _photoRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'photoId': IndexSchema(
      id: -1877533456151046685,
      name: r'photoId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'photoId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'captureDateMs': IndexSchema(
      id: 4314549383730651494,
      name: r'captureDateMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'captureDateMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'captureIdentifier': IndexSchema(
      id: -8703845986514604199,
      name: r'captureIdentifier',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'captureIdentifier',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'importedDateMs': IndexSchema(
      id: 5643946234620198839,
      name: r'importedDateMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'importedDateMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'format': IndexSchema(
      id: -5115469427096626106,
      name: r'format',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'format',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isFavorite': IndexSchema(
      id: 5742774614603939776,
      name: r'isFavorite',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isFavorite',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'rating': IndexSchema(
      id: 3934517271104932818,
      name: r'rating',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rating',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'colorLabel': IndexSchema(
      id: 8355619933028580449,
      name: r'colorLabel',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'colorLabel',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isImported': IndexSchema(
      id: -7437563992851340482,
      name: r'isImported',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isImported',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'isRaw': IndexSchema(
      id: -1234370218797795964,
      name: r'isRaw',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isRaw',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'isEdited': IndexSchema(
      id: -5801961999792417715,
      name: r'isEdited',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isEdited',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'hasEdits': IndexSchema(
      id: 3176515439575293122,
      name: r'hasEdits',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'hasEdits',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'lastEditedAtMs': IndexSchema(
      id: -7524301036198637562,
      name: r'lastEditedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastEditedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _photoRecordGetId,
  getLinks: _photoRecordGetLinks,
  attach: _photoRecordAttach,
  version: '3.1.0+1',
);

int _photoRecordEstimateSize(
  PhotoRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.activeVersionId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.albumTagsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.captureIdentifier.length * 3;
  {
    final value = object.colorLabel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.editedFilePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.format.length * 3;
  {
    final value = object.lens;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.location;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.originalFilePath.length * 3;
  bytesCount += 3 + object.photoId.length * 3;
  {
    final value = object.resolution;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shutterSpeed;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.simulationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.thumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.versionsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _photoRecordSerialize(
  PhotoRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activeVersionId);
  writer.writeString(offsets[1], object.albumTagsJson);
  writer.writeDouble(offsets[2], object.aperture);
  writer.writeLong(offsets[3], object.captureDateMs);
  writer.writeString(offsets[4], object.captureIdentifier);
  writer.writeString(offsets[5], object.colorLabel);
  writer.writeString(offsets[6], object.editedFilePath);
  writer.writeDouble(offsets[7], object.focalLength);
  writer.writeString(offsets[8], object.format);
  writer.writeBool(offsets[9], object.hasEdits);
  writer.writeLong(offsets[10], object.height);
  writer.writeLong(offsets[11], object.importedDateMs);
  writer.writeBool(offsets[12], object.isEdited);
  writer.writeBool(offsets[13], object.isFavorite);
  writer.writeBool(offsets[14], object.isImported);
  writer.writeBool(offsets[15], object.isRaw);
  writer.writeDouble(offsets[16], object.iso);
  writer.writeLong(offsets[17], object.lastEditedAtMs);
  writer.writeString(offsets[18], object.lens);
  writer.writeString(offsets[19], object.location);
  writer.writeString(offsets[20], object.originalFilePath);
  writer.writeString(offsets[21], object.photoId);
  writer.writeLong(offsets[22], object.rating);
  writer.writeString(offsets[23], object.resolution);
  writer.writeString(offsets[24], object.shutterSpeed);
  writer.writeString(offsets[25], object.simulationId);
  writer.writeString(offsets[26], object.thumbnailPath);
  writer.writeString(offsets[27], object.versionsJson);
  writer.writeLong(offsets[28], object.width);
}

PhotoRecord _photoRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PhotoRecord();
  object.activeVersionId = reader.readStringOrNull(offsets[0]);
  object.albumTagsJson = reader.readStringOrNull(offsets[1]);
  object.aperture = reader.readDoubleOrNull(offsets[2]);
  object.captureDateMs = reader.readLong(offsets[3]);
  object.captureIdentifier = reader.readString(offsets[4]);
  object.colorLabel = reader.readStringOrNull(offsets[5]);
  object.editedFilePath = reader.readStringOrNull(offsets[6]);
  object.focalLength = reader.readDoubleOrNull(offsets[7]);
  object.format = reader.readString(offsets[8]);
  object.hasEdits = reader.readBool(offsets[9]);
  object.height = reader.readLongOrNull(offsets[10]);
  object.id = id;
  object.importedDateMs = reader.readLong(offsets[11]);
  object.isEdited = reader.readBool(offsets[12]);
  object.isFavorite = reader.readBool(offsets[13]);
  object.isImported = reader.readBool(offsets[14]);
  object.isRaw = reader.readBool(offsets[15]);
  object.iso = reader.readDoubleOrNull(offsets[16]);
  object.lastEditedAtMs = reader.readLongOrNull(offsets[17]);
  object.lens = reader.readStringOrNull(offsets[18]);
  object.location = reader.readStringOrNull(offsets[19]);
  object.originalFilePath = reader.readString(offsets[20]);
  object.photoId = reader.readString(offsets[21]);
  object.rating = reader.readLong(offsets[22]);
  object.resolution = reader.readStringOrNull(offsets[23]);
  object.shutterSpeed = reader.readStringOrNull(offsets[24]);
  object.simulationId = reader.readStringOrNull(offsets[25]);
  object.thumbnailPath = reader.readStringOrNull(offsets[26]);
  object.versionsJson = reader.readStringOrNull(offsets[27]);
  object.width = reader.readLongOrNull(offsets[28]);
  return object;
}

P _photoRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _photoRecordGetId(PhotoRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _photoRecordGetLinks(PhotoRecord object) {
  return [];
}

void _photoRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  PhotoRecord object,
) {
  object.id = id;
}

extension PhotoRecordByIndex on IsarCollection<PhotoRecord> {
  Future<PhotoRecord?> getByPhotoId(String photoId) {
    return getByIndex(r'photoId', [photoId]);
  }

  PhotoRecord? getByPhotoIdSync(String photoId) {
    return getByIndexSync(r'photoId', [photoId]);
  }

  Future<bool> deleteByPhotoId(String photoId) {
    return deleteByIndex(r'photoId', [photoId]);
  }

  bool deleteByPhotoIdSync(String photoId) {
    return deleteByIndexSync(r'photoId', [photoId]);
  }

  Future<List<PhotoRecord?>> getAllByPhotoId(List<String> photoIdValues) {
    final values = photoIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'photoId', values);
  }

  List<PhotoRecord?> getAllByPhotoIdSync(List<String> photoIdValues) {
    final values = photoIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'photoId', values);
  }

  Future<int> deleteAllByPhotoId(List<String> photoIdValues) {
    final values = photoIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'photoId', values);
  }

  int deleteAllByPhotoIdSync(List<String> photoIdValues) {
    final values = photoIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'photoId', values);
  }

  Future<Id> putByPhotoId(PhotoRecord object) {
    return putByIndex(r'photoId', object);
  }

  Id putByPhotoIdSync(PhotoRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'photoId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPhotoId(List<PhotoRecord> objects) {
    return putAllByIndex(r'photoId', objects);
  }

  List<Id> putAllByPhotoIdSync(
    List<PhotoRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'photoId', objects, saveLinks: saveLinks);
  }
}

extension PhotoRecordQueryWhereSort
    on QueryBuilder<PhotoRecord, PhotoRecord, QWhere> {
  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyCaptureDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'captureDateMs'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyImportedDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'importedDateMs'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isFavorite'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'rating'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isImported'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyIsRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isRaw'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isEdited'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyHasEdits() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'hasEdits'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhere> anyLastEditedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastEditedAtMs'),
      );
    });
  }
}

extension PhotoRecordQueryWhere
    on QueryBuilder<PhotoRecord, PhotoRecord, QWhereClause> {
  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> photoIdEqualTo(
    String photoId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'photoId', value: [photoId]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> photoIdNotEqualTo(
    String photoId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'photoId',
                lower: [],
                upper: [photoId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'photoId',
                lower: [photoId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'photoId',
                lower: [photoId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'photoId',
                lower: [],
                upper: [photoId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureDateMsEqualTo(int captureDateMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'captureDateMs',
          value: [captureDateMs],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureDateMsNotEqualTo(int captureDateMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureDateMs',
                lower: [],
                upper: [captureDateMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureDateMs',
                lower: [captureDateMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureDateMs',
                lower: [captureDateMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureDateMs',
                lower: [],
                upper: [captureDateMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureDateMsGreaterThan(int captureDateMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'captureDateMs',
          lower: [captureDateMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureDateMsLessThan(int captureDateMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'captureDateMs',
          lower: [],
          upper: [captureDateMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureDateMsBetween(
    int lowerCaptureDateMs,
    int upperCaptureDateMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'captureDateMs',
          lower: [lowerCaptureDateMs],
          includeLower: includeLower,
          upper: [upperCaptureDateMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureIdentifierEqualTo(String captureIdentifier) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'captureIdentifier',
          value: [captureIdentifier],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  captureIdentifierNotEqualTo(String captureIdentifier) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureIdentifier',
                lower: [],
                upper: [captureIdentifier],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureIdentifier',
                lower: [captureIdentifier],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureIdentifier',
                lower: [captureIdentifier],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'captureIdentifier',
                lower: [],
                upper: [captureIdentifier],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  importedDateMsEqualTo(int importedDateMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'importedDateMs',
          value: [importedDateMs],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  importedDateMsNotEqualTo(int importedDateMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedDateMs',
                lower: [],
                upper: [importedDateMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedDateMs',
                lower: [importedDateMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedDateMs',
                lower: [importedDateMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedDateMs',
                lower: [],
                upper: [importedDateMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  importedDateMsGreaterThan(int importedDateMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedDateMs',
          lower: [importedDateMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  importedDateMsLessThan(int importedDateMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedDateMs',
          lower: [],
          upper: [importedDateMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  importedDateMsBetween(
    int lowerImportedDateMs,
    int upperImportedDateMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedDateMs',
          lower: [lowerImportedDateMs],
          includeLower: includeLower,
          upper: [upperImportedDateMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> formatEqualTo(
    String format,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'format', value: [format]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> formatNotEqualTo(
    String format,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'format',
                lower: [],
                upper: [format],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'format',
                lower: [format],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'format',
                lower: [format],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'format',
                lower: [],
                upper: [format],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> isFavoriteEqualTo(
    bool isFavorite,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isFavorite', value: [isFavorite]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  isFavoriteNotEqualTo(bool isFavorite) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isFavorite',
                lower: [],
                upper: [isFavorite],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isFavorite',
                lower: [isFavorite],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isFavorite',
                lower: [isFavorite],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isFavorite',
                lower: [],
                upper: [isFavorite],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> ratingEqualTo(
    int rating,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'rating', value: [rating]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> ratingNotEqualTo(
    int rating,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rating',
                lower: [],
                upper: [rating],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rating',
                lower: [rating],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rating',
                lower: [rating],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rating',
                lower: [],
                upper: [rating],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> ratingGreaterThan(
    int rating, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'rating',
          lower: [rating],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> ratingLessThan(
    int rating, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'rating',
          lower: [],
          upper: [rating],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> ratingBetween(
    int lowerRating,
    int upperRating, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'rating',
          lower: [lowerRating],
          includeLower: includeLower,
          upper: [upperRating],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> colorLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'colorLabel', value: [null]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  colorLabelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'colorLabel',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> colorLabelEqualTo(
    String? colorLabel,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'colorLabel', value: [colorLabel]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  colorLabelNotEqualTo(String? colorLabel) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'colorLabel',
                lower: [],
                upper: [colorLabel],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'colorLabel',
                lower: [colorLabel],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'colorLabel',
                lower: [colorLabel],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'colorLabel',
                lower: [],
                upper: [colorLabel],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> isImportedEqualTo(
    bool isImported,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isImported', value: [isImported]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  isImportedNotEqualTo(bool isImported) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [],
                upper: [isImported],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [isImported],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [isImported],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [],
                upper: [isImported],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> isRawEqualTo(
    bool isRaw,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isRaw', value: [isRaw]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> isRawNotEqualTo(
    bool isRaw,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isRaw',
                lower: [],
                upper: [isRaw],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isRaw',
                lower: [isRaw],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isRaw',
                lower: [isRaw],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isRaw',
                lower: [],
                upper: [isRaw],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> isEditedEqualTo(
    bool isEdited,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isEdited', value: [isEdited]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> isEditedNotEqualTo(
    bool isEdited,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isEdited',
                lower: [],
                upper: [isEdited],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isEdited',
                lower: [isEdited],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isEdited',
                lower: [isEdited],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isEdited',
                lower: [],
                upper: [isEdited],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> hasEditsEqualTo(
    bool hasEdits,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'hasEdits', value: [hasEdits]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause> hasEditsNotEqualTo(
    bool hasEdits,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasEdits',
                lower: [],
                upper: [hasEdits],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasEdits',
                lower: [hasEdits],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasEdits',
                lower: [hasEdits],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasEdits',
                lower: [],
                upper: [hasEdits],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'lastEditedAtMs', value: [null]),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastEditedAtMs',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsEqualTo(int? lastEditedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastEditedAtMs',
          value: [lastEditedAtMs],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsNotEqualTo(int? lastEditedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastEditedAtMs',
                lower: [],
                upper: [lastEditedAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastEditedAtMs',
                lower: [lastEditedAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastEditedAtMs',
                lower: [lastEditedAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastEditedAtMs',
                lower: [],
                upper: [lastEditedAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsGreaterThan(int? lastEditedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastEditedAtMs',
          lower: [lastEditedAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsLessThan(int? lastEditedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastEditedAtMs',
          lower: [],
          upper: [lastEditedAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterWhereClause>
  lastEditedAtMsBetween(
    int? lowerLastEditedAtMs,
    int? upperLastEditedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastEditedAtMs',
          lower: [lowerLastEditedAtMs],
          includeLower: includeLower,
          upper: [upperLastEditedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PhotoRecordQueryFilter
    on QueryBuilder<PhotoRecord, PhotoRecord, QFilterCondition> {
  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'activeVersionId'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'activeVersionId'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'activeVersionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'activeVersionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'activeVersionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'activeVersionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'activeVersionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'activeVersionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'activeVersionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'activeVersionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activeVersionId', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  activeVersionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'activeVersionId', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'albumTagsJson'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'albumTagsJson'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'albumTagsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'albumTagsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'albumTagsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'albumTagsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'albumTagsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'albumTagsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'albumTagsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'albumTagsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'albumTagsJson', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  albumTagsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'albumTagsJson', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  apertureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'aperture'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  apertureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'aperture'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> apertureEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aperture',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  apertureGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aperture',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  apertureLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aperture',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> apertureBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aperture',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureDateMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'captureDateMs', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureDateMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'captureDateMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureDateMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'captureDateMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureDateMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'captureDateMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'captureIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'captureIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'captureIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'captureIdentifier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'captureIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'captureIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'captureIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'captureIdentifier',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'captureIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  captureIdentifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'captureIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'colorLabel'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'colorLabel'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'colorLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'colorLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'colorLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'colorLabel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'colorLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'colorLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'colorLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'colorLabel',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorLabel', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  colorLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'colorLabel', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'editedFilePath'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'editedFilePath'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'editedFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'editedFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'editedFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'editedFilePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'editedFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'editedFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'editedFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'editedFilePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'editedFilePath', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  editedFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'editedFilePath', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  focalLengthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'focalLength'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  focalLengthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'focalLength'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  focalLengthEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'focalLength',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  focalLengthGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'focalLength',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  focalLengthLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'focalLength',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  focalLengthBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'focalLength',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> formatEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'format',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  formatGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'format',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> formatLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'format',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> formatBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'format',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  formatStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'format',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> formatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'format',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> formatContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'format',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> formatMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'format',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  formatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'format', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  formatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'format', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> hasEditsEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasEdits', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'height'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'height'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> heightEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'height', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  heightGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'height',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> heightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'height',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> heightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'height',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  importedDateMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importedDateMs', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  importedDateMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importedDateMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  importedDateMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importedDateMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  importedDateMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importedDateMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isEditedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isEdited', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFavorite', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  isImportedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isImported', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isRawEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isRaw', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'iso'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'iso'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isoEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'iso',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isoGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'iso',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isoLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'iso',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> isoBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'iso',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lastEditedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastEditedAtMs'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lastEditedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastEditedAtMs'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lastEditedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastEditedAtMs', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lastEditedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastEditedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lastEditedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastEditedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lastEditedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastEditedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lens'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lens'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lens',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lens',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lens',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lens',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lens',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lens',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lens',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lens',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> lensIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lens', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  lensIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lens', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'location'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'location'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> locationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> locationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'location',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> locationMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'location',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'location', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'location', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalFilePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'originalFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'originalFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'originalFilePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'originalFilePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'originalFilePath', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  originalFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'originalFilePath', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> photoIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'photoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  photoIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'photoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> photoIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'photoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> photoIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'photoId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  photoIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'photoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> photoIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'photoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> photoIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'photoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> photoIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'photoId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  photoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'photoId', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  photoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'photoId', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> ratingEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rating', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  ratingGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rating',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> ratingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rating',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> ratingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rating',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolution'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolution'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolution',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'resolution',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolution', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  resolutionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'resolution', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'shutterSpeed'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'shutterSpeed'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shutterSpeed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shutterSpeed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shutterSpeed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shutterSpeed',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shutterSpeed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shutterSpeed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shutterSpeed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shutterSpeed',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shutterSpeed', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  shutterSpeedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shutterSpeed', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'simulationId'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'simulationId'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'simulationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'simulationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'simulationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'simulationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'simulationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'simulationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'simulationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'simulationId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'simulationId', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  simulationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'simulationId', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  thumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'versionsJson'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'versionsJson'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'versionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'versionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'versionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'versionsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'versionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'versionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'versionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'versionsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'versionsJson', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  versionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'versionsJson', value: ''),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> widthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'width'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  widthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'width'),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> widthEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'width', value: value),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition>
  widthGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'width',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> widthLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'width',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterFilterCondition> widthBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'width',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PhotoRecordQueryObject
    on QueryBuilder<PhotoRecord, PhotoRecord, QFilterCondition> {}

extension PhotoRecordQueryLinks
    on QueryBuilder<PhotoRecord, PhotoRecord, QFilterCondition> {}

extension PhotoRecordQuerySortBy
    on QueryBuilder<PhotoRecord, PhotoRecord, QSortBy> {
  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByActiveVersionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeVersionId', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByActiveVersionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeVersionId', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByAlbumTagsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumTagsJson', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByAlbumTagsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumTagsJson', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByAperture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aperture', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByApertureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aperture', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByCaptureDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureDateMs', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByCaptureDateMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureDateMs', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByCaptureIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureIdentifier', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByCaptureIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureIdentifier', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByColorLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorLabel', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByColorLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorLabel', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByEditedFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedFilePath', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByEditedFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedFilePath', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByFocalLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focalLength', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByFocalLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focalLength', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByHasEdits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasEdits', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByHasEditsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasEdits', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByImportedDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedDateMs', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByImportedDateMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedDateMs', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsImportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRaw', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRaw', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iso', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByIsoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iso', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByLastEditedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedAtMs', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByLastEditedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedAtMs', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByLens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lens', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByLensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lens', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByOriginalFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilePath', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByOriginalFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilePath', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByPhotoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoId', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByPhotoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoId', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByResolution() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByResolutionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByShutterSpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shutterSpeed', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByShutterSpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shutterSpeed', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortBySimulationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simulationId', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortBySimulationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simulationId', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByVersionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionsJson', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  sortByVersionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionsJson', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> sortByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension PhotoRecordQuerySortThenBy
    on QueryBuilder<PhotoRecord, PhotoRecord, QSortThenBy> {
  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByActiveVersionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeVersionId', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByActiveVersionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeVersionId', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByAlbumTagsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumTagsJson', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByAlbumTagsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumTagsJson', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByAperture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aperture', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByApertureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aperture', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByCaptureDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureDateMs', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByCaptureDateMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureDateMs', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByCaptureIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureIdentifier', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByCaptureIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'captureIdentifier', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByColorLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorLabel', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByColorLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorLabel', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByEditedFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedFilePath', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByEditedFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedFilePath', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByFocalLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focalLength', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByFocalLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focalLength', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByHasEdits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasEdits', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByHasEditsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasEdits', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByImportedDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedDateMs', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByImportedDateMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedDateMs', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsImportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRaw', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRaw', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iso', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByIsoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iso', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByLastEditedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedAtMs', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByLastEditedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastEditedAtMs', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByLens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lens', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByLensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lens', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByOriginalFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilePath', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByOriginalFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFilePath', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByPhotoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoId', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByPhotoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoId', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByResolution() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByResolutionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByShutterSpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shutterSpeed', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByShutterSpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shutterSpeed', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenBySimulationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simulationId', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenBySimulationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simulationId', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByVersionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionsJson', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy>
  thenByVersionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionsJson', Sort.desc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QAfterSortBy> thenByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension PhotoRecordQueryWhereDistinct
    on QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> {
  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByActiveVersionId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'activeVersionId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByAlbumTagsJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'albumTagsJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByAperture() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aperture');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByCaptureDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'captureDateMs');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct>
  distinctByCaptureIdentifier({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'captureIdentifier',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByColorLabel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorLabel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByEditedFilePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'editedFilePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByFocalLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'focalLength');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByFormat({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'format', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByHasEdits() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasEdits');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByImportedDateMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importedDateMs');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEdited');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isImported');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByIsRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRaw');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iso');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByLastEditedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastEditedAtMs');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByLens({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lens', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByLocation({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'location', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByOriginalFilePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'originalFilePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByPhotoId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating');
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByResolution({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resolution', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByShutterSpeed({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shutterSpeed', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctBySimulationId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'simulationId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByThumbnailPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'thumbnailPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByVersionsJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'versionsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PhotoRecord, PhotoRecord, QDistinct> distinctByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'width');
    });
  }
}

extension PhotoRecordQueryProperty
    on QueryBuilder<PhotoRecord, PhotoRecord, QQueryProperty> {
  QueryBuilder<PhotoRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations>
  activeVersionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeVersionId');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> albumTagsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'albumTagsJson');
    });
  }

  QueryBuilder<PhotoRecord, double?, QQueryOperations> apertureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aperture');
    });
  }

  QueryBuilder<PhotoRecord, int, QQueryOperations> captureDateMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'captureDateMs');
    });
  }

  QueryBuilder<PhotoRecord, String, QQueryOperations>
  captureIdentifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'captureIdentifier');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> colorLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorLabel');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations>
  editedFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editedFilePath');
    });
  }

  QueryBuilder<PhotoRecord, double?, QQueryOperations> focalLengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'focalLength');
    });
  }

  QueryBuilder<PhotoRecord, String, QQueryOperations> formatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'format');
    });
  }

  QueryBuilder<PhotoRecord, bool, QQueryOperations> hasEditsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasEdits');
    });
  }

  QueryBuilder<PhotoRecord, int?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<PhotoRecord, int, QQueryOperations> importedDateMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importedDateMs');
    });
  }

  QueryBuilder<PhotoRecord, bool, QQueryOperations> isEditedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEdited');
    });
  }

  QueryBuilder<PhotoRecord, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<PhotoRecord, bool, QQueryOperations> isImportedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isImported');
    });
  }

  QueryBuilder<PhotoRecord, bool, QQueryOperations> isRawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRaw');
    });
  }

  QueryBuilder<PhotoRecord, double?, QQueryOperations> isoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iso');
    });
  }

  QueryBuilder<PhotoRecord, int?, QQueryOperations> lastEditedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastEditedAtMs');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> lensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lens');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'location');
    });
  }

  QueryBuilder<PhotoRecord, String, QQueryOperations>
  originalFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalFilePath');
    });
  }

  QueryBuilder<PhotoRecord, String, QQueryOperations> photoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoId');
    });
  }

  QueryBuilder<PhotoRecord, int, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> resolutionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolution');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> shutterSpeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shutterSpeed');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> simulationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'simulationId');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> thumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailPath');
    });
  }

  QueryBuilder<PhotoRecord, String?, QQueryOperations> versionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'versionsJson');
    });
  }

  QueryBuilder<PhotoRecord, int?, QQueryOperations> widthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'width');
    });
  }
}
