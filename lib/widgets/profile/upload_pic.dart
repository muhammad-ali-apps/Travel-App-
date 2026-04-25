import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:img_picker/img_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> uploadProfilePicToImgBB() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) {
    print('No image selected.');
    return null;
  }

  File imageFile = File(pickedFile.path);
  String apiKey =
      '0b83d7e3d3051232d1601746914f2420'; // Replace with your imgbb API Key
  String base64Image = base64Encode(imageFile.readAsBytesSync());

  final response = await http.post(
    Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
    body: {'image': base64Image},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    String imageUrl = data['data']['url'];

    // Firestore me save
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImage': imageUrl,
    });

    // SharedPreferences me save
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfilePic', imageUrl);

    print('Profile Picture Uploaded to imgbb Successfully!');
    return imageUrl; // <-- yeh add kiya
  } else {
    print('Failed to upload image: ${response.body}');
    return null; // Error case
  }
}

Future<void> saveToSharedPrefs(String name, String imageUrl) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userName', name);
  await prefs.setString('userProfilePic', imageUrl);
}
