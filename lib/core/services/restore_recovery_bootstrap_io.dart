import 'data_backup_service.dart';

Future<bool> recoverInterruptedRestoreIfNeeded() {
  return DataBackupService().recoverInterruptedRestore();
}
