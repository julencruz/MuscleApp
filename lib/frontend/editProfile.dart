import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muscle_app/backend/edit_profile.dart';
import 'package:muscle_app/backend/register_login.dart';
import 'package:muscle_app/frontend/login.dart';
import 'package:muscle_app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class EditProfileDrawer extends StatefulWidget {
  const EditProfileDrawer({super.key});

  @override
  State<EditProfileDrawer> createState() => _EditProfileDrawerState();
}

class _EditProfileDrawerState extends State<EditProfileDrawer> {
  final _nameController = TextEditingController();
  String _gender = 'Woman';
  String _unit = 'Metric';
  final _service = ProfileService();
  bool _isLoading = true;
  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme') ?? 'system';
    setState(() {
      if (savedTheme == 'light') {
        _themeMode = AppThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = AppThemeMode.dark;
      } else {
        _themeMode = AppThemeMode.system;
      }
    });
    _applyTheme(_themeMode);
  }

  Future<void> _applyTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    switch (mode) {
      case AppThemeMode.light:
        setLightThemeColors();
        themeString = 'light';
        break;
      case AppThemeMode.dark:
        setDarkThemeColors();
        themeString = 'dark';
        break;
      case AppThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        if (brightness == Brightness.dark) {
          setDarkThemeColors();
        } else {
          setLightThemeColors();
        }
        themeString = 'system';
        break;
    }
    await prefs.setString('theme', themeString);
    setState(() {});
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = userData['nombre'] ?? '';
            _gender = userData['genero'] ?? 'Woman';
            _unit = (userData['unidades'] ?? 'Metric');
            _unit = _unit[0].toUpperCase() + _unit.substring(1).toLowerCase();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('Error al cargar los datos del usuario: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      await _service.updateUserProfile(
        name: _nameController.text.trim(),
        gender: _gender,
        unit: _unit,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved succesfully', style: TextStyle(color: contraryTextColor)), backgroundColor: snackBarBackgroundColor),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes', style: TextStyle(color: contraryTextColor)), backgroundColor: snackBarBackgroundColor),
      );
    }
  }

  void _showSelectionSheet({required String title, required List<Widget> options}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: hintColor)),
            ),
            ...options,
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Edit Name', style: TextStyle(color: textColor)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dividerColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: hintColor)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: backgroundColor,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      children: [
                        _buildProfileHeader(),
                        _buildSectionTitle('ACCOUNT'),
                        _buildSettingsCard(children: [
                          _buildEditableTile(
                            icon: Icons.person_outline,
                            title: 'Name',
                            value: _nameController.text,
                            onTap: _showNameDialog,
                          ),
                          Divider(height: 1, indent: 56, color: dividerColor),
                          _buildEditableTile(
                            icon: Icons.people_alt_outlined,
                            title: 'Gender',
                            value: _gender,
                            onTap: () => _showSelectionSheet(
                              title: 'Select Gender',
                              options: [
                                _buildGenderOption('Woman'),
                                _buildGenderOption('Man'),
                                _buildGenderOption('Other'),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 28),
                        _buildSectionTitle('PREFERENCES'),
                        _buildSettingsCard(children: [
                          _buildEditableTile(
                            icon: Icons.straighten_outlined,
                            title: 'Measurement System',
                            value: _unit,
                            onTap: () => _showSelectionSheet(
                              title: 'Select Unit System',
                              options: [
                                _buildUnitOption('Metric'),
                                _buildUnitOption('Imperial'),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 28),
                        _buildSectionTitle('APPEARANCE'),
                        _buildSettingsCard(children: [
                          _buildEditableTile(
                            icon: Icons.brightness_6_outlined,
                            title: 'Theme',
                            value: _themeMode == AppThemeMode.system
                                ? 'System'
                                : _themeMode == AppThemeMode.light
                                    ? 'Light'
                                    : 'Dark',
                            onTap: () => _showSelectionSheet(
                              title: 'Select Theme',
                              options: [
                                _buildThemeOption(AppThemeMode.system, 'System'),
                                _buildThemeOption(AppThemeMode.light, 'Light'),
                                _buildThemeOption(AppThemeMode.dark, 'Dark'),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 36),
                        _buildSaveButton(),
                        const SizedBox(height: 24),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeOption(AppThemeMode mode, String label) {
    return ListTile(
      title: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
      leading: Radio<AppThemeMode>(
        value: mode,
        groupValue: _themeMode,
        activeColor: redColor,
        onChanged: (v) {
          setState(() {
            _themeMode = v!;
            _applyTheme(_themeMode);
            Navigator.pop(context);
          });
        },
      ),
      onTap: () {
        setState(() {
          _themeMode = mode;
          _applyTheme(_themeMode);
          Navigator.pop(context);
        });
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: redColor, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: backgroundColor,
              child: Icon(Icons.person, size: 56, color: redColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: hintColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: dividerColor, width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditableTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: hintColor, size: 26),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
              fontSize: 16)),
      subtitle: Text(value.isEmpty ? 'Not set' : value,
          style: TextStyle(color: hintColor, fontSize: 14)),
      trailing: Icon(Icons.chevron_right, color: hintColor, size: 28),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minVerticalPadding: 0,
      onTap: onTap,
    );
  }

  Widget _buildGenderOption(String value) {
    return ListTile(
      title: Text(value, style: TextStyle(color: textColor, fontSize: 16)),
      leading: Radio<String>(
        value: value,
        groupValue: _gender,
        activeColor: redColor,
        onChanged: (v) => setState(() {
          _gender = v!;
          Navigator.pop(context);
        }),
      ),
      onTap: () => setState(() {
        _gender = value;
        Navigator.pop(context);
      }),
    );
  }

  Widget _buildUnitOption(String value) {
    return ListTile(
      title: Text(value, style: TextStyle(color: textColor, fontSize: 16)),
      leading: Radio<String>(
        value: value,
        groupValue: _unit,
        activeColor: redColor,
        onChanged: (v) => setState(() {
          _unit = v!;
          Navigator.pop(context);
        }),
      ),
      onTap: () => setState(() {
        _unit = value;
        Navigator.pop(context);
      }),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: redColor,
        foregroundColor: contraryTextColor,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        shadowColor: backgroundColor.withOpacity(0.2),
      ),
      child: const Text('Save Changes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () {
        AuthService.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged out successfully'),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      child: Text(
        'Log Out',
        style: TextStyle(
          color: redColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
