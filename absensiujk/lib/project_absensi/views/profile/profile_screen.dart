import 'package:flutter/material.dart';
import '../../reusable/app_theme.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // DATA
  // ============================================================
  String name = 'Memuat...';
  String email = 'Memuat...';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET PROFILE
  // ============================================================
  Future<void> getUserData() async {
    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          name = '-';
          email = '-';
        });

        return;
      }

      final response = await ApiServices().getProfile(token: token);

      if (response.statusCode == 200) {
        final user = response.data['data'];

        if (!mounted) return;

        setState(() {
          name = user['name'] ?? '-';
          email = user['email'] ?? '-';
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil profile: $e'),
          backgroundColor: AppPalette.snack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================
  Future<void> updateProfile() async {
    final token = await StorageServices.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama dan email tidak boleh kosong'),
          backgroundColor: AppPalette.snack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      return;
    }

    try {
      final response = await ApiServices().updateProfile(
        token: token,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (response.statusCode == 200) {
        await StorageServices.saveUser(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
        );

        await getUserData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                SizedBox(width: 9),
                Text('Profile berhasil diperbarui'),
              ],
            ),
            backgroundColor: AppPalette.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update profile: $e'),
          backgroundColor: AppPalette.snack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================
  void openEditProfile() {
    nameController.text = name;
    emailController.text = email;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 12,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + 25,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppPalette.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: 25),

                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Perbarui informasi akun kamu',
                  style: TextStyle(
                    color: AppPalette.textSecondary,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: 25),

                _editField(
                  controller: nameController,
                  label: 'Nama',
                  icon: Icons.person_outline_rounded,
                ),

                SizedBox(height: 16),

                _editField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await updateProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EDIT FIELD
  // ============================================================
  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 8),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppPalette.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppPalette.accentLight,
            ),
            filled: true,
            fillColor: AppPalette.card2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppPalette.accent,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppPalette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari akun?',
            style: TextStyle(
              color: AppPalette.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
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
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.snack,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await StorageServices.removeToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // DARK MODE
  // ============================================================
  Future<void> changeTheme(bool value) async {
    await ThemeController.setDark(value);
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, _, __) => _buildThemed(context),
    );
  }

  Widget _buildThemed(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: RefreshIndicator(
        color: AppPalette.accent,
        onRefresh: getUserData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHero(),

              SizedBox(height: 22),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    _buildAccountCard(),

                    SizedBox(height: 16),

                    _buildSettingsCard(),

                    SizedBox(height: 16),

                    _buildLogoutCard(),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HERO
  // ============================================================
  Widget _buildProfileHero() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        55,
        18,
        28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.chip,
            AppPalette.card,
            AppPalette.bg,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          // TOP BAR
          Row(
            children: [
              _circleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              Spacer(),

              Text(
                'Profile',
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),

              Spacer(),

              _circleButton(
                icon: Icons.more_horiz_rounded,
                onTap: () {},
              ),
            ],
          ),

          SizedBox(height: 35),

          // AVATAR
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppPalette.accentLight,
                      AppPalette.accent,
                      AppPalette.accentDeep,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.accent
                          .withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.bg,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/image/a.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color: AppPalette.card2,
                          child: Icon(
                            Icons.person_rounded,
                            size: 55,
                            color: AppPalette.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              Positioned(
                right: -3,
                bottom: 5,
                child: GestureDetector(
                  onTap: openEditProfile,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.accent,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 5),

          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 13,
            ),
          ),

          SizedBox(height: 15),

          // ACTIVE BADGE
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppPalette.accent
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppPalette.accent
                    .withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppPalette.accentLight,
                  size: 16,
                ),

                SizedBox(width: 7),

                Text(
                  'Pengguna Aktif',
                  style: TextStyle(
                    color: AppPalette.accentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CIRCLE BUTTON
  // ============================================================
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppPalette.card2,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 43,
          height: 43,
          child: Icon(
            icon,
            color: AppPalette.accentLight,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================
  Widget _buildAccountCard() {
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.person_rounded,
            title: 'Informasi Akun',
            subtitle: 'Data pribadi dan akun kamu',
          ),

          SizedBox(height: 20),

          _profileRow(
            icon: Icons.person_outline_rounded,
            title: 'Nama',
            value: name,
            onTap: openEditProfile,
          ),

          SizedBox(height: 10),

          _profileRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
            onTap: () {},
          ),

          SizedBox(height: 14),

          // EDIT BUTTON
          Material(
            color: AppPalette.accent
                .withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: openEditProfile,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppPalette.accent
                        .withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: AppPalette.accentLight,
                      size: 20,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: AppPalette.accentLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppPalette.accentLight,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE ROW
  // ============================================================
  Widget _profileRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppPalette.card2,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: AppPalette.card,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppPalette.accent
                      .withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AppPalette.accentLight,
                  size: 21,
                ),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppPalette.divider,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================
  Widget _buildSettingsCard() {
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.settings_rounded,
            title: 'Pengaturan',
            subtitle: 'Sesuaikan tampilan aplikasi',
          ),

          SizedBox(height: 20),

          ValueListenableBuilder<bool>(
            valueListenable:
                ThemeController.isDarkMode,
            builder: (
              context,
              isDarkMode,
              child,
            ) {
              return Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.card2,
                  borderRadius:
                      BorderRadius.circular(19),
                  border: Border.all(
                    color: AppPalette.card,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppPalette.accent
                            .withValues(alpha: 0.09),
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppPalette.accentLight,
                        size: 22,
                      ),
                    ),

                    SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: AppPalette.textPrimary,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Mode gelap untuk kenyamanan mata',
                            style: TextStyle(
                              color: AppPalette.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: isDarkMode,
                      onChanged: changeTheme,
                      activeThumbColor:
                          Colors.white,
                      activeTrackColor:
                          AppPalette.accent,
                      inactiveThumbColor:
                          Colors.white70,
                      inactiveTrackColor:
                          AppPalette.chip,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DARK CARD
  // ============================================================
  Widget _darkCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppPalette.card2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // CARD HEADER
  // ============================================================
  Widget _cardHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.accentLight,
                AppPalette.accent,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),

        SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),

              SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGOUT CARD
  // ============================================================
  Widget _buildLogoutCard() {
    return Material(
      color: AppPalette.card2,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: logout,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: AppPalette.snack
                  .withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: AppPalette.snack
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppPalette.snack,
                  size: 21,
                ),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppPalette.snack,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Keluar dari akun ini',
                      style: TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppPalette.snack,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}