import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart'; // Import for permissions
import 'text_recognition_service.dart'; // Make sure this file exists in your lib folder
import 'note_detail_page.dart'; // Correct relative import for NoteDetailPage
import 'package:device_info_plus/device_info_plus.dart'; // Import for device info

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  late CameraController _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isGalleryPermissionGranted = false;
  final TextRecognitionService _textRecognitionService = TextRecognitionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions(); // Request permissions on init
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _textRecognitionService.dispose(); // Dispose the OCR service
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changes are handled here to pause/resume camera
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Requests camera and gallery permissions from the user.
  /// Updates the permission status and initializes the camera if granted.
  Future<void> _requestPermissions() async {
  // Request camera permission
  var cameraStatus = await Permission.camera.status;
  if (!cameraStatus.isGranted) {
    cameraStatus = await Permission.camera.request();
  }
  
  // Request gallery permission based on Android version
  Permission photosPermission;
  if (await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt) >= 33) {
    photosPermission = Permission.photos;
  } else {
    photosPermission = Permission.storage;
  }
  
  var photosStatus = await photosPermission.status;
  if (!photosStatus.isGranted) {
    photosStatus = await photosPermission.request();
  }
  
  setState(() {
    _isCameraPermissionGranted = cameraStatus.isGranted;
    _isGalleryPermissionGranted = photosStatus.isGranted;
  });

  if (cameraStatus.isGranted) {
    _initializeCamera();
  } else {
    _showPermissionDeniedMessage('Camera');
  }
}

  /// Initializes the camera controller.
  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return; // Prevent re-initialization if already initialized

    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showErrorMessage('No cameras found on this device.');
        return;
      }
      // Select the first available camera
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
      await _cameraController.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      _showErrorMessage('Error initializing camera: ${e.description}');
      // Handle specific camera errors (e.g., camera in use)
    } catch (e) {
      _showErrorMessage('An unexpected error occurred during camera initialization: $e');
    }
  }

  /// Displays an error message using a SnackBar.
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Displays an AlertDialog when a permission is denied, offering to open app settings.
  void _showPermissionDeniedMessage(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType Permission Denied'),
          content: Text('Please grant $permissionType permission in app settings to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Opens app settings for the user
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a message if camera permission is not granted
    if (!_isCameraPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF9F9DD),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera permission is required to scan notes.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    // Show a loading indicator while camera is initializing
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF9F9DD),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Main UI when camera is ready
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF9F9DD), // Your app's theme color
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Camera preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          ),
          // Your UI overlays (borders, buttons)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: _buildScanBorders(),
            ),
          ),
          Positioned(
            bottom: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gallery button
                IconButton(
                  onPressed: _isGalleryPermissionGranted ? _pickImageFromGallery : () => _showPermissionDeniedMessage('Gallery'),
                  icon: const Icon(Icons.image, size: 40, color: Colors.white),
                  tooltip: 'Pick from Gallery',
                ),
                const SizedBox(width: 50),
                // Capture button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the visual scanning borders on the camera preview.
  Widget _buildScanBorders() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCorner(topLeft: true),
              _buildCorner(topRight: true),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCorner(bottomLeft: true),
              _buildCorner(bottomRight: true),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper function to build individual corners of the scanning border.
  Widget _buildCorner({bool topLeft = false, bool topRight = false, bool bottomLeft = false, bool bottomRight = false}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight ? const BorderSide(color: Colors.black, width: 3) : BorderSide.none,
          left: topLeft || bottomLeft ? const BorderSide(color: Colors.black, width: 3) : BorderSide.none,
          right: topRight || bottomRight ? const BorderSide(color: Colors.black, width: 3) : BorderSide.none,
          bottom: bottomLeft || bottomRight ? const BorderSide(color: Colors.black, width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  /// Takes a picture using the camera controller and processes it.
  Future<void> _takePicture() async {
    if (!_cameraController.value.isInitialized) {
      _showErrorMessage('Camera not initialized.');
      return;
    }

    try {
      final XFile file = await _cameraController.takePicture();
      await _processImageAndNavigate(file.path);
    } on CameraException catch (e) {
      _showErrorMessage('Error taking picture: ${e.description}');
    } catch (e) {
      _showErrorMessage('An unexpected error occurred while taking picture: $e');
    }
  }

  /// Picks an image from the gallery and processes it.
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        await _processImageAndNavigate(file.path);
      }
    } catch (e) {
      _showErrorMessage('Error picking image from gallery: $e');
    }
  }

  /// Processes the image using OCR and navigates to the NoteDetailPage.
  Future<void> _processImageAndNavigate(String imagePath) async {
    try {
      // Show a loading indicator while processing
      showDialog(
        context: context,
        barrierDismissible: false, // User cannot dismiss by tapping outside
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing image with OCR...'),
              ],
            ),
          );
        },
      );

      String recognizedText = await _textRecognitionService.recognizeTextFromImage(imagePath);
      
      // Dismiss the loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Navigate to your note creation page with the recognized text
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoteDetailPage(
            isNewNote: true, // It's a new note created from a scan
            title: 'Scanned Note', // Default title for scanned notes
            description: '', // This will be overridden by initialText
            initialText: recognizedText, // Pass the OCR-recognized text here
          ),
        ),
      );
    } catch (e) {
      // Dismiss the loading indicator if an error occurs
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorMessage('Failed to recognize text: $e');
    }
  }
}
