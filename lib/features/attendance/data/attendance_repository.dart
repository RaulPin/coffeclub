import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registro de entrada/salida de un trabajador en una cafetería.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.cafeId,
    required this.staffUid,
    required this.staffName,
    required this.clockInAt,
    this.clockOutAt,
  });

  final String id;
  final String cafeId;
  final String staffUid;
  final String staffName;
  final DateTime clockInAt;
  final DateTime? clockOutAt;

  bool get isOpen => clockOutAt == null;
}

/// Asistencia del personal (checar entrada y salida). Vive en `attendance/`.
class AttendanceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('attendance');

  Future<void> clockIn({
    required String cafeId,
    required String staffUid,
    required String staffName,
  }) async {
    await _col.add({
      'cafeId': cafeId,
      'staffUid': staffUid,
      'staffName': staffName,
      'clockInAt': Timestamp.now(),
      'clockOutAt': null,
    });
  }

  Future<void> clockOut(String recordId) =>
      _col.doc(recordId).update({'clockOutAt': Timestamp.now()});

  /// Turno abierto del trabajador (sin salida), o null si no ha checado.
  /// Se filtra en cliente para no requerir un índice compuesto.
  Stream<AttendanceRecord?> watchOpen(String staffUid) => _col
          .where('staffUid', isEqualTo: staffUid)
          .snapshots()
          .map((snap) {
        final open = snap.docs
            .map(_fromDoc)
            .where((r) => r.isOpen)
            .toList()
          ..sort((a, b) => b.clockInAt.compareTo(a.clockInAt));
        return open.isEmpty ? null : open.first;
      });

  AttendanceRecord _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return AttendanceRecord(
      id: doc.id,
      cafeId: d['cafeId'] as String? ?? '',
      staffUid: d['staffUid'] as String? ?? '',
      staffName: d['staffName'] as String? ?? '',
      clockInAt: (d['clockInAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clockOutAt: (d['clockOutAt'] as Timestamp?)?.toDate(),
    );
  }
}

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) => AttendanceRepository());

/// Turno abierto del trabajador actual (null = no ha checado entrada).
final openAttendanceProvider =
    StreamProvider.family<AttendanceRecord?, String>((ref, staffUid) {
  return ref.watch(attendanceRepositoryProvider).watchOpen(staffUid);
});
