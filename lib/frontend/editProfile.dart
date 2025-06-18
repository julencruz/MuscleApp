import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muscle_app/backend/edit_profile.dart';
import 'package:muscle_app/backend/register_login.dart';
import 'package:muscle_app/frontend/login.dart';
import 'package:muscle_app/backend/update_dock.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  String _gender = 'Woman';
  String _unit = 'Metric';
  final _service = ProfileService();
  final _accentColor = const Color(0xFFD32F2F);
  final _background = Colors.grey.shade50;

  bool _isLoading = true; // <--- Añadido

  @override
  void initState() {
    super.initState();
    // Cargar datos del usuario al iniciar
    _loadUserData();
  }

  // Método para cargar los datos del usuario
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
            _unit = userData['unidades'] ?? 'Metric';
            _unit = _unit[0].toUpperCase() + _unit.substring(1).toLowerCase();
            _isLoading = false; // <--- Solo aquí dejamos de cargar
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error al cargar los datos del usuario: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
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
        SnackBar(
          content: const Text('Changes saved successfully'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: $e'),
        ),
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
                  color: Colors.grey.shade800
                )),
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
        backgroundColor: Colors.white,
        title: Text('Edit Name', style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    UpdateDock.updateSystemUI(Colors.grey[50]!);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
              UpdateDock.updateSystemUI(Colors.white);
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
            UpdateDock.updateSystemUI(Colors.white);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _buildProfileHeader(),
                _buildSectionTitle('ACCOUNT'),
                _buildSettingsCard(
                  children: [
                    _buildEditableTile(
                      icon: Icons.person_outline,
                      title: 'Name',
                      value: _nameController.text,
                      onTap: _showNameDialog,
                    ),
                    Divider(height: 1, indent: 56, color: Colors.grey.shade200),
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
                  ],
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('PREFERENCES'),
                _buildSettingsCard(
                  children: [
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
                  ],
                ),
                const SizedBox(height: 36),
                _buildSaveButton(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
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
              border: Border.all(color: _accentColor, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: _background,
              child: Icon(Icons.person, size: 56, color: _accentColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800
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
          color: Colors.grey.shade600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade100, width: 1.5),
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
      leading: Icon(icon, color: Colors.grey.shade700, size: 26),
      title: Text(title, style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
        fontSize: 16
      )),
      subtitle: Text(value.isEmpty ? 'Not set' : value,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      trailing: Icon(Icons.chevron_right, 
        color: Colors.grey.shade400, size: 28),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minVerticalPadding: 0,
      onTap: onTap,
    );
  }

  Widget _buildGenderOption(String value) {
    return ListTile(
      title: Text(value, style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 16
      )),
      leading: Radio<String>(
        value: value,
        groupValue: _gender,
        activeColor: _accentColor,
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
      title: Text(value, style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 16
      )),
      leading: Radio<String>(
        value: value,
        groupValue: _unit,
        activeColor: _accentColor,
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
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 1,
        shadowColor: _accentColor.withOpacity(0.2),
      ),
      child: const Text('Save Changes', 
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      child: Text(
        'Log Out',
        style: TextStyle(
          color: _accentColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5
        ),
      ),
    );
  }
}