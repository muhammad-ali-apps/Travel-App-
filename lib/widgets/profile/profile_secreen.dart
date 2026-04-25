import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_app/widgets/authantication/login.dart';
import 'package:travel_app/widgets/profile/upload_pic.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>?;
        } else {
          // Agar document exist nahi karta to default data create karenge
          userData = {
            'name': currentUser!.displayName ?? 'No Name',
            'email': currentUser!.email ?? 'No Email',
            'profileImage': 'https://picsum.photos/',
            'bio': 'Hey there! I am using Travel Book.',
            'uid': currentUser!.uid,
          };

          // Firestore mein save kar denge
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .set(userData!);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Default data set kar denge error ke case mein
      userData = {
        'name': currentUser?.displayName ?? 'No Name',
        'email': currentUser?.email ?? 'No Email',
        'profileImage': 'https://via.placeholder.com/150',
        'bio': 'Hey there! I am using Travel Book.',
      };
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Safe way to get field value with fallback
  String _getFieldValue(String fieldName, String fallback) {
    if (userData == null) return fallback;

    // Multiple field names ko check karte hain
    switch (fieldName) {
      case 'profileImage':
        return userData!['profileImage'] ??
            userData!['avatarUrl'] ??
            userData!['avatar'] ??
            fallback;
      case 'name':
        return userData!['name'] ??
            userData!['displayName'] ??
            currentUser?.displayName ??
            fallback;
      case 'email':
        return userData!['email'] ?? currentUser?.email ?? fallback;
      case 'bio':
        return userData!['bio'] ?? userData!['description'] ?? fallback;
      default:
        return userData![fieldName] ?? fallback;
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  String userName = '';
  String userProfilePic = '';

  void loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Guest';
      userProfilePic = prefs.getString('userProfilePic') ?? '';
    });

    print('Loaded Name: $userName');
    print('Loaded Profile Pic: $userProfilePic');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              String? uploadedImageUrl = await uploadProfilePicToImgBB();

              if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
                await saveToSharedPrefs(
                  _getFieldValue('name', 'No Name'),
                  uploadedImageUrl,
                );
                _loadUserData();
                loadUserData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundImage: userProfilePic.isNotEmpty
                  ? NetworkImage(userProfilePic)
                  : AssetImage('assets/default_avatar.jpg') as ImageProvider,
            ),
            SizedBox(width: 10),
            Text(
              userName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Name
            Text(
              _getFieldValue('name', 'No Name'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8),

            // Email
            Text(
              _getFieldValue('email', 'No Email'),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            SizedBox(height: 20),

            // Bio Card
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getFieldValue(
                        'bio',
                        'Hey there! I am using Travel Book.',
                      ),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // User Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('User ID', currentUser?.uid ?? 'N/A'),
                    Divider(),
                    _buildInfoRow(
                      'Email Verified',
                      currentUser?.emailVerified == true ? 'Yes' : 'No',
                    ),
                    Divider(),
                    _buildInfoRow(
                      'Account Created',
                      currentUser?.metadata.creationTime?.toString().split(
                            ' ',
                          )[0] ??
                          'N/A',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await uploadProfilePicToImgBB();
                      _loadUserData(); // Refresh Data
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Settings functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Settings coming soon!')),
                      );
                    },
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: Icon(Icons.logout),
                    label: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
