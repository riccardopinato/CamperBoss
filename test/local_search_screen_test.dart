import 'package:camperboss/core/providers/local_search_provider.dart';
import 'package:camperboss/core/services/local_search_service.dart';
import 'package:camperboss/data/models/search_models.dart';
import 'package:camperboss/features/search/presentation/local_search_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('provider exposes local search service', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(localSearchServiceProvider),
      isA<LocalSearchService>(),
    );
  });

  testWidgets('search screen rebuilds index, filters and opens result',
      (tester) async {
    final service = _FakeSearchIndex();
    SearchHit? opened;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return ProviderScope(
              child: MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: LocalSearchScreen(
                    searchService: service,
                    onOpenHit: (hit) => opened = hit,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.rebuildCount, 1);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Libretto camper'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tagliando');
    await tester.pumpAndSettle();
    expect(find.text('Tagliando annuale'), findsOneWidget);
    expect(find.text('Libretto camper'), findsNothing);

    await tester.tap(find.text('Tagliando annuale'));
    await tester.pumpAndSettle();
    expect(opened?.type, SearchDocumentType.maintenance);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Tagliando annuale'), findsNothing);
  });
}

class _FakeSearchIndex implements LocalSearchIndex {
  int rebuildCount = 0;
  final _documents = <SearchDocument>[];

  @override
  Future<void> index(SearchDocument document) async {
    _documents.removeWhere((item) => item.id == document.id);
    _documents.add(document);
  }

  @override
  Future<void> rebuild() async {
    rebuildCount++;
    _documents
      ..clear()
      ..addAll([
        SearchDocument(
          id: 'document:1',
          type: SearchDocumentType.vehicleDocument,
          sourceId: '1',
          title: 'Libretto camper',
          body: 'Carta di circolazione.',
          metadata: const {},
          updatedAt: DateTime(2026, 6, 19),
        ),
        SearchDocument(
          id: 'maintenance:1',
          type: SearchDocumentType.maintenance,
          sourceId: '1',
          title: 'Tagliando annuale',
          body: 'Manutenzione programmata.',
          metadata: const {},
          updatedAt: DateTime(2026, 6, 18),
        ),
      ]);
  }

  @override
  Future<void> remove(String id) async {
    _documents.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<SearchHit>> search(
    String query, {
    Set<SearchDocumentType>? types,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    int limit = 50,
  }) async {
    final normalized = query.toLowerCase();
    return _documents
        .where((document) {
          if (types != null && !types.contains(document.type)) return false;
          return normalized.isEmpty ||
              document.title.toLowerCase().contains(normalized) ||
              document.body.toLowerCase().contains(normalized);
        })
        .map(
          (document) => SearchHit(
            sourceId: document.sourceId,
            type: document.type,
            title: document.title,
            snippet: document.body,
            score: 1,
            updatedAt: document.updatedAt,
          ),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<SearchIndexSnapshot> snapshot() async {
    return SearchIndexSnapshot(
      status: _documents.isEmpty
          ? SearchIndexStatus.empty
          : SearchIndexStatus.ready,
      version: 1,
      documentCount: _documents.length,
    );
  }
}
