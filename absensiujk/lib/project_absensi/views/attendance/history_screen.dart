import 'package:flutter/material.dart';
import '../../reusable/app_theme.dart';

import '../../models/attendance_model.dart';

import '../../services/api_services.dart';

import '../../services/storage_services.dart';

class HistoryScreen extends StatefulWidget {

  const HistoryScreen({super.key});

  @override

  State<HistoryScreen> createState() => _HistoryScreenState();

}

class _HistoryScreenState extends State<HistoryScreen> {

  static Color get bgColor => AppPalette.bg;

  static Color get cardColor => AppPalette.card;

  static Color get accentColor => AppPalette.accent;

  static Color get accentLight => AppPalette.accentLight;

  List<AttendanceModel> history = [];

  bool isLoading = true;

  @override

  void initState() {

    super.initState();

    getHistory();

  }

  Future<void> getHistory() async {

    try {

      final token = await StorageServices.getToken();

      if (token == null) {

        if (!mounted) return;

        setState(() {

          isLoading = false;

        });

        return;

      }

      final response = await ApiServices().getHistory(

        token: token,

        start: '2026-01-01',

        end: '2026-12-31',

      );

      if (response.statusCode == 200) {

        final List data = response.data['data'];

        if (!mounted) return;

        setState(() {

          history = data.map((item) => AttendanceModel.fromJson(item)).toList();

          isLoading = false;

        });

      } else {

        if (!mounted) return;

        setState(() {

          isLoading = false;

        });

      }

    } catch (e) {

      if (!mounted) return;

      setState(() {

        isLoading = false;

      });

      ScaffoldMessenger.of(context)

          .showSnackBar(SnackBar(content: Text('Gagal mengambil riwayat: $e')));

    }

  }

  String formatDate(String? value) {

    if (value == null || value.isEmpty) {

      return '-';

    }

    try {

      final dateTime = DateTime.parse(value);

      final months = [

        'JAN',

        'FEB',

        'MAR',

        'APR',

        'MEI',

        'JUN',

        'JUL',

        'AGU',

        'SEP',

        'OKT',

        'NOV',

        'DES',

      ];

      return '${dateTime.day.toString().padLeft(2, '0')} '

          '${months[dateTime.month - 1]} '

          '${dateTime.year}';

    } catch (_) {

      return value;

    }

  }

  String formatTime(String? value) {

    if (value == null || value.isEmpty) {

      return '-';

    }

    try {

      final dateTime = DateTime.parse(value);

      return '${dateTime.hour.toString().padLeft(2, '0')}:'

          '${dateTime.minute.toString().padLeft(2, '0')}:'

          '${dateTime.second.toString().padLeft(2, '0')}';

    } catch (_) {

      return value;

    }

  }

