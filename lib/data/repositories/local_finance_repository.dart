import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../models/finance_models.dart';

abstract interface class FinanceRepository {
  Future<List<Expense>> listExpenses();
  Future<Expense> saveExpense(Expense expense);
  Future<void> deleteExpense(String id);

  Future<List<FuelEntry>> listFuelEntries();
  Future<FuelEntry> saveFuelEntry(FuelEntry entry);
  Future<void> deleteFuelEntry(String id);

  Future<TripBudget?> loadTripBudget(int tripId);
  Future<void> saveTripBudget(TripBudget budget);
  Future<void> deleteTripBudget(int tripId);

  Future<List<TripBooking>> listBookings();
  Future<TripBooking> saveBooking(TripBooking booking);
  Future<void> deleteBooking(String id);
}

class LocalFinanceRepository implements FinanceRepository {
  LocalFinanceRepository({
    AppDatabase? database,
    LocalJsonCollection? expensesCollection,
    LocalJsonCollection? fuelCollection,
    LocalJsonCollection? budgetsCollection,
    LocalJsonCollection? bookingsCollection,
    DataRevisionStore? revisionStore,
  })  : _database = database ?? AppDatabase.instance,
        _expensesCollection =
            expensesCollection ?? LocalJsonCollection('camperboss.expenses'),
        _fuelCollection =
            fuelCollection ?? LocalJsonCollection('camperboss.fuel_entries'),
        _budgetsCollection =
            budgetsCollection ?? LocalJsonCollection('camperboss.trip_budgets'),
        _bookingsCollection =
            bookingsCollection ?? LocalJsonCollection('camperboss.bookings'),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final AppDatabase _database;
  final LocalJsonCollection _expensesCollection;
  final LocalJsonCollection _fuelCollection;
  final LocalJsonCollection _budgetsCollection;
  final LocalJsonCollection _bookingsCollection;
  final DataRevisionStore _revisionStore;

  @override
  Future<List<Expense>> listExpenses() async {
    if (kIsWeb) {
      final rows = await _expensesCollection.listRows();
      return rows.map(Expense.fromMap).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.expensesTable,
      orderBy: 'occurred_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<Expense> saveExpense(Expense expense) async {
    if (kIsWeb) {
      final saved = await _expensesCollection.saveRow(expense.toMap());
      _revisionStore.bump();
      return Expense.fromMap(saved);
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.expensesTable,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _revisionStore.bump();
    return expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    if (kIsWeb) {
      await _expensesCollection.deleteRow(id);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(AppDatabase.expensesTable, where: 'id = ?', whereArgs: [id]);
    _revisionStore.bump();
  }

  @override
  Future<List<FuelEntry>> listFuelEntries() async {
    if (kIsWeb) {
      final rows = await _fuelCollection.listRows();
      return rows.map(FuelEntry.fromMap).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.fuelEntriesTable,
      orderBy: 'date DESC, odometer_km DESC',
    );
    return rows.map(FuelEntry.fromMap).toList();
  }

  @override
  Future<FuelEntry> saveFuelEntry(FuelEntry entry) async {
    if (kIsWeb) {
      final saved = await _fuelCollection.saveRow(entry.toMap());
      _revisionStore.bump();
      return FuelEntry.fromMap(saved);
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.fuelEntriesTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _revisionStore.bump();
    return entry;
  }

  @override
  Future<void> deleteFuelEntry(String id) async {
    if (kIsWeb) {
      await _fuelCollection.deleteRow(id);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.fuelEntriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    _revisionStore.bump();
  }

  @override
  Future<TripBudget?> loadTripBudget(int tripId) async {
    if (kIsWeb) {
      final rows = await _budgetsCollection.listRows();
      final match = rows.where((row) => row['trip_id'] == tripId).toList();
      if (match.isEmpty) return null;
      return TripBudget.fromMap(match.first);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.tripBudgetsTable,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TripBudget.fromMap(rows.first);
  }

  @override
  Future<void> saveTripBudget(TripBudget budget) async {
    if (kIsWeb) {
      await _budgetsCollection.saveRow({
        ...budget.toMap(),
        'id': budget.tripId,
      });
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.tripBudgetsTable,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _revisionStore.bump();
  }

  @override
  Future<void> deleteTripBudget(int tripId) async {
    if (kIsWeb) {
      await _budgetsCollection.deleteRow(tripId);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.tripBudgetsTable,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    _revisionStore.bump();
  }

  @override
  Future<List<TripBooking>> listBookings() async {
    if (kIsWeb) {
      final rows = await _bookingsCollection.listRows();
      return rows.map(TripBooking.fromMap).toList()
        ..sort((a, b) {
          final aDate = a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.tripBookingsTable,
      orderBy: 'starts_at ASC, title ASC',
    );
    return rows.map(TripBooking.fromMap).toList();
  }

  @override
  Future<TripBooking> saveBooking(TripBooking booking) async {
    if (kIsWeb) {
      final saved = await _bookingsCollection.saveRow(booking.toMap());
      _revisionStore.bump();
      return TripBooking.fromMap(saved);
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.tripBookingsTable,
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _revisionStore.bump();
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
    if (kIsWeb) {
      await _bookingsCollection.deleteRow(id);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.tripBookingsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    _revisionStore.bump();
  }
}
