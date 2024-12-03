import 'package:flutter/material.dart';
import '../reusable_widget/appbar_footer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui'; // Import this for the blur effect

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Add dark mode state
  bool isDarkMode = false;

  // Add controller variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _purokController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  String? _avatarPath;

  // Add user email variable
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  // Add new method to handle initialization
  Future<void> _initializeUserData() async {
    try {
      // First try to get email from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('userEmail');

      if (savedEmail != null) {
        setState(() {
          userEmail = savedEmail;
        });
        await _loadUserData(); // Load data after getting email
        await _loadLocalUserData(); // Load data from SharedPreferences
      } else {
        // Fallback to Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          setState(() {
            userEmail = user.email;
          });
          await _loadUserData();
          await _loadLocalUserData();
        } else {
          // If no user is found, redirect to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error initializing user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error loading user data. Please try logging in again.')),
      );
      // Navigate to login screen if there's an error
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Add new method to load data from SharedPreferences
  Future<void> _loadLocalUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('userFullName') ?? '';
        _mobileController.text = prefs.getString('userPhone') ?? '';
      });
    } catch (e) {
      print('Error loading local user data: $e');
    }
  }

  // Update the load user data method
  Future<void> _loadUserData() async {
    try {
      if (userEmail == null) return;

      final QuerySnapshot userData = await FirebaseFirestore.instance
          .collection('user')
          .where('Email', isEqualTo: userEmail)
          .get();

      if (userData.docs.isNotEmpty) {
        final userDoc = userData.docs.first.data() as Map<String, dynamic>;

        // Save data to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'userFullName', userDoc['Full Name']?.toString() ?? '');
        await prefs.setString('userPhone', userDoc['Phone']?.toString() ?? '');

        setState(() {
          _nameController.text = userDoc['Full Name']?.toString() ?? '';
          _ageController.text = userDoc['Age']?.toString() ?? '';
          _mobileController.text = userDoc['Phone']?.toString() ?? '';
          _purokController.text = userDoc['Purok']?.toString() ?? '';
          _barangayController.text = userDoc['Barangay']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  // Update the check missing fields method to match registration field names
  void _checkMissingFields(Map<String, dynamic> userDoc) {
    final requiredFields = {
      'Full Name': _nameController,
      'Phone': _mobileController,
      'age': _ageController,
      'purok': _purokController,
      'barangay': _barangayController,
    };

    requiredFields.forEach((field, controller) {
      if (userDoc[field] == null || userDoc[field].toString().isEmpty) {
        print('Missing field: $field');
      }
    });
  }

  // Add method to handle image picking
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // For web, you might want to handle the image differently
        // For example, you could upload it to storage and get a URL
        setState(() {
          _avatarPath = image.path; // This will be a blob URL on web
        });
      } else {
        setState(() {
          _avatarPath = image.path;
        });
      }
    }
  }

  Widget _buildAvatarImage() {
    if (_avatarPath == null) {
      return Icon(
        Icons.add_a_photo,
        size: 40,
        color: Colors.purple[700],
      );
    }

    // Check if running on web
    if (kIsWeb) {
      // For web, you'll need to handle the image differently
      // This assumes you're storing the web image as a network URL
      return Image.network(
        _avatarPath!,
        fit: BoxFit.cover,
      );
    } else {
      // For mobile platforms, use File
      return Image.file(
        File(_avatarPath!),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildCustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              // Main container - removed positioning since it's no longer in a Stack
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dark Mode Switch
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.dark_mode, color: Colors.purple[700]),
                              SizedBox(width: 12),
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: isDarkMode,
                            onChanged: (value) {
                              setState(() {
                                isDarkMode = value;
                              });
                            },
                            activeColor: Colors.purple[700],
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey[300]),

                    // Contact Information
                    _buildOptionRow(
                      'Contact Information',
                      Icons.contact_mail,
                      () => _showContactInfoDialog(),
                    ),

                    Divider(height: 1, color: Colors.grey[300]),

                    // Customer Service
                    _buildOptionRow(
                      'Customer Service',
                      Icons.headset_mic,
                      () {/* navigation */},
                    ),

                    Divider(height: 1, color: Colors.grey[300]),

                    // Community Guidelines
                    _buildOptionRow(
                      'Community Guidelines',
                      Icons.people,
                      () {/* navigation */},
                    ),

                    Divider(height: 1, color: Colors.grey[300]),

                    // Add Logout button inside container
                    InkWell(
                      onTap: () {
                        // Add logout functionality
                      },
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red[400]),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[400],
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildCustomBottomNavBar(context),
    );
  }

  // New helper method for option rows
  Widget _buildOptionRow(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple[700]),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showContactInfoDialog() {
    // First check if all required fields are filled
    bool isProfileComplete = _nameController.text.isNotEmpty &&
        _ageController.text.isNotEmpty &&
        _mobileController.text.isNotEmpty &&
        _purokController.text.isNotEmpty &&
        _barangayController.text.isNotEmpty;

    if (isProfileComplete) {
      // Show completed profile dialog with edit option
      _showCompletedProfileDialog();
    } else {
      // Show the existing dialog for incomplete profile
      _showIncompleteProfileDialog();
    }
  }

  // Add new method for showing completed profile
  void _showCompletedProfileDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5), // Dim the background
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Apply blur
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFBD59), Color(0xFFFF9000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LinePainter(),
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFFFFBD59),
                              width: 2,
                            ),
                            image: _avatarPath != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(_avatarPath!)
                                        : FileImage(File(_avatarPath!))
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _avatarPath == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color(0xFFFFBD59),
                                )
                              : null,
                        ),
                        SizedBox(height: 16),

                        // Info Cards
                        ..._buildInfoCards(),

                        SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close, size: 18),
                                label: Text('Close',
                                    style: TextStyle(fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFFBD59),
                                      Color(0xFFFF9000)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showIncompleteProfileDialog();
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfoCards() {
    // First create the basic info cards
    final basicInfoData = [
      {
        'icon': Icons.person,
        'label': 'Full Name',
        'value': _nameController.text
      },
      {'icon': Icons.cake, 'label': 'Age', 'value': _ageController.text},
      {'icon': Icons.phone, 'label': 'Phone', 'value': _mobileController.text},
    ];

    // Create list of cards starting with basic info
    List<Widget> cards = basicInfoData
        .map((info) => _buildBasicInfoCard(
              icon: info['icon'] as IconData,
              label: info['label'] as String,
              value: info['value'] as String,
            ))
        .toList();

    // Add the combined address card
    cards.add(_buildAddressCard());

    return cards;
  }

  Widget _buildBasicInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color(0xFFFFBD59).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Color(0xFFFFBD59),
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color(0xFFFFBD59).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.location_on,
              color: Color(0xFFFFBD59),
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purok field (smaller width)
                    Flexible(
                      flex: 2, // Takes up less space
                      child: Text(
                        'Purok ${_purokController.text}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    // Barangay field (larger width)
                    Flexible(
                      flex: 5, // Takes up more space
                      child: Text(
                        'Barangay ${_barangayController.text}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rename existing dialog show method
  void _showIncompleteProfileDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuint,
          )),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Updated Header color
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBD59), // Updated color
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Complete Profile Information:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Content wrapped in Expanded
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar and form fields
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Avatar picker
                                  Hero(
                                    tag: 'avatar',
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[200],
                                          border: Border.all(
                                            color: Colors.purple[700]!,
                                            width: 3,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: _buildAvatarImage(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  // Form fields
                                  ..._buildAnimatedFields(animation),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saveUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFFFBD59), // Updated color
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAnimatedFields(Animation<double> animation) {
    final List<Widget> fields = [
      _buildTextField(_nameController, 'Full Name', Icons.person),
      _buildTextField(_ageController, 'Age', Icons.cake,
          keyboardType: TextInputType.number),
      _buildTextField(_mobileController, 'Mobile Number', Icons.phone,
          keyboardType: TextInputType.phone),
      // Replace single fields with a Row containing both address fields
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purok field (smaller width)
          Flexible(
            flex: 2, // Takes up less space
            child: _buildTextField(
              _purokController,
              'Purok',
              Icons.location_on,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 12), // Space between fields
          // Barangay field (larger width)
          Flexible(
            flex: 5, // Takes up more space
            child: _buildTextField(
              _barangayController,
              'Barangay',
              Icons.location_city,
            ),
          ),
        ],
      ),
    ];

    return fields.asMap().entries.map((entry) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(
            0.2 + (entry.key * 0.1),
            1.0,
            curve: Curves.easeOutQuint,
          ),
        )),
        child: FadeTransition(
          opacity: animation,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: entry.value,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    bool isFromRegistration = label == 'Full Name' || label == 'Mobile Number';
    bool isEmpty = controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: true, // Always enable editing
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(
              icon,
              color: isFromRegistration
                  ? Colors.purple[700]
                  : isEmpty
                      ? Colors.orange[700]
                      : Colors.purple[700],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isFromRegistration
                    ? Colors.grey[300]!
                    : isEmpty
                        ? Colors.orange[300]!
                        : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.purple[700]!,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isFromRegistration
                ? Colors.grey[50]
                : isEmpty
                    ? Colors.orange[50]
                    : Colors.grey[50],
            helperText: !isFromRegistration && isEmpty
                ? 'Please complete your profile information'
                : null,
            helperStyle: TextStyle(color: Colors.orange[700]),
            suffixIcon: isFromRegistration && !isEmpty
                ? Icon(Icons.check_circle, color: Colors.green[400])
                : !isFromRegistration && isEmpty
                    ? Tooltip(
                        message: 'This field needs to be filled',
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.orange[400],
                        ),
                      )
                    : null,
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  // Update the save method
  Future<void> _saveUserData() async {
    try {
      if (userEmail == null) return;

      final QuerySnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .where('Email', isEqualTo: userEmail)
          .get();

      if (userDoc.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userDoc.docs.first.id)
            .update({
          'Full Name': _nameController.text,
          'Age': int.tryParse(_ageController.text) ?? 0,
          'Phone': _mobileController.text,
          'Purok': _purokController.text,
          'Barangay': _barangayController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }
}

// Add this custom painter class outside the widget
class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines
    for (double i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(-size.height + i, size.height),
        Offset(i, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
