import 'package:flutter/foundation.dart';

enum LumaPhotoFormat { raw, jpg, heic, png, unknown }

enum LumaColorLabel { none, red, yellow, green, blue }

enum LumaPhotoSort { newest, oldest, ratingHigh, favoritesFirst }

enum LumaSmartAlbum {
  all,
  favorites,
  raw,
  edited,
  imported,
  recentlyEdited,
  portrait,
  landscape,
}

enum LumaHistogramMode { off, luminance, rgb }

@immutable
class LumaEditInstruction {
  final String key;
  final Object? value;

  const LumaEditInstruction({required this.key, required this.value});

  factory LumaEditInstruction.fromJson(Map<String, dynamic> json) {
    return LumaEditInstruction(
      key: json['key'] as String? ?? 'unknown',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value};
  }
}

@immutable
class LumaPhotoVersion {
  final String versionId;
  final String name;
  final int createdAtMs;
  final List<LumaEditInstruction> instructions;
  final String? renderedPath;

  const LumaPhotoVersion({
    required this.versionId,
    required this.name,
    required this.createdAtMs,
    required this.instructions,
    this.renderedPath,
  });

  factory LumaPhotoVersion.fromJson(Map<String, dynamic> json) {
    final rawInstructions = json['instructions'];
    final instructions = rawInstructions is List
        ? rawInstructions
              .whereType<Map>()
              .map(
                (item) => LumaEditInstruction.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <LumaEditInstruction>[];

    return LumaPhotoVersion(
      versionId: json['versionId'] as String? ?? 'version',
      name: json['name'] as String? ?? 'Version',
      createdAtMs:
          (json['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      instructions: instructions,
      renderedPath: json['renderedPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'versionId': versionId,
      'name': name,
      'createdAtMs': createdAtMs,
      'instructions': instructions.map((item) => item.toJson()).toList(),
      'renderedPath': renderedPath,
    };
  }

  LumaPhotoVersion copyWith({
    String? versionId,
    String? name,
    int? createdAtMs,
    List<LumaEditInstruction>? instructions,
    Object? renderedPath = _unset,
  }) {
    return LumaPhotoVersion(
      versionId: versionId ?? this.versionId,
      name: name ?? this.name,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      instructions: instructions ?? this.instructions,
      renderedPath: identical(renderedPath, _unset)
          ? this.renderedPath
          : renderedPath as String?,
    );
  }
}

@immutable
class LumaPhoto {
  final String photoId;
  final String captureIdentifier;
  final int captureDateMs;
  final double? iso;
  final String? shutterSpeed;
  final double? aperture;
  final double? focalLength;
  final String? lens;
  final int? width;
  final int? height;
  final LumaPhotoFormat format;
  final bool isFavorite;
  final int rating;
  final LumaColorLabel colorLabel;
  final String? location;
  final bool imported;
  final String originalPath;
  final String workingPath;
  final String? thumbnailPath;
  final int? lastEditedAtMs;
  final List<LumaPhotoVersion> versions;
  final String activeVersionId;

  const LumaPhoto({
    required this.photoId,
    required this.captureIdentifier,
    required this.captureDateMs,
    required this.format,
    required this.isFavorite,
    required this.rating,
    required this.colorLabel,
    required this.imported,
    required this.originalPath,
    required this.workingPath,
    required this.versions,
    required this.activeVersionId,
    this.iso,
    this.shutterSpeed,
    this.aperture,
    this.focalLength,
    this.lens,
    this.width,
    this.height,
    this.location,
    this.thumbnailPath,
    this.lastEditedAtMs,
  });

  factory LumaPhoto.fromJson(Map<String, dynamic> json) {
    final rawVersions = json['versions'];
    final versions = rawVersions is List
        ? rawVersions
              .whereType<Map>()
              .map(
                (item) =>
                    LumaPhotoVersion.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <LumaPhotoVersion>[];

    return LumaPhoto(
      photoId: json['photoId'] as String? ?? 'photo',
      captureIdentifier:
          json['captureIdentifier'] as String? ??
          (json['photoId'] as String? ?? 'capture'),
      captureDateMs:
          (json['captureDateMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      iso: (json['iso'] as num?)?.toDouble(),
      shutterSpeed: json['shutterSpeed'] as String?,
      aperture: (json['aperture'] as num?)?.toDouble(),
      focalLength: (json['focalLength'] as num?)?.toDouble(),
      lens: json['lens'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      format: lumaPhotoFormatFromWire(json['format'] as String?),
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      rating: ((json['rating'] as num?)?.toInt() ?? 0).clamp(0, 5),
      colorLabel: lumaColorLabelFromWire(json['colorLabel'] as String?),
      location: json['location'] as String?,
      imported: (json['imported'] as bool?) ?? false,
      originalPath: json['originalPath'] as String? ?? '',
      workingPath:
          json['workingPath'] as String? ??
          (json['originalPath'] as String? ?? ''),
      thumbnailPath: json['thumbnailPath'] as String?,
      lastEditedAtMs: (json['lastEditedAtMs'] as num?)?.toInt(),
      versions: versions,
      activeVersionId:
          json['activeVersionId'] as String? ??
          (versions.isNotEmpty ? versions.last.versionId : 'original'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoId': photoId,
      'captureIdentifier': captureIdentifier,
      'captureDateMs': captureDateMs,
      'iso': iso,
      'shutterSpeed': shutterSpeed,
      'aperture': aperture,
      'focalLength': focalLength,
      'lens': lens,
      'width': width,
      'height': height,
      'format': format.wireValue,
      'isFavorite': isFavorite,
      'rating': rating,
      'colorLabel': colorLabel.wireValue,
      'location': location,
      'imported': imported,
      'originalPath': originalPath,
      'workingPath': workingPath,
      'thumbnailPath': thumbnailPath,
      'lastEditedAtMs': lastEditedAtMs,
      'versions': versions.map((item) => item.toJson()).toList(),
      'activeVersionId': activeVersionId,
    };
  }

  bool get isEdited => versions.length > 1;

  bool get isPortrait {
    final w = width;
    final h = height;
    if (w == null || h == null) return false;
    return h > w;
  }

  bool get isLandscape {
    final w = width;
    final h = height;
    if (w == null || h == null) return false;
    return w >= h;
  }

  LumaPhoto copyWith({
    String? photoId,
    String? captureIdentifier,
    int? captureDateMs,
    Object? iso = _unset,
    Object? shutterSpeed = _unset,
    Object? aperture = _unset,
    Object? focalLength = _unset,
    Object? lens = _unset,
    Object? width = _unset,
    Object? height = _unset,
    LumaPhotoFormat? format,
    bool? isFavorite,
    int? rating,
    LumaColorLabel? colorLabel,
    Object? location = _unset,
    bool? imported,
    String? originalPath,
    String? workingPath,
    Object? thumbnailPath = _unset,
    Object? lastEditedAtMs = _unset,
    List<LumaPhotoVersion>? versions,
    String? activeVersionId,
  }) {
    return LumaPhoto(
      photoId: photoId ?? this.photoId,
      captureIdentifier: captureIdentifier ?? this.captureIdentifier,
      captureDateMs: captureDateMs ?? this.captureDateMs,
      iso: identical(iso, _unset) ? this.iso : iso as double?,
      shutterSpeed: identical(shutterSpeed, _unset)
          ? this.shutterSpeed
          : shutterSpeed as String?,
      aperture: identical(aperture, _unset)
          ? this.aperture
          : aperture as double?,
      focalLength: identical(focalLength, _unset)
          ? this.focalLength
          : focalLength as double?,
      lens: identical(lens, _unset) ? this.lens : lens as String?,
      width: identical(width, _unset) ? this.width : width as int?,
      height: identical(height, _unset) ? this.height : height as int?,
      format: format ?? this.format,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      colorLabel: colorLabel ?? this.colorLabel,
      location: identical(location, _unset)
          ? this.location
          : location as String?,
      imported: imported ?? this.imported,
      originalPath: originalPath ?? this.originalPath,
      workingPath: workingPath ?? this.workingPath,
      thumbnailPath: identical(thumbnailPath, _unset)
          ? this.thumbnailPath
          : thumbnailPath as String?,
      lastEditedAtMs: identical(lastEditedAtMs, _unset)
          ? this.lastEditedAtMs
          : lastEditedAtMs as int?,
      versions: versions ?? this.versions,
      activeVersionId: activeVersionId ?? this.activeVersionId,
    );
  }
}

const Object _unset = Object();

extension LumaPhotoFormatCodec on LumaPhotoFormat {
  String get wireValue {
    switch (this) {
      case LumaPhotoFormat.raw:
        return 'raw';
      case LumaPhotoFormat.jpg:
        return 'jpg';
      case LumaPhotoFormat.heic:
        return 'heic';
      case LumaPhotoFormat.png:
        return 'png';
      case LumaPhotoFormat.unknown:
        return 'unknown';
    }
  }
}

LumaPhotoFormat lumaPhotoFormatFromWire(String? value) {
  switch (value) {
    case 'raw':
      return LumaPhotoFormat.raw;
    case 'jpg':
      return LumaPhotoFormat.jpg;
    case 'heic':
      return LumaPhotoFormat.heic;
    case 'png':
      return LumaPhotoFormat.png;
    default:
      return LumaPhotoFormat.unknown;
  }
}

extension LumaColorLabelCodec on LumaColorLabel {
  String get wireValue {
    switch (this) {
      case LumaColorLabel.none:
        return 'none';
      case LumaColorLabel.red:
        return 'red';
      case LumaColorLabel.yellow:
        return 'yellow';
      case LumaColorLabel.green:
        return 'green';
      case LumaColorLabel.blue:
        return 'blue';
    }
  }

  String get label {
    switch (this) {
      case LumaColorLabel.none:
        return 'None';
      case LumaColorLabel.red:
        return 'Red';
      case LumaColorLabel.yellow:
        return 'Yellow';
      case LumaColorLabel.green:
        return 'Green';
      case LumaColorLabel.blue:
        return 'Blue';
    }
  }
}

LumaColorLabel lumaColorLabelFromWire(String? value) {
  switch (value) {
    case 'red':
      return LumaColorLabel.red;
    case 'yellow':
      return LumaColorLabel.yellow;
    case 'green':
      return LumaColorLabel.green;
    case 'blue':
      return LumaColorLabel.blue;
    default:
      return LumaColorLabel.none;
  }
}
