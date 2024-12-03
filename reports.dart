import 'dart:typed_data'; // For Flutter Web to handle image bytes
import 'dart:io'; // For mobile file handling
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For base64 encoding
import '../reusable_widget/appbar_footer.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportageState();
}

class _ReportageState extends State<ReportPage> {
  // List of predefined locations
  final List<String> locations = ['Talic', 'Poblacion', 'Mobod', 'Labo'];

  // Updated text controllers to match naming convention
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _purokController = TextEditingController();

  // Updated selected values to match naming convention
  String? _selectedLocation;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  // Add this property
  final user = FirebaseAuth.instance.currentUser;

  // Add this property to track message visibility
  bool _showMessage = false;

  // Function to pick an image
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      if (kIsWeb) {
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final Uint8List imageBytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = imageBytes;
          });
        }
      } else {
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final File file = File(image.path);
          final Uint8List bytes = await file.readAsBytes();
          setState(() {
            _selectedImageFile = file;
            _selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Function to save data to Firestore
  Future<void> saveReport() async {
    if (_problemController.text.isEmpty ||
        _selectedLocation == null ||
        _purokController.text.isEmpty ||
        _landmarkController.text.isEmpty ||
        (_selectedImageFile == null && _selectedImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill in all fields and upload an image.')),
      );
      return;
    }

    try {
      CollectionReference reports =
          FirebaseFirestore.instance.collection('reports');

      // Convert image to base64
      String? base64Image;
      if (_selectedImageBytes != null) {
        base64Image = base64Encode(_selectedImageBytes!);
      }

      await reports.add({
        'report': _problemController.text,
        'purok': _purokController.text,
        'barangay': _selectedLocation,
        'landmark': _landmarkController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'image': base64Image,
      });

      // Clear inputs
      _problemController.clear();
      _purokController.clear();
      _landmarkController.clear();
      setState(() {
        _selectedLocation = null;
        _selectedImageFile = null;
        _selectedImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    }
  }

  Widget _buildReportHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Text(
                'Note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showMessage = !_showMessage;
                  });
                },
                child: Icon(Icons.info_outline, color: Colors.orange[700]),
              ),
            ],
          ),
        ),
        if (_showMessage)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 1.5),
            ),
            child: Text(
              'Please provide right information to the area and the problem.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFFFD89D), width: 1.5),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          spreadRadius: 1,
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              buildCustomAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Header
                      _buildReportHeader(),

                      // Problem Description TextField
                      _buildProblemTextField(textFieldDecoration),

                      // Location Fields
                      _buildLocationFields(textFieldDecoration),

                      // Image Upload
                      _buildImageUpload(),

                      // Submit Button
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildCustomBottomNavBar(context),
    );
  }

  Widget _buildProblemTextField(BoxDecoration decoration) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: decoration,
      child: TextFormField(
        controller: _problemController,
        maxLines: 2,
        style: TextStyle(fontSize: 14),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(12),
          labelText: 'Describe the issue in detail',
          labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon:
              Icon(Icons.description_outlined, color: Colors.orange[700]),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLocationFields(BoxDecoration decoration) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                decoration: decoration,
                child: TextFormField(
                  controller: _purokController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    labelText: 'Purok',
                    labelStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: Colors.orange[700]),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: decoration,
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedLocation,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Select Barangay',
                    labelStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    prefixIcon:
                        Icon(Icons.map_outlined, color: Colors.orange[700]),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  items: locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: decoration,
          child: TextFormField(
            controller: _landmarkController,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              labelText: 'Landmark',
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              prefixIcon: Icon(Icons.place_outlined, color: Colors.orange[700]),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUpload() {
    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 24),
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFFFD89D), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: pickImage,
        child: _selectedImageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _selectedImageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : _selectedImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 24,
                          color: Colors.orange[700],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: 120,
        child: ElevatedButton(
          onPressed: saveReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(221, 237, 169, 52),
            minimumSize: Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
          ),
          child: Text(
            'Submit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
