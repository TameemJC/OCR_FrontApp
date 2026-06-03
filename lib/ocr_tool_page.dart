import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'discovery.dart';
import 'local_ocr_service.dart';

class OCRToolPage extends StatefulWidget {
  const OCRToolPage({super.key});

  @override
  State<OCRToolPage> createState() => _OCRToolPageState();
}

class _OCRToolPageState extends State<OCRToolPage> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  String _imageName = '';
  String _extractedText = '';
  String _translatedText = '';
  bool _isLoading = false;
  bool _isImagePicked = false;
  String? _lastFilePath;
  bool _isServerConnected = false;
  String _sourceLanguage = 'ar';
  String _targetLanguage = 'en';
  bool _showTranslation = true;
  String _currentServerUrl = '';
  bool _isDiscovering = false;

  final ImagePicker _picker = ImagePicker();
  late SimpleOCRService _smartianService;

  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;
  bool get isWindows => Platform.isWindows;
  bool get isLinux => Platform.isLinux;
  bool get isMacOS => Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDiscoverServer();
    });
  }

  Future<void> _requestPermissions() async {
    if (isAndroid) {
      final status = await Permission.location.request();
      if (status.isDenied) {
        _showErrorSnackBar('Location permission helps discover server on network');
      }

      if (await Permission.nearbyWifiDevices.isDenied) {
        await Permission.nearbyWifiDevices.request();
      }
    }
  }

  Future<void> _initService() async {
    _smartianService = SimpleOCRService(
      baseUrl: 'http://localhost:5000',
      geminiApiKey: 'AIzaSyDQb_PTTGpugk6_j1tfP0O-DwHVgzGb9MQ',
    );
  }

  Future<void> _autoDiscoverServer() async {
    if (_isDiscovering) return;

    setState(() {
      _isDiscovering = true;
      _isServerConnected = false;
    });

    try {
      _showSuccessSnackBar('Searching for OCR server...');
      final serverUrl = await ServerDiscoveryService.discoverServer();

      if (serverUrl != null) {
        setState(() {
          _currentServerUrl = serverUrl;
          _smartianService = SimpleOCRService(
            baseUrl: serverUrl,
            geminiApiKey: 'AIzaSyDQb_PTTGpugk6_j1tfP0O-DwHVgzGb9MQ',
          );
          _isServerConnected = true;
        });
        _showSuccessSnackBar('Server found at: $serverUrl');
      } else {
        setState(() {
          _isServerConnected = false;
        });
        _showErrorSnackBar('Could not find OCR server on network\nMake sure server is running on port 5000');
      }
    } catch (e) {
      _showErrorSnackBar('Discovery error: $e');
      setState(() {
        _isServerConnected = false;
      });
    } finally {
      setState(() {
        _isDiscovering = false;
      });
    }
  }


  Future<void> _pickImageFromFileManager() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff'],
      );

      if (result != null) {
        final file = result.files.first;

        setState(() {
          _imageName = file.name;
          _lastFilePath = file.path;
          _imageBytes = file.bytes;
          _isImagePicked = true;
          _extractedText = '';
          _translatedText = '';
        });

        if (file.path != null) {
          _selectedImage = File(file.path!);
        } else {
          _selectedImage = null;
        }

        _showSuccessSnackBar('Loaded: ${file.name}');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageName = pickedFile.name;
          _lastFilePath = pickedFile.path;
          _isImagePicked = true;
          _extractedText = '';
          _translatedText = '';
        });
        _showSuccessSnackBar('Photo captured');
      }
    } catch (e) {
      _showErrorSnackBar('Error using camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageName = pickedFile.name;
          _lastFilePath = pickedFile.path;
          _isImagePicked = true;
          _extractedText = '';
          _translatedText = '';
        });
        _showSuccessSnackBar('Image loaded from gallery');
      }
    } catch (e) {
      _showErrorSnackBar('Error accessing gallery: $e');
    }
  }

  Future<void> _processImageWithTranslation() async {
    if (!_isServerConnected) {
      _showErrorSnackBar('OCR server not connected');
      return;
    }

    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isLoading = true;
      _extractedText = '';
      _translatedText = '';
    });

    try {
      TranslationResult result = await _smartianService.processImageWithTranslation(_selectedImage!);

      setState(() {
        _extractedText = result.originalText;
        _translatedText = result.translatedText;
        _sourceLanguage = result.sourceLanguage;
        _targetLanguage = result.targetLanguage;
        _isLoading = false;
      });

      _showSuccessSnackBar('OCR and Translation completed!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Processing failed: $e');
    }
  }

  Future<void> _extractTextOnly() async {
    if (!_isServerConnected) {
      _showErrorSnackBar('OCR server not connected');
      return;
    }

    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isLoading = true;
      _extractedText = '';
      _translatedText = '';
    });

    try {
      String result = await _smartianService.processImage(_selectedImage!);

      setState(() {
        _extractedText = result;
        _isLoading = false;
      });

      _showSuccessSnackBar('OCR completed!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('OCR failed: $e');
    }
  }

  Future<void> _translateSamaritanOnly() async {
    if (_extractedText.isEmpty) {
      _showErrorSnackBar('No text to translate');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String translated = await _smartianService.translateText(_extractedText);

      setState(() {
        _translatedText = translated;
        _showTranslation = true;
        _isLoading = false;
      });

      _showSuccessSnackBar('Translation completed!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Translation failed: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _isImagePicked = false;
      _extractedText = '';
      _translatedText = '';
      _imageName = '';
      _lastFilePath = null;
    });
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      _showSuccessSnackBar('Text copied to clipboard');
    }
  }

  void _toggleView() {
    setState(() {
      _showTranslation = !_showTranslation;
    });
  }



  String _getLanguageName(String code) {
    switch (code) {
      case 'he':
        return 'Hebrew';
      case 'ar':
        return 'Arabic';
      case 'sam':
        return 'Samaritan';
      case 'en':
        return 'English';
      case 'unknown':
        return 'Unknown';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final imageHeight = isSmallScreen ? 200.0 : 250.0;
    final fontSize = isSmallScreen ? 18.0 : 22.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Samaritan OCR',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _isDiscovering
                  ? '🔍 Discovering...'
                  : (_isServerConnected ? '🟢 Connected' : '🔴 Disconnected'),
              style: TextStyle(
                color: _isDiscovering ? Colors.amber : (_isServerConnected ? Colors.green : Colors.red),
                fontSize: 10,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.amber),
            onPressed: () async {
              final serverUrl = await ServerDiscoveryService.promptForServerIp(context);
              if (serverUrl != null) {
                setState(() {
                  _currentServerUrl = serverUrl;
                  _smartianService = SimpleOCRService(
                    baseUrl: serverUrl,
                    geminiApiKey: 'AIzaSyDQb_PTTGpugk6_j1tfP0O-DwHVgzGb9MQ',
                  );
                  _isServerConnected = true;
                });
                _showSuccessSnackBar('Connected to: $serverUrl');
              }
            },
            tooltip: 'Manual IP Entry',
          ),
          IconButton(
            icon: Icon(_isDiscovering ? Icons.hourglass_empty : Icons.wifi_find,
                color: Colors.amber),
            onPressed: _isDiscovering ? null : _autoDiscoverServer,
            tooltip: 'Discover Server',
          ),
          if (_isImagePicked)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _clearImage,
              tooltip: 'Clear Image',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isServerConnected
                        ? [Colors.green[900]!, Colors.green[700]!]
                        : [Colors.red[900]!, Colors.red[700]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isServerConnected ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isServerConnected
                            ? 'Server Ready'
                            : 'Tap 🔍 to find server',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isImagePicked ? Colors.amber : Colors.grey[800]!,
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text('Error loading image', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      );
                    },
                  ),
                )
                    : _imageBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text('Error loading image', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      );
                    },
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.translate,
                      size: 50,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG, GIF, BMP, TIFF, WEBP',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    if (_lastFilePath != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last: ${path.basename(_lastFilePath!)}',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              if (_imageName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected: ${_imageName.length > 30 ? '...${_imageName.substring(_imageName.length - 27)}' : _imageName}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 16),

              if (!_isImagePicked)
                Column(
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.folder_open,
                      label: 'Browse',
                      color: Colors.amber,
                      onTap: _pickImageFromFileManager,
                      subtitle: 'Files',
                    ),
                    const SizedBox(height: 10),
                    if (isAndroid || isIOS)
                      Row(
                        children: [
                          Expanded(
                            child: _buildImageSourceButton(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              color: Colors.amber,
                              onTap: _pickImageFromCamera,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildImageSourceButton(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              color: Colors.amber,
                              onTap: _pickImageFromGallery,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

              const SizedBox(height: 12),

              if (_isImagePicked && !_isLoading)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isServerConnected ? _extractTextOnly : null,
                            icon: const Icon(Icons.text_fields, size: 18),
                            label: const Text('OCR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isServerConnected ? _processImageWithTranslation : null,
                            icon: const Icon(Icons.translate, size: 18),
                            label: const Text('OCR+Trans'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_extractedText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _translateSamaritanOnly,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Translate Text'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                      ),
                    ],
                  ],
                ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 16),
                        Text('Processing...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

              if (_extractedText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _showTranslation ? 'Translation:' : 'Original:',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showTranslation ? Icons.visibility : Icons.visibility_off,
                            color: Colors.amber,
                            size: 20,
                          ),
                          onPressed: _toggleView,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.amber, size: 20),
                          onPressed: _copyToClipboard,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_showTranslation && _translatedText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getLanguageName(_sourceLanguage),
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, color: Colors.grey, size: 12),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getLanguageName(_targetLanguage),
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxHeight: isSmallScreen ? 300 : 400,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withAlpha(100)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _showTranslation && _translatedText.isNotEmpty
                          ? _translatedText
                          : (_extractedText.isNotEmpty ? _extractedText : 'No text detected'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: _showTranslation && _translatedText.isNotEmpty
                          ? TextDirection.ltr
                          : (_sourceLanguage == 'ar' || _sourceLanguage == 'he'
                          ? TextDirection.rtl
                          : TextDirection.ltr),
                    ),
                  ),
                ),
                if (!_showTranslation && _translatedText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _toggleView,
                    icon: const Icon(Icons.translate, color: Colors.amber, size: 16),
                    label: const Text(
                      'Show Translation',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 14),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: color.withAlpha(200), fontSize: 9),
              ),
            ],
          ],
        ),
      ),
    );
  }
}