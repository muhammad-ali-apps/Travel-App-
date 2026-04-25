// Helper function to build rating sectionimport 'dart:io'; // For handling image files
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore for database
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart'; // Flutter UI components

// Main screen widget for creating posts
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

User? currentUser;

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Text controllers to get input from text fields
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _avatorcontroller =
      TextEditingController(); // For image URL input
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Variables to store app state
  List<File> _selectedImages =
      []; // List to store selected images (for preview only)
  List<String> _imageUrls = [];
  double _rating = 5.0; // Rating value (1-5 stars)
  bool _isLoading = false; // To show loading indicator

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Firestore database

  // Clean up controllers when widget is destroyed
  @override
  void dispose() {
    _captionController.dispose(); // Free memory
    _descriptionController.dispose(); // Free memory
    _locationController.dispose(); // Free memory
    _imageUrlController.dispose();
    _avatorcontroller.dispose();
    _namecontroller.dispose(); // Free memory
    super.dispose();
  }

  // Function to add image URL to list
  void _addImageUrl() {
    String imageUrl = _imageUrlController.text.trim();

    // Check if URL is not empty
    if (imageUrl.isNotEmpty) {
      // Basic URL validation - check if it looks like an image URL
      if (imageUrl.startsWith('http') &&
          (imageUrl.contains('.jpg') ||
              imageUrl.contains('.jpeg') ||
              imageUrl.contains('.png') ||
              imageUrl.contains('.gif'))) {
        setState(() {
          _imageUrls.add(imageUrl); // Add URL to list
        });

        _imageUrlController.clear(); // Clear input field

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image URL added! 🖼️'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error for invalid URL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid image URL (jpg, jpeg, png, gif)',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to save post data to Firestore database
  Future<void> _savePostToFirestore() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    String profilename = userDoc['name'] ?? 'Guest';
    // Get text from input fields
    String caption = _captionController.text.trim(); // Remove extra spaces
    String description = _descriptionController.text
        .trim(); // Remove extra spaces
    String location = _locationController.text.trim(); // Remove extra spaces
    String imgURL = _imageUrlController.text.trim();

    // Check if required fields are filled
    if (caption.isEmpty || description.isEmpty || location.isEmpty) {
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill Caption, Description, and Location'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop execution
    }

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      print('Starting to save post...'); // Debug log

      // Create post data object
      Map<String, dynamic> postData = {
        'profilename': profilename,
        'caption': caption, // Post caption
        'description': description, // Post description
        'location': location, // Post location
        'rating': _rating, // User rating
        'likes': [], // Array of user IDs who liked
        'likesCount': 0,
        'imageUrls': imgURL, // List of image URLs (directly from input)
        'timestamp': FieldValue.serverTimestamp(), // Server timestamp
        'createdAt': DateTime.now().toIso8601String(), // Local timestamp
      };

      print('Saving post data to Firestore...'); // Debug log
      print('Post data: $postData'); // Debug log to see what's being saved

      // Save post to Firestore database
      DocumentReference docRef = await _firestore
          .collection('post') // Collection name
          .add(postData); // Add document with data

      print('Post saved with ID: ${docRef.id}'); // Debug log

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form after successful save
      _clearForm();
    } on FirebaseException catch (e) {
      // Handle Firebase specific errors
      print('Firebase Error: ${e.code} - ${e.message}'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle any other errors
      print('General Error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide loading indicator (always runs)
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to clear all form data
  void _clearForm() {
    _captionController.clear(); // Clear caption field
    _descriptionController.clear(); // Clear description field
    _locationController.clear(); // Clear location field
    _imageUrlController.clear(); // Clear image URL field
    setState(() {
      _selectedImages.clear(); // Remove all selected images
      _imageUrls.clear(); // Remove all image URLs
      _rating = 5.0; // Reset rating to 5 stars
    });
  }

  // Function to remove image URL from list
  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index); // Remove URL at specific index
    });

    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image URL removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  // Build the main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background color
      // App bar at the top
      appBar: AppBar(
        backgroundColor: Colors.white, // White background
        elevation: 1, // Small shadow
        title: const Text(
          'Create Post', // Title text
          style: TextStyle(
            color: Colors.black87, // Dark text color
            fontWeight: FontWeight.bold, // Bold text
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87), // Close icon
          onPressed: () => Navigator.pop(context), // Go back when pressed
        ),
        actions: [
          // Publish button in app bar
          TextButton(
            onPressed: _isLoading
                ? null
                : _savePostToFirestore, // Disable when loading
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ), // Loading spinner
                  )
                : const Text(
                    'Publish', // Button text
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),

      // Main content body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), // Padding around content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align to left
          children: [
            // Section title
            const Text(
              'Share Your Experience',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8), // Space between elements
            // Section subtitle
            const Text(
              'Tell others about your amazing journey',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24), // Space between elements
            // Caption input field
            _buildInputField(
              controller: _captionController,
              label: 'Tittle *',
              hint: 'What\'s on your mind?',
              maxLines: 2,
              icon: Icons.edit,
            ),
            const SizedBox(height: 16), // Space between elements
            // Description input field
            _buildInputField(
              controller: _descriptionController,
              label: 'Description *',
              hint: 'Share details about your experience...',
              maxLines: 4,
              icon: Icons.description,
            ),
            const SizedBox(height: 16), // Space between elements
            // Location input field
            _buildInputField(
              controller: _locationController,
              label: 'Location *',
              hint: 'Where was this taken?',
              maxLines: 1,
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16), // Space between elements
            // Image URL input field
            _buildImageUrlInput(),
            const SizedBox(height: 20), // Space between elements
            // Rating section
            _buildRatingSection(),
            const SizedBox(height: 20), // Space between elements
            // Images section
            _buildImagesSection(),
          ],
        ),
      ),
    );
  }

  // Helper function to build input text fields
  Widget _buildInputField({
    required TextEditingController controller, // Text controller
    required String label, // Field label
    required String hint, // Placeholder text
    required int maxLines, // Maximum lines
    required IconData icon, // Icon to show
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Light shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller, // Connect controller
        maxLines: maxLines, // Set maximum lines
        decoration: InputDecoration(
          labelText: label, // Label text
          hintText: hint, // Hint text
          prefixIcon: Icon(icon, color: Colors.blue), // Icon with blue color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Rounded border
            borderSide: BorderSide.none, // No border line
          ),
          filled: true, // Fill background
          fillColor: Colors.white, // White fill color
        ),
      ),
    );
  }

  // Helper function to build image URL input section
  Widget _buildImageUrlInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Light shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image URL input field
          TextField(
            controller: _imageUrlController, // Connect controller
            decoration: InputDecoration(
              labelText: 'Image URL', // Label text
              hintText:
                  'Enter image URL (https://example.com/image.jpg)', // Hint text
              prefixIcon: const Icon(
                Icons.link,
                color: Colors.blue,
              ), // Link icon
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.green), // Add icon
                onPressed: _addImageUrl, // Function to add URL
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), // Rounded border
                borderSide: BorderSide.none, // No border line
              ),
              filled: true, // Fill background
              fillColor: Colors.white, // White fill color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16), // Padding inside container
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Light shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align left
        children: [
          // Section header
          const Row(
            children: [
              Icon(Icons.star, color: Colors.orange), // Star icon
              SizedBox(width: 8), // Space between icon and text
              Text(
                'Rate Your Experience',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12), // Space between elements
          // Star rating row
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Space between elements
            children: [
              // Star buttons
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1.0; // Set rating (1-5)
                      });
                    },
                    child: Icon(
                      index < _rating
                          ? Icons.star
                          : Icons.star_outline, // Filled or outline
                      color: Colors.orange, // Orange color
                      size: 32, // Icon size
                    ),
                  );
                }),
              ),
              // Rating text
              Text(
                '${_rating.toInt()}/5', // Show current rating
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper function to build images section
  Widget _buildImagesSection() {
    // Return empty widget if no image URLs added
    if (_imageUrls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32), // Large padding
        decoration: BoxDecoration(
          color: Colors.grey[100], // Light grey background
          borderRadius: BorderRadius.circular(12), // Rounded corners
          border: Border.all(color: Colors.grey[300]!), // Grey border
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.link, // Link icon for URLs
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8), // Space between icon and text
              Text(
                'No image URLs added',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4), // Space between texts
              Text(
                'Add image URLs above to display them here',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show image URLs list
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Light shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align left
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16), // Padding around header
            child: Row(
              children: [
                const Icon(Icons.image, color: Colors.blue), // Image icon
                const SizedBox(width: 8), // Space between icon and text
                Text(
                  'Image URLs (${_imageUrls.length})', // Show count
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // URLs list
          ListView.builder(
            shrinkWrap: true, // Take only needed space
            physics: const NeverScrollableScrollPhysics(), // Disable scroll
            itemCount: _imageUrls.length, // Number of URLs
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ), // Margins
                padding: const EdgeInsets.all(12), // Internal padding
                decoration: BoxDecoration(
                  color: Colors.grey[50], // Light background
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                  border: Border.all(color: Colors.grey[200]!), // Light border
                ),
                child: Row(
                  children: [
                    // URL preview image
                    Container(
                      width: 50, // Fixed width
                      height: 50, // Fixed height
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // Rounded corners
                        color: Colors.grey[200], // Placeholder color
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // Clip to rounded corners
                        child: Image.network(
                          _imageUrls[index], // Load image from URL
                          fit: BoxFit.cover, // Cover entire container
                          errorBuilder: (context, error, stackTrace) {
                            // Show error icon if image fails to load
                            return const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 24,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            // Show loading indicator while image loads
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Space between image and text
                    // URL text (truncated if too long)
                    Expanded(
                      child: Text(
                        _imageUrls[index], // Show URL
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2, // Maximum 2 lines
                        overflow: TextOverflow.ellipsis, // Show ... if too long
                      ),
                    ),
                    const SizedBox(width: 8), // Space before remove button
                    // Remove button
                    GestureDetector(
                      onTap: () =>
                          _removeImageUrl(index), // Remove URL when tapped
                      child: Container(
                        padding: const EdgeInsets.all(6), // Small padding
                        decoration: const BoxDecoration(
                          color: Colors.red, // Red background
                          shape: BoxShape.circle, // Circular shape
                        ),
                        child: const Icon(
                          Icons.close, // Close icon
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16), // Space at bottom
        ],
      ),
    );
  }
}
