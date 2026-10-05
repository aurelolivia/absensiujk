import 'package:flutter/material.dart';
import '../../reusable/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/attendance_model.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';

import '../attendance/attendance_screen.dart';
import '../attendance/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../reusable/live_clock_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // =========================
  // WARNA
  // =========================

  static Color get bgColor => AppPalette.bg;
  static Color get cardColor => AppPalette.card;
  static Color get cardColor2 => AppPalette.card2;
  static Color get accentColor => AppPalette.accent;
  static Color get accentLight => AppPalette.accentLight;

  // =========================
  // DATA
  // =========================

  String userName = 'Pengguna';

  bool isLoading = false;

  bool isLocationLoading = false;

  List<AttendanceModel> attendanceList = [];

  AttendanceModel? todayAttendance;

  String locationAddress = 'Mencari lokasi...';

  Position? currentPosition;

  GoogleMapController? mapController;

  final LatLng defaultLocation =
      LatLng(-6.2000, 106.816666);

  @override
  void initState() {
    super.initState();

    loadDashboard();

    getCurrentLocation();
  }

  // =========================
  // LOAD DASHBOARD
  // =========================

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      // =========================
      // PROFILE
      // =========================

      final profileResponse =
          await ApiServices().getProfile(token: token);

      if (profileResponse.statusCode == 200) {
        final profileData = profileResponse.data['data'];

        if (profileData != null && mounted) {
          setState(() {
            userName =
                profileData['name']?.toString() ?? 'Pengguna';
          });
        }
      }

      // =========================
      // HISTORY
      // =========================

      final now = DateTime.now();

      final historyResponse =
          await ApiServices().getHistory(
        token: token,
        start: '${now.year}-01-01',
        end: '${now.year}-12-31',
      );

      if (historyResponse.statusCode == 200) {
        final data = historyResponse.data['data'];

        if (data is List) {
          final list = data
              .map(
                (item) => AttendanceModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();

          AttendanceModel? today;

          for (final item in list) {
            if (item.checkIn != null &&
                item.checkIn!.isNotEmpty) {
              final parsedDate =
                  DateTime.tryParse(item.checkIn!);

              if (parsedDate != null &&
                  parsedDate.year == now.year &&
                  parsedDate.month == now.month &&
                  parsedDate.day == now.day) {
                today = item;
                break;
              }
            }
          }

          if (mounted) {
            setState(() {
              attendanceList = list;
              todayAttendance = today;
            });
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat dashboard: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================
  // GPS
  // =========================

  Future<void> getCurrentLocation() async {
    if (mounted) {
      setState(() {
        isLocationLoading = true;
        locationAddress = 'Mencari lokasi...';
      });
    }

    try {
      // Cek GPS
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            locationAddress = 'GPS belum aktif';
            isLocationLoading = false;
          });
        }

        return;
      }

      // Cek permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            locationAddress = 'Izin lokasi ditolak';
            isLocationLoading = false;
          });
        }

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            locationAddress =
                'Izin lokasi ditolak permanen';
            isLocationLoading = false;
          });
        }

        return;
      }

      // Ambil posisi GPS terbaru
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition = position;

        // GPS tetap asli,
        // tetapi label yang ditampilkan adalah PPKD JU.
        locationAddress = 'PPKD JU';

        isLocationLoading = false;
      });

      // Pindahkan kamera Google Maps ke GPS terbaru
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              position.latitude,
              position.longitude,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          locationAddress =
              'Gagal mendapatkan lokasi';

          isLocationLoading = false;
        });
      }
    }
  }

  // =========================
  // STATISTIK
  // =========================

  int get totalAttendance {
    return attendanceList.where((item) {
      return item.status.toLowerCase() == 'masuk';
    }).length;
  }

  int get totalCheckOut {
    return attendanceList.where((item) {
      return item.checkOut != null &&
          item.checkOut!.isNotEmpty;
    }).length;
  }

  int get totalIzinSakit {
    return attendanceList.where((item) {
      return item.status.toLowerCase() == 'izin';
    }).length;
  }

  String get todayStatus {
    if (todayAttendance == null) {
      return 'Belum Absen';
    }

    final status =
        todayAttendance!.status.toLowerCase();

    if (status == 'izin') {
      return 'Izin Sakit';
    }

    if (status == 'masuk') {
      return 'Hadir';
    }

    return todayAttendance!.status ?? 'Belum Absen';
  }

  // =========================
  // FORMAT TANGGAL
  // =========================

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // =========================
  // MARKER GPS
  // =========================

  Set<Marker> get currentMarker {
    if (currentPosition == null) {
      return {};
    }

    return {
      Marker(
        markerId:
            MarkerId('currentLocation'),

        position: LatLng(
          currentPosition!.latitude,
          currentPosition!.longitude,
        ),

        infoWindow: InfoWindow(
          title: 'Lokasi Saya',
          snippet: 'PPKD JU',
        ),
      ),
    };
  }

  // =========================
  // NAVIGATION
  // =========================

  void openAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceScreen(),
      ),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(),
      ),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

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

      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor: cardColor,

          onRefresh: () async {
            await loadDashboard();
            await getCurrentLocation();
          },

          child: SingleChildScrollView(
            physics:
                AlwaysScrollableScrollPhysics(),

            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              110,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // HEADER
                _buildHeader(),

                SizedBox(height: 20),

                // JAM DIGITAL (FITUR BARU)
                LiveClockCard(),

                SizedBox(height: 14),

                // WELCOME / BUKA ABSENSI
                _buildWelcomeCard(),

                SizedBox(height: 22),

                // STATISTIK
                _buildSectionTitle(
                  'Statistik Absensi',
                  'Ringkasan kehadiran kamu',
                ),

                SizedBox(height: 10),

                _buildStatistics(),

                SizedBox(height: 22),

                // ABSENSI HARI INI
                _buildSectionTitle(
                  'Absensi Hari Ini',
                  'Status kehadiran hari ini',
                ),

                SizedBox(height: 10),

                _buildTodayAttendance(),

                SizedBox(height: 22),

                // RIWAYAT
                _buildSectionTitle(
                  'Riwayat Kehadiran',
                  'Absensi terbaru kamu',
                ),

                SizedBox(height: 6),

                _buildHistoryHeader(),

                SizedBox(height: 8),

                if (attendanceList.isEmpty)
                  _buildEmptyHistory()
                else
                  ...attendanceList
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding:
                              EdgeInsets.only(
                            bottom: 10,
                          ),
                          child:
                              _buildHistoryCard(item),
                        ),
                      ),

                if (attendanceList.length > 3)
                  _buildSeeAllButton(),

                SizedBox(height: 22),

                // LOKASI
                _buildSectionTitle(
                  'Lokasi Saya',
                  'Lokasi GPS perangkat kamu',
                ),

                SizedBox(height: 10),

                _buildLocationCard(),

                SizedBox(height: 10),

                _buildMapPreview(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar:
          _buildBottomNavigationBar(),
    );
  }

  // =========================
  // SECTION TITLE
  // =========================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 3),

        Text(
          subtitle,

          style: TextStyle(
            color: AppPalette.textSecondary
                .withValues(alpha: 0.75),

            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // =========================
  // HEADER
  // =========================

  Widget _buildHeader() {
    final initial = userName.isNotEmpty
        ? userName[0].toUpperCase()
        : 'U';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),

            gradient:
                LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,

              colors: [
                AppPalette.accent,
                AppPalette.accentLight,
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(
                  alpha: 0.20,
                ),

                blurRadius: 15,

                offset: Offset(0, 7),
              ),
            ],
          ),

          child: Center(
            child: Text(
              initial,

              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Selamat datang 👋',

                style: TextStyle(
                  color: AppPalette.textSecondary
                      .withValues(alpha: 0.80),

                  fontSize: 11,
                ),
              ),

              SizedBox(height: 2),

              Text(
                userName,

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: openProfile,

          style: IconButton.styleFrom(
            backgroundColor: cardColor,

            padding:
                EdgeInsets.all(10),
          ),

          icon: Icon(
            Icons.person_outline_rounded,
            color: AppPalette.textPrimary,
            size: 21,
          ),
        ),
      ],
    );
  }

  // =========================
  // WELCOME CARD
  // =========================

  Widget _buildWelcomeCard() {
    final now = DateTime.now();

    final weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dateText =
        '${weekdays[now.weekday - 1]}, '
        '${now.day} '
        '${months[now.month - 1]} '
        '${now.year}';

    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),

        gradient:
            LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            AppPalette.chip,
            AppPalette.card,
          ],
        ),

        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.12,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.12,
            ),

            blurRadius: 20,

            offset: Offset(0, 9),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateText,

                  style: TextStyle(
                    color: AppPalette.textSecondary.withValues(
                      alpha: 0.90,
                    ),

                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: accentColor
                      .withValues(
                    alpha: 0.14,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: accentLight,
                    ),

                    SizedBox(width: 4),

                    Text(
                      'Absensi',

                      style: TextStyle(
                        color:
                            accentLight,

                        fontWeight:
                            FontWeight.w700,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 15),

          Text(
            'SHOW UP AND SLAY TODAY',

            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'clock in now, clock out later. DONT MIISS IT!',
           
            style: TextStyle(
              color: AppPalette.textSecondary
                  .withValues(alpha: 0.90),

              fontSize: 12,
            ),
          ),

          SizedBox(height: 16),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: openAttendance,

              icon: Icon(
                Icons.fingerprint_rounded,
                size: 19,
              ),

              label:
                  Text('Buka Absensi'),

              style:
                  ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor:
                    accentColor,

                foregroundColor:
                    Colors.white,

                padding:
                    EdgeInsets.symmetric(
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // STATISTICS
  // =========================

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Hadir',
            value:
                totalAttendance.toString(),
            icon:
                Icons.check_circle_outline,
          ),
        ),

        SizedBox(width: 9),

        Expanded(
          child: _buildStatCard(
            title: 'Pulang',
            value:
                totalCheckOut.toString(),
            icon:
                Icons.logout_rounded,
          ),
        ),

        SizedBox(width: 9),

        Expanded(
          child: _buildStatCard(
            title: 'Izin',
            value:
                totalIzinSakit.toString(),
            icon:
                Icons.event_note_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
          EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: AppPalette.divider.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: accentColor
                  .withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Icon(
              icon,
              color: accentLight,
              size: 18,
            ),
          ),

          SizedBox(height: 10),

          Text(
            value,

            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 2),

          Text(
            title,

            style: TextStyle(
              color: AppPalette.textSecondary.withValues(
                alpha: 0.75,
              ),

              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TODAY ATTENDANCE
  // =========================

  Widget _buildTodayAttendance() {
    final isHadir =
        todayStatus == 'Hadir';

    final isIzin =
        todayStatus == 'Izin Sakit';

    return Container(
      width: double.infinity,

      padding:
          EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: AppPalette.divider.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              color: isHadir
                  ? accentColor.withValues(
                      alpha: 0.12,
                    )
                  : isIzin
                      ? AppPalette.snack.withValues(
                          alpha: 0.12,
                        )
                      : AppPalette.divider.withValues(
                          alpha: 0.20,
                        ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Icon(
              isHadir
                  ? Icons.check_circle_rounded
                  : isIzin
                      ? Icons.event_note_rounded
                      : Icons.access_time_rounded,

              color: isHadir
                  ? accentLight
                  : isIzin
                      ? AppPalette.snack
                      : AppPalette.textSecondary,

              size: 21,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Status Hari Ini',

                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  todayAttendance == null
                      ? 'Kamu belum melakukan absensi.'
                      : 'Data absensi hari ini tersedia.',

                  style: TextStyle(
                    color: AppPalette.textSecondary.withValues(
                      alpha: 0.75,
                    ),

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: isHadir
                  ? accentColor.withValues(
                      alpha: 0.12,
                    )
                  : isIzin
                      ? AppPalette.snack.withValues(
                          alpha: 0.12,
                        )
                      : AppPalette.divider.withValues(
                          alpha: 0.20,
                        ),

              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: Text(
              todayStatus,

              style: TextStyle(
                color: isHadir
                    ? accentLight
                    : isIzin
                        ? AppPalette.snack
                        : AppPalette.textSecondary,

                fontSize: 10,

                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // LOCATION CARD
  // =========================

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,

      padding:
          EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.08,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: accentColor
                  .withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child: Icon(
              Icons.location_on_rounded,
              color: accentLight,
              size: 21,
            ),
          ),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Lokasi Saat Ini',

                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  locationAddress,

                  style: TextStyle(
                    color: AppPalette.textSecondary.withValues(
                      alpha: 0.85,
                    ),

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (isLocationLoading)
            SizedBox(
              width: 19,
              height: 19,

              child:
                  CircularProgressIndicator(
                strokeWidth: 2,

                color: accentLight,
              ),
            )
          else
            IconButton(
              onPressed:
                  getCurrentLocation,

              padding: EdgeInsets.zero,

              constraints:
                  BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),

              icon: Icon(
                Icons.refresh_rounded,
                color: accentLight,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // GOOGLE MAP PREVIEW
  // =========================

  Widget _buildMapPreview() {
    final mapPosition =
        currentPosition != null
            ? LatLng(
                currentPosition!.latitude,
                currentPosition!.longitude,
              )
            : defaultLocation;

    return Container(
      width: double.infinity,

      // DIPERKECIL DARI 245 → 180
      height: 180,

      clipBehavior:
          Clip.antiAlias,

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.08,
          ),
        ),
      ),

      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(
              target: mapPosition,
              zoom: 16,
            ),

            markers: currentMarker,

            myLocationEnabled: true,

            myLocationButtonEnabled:
                false,

            zoomControlsEnabled: false,

            compassEnabled: false,

            mapToolbarEnabled: false,

            onMapCreated:
                (controller) {
              mapController =
                  controller;

              if (currentPosition !=
                  null) {
                controller
                    .animateCamera(
                  CameraUpdate
                      .newLatLng(
                    LatLng(
                      currentPosition!
                          .latitude,
                      currentPosition!
                          .longitude,
                    ),
                  ),
                );
              }
            },
          ),

          // LABEL PPKD JU
          Positioned(
            top: 12,
            left: 12,

            child: Container(
              padding:
                  EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 7,
              ),

              decoration: BoxDecoration(
                color: cardColor
                    .withValues(
                  alpha: 0.94,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                border: Border.all(
                  color: accentColor
                      .withValues(
                    alpha: 0.18,
                  ),
                ),
              ),

              child: Row(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: accentLight,
                    size: 16,
                  ),

                  SizedBox(width: 5),

                  Text(
                    'PPKD JU',

                    style: TextStyle(
                      color:
                          AppPalette.textPrimary,

                      fontSize: 11,

                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TOMBOL LOKASI
          Positioned(
            right: 12,
            bottom: 12,

            child: Material(
              color: cardColor,

              borderRadius:
                  BorderRadius.circular(
                13,
              ),

              child: InkWell(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),

                onTap: () async {
                  await getCurrentLocation();

                  if (currentPosition !=
                      null) {
                    mapController
                        ?.animateCamera(
                      CameraUpdate
                          .newLatLng(
                        LatLng(
                          currentPosition!
                              .latitude,
                          currentPosition!
                              .longitude,
                        ),
                      ),
                    );
                  }
                },

                child: Padding(
                  padding:
                      EdgeInsets.all(10),

                  child: Icon(
                    Icons
                        .my_location_rounded,

                    color: accentLight,

                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HISTORY HEADER
  // =========================

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        Text(
          '${attendanceList.length} data absensi',

          style: TextStyle(
            color: AppPalette.textSecondary.withValues(
              alpha: 0.70,
            ),

            fontSize: 10,
          ),
        ),

        Spacer(),

        if (attendanceList.isNotEmpty)
          TextButton(
            onPressed: openHistory,

            style: TextButton.styleFrom(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
            ),

            child: Text(
              'Lihat Semua',

              style: TextStyle(
                color: accentLight,
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  // =========================
  // HISTORY CARD
  // =========================

  Widget _buildHistoryCard(
    AttendanceModel item,
  ) {
    final isIzin =
        item.status.toLowerCase() ==
            'izin';

    return Container(
      width: double.infinity,

      padding:
          EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(19),

        border: Border.all(
          color: AppPalette.divider.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration:
                    BoxDecoration(
                  color: isIzin
                      ? AppPalette.snack.withValues(
                          alpha: 0.12,
                        )
                      : accentColor
                          .withValues(
                          alpha: 0.12,
                        ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Icon(
                  isIzin
                      ? Icons
                          .event_note_rounded
                      : Icons.check_rounded,

                  color: isIzin
                      ? AppPalette.snack
                      : accentLight,

                  size: 20,
                ),
              ),

              SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      formatDate(
                        item.checkIn,
                      ),

                      style:
                          TextStyle(
                        color:
                            AppPalette.textPrimary,

                        fontSize: 13,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      isIzin
                          ? 'Izin Sakit'
                          : 'Kehadiran',

                      style: TextStyle(
                        color:
                            AppPalette.textSecondary.withValues(
                          alpha: 0.75,
                        ),

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: isIzin
                      ? AppPalette.snack.withValues(
                          alpha: 0.12,
                        )
                      : accentColor
                          .withValues(
                          alpha: 0.12,
                        ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  isIzin ? 'Izin' : 'Hadir',

                  style: TextStyle(
                    color: isIzin
                        ? AppPalette.snack
                        : accentLight,

                    fontSize: 9,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: _buildTimeItem(
                  icon:
                      Icons.login_rounded,
                  title: 'Masuk',
                  value:
                      formatTime(
                    item.checkIn,
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 28,

                color:
                    AppPalette.divider.withValues(
                  alpha: 0.20,
                ),
              ),

              Expanded(
                child: _buildTimeItem(
                  icon:
                      Icons.logout_rounded,
                  title: 'Pulang',
                  value:
                      formatTime(
                    item.checkOut,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal: 7,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: accentLight,
          ),

          SizedBox(width: 6),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  color: AppPalette.textSecondary.withValues(
                    alpha: 0.70,
                  ),

                  fontSize: 9,
                ),
              ),

              SizedBox(height: 2),

              Text(
                value,

                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // EMPTY HISTORY
  // =========================

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,

      padding:
          EdgeInsets.all(23),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(19),
      ),

      child: Column(
        children: [
          Icon(
            Icons.history_rounded,

            color: AppPalette.textSecondary.withValues(
              alpha: 0.55,
            ),

            size: 36,
          ),

          SizedBox(height: 9),

          Text(
            'Belum ada riwayat absensi',

            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight:
                  FontWeight.w700,
              fontSize: 13,
            ),
          ),

          SizedBox(height: 3),

          Text(
            'Data absensi kamu akan muncul di sini.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color: AppPalette.textSecondary.withValues(
                alpha: 0.70,
              ),

              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEE ALL
  // =========================

  Widget _buildSeeAllButton() {
    return SizedBox(
      width: double.infinity,

      child: OutlinedButton(
        onPressed: openHistory,

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              accentLight,

          side: BorderSide(
            color:
                accentColor.withValues(
              alpha: 0.20,
            ),
          ),

          padding:
              EdgeInsets.symmetric(
            vertical: 11,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),

        child: Text(
          'Lihat Semua Riwayat',

          style: TextStyle(
            fontWeight:
                FontWeight.w800,

            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // =========================
  // BOTTOM NAVIGATION
  // =========================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,

        border: Border(
          top: BorderSide(
            color: AppPalette.divider.withValues(
              alpha: 0.20,
            ),
          ),
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 7,
          ),

          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon:
                      Icons.home_rounded,
                  label: 'Home',
                  active: true,
                  onTap: () {},
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  icon:
                      Icons.fingerprint_rounded,
                  label: 'Kehadiran',
                  active: false,
                  onTap:
                      openAttendance,
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  icon:
                      Icons.person_rounded,
                  label: 'Profile',
                  active: false,
                  onTap: openProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(15),

      onTap: onTap,

      child: Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 6,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              icon,

              size: 21,

              color: active
                  ? accentLight
                  : AppPalette.textSecondary.withValues(
                      alpha: 0.65,
                    ),
            ),

            SizedBox(height: 3),

            Text(
              label,

              style: TextStyle(
                color: active
                    ? accentLight
                    : AppPalette.textSecondary.withValues(
                        alpha: 0.65,
                      ),

                fontSize: 9,

                fontWeight: active
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}