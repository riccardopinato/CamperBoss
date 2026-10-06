/// Lightweight process-wide revision counter for user-owned local data.
///
/// Every successful mutation of searchable CamperBoss data increments the
/// shared revision. The first search after every app launch is rebuilt, so the
/// counter does not need persistence.
class DataRevisionStore {
  DataRevisionStore._();

  DataRevisionStore.isolated();

  static final DataRevisionStore _shared = DataRevisionStore._();

  factory DataRevisionStore() => _shared;

  int _revision = 0;

  int current() => _revision;

  int bump() => ++_revision;
}
