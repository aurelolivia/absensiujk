import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/attendance_model.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';

import '../attendance/attendance_screen.dart';
import '../attendance/history_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // =========================
  // WARNA
  // =========================

  static const Color bgColor = Color(0xFFFFF7FA);
  static const Color cardColor = Color(0xFFFFEAF1);
  static const Color cardColor2 = Color(0xFFFFF1F5);
  static const Color accentColor = Color(0xFFE89AB7);
  static const Color accentLight = Color(0xFFD96F96);

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
      const LatLng(-6.2000, 106.816666);

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
        locationSettings: const LocationSettings(
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
      return item.status?.toLowerCase() == 'masuk';
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
      return item.status?.toLowerCase() == 'izin';
    }).length;
  }

  String get todayStatus {
    if (todayAttendance == null) {
      return 'Belum Absen';
    }

    final status =
        todayAttendance!.status?.toLowerCase();

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
            const MarkerId('currentLocation'),

        position: LatLng(
          currentPosition!.latitude,
          currentPosition!.longitude,
        ),

        infoWindow: const InfoWindow(
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
        builder: (_) => const AttendanceScreen(),
      ),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryScreen(),
      ),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
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
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
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

                const SizedBox(height: 20),

                // WELCOME / BUKA ABSENSI
                _buildWelcomeCard(),

                const SizedBox(height: 22),

                // STATISTIK
                _buildSectionTitle(
                  'Statistik Absensi',
                  'Ringkasan kehadiran kamu',
                ),

                const SizedBox(height: 10),

                _buildStatistics(),

                const SizedBox(height: 22),

                // ABSENSI HARI INI
                _buildSectionTitle(
                  'Absensi Hari Ini',
                  'Status kehadiran hari ini',
                ),

                const SizedBox(height: 10),

                _buildTodayAttendance(),

                const SizedBox(height: 22),

                // RIWAYAT
                _buildSectionTitle(
                  'Riwayat Kehadiran',
                  'Absensi terbaru kamu',
                ),

                const SizedBox(height: 6),

                _buildHistoryHeader(),

                const SizedBox(height: 8),

                if (attendanceList.isEmpty)
                  _buildEmptyHistory()
                else
                  ...attendanceList
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child:
                              _buildHistoryCard(item),
                        ),
                      ),

                if (attendanceList.length > 3)
                  _buildSeeAllButton(),

                const SizedBox(height: 22),

                // LOKASI
                _buildSectionTitle(
                  'Lokasi Saya',
                  'Lokasi GPS perangkat kamu',
                ),

                const SizedBox(height: 10),

                _buildLocationCard(),

                const SizedBox(height: 10),

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

          style: const TextStyle(
            color: Color(0xFF54283A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,

          style: TextStyle(
            color: const Color(0xFF9E7180)
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
                const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,

              colors: [
                Color(0xFFE89AB7),
                Color(0xFFD96F96),
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(
                  alpha: 0.20,
                ),

                blurRadius: 15,

                offset: const Offset(0, 7),
              ),
            ],
          ),

          child: Center(
            child: Text(
              initial,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Selamat datang 👋',

                style: TextStyle(
                  color: const Color(0xFF9E7180)
                      .withValues(alpha: 0.80),

                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                userName,

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Color(0xFF54283A),
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
                const EdgeInsets.all(10),
          ),

          icon: const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFF54283A),
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

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),

        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color(0xFFFFDCE8),
            Color(0xFFFFEAF1),
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

            offset: const Offset(0, 9),
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
                    color: const Color(
                      0xFF9E7180,
                    ).withValues(
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
                    const EdgeInsets.symmetric(
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

                child: const Row(
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

          const SizedBox(height: 15),

          const Text(
            'Tetap semangat hari ini!',

            style: TextStyle(
              color: Color(0xFF54283A),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Jangan lupa lakukan absensi '
            'sesuai kondisi kamu.',

            style: TextStyle(
              color: const Color(0xFF9E7180)
                  .withValues(alpha: 0.90),

              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: openAttendance,

              icon: const Icon(
                Icons.fingerprint_rounded,
                size: 19,
              ),

              label:
                  const Text('Buka Absensi'),

              style:
                  ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor:
                    accentColor,

                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets.symmetric(
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

        const SizedBox(width: 9),

        Expanded(
          child: _buildStatCard(
            title: 'Pulang',
            value:
                totalCheckOut.toString(),
            icon:
                Icons.logout_rounded,
          ),
        ),

        const SizedBox(width: 9),

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
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: const Color(
            0xFFB98B9B,
          ).withValues(
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

          const SizedBox(height: 10),

          Text(
            value,

            style: const TextStyle(
              color: Color(0xFF54283A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: TextStyle(
              color: const Color(
                0xFF9E7180,
              ).withValues(
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
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: const Color(
            0xFFB98B9B,
          ).withValues(
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
                      ? const Color(
                          0xFFE58BA6,
                        ).withValues(
                          alpha: 0.12,
                        )
                      : const Color(
                          0xFFB98B9B,
                        ).withValues(
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
                      ? const Color(
                          0xFFE58BA6,
                        )
                      : const Color(
                          0xFF9E7180,
                        ),

              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Status Hari Ini',

                  style: TextStyle(
                    color: Color(0xFF54283A),
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  todayAttendance == null
                      ? 'Kamu belum melakukan absensi.'
                      : 'Data absensi hari ini tersedia.',

                  style: TextStyle(
                    color: const Color(
                      0xFF9E7180,
                    ).withValues(
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
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: isHadir
                  ? accentColor.withValues(
                      alpha: 0.12,
                    )
                  : isIzin
                      ? const Color(
                          0xFFE58BA6,
                        ).withValues(
                          alpha: 0.12,
                        )
                      : const Color(
                          0xFFB98B9B,
                        ).withValues(
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
                        ? const Color(
                            0xFFE58BA6,
                          )
                        : const Color(
                            0xFF9E7180,
                          ),

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
          const EdgeInsets.all(15),

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

            child: const Icon(
              Icons.location_on_rounded,
              color: accentLight,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Lokasi Saat Ini',

                  style: TextStyle(
                    color: Color(0xFF54283A),
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  locationAddress,

                  style: TextStyle(
                    color: const Color(
                      0xFF9E7180,
                    ).withValues(
                      alpha: 0.85,
                    ),

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (isLocationLoading)
            const SizedBox(
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
                  const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),

              icon: const Icon(
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
                  const EdgeInsets
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

              child: const Row(
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
                          Color(0xFF54283A),

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

                child: const Padding(
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
            color: const Color(
              0xFF9E7180,
            ).withValues(
              alpha: 0.70,
            ),

            fontSize: 10,
          ),
        ),

        const Spacer(),

        if (attendanceList.isNotEmpty)
          TextButton(
            onPressed: openHistory,

            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
            ),

            child: const Text(
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
        item.status?.toLowerCase() ==
            'izin';

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(19),

        border: Border.all(
          color: const Color(
            0xFFB98B9B,
          ).withValues(
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
                      ? const Color(
                          0xFFE58BA6,
                        ).withValues(
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
                      ? const Color(
                          0xFFE58BA6,
                        )
                      : accentLight,

                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

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
                          const TextStyle(
                        color:
                            Color(0xFF54283A),

                        fontSize: 13,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      isIzin
                          ? 'Izin Sakit'
                          : 'Kehadiran',

                      style: TextStyle(
                        color:
                            const Color(
                          0xFF9E7180,
                        ).withValues(
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
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: isIzin
                      ? const Color(
                          0xFFE58BA6,
                        ).withValues(
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
                        ? const Color(
                            0xFFE58BA6,
                          )
                        : accentLight,

                    fontSize: 9,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

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
                    const Color(
                  0xFFB98B9B,
                ).withValues(
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
          const EdgeInsets.symmetric(
        horizontal: 7,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: accentLight,
          ),

          const SizedBox(width: 6),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  color: const Color(
                    0xFF9E7180,
                  ).withValues(
                    alpha: 0.70,
                  ),

                  fontSize: 9,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,

                style: const TextStyle(
                  color: Color(0xFF54283A),
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
          const EdgeInsets.all(23),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(19),
      ),

      child: Column(
        children: [
          Icon(
            Icons.history_rounded,

            color: const Color(
              0xFF9E7180,
            ).withValues(
              alpha: 0.55,
            ),

            size: 36,
          ),

          const SizedBox(height: 9),

          const Text(
            'Belum ada riwayat absensi',

            style: TextStyle(
              color: Color(0xFF54283A),
              fontWeight:
                  FontWeight.w700,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Data absensi kamu akan muncul di sini.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color: const Color(
                0xFF9E7180,
              ).withValues(
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
              const EdgeInsets.symmetric(
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

        child: const Text(
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
            color: const Color(
              0xFFB98B9B,
            ).withValues(
              alpha: 0.20,
            ),
          ),
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
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
            const EdgeInsets.symmetric(
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
                  : const Color(
                      0xFF9E7180,
                    ).withValues(
                      alpha: 0.65,
                    ),
            ),

            const SizedBox(height: 3),

            Text(
              label,

              style: TextStyle(
                color: active
                    ? accentLight
                    : const Color(
                        0xFF9E7180,
                      ).withValues(
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