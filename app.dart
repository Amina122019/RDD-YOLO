import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Condition Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RoadConditionDetectorPage(),
    );
  }
}

class RoadConditionDetectorPage extends StatefulWidget {
  @override
  _RoadConditionDetectorPageState createState() => _RoadConditionDetectorPageState();
}

class _RoadConditionDetectorPageState extends State<RoadConditionDetectorPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _image;
  String? _detectionResult;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = bytes;
        _detectionResult = null;
      });
    }
  }

  Future<void> _detectRoadConditions() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final base64Image = base64Encode(_image!);
      final response = await http.post(
        Uri.parse('http://localhost:8000/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'base_file': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detectionResult = data['detected_classes'];
          _image = base64Decode(data['image_with_boxes']);
        });
      } else {
        throw Exception('Failed to detect road conditions');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Road Condition Detector'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Select Image'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              if (_image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_image!, fit: BoxFit.cover),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _detectRoadConditions,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Detect Road Conditions'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
              if (_detectionResult != null) ...[
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detection Results:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(_detectionResult!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}