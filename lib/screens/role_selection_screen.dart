import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  final _adminPasswordController = TextEditingController();
  String? _error;
  String? _adminPasswordRemote;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminPassword();
  }

  Future<void> _fetchAdminPassword() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    setState(() {
      _adminPasswordRemote = remoteConfig.getString('admin_password');
      _loading = false;
    });
  }

  void _proceed() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_selectedRole == 'admin') {
      if (_adminPasswordController.text == _adminPasswordRemote) {
        await auth.updateRole('admin');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          _error = 'Sandi admin salah!';
        });
      }
    } else if (_selectedRole == 'kasir') {
      await auth.updateRole('kasir');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Pilih Role')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Pilih Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Masuk sebagai:', style: TextStyle(fontSize: 20)),
              SizedBox(height: 24),
              RadioListTile<String>(
                title: Text('Admin'),
                value: 'admin',
                groupValue: _selectedRole,
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val;
                    _error = null;
                  });
                },
              ),
              if (_selectedRole == 'admin')
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: TextField(
                    controller: _adminPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Sandi Admin',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              RadioListTile<String>(
                title: Text('Kasir'),
                value: 'kasir',
                groupValue: _selectedRole,
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val;
                    _error = null;
                  });
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedRole == null ? null : _proceed,
                child: Text('Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 