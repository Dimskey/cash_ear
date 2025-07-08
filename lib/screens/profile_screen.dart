import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('Profil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
              CircleAvatar(radius: 40, backgroundImage: NetworkImage(user!.photoUrl!))
            else
              CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            SizedBox(height: 16),
            Text(user?.name ?? '-', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(user?.email ?? '-', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
} 