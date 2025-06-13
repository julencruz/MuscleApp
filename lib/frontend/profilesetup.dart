import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  static const _textStyle = TextStyle(fontSize: 16);
  static const _spacer30 = SizedBox(height: 30);

  static final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFA90015),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 20),
    minimumSize: const Size(250, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    )
  );

  Widget _buttonContainer(Widget child) => Align(
    alignment: Alignment.center,
    child: SizedBox(width: 250, child: child),
  );


  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/placeholder_avatar.png'),
              backgroundColor: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'EDIT PROFILE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 60),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatarSection(),
                _spacer30,
                TextFormField(decoration: _inputDecoration('Name')),
                _spacer30,
                TextFormField(
                  decoration: _inputDecoration('Weight'),
                  keyboardType: TextInputType.number,
                ),
                _spacer30,
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Gender'),
                  value: 'Woman',
                  items: const [
                    DropdownMenuItem(value: 'Woman', child: Text('Woman')),
                    DropdownMenuItem(value: 'Man', child: Text('Man')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {},
                ),
                _spacer30,
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Unit System'),
                  value: 'Metrics',
                  items: const [
                    DropdownMenuItem(
                      value: 'Metrics',
                      child: Text('Metrics (kg/cm)'),
                    ),
                    DropdownMenuItem(
                      value: 'Imperial',
                      child: Text('Imperial (lbs/ft)'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
                _spacer30,
                _buttonContainer(
                  ElevatedButton(
                    onPressed: () {},
                    style: _buttonStyle,
                    child: const Text('SAVE CHANGES', style: _textStyle),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
