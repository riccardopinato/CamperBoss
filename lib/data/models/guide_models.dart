import 'dart:convert';

enum GuideContentType {
  markdown,
  html,
  pdf,
  json,
}

enum GuideCollectionState {
  notInstalled,
  partiallyInstalled,
  installed,
  updateAvailable,
}

class GuideEntry {
  const GuideEntry({
    required this.id,
    required this.title,
    required this.relativePath,
    required this.contentType,
    this.summary,
    this.keywords = const [],
    this.imagePaths = const [],
  });

  final String id;
  final String title;
  final String relativePath;
  final GuideContentType contentType;
  final String? summary;
  final List<String> keywords;
  final List<String> imagePaths;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'relativePath': relativePath,
      'contentType': contentType.name,
      'summary': summary,
      'keywords': keywords,
      'imagePaths': imagePaths,
    };
  }

  factory GuideEntry.fromMap(Map<String, Object?> map) {
    return GuideEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      relativePath: map['relativePath'] as String,
      contentType: GuideContentType.values.firstWhere(
        (value) => value.name == map['contentType'],
        orElse: () => GuideContentType.markdown,
      ),
      summary: map['summary'] as String?,
      keywords: (map['keywords'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      imagePaths: (map['imagePaths'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class GuidePackage {
  const GuidePackage({
    required this.id,
    required this.title,
    required this.version,
    required this.language,
    required this.countryCodes,
    required this.category,
    required this.requiresPro,
    required this.updatedAt,
    required this.attribution,
    required this.entries,
    this.localRootPath,
  });

  final String id;
  final String title;
  final String version;
  final String language;
  final List<String> countryCodes;
  final String category;
  final bool requiresPro;
  final DateTime updatedAt;
  final String attribution;
  final List<GuideEntry> entries;
  final String? localRootPath;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'version': version,
      'language': language,
      'countryCodes': countryCodes,
      'category': category,
      'requiresPro': requiresPro,
      'updatedAt': updatedAt.toIso8601String(),
      'attribution': attribution,
      'entries': entries.map((item) => item.toMap()).toList(),
      'localRootPath': localRootPath,
    };
  }

  factory GuidePackage.fromMap(Map<String, Object?> map) {
    return GuidePackage(
      id: map['id'] as String,
      title: map['title'] as String,
      version: map['version'] as String,
      language: map['language'] as String? ?? 'it',
      countryCodes: (map['countryCodes'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      category: map['category'] as String? ?? 'guide',
      requiresPro: map['requiresPro'] as bool? ?? false,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      attribution: map['attribution'] as String? ?? '',
      entries: (map['entries'] as List<dynamic>? ?? const [])
          .map((item) =>
              GuideEntry.fromMap(Map<String, Object?>.from(item as Map)))
          .toList(growable: false),
      localRootPath: map['localRootPath'] as String?,
    );
  }
}

class GuideDocument {
  const GuideDocument({
    required this.packageId,
    required this.entryId,
    required this.title,
    required this.contentType,
    required this.content,
    required this.attribution,
    this.localPath,
  });

  final String packageId;
  final String entryId;
  final String title;
  final GuideContentType contentType;
  final String content;
  final String attribution;
  final String? localPath;
}

class ContentCollection {
  const ContentCollection({
    required this.id,
    required this.title,
    required this.packageIds,
    this.includesCollectionId,
  });

  final String id;
  final String title;
  final List<String> packageIds;
  final String? includesCollectionId;
}

class GuideReadingProgress {
  const GuideReadingProgress({
    required this.entryId,
    required this.offset,
    required this.updatedAt,
  });

  final String entryId;
  final int offset;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'entryId': entryId,
      'offset': offset,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GuideReadingProgress.fromMap(Map<String, Object?> map) {
    return GuideReadingProgress(
      entryId: map['entryId'] as String,
      offset: (map['offset'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class OnboardingProgress {
  const OnboardingProgress({
    required this.schemaVersion,
    required this.completedStepIds,
    required this.skippedStepIds,
    required this.selectedGuidePackageIds,
    required this.localeCode,
    required this.countryCode,
    required this.installChecklist,
    this.currentStepId,
    this.completed = false,
  });

  final int schemaVersion;
  final Set<String> completedStepIds;
  final Set<String> skippedStepIds;
  final Set<String> selectedGuidePackageIds;
  final String? currentStepId;
  final bool completed;
  final String? localeCode;
  final String? countryCode;
  final bool installChecklist;

  OnboardingProgress copyWith({
    int? schemaVersion,
    Set<String>? completedStepIds,
    Set<String>? skippedStepIds,
    Set<String>? selectedGuidePackageIds,
    String? currentStepId,
    bool clearCurrentStepId = false,
    bool? completed,
    String? localeCode,
    String? countryCode,
    bool? installChecklist,
  }) {
    return OnboardingProgress(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      skippedStepIds: skippedStepIds ?? this.skippedStepIds,
      selectedGuidePackageIds:
          selectedGuidePackageIds ?? this.selectedGuidePackageIds,
      currentStepId:
          clearCurrentStepId ? null : currentStepId ?? this.currentStepId,
      completed: completed ?? this.completed,
      localeCode: localeCode ?? this.localeCode,
      countryCode: countryCode ?? this.countryCode,
      installChecklist: installChecklist ?? this.installChecklist,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'completedStepIds': completedStepIds.toList()..sort(),
      'skippedStepIds': skippedStepIds.toList()..sort(),
      'selectedGuidePackageIds': selectedGuidePackageIds.toList()..sort(),
      'currentStepId': currentStepId,
      'completed': completed,
      'localeCode': localeCode,
      'countryCode': countryCode,
      'installChecklist': installChecklist,
    };
  }

  factory OnboardingProgress.fromMap(Map<String, Object?> map) {
    return OnboardingProgress(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      completedStepIds: ((map['completedStepIds'] as List<dynamic>? ?? const [])
              .whereType<String>())
          .toSet(),
      skippedStepIds: ((map['skippedStepIds'] as List<dynamic>? ?? const [])
              .whereType<String>())
          .toSet(),
      selectedGuidePackageIds:
          ((map['selectedGuidePackageIds'] as List<dynamic>? ?? const [])
                  .whereType<String>())
              .toSet(),
      currentStepId: map['currentStepId'] as String?,
      completed: map['completed'] as bool? ?? false,
      localeCode: map['localeCode'] as String?,
      countryCode: map['countryCode'] as String?,
      installChecklist: map['installChecklist'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory OnboardingProgress.fromJson(String source) {
    return OnboardingProgress.fromMap(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }

  static const empty = OnboardingProgress(
    schemaVersion: 1,
    completedStepIds: {},
    skippedStepIds: {},
    selectedGuidePackageIds: {},
    localeCode: null,
    countryCode: null,
    installChecklist: false,
  );
}
