import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import 'app_theme.dart';

/// Kalender absensi: menandai tanggal yang sudah absen.
///   hijau  = hadir (status "masuk")
///   oranye = izin
/// Hanya MENAMPILKAN data yang sudah dimuat dashboard, tidak memanggil API baru.
class AttendanceCalendar extends StatefulWidget {
  final List<AttendanceModel> attendanceList;

  const AttendanceCalendar({super.key, required this.attendanceList});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  static const Color _green = Color(0xFF66BB6A);
  static const Color _orange = Color(0xFFFFA726);

  static const List<String> _weekdayShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];
  static const List<String> _weekdayLong = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  late DateTime _month; // selalu tanggal 1 dari bulan yang sedang ditampilkan
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = DateTime(now.year, now.month, now.day);
  }

  // ---------- helper ----------

  int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  bool _sameDay(DateTime a, DateTime b) => _key(a) == _key(b);

  DateTime? _dateOf(AttendanceModel item) {
    final raw = (item.checkIn != null && item.checkIn!.isNotEmpty)
        ? item.checkIn
        : item.createdAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// tanggal -> data absensi (kalau ada beberapa di hari yang sama, ambil yang pertama)
  Map<int, AttendanceModel> _buildMap() {
    final map = <int, AttendanceModel>{};
    for (final item in widget.attendanceList) {
      final date = _dateOf(item);
      if (date == null) continue;
      map.putIfAbsent(_key(date), () => item);
    }
    return map;
  }

  Color _statusColor(AttendanceModel item) {
    final s = item.status.toLowerCase();
    if (s == 'masuk') return _green;
    if (s == 'izin') return _orange;
    return AppPalette.accent;
  }

  String _statusLabel(AttendanceModel item) {
    final s = item.status.toLowerCase();
    if (s == 'masuk') return 'Hadir';
    if (s == 'izin') return 'Izin';
    return item.status;
  }

  String _time(String? value) {
    if (value == null || value.isEmpty) return '-';
    final d = DateTime.tryParse(value);
    if (d == null) return value;
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // Kalender dibatasi Januari-Desember tahun ini, sama seperti data
  // riwayat yang diambil dashboard.
  bool get _canPrev => _month.month > 1;
  bool get _canNext => _month.month < 12;

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final map = _buildMap();

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = _month.weekday - 1; // Senin = 0

    int hadir = 0;
    int izin = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final rec = map[_key(DateTime(_month.year, _month.month, d))];
      if (rec == null) continue;
      final s = rec.status.toLowerCase();
      if (s == 'masuk') hadir++;
      if (s == 'izin') izin++;
    }

    final cells = <Widget>[
      for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (int d = 1; d <= daysInMonth; d++) _dayCell(d, map),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul bulan + tombol geser
          Row(
            children: [
              _navButton(
                Icons.chevron_left_rounded,
                _canPrev ? () => _changeMonth(-1) : null,
              ),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _navButton(
                Icons.chevron_right_rounded,
                _canNext ? () => _changeMonth(1) : null,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Nama hari
          Row(
            children: [
              for (final w in _weekdayShort)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Tanggal
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.95,
            children: cells,
          ),

          const SizedBox(height: 10),

          // Keterangan warna
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend(_green, 'Hadir ($hadir)'),
              _legend(_orange, 'Izin ($izin)'),
              _legendRing('Hari ini'),
            ],
          ),

          const SizedBox(height: 12),

          _detail(map),
        ],
      ),
    );
  }

  // ---------- potongan widget ----------

  Widget _navButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 24,
          color: onTap == null
              ? AppPalette.textSecondary.withValues(alpha: 0.35)
              : AppPalette.accentLight,
        ),
      ),
    );
  }

  Widget _dayCell(int day, Map<int, AttendanceModel> map) {
    final date = DateTime(_month.year, _month.month, day);
    final rec = map[_key(date)];
    final isToday = _sameDay(date, DateTime.now());
    final isSelected = _selected != null && _sameDay(date, _selected!);

    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: (isToday && !isSelected)
              ? Border.all(color: AppPalette.accentLight, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : AppPalette.textPrimary,
                fontSize: 12,
                fontWeight: (isToday || isSelected)
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rec == null ? Colors.transparent : _statusColor(rec),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(color: AppPalette.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _legendRing(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppPalette.accentLight, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(color: AppPalette.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  /// Kartu keterangan untuk tanggal yang sedang dipilih
  Widget _detail(Map<int, AttendanceModel> map) {
    if (_selected == null) return const SizedBox.shrink();

    final date = _selected!;
    final rec = map[_key(date)];
    final title =
        '${_weekdayLong[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.card2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (rec == null)
            Text(
              'Tidak ada data absensi',
              style: TextStyle(color: AppPalette.textSecondary, fontSize: 11),
            )
          else ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(rec),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(rec),
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Masuk ${_time(rec.checkIn)}   •   Pulang ${_time(rec.checkOut)}',
              style: TextStyle(color: AppPalette.textSecondary, fontSize: 11),
            ),
            if (rec.alasanIzin != null && rec.alasanIzin!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Alasan: ${rec.alasanIzin}',
                style: TextStyle(color: AppPalette.textSecondary, fontSize: 11),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
