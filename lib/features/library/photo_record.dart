import 'package:isar/isar.dart';

part 'photo_record.g.dart';

@collection
class PhotoRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String photoId;

  @Index()
  late int captureDateMs;

  @Index()
  late String captureIdentifier;

  late String originalFilePath;
  String? editedFilePath;
  String? thumbnailPath;

  @Index()
  late int importedDateMs;

  double? iso;
  String? shutterSpeed;
  double? aperture;
  double? focalLength;
  String? lens;
  String? resolution;

  @Index()
  late String format;

  @Index()
  late bool isFavorite;

  @Index()
  late int rating;

  @Index()
  String? colorLabel;
  String? location;
  String? albumTagsJson;
  String? simulationId;

  @Index()
  late bool isImported;

  @Index()
  late bool isRaw;

  @Index()
  late bool isEdited;

  @Index()
  late bool hasEdits;

  int? width;
  int? height;
  @Index()
  int? lastEditedAtMs;

  String? activeVersionId;
  String? versionsJson;
}