  bool isPermission(String status) {

    return status.toLowerCase() == 'izin';

  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, _, __) => _buildThemed(context),
    );
  }

  Widget _buildThemed(BuildContext context) {

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor: bgColor,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(

          onPressed: () {

            Navigator.pop(context);

          },

          icon: Icon(

            Icons.arrow_back_ios_new_rounded,

            color: AppPalette.textPrimary,

            size: 19,

          ),

        ),

        title: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(

              'Riwayat Absensi',

              style: TextStyle(

                color: AppPalette.textPrimary,

                fontSize: 20,

                fontWeight: FontWeight.w900,

              ),

            ),

            SizedBox(height: 2),

            Text(

              'Aktivitas absensi kamu',

              style: TextStyle(

                color: AppPalette.textSecondary,

                fontSize: 10,

                fontWeight: FontWeight.w500,

              ),

            ),

          ],

        ),

        actions: [

          IconButton(

            onPressed: getHistory,

            icon: Icon(

              Icons.refresh_rounded,

              color: accentLight,

            ),

          ),

        ],

      ),

      body: isLoading

          ? Center(

              child: CircularProgressIndicator(

                color: accentColor,

              ),

            )

          : history.isEmpty

          ? _buildEmptyState()

          : RefreshIndicator(

              color: accentColor,

              backgroundColor: cardColor,

              onRefresh: getHistory,

              child: ListView.builder(

                physics: AlwaysScrollableScrollPhysics(),

                padding: EdgeInsets.fromLTRB(16, 12, 16, 30),

                itemCount: history.length,

                itemBuilder: (context, index) {

                  return _buildHistoryCard(history[index]);

                },

              ),

            ),

    );

  }

  Widget _buildHistoryCard(AttendanceModel item) {

    final izin = isPermission(item.status);

    final statusColor = izin

        ? AppPalette.snack

        : accentLight;

    return Container(

      margin: EdgeInsets.only(bottom: 15),

      padding: EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: cardColor,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(

          color: AppPalette.textPrimary.withValues(alpha: 0.06),

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Container(

                width: 50,

                height: 50,

                decoration: BoxDecoration(

                  color: accentColor.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(16),

                ),

                child: Icon(

                  izin

                      ? Icons.sick_rounded

                      : Icons.calendar_month_rounded,

                  color: accentLight,

                  size: 24,

                ),

              ),

              SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      formatDate(item.checkIn ?? item.createdAt),

                      style: TextStyle(

                        color: AppPalette.textPrimary,

                        fontSize: 16,

                        fontWeight: FontWeight.w900,

                      ),

                    ),

                    SizedBox(height: 5),

                    Text(

                      formatTime(item.checkIn ?? item.createdAt),

                      style: TextStyle(

                        color: AppPalette.textSecondary,

                        fontSize: 11,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),

              _statusBadge(item.status, statusColor),

              SizedBox(width: 3),

              IconButton(

                onPressed: () {

                  _showDeleteDialog(item);

                },

                icon: Icon(

                  Icons.delete_outline_rounded,

                  color: AppPalette.textSecondary,

                  size: 20,

                ),

              ),

            ],

          ),

          SizedBox(height: 20),

          _buildTimeline(

            icon: Icons.login_rounded,

            color: accentLight,

            title: 'Check In',

            time: formatTime(item.checkIn),

            location: item.checkInAddress ?? item.checkInLocation ?? '-',

            isLast: item.checkOut == null || item.checkOut!.isEmpty,

          ),

          if (item.checkOut != null && item.checkOut!.isNotEmpty)

            _buildTimeline(

              icon: Icons.logout_rounded,

              color: AppPalette.soft,

              title: 'Check Out',

              time: formatTime(item.checkOut),

              location: item.checkOutAddress ?? item.checkOutLocation ?? '-',

              isLast: true,

            ),

        ],

      ),

    );

  }

  Widget _buildTimeline({

    required IconData icon,

    required Color color,

    required String title,

    required String time,

    required String location,

    required bool isLast,

  }) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        SizedBox(

          width: 38,

          child: Column(

            children: [

              Container(

                width: 34,

                height: 34,

                decoration: BoxDecoration(

                  color: color.withValues(alpha: 0.10),

                  shape: BoxShape.circle,

                ),

                child: Icon(

                  icon,

                  color: color,

                  size: 17,

                ),

              ),

              if (!isLast)

                Container(

                  width: 2,

                  height: 55,

                  margin: EdgeInsets.symmetric(vertical: 4),

                  color: AppPalette.textSecondary.withValues(alpha: 0.18),

                ),

            ],

          ),

        ),

        SizedBox(width: 12),

        Expanded(

          child: Padding(

            padding: EdgeInsets.only(bottom: 12),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    Text(

                      title,

                      style: TextStyle(

                        color: AppPalette.textPrimary,

                        fontSize: 13,

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                    SizedBox(width: 8),

                    Container(

                      padding: EdgeInsets.symmetric(

                        horizontal: 8,

                        vertical: 4,

                      ),

                      decoration: BoxDecoration(

                        color: AppPalette.textPrimary

                            .withValues(alpha: 0.05),

                        borderRadius: BorderRadius.circular(8),

                      ),

                      child: Text(

                        time,

                        style: TextStyle(

                          color: AppPalette.textSecondary,

                          fontSize: 9,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                    ),

                  ],

                ),

                SizedBox(height: 7),

                Row(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Icon(

                      Icons.location_on_outlined,

                      color: AppPalette.divider,

                      size: 14,

                    ),

                    SizedBox(width: 5),

                    Expanded(

                      child: Text(

                        location,

                        style: TextStyle(

                          color: AppPalette.textSecondary,

                          fontSize: 10,

                          height: 1.45,

                        ),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ),

      ],

    );

  }

  Widget _statusBadge(String status, Color color) {

    return Container(

      padding: EdgeInsets.symmetric(

        horizontal: 10,

        vertical: 7,

      ),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(30),

      ),

      child: Text(

        status.toUpperCase(),

        style: TextStyle(

          color: color,

          fontSize: 9,

          fontWeight: FontWeight.w900,

        ),

      ),

    );

  }

  Widget _buildEmptyState() {

    return Center(

      child: Padding(

        padding: EdgeInsets.all(30),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              width: 90,

              height: 90,

              decoration: BoxDecoration(

                color: accentColor.withValues(alpha: 0.08),

                borderRadius: BorderRadius.circular(28),

              ),

              child: Icon(

                Icons.history_rounded,

                color: accentLight,

                size: 42,

              ),

            ),

            SizedBox(height: 20),

            Text(

              'Belum Ada Riwayat',

              style: TextStyle(

                color: AppPalette.textPrimary,

                fontSize: 19,

                fontWeight: FontWeight.w900,

              ),

            ),

            SizedBox(height: 8),

            Text(

              'Riwayat absensi kamu akan muncul di sini.',

              textAlign: TextAlign.center,

              style: TextStyle(

                color: AppPalette.textSecondary,

                fontSize: 12,

              ),

            ),

          ],

        ),

      ),

    );

  }

  Future<void> _showDeleteDialog(AttendanceModel item) async {

    final result = await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          backgroundColor: cardColor,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(22),

          ),

          title: Text(

            'Hapus Riwayat?',

            style: TextStyle(

              color: AppPalette.textPrimary,

              fontWeight: FontWeight.w800,

            ),

          ),

          content: Text(

            'Apakah kamu yakin ingin menghapus '

            'riwayat absensi ini?',

            style: TextStyle(

              color: AppPalette.textSecondary,

            ),

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context, false);

              },

              child: Text(

                'Batal',

                style: TextStyle(

                  color: AppPalette.textSecondary,

                ),

              ),

            ),

            ElevatedButton(

              onPressed: () {

                Navigator.pop(context, true);

              },

              style: ElevatedButton.styleFrom(

                backgroundColor: AppPalette.snack,

                foregroundColor: AppPalette.bg,

              ),

              child: Text('Hapus'),

            ),

          ],

        );

      },

    );

    if (result == true) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Fitur hapus siap dihubungkan ke API DELETE.'),

        ),

      );

    }

  }

}