import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // Controller for the registration number input
  final TextEditingController _registrationNumberController = TextEditingController();

  // Dummy target location coordinates
  final double targetLatitude = 6.8257430;
  final double targetLongitude = 79.8731204;
  final double allowedRange = 200.0; // in meters

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Barcode Type: ${describeEnum(result!.format)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Data: ${result!.code}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkLocationAndSubmit,
                    child: const Text('Mark Attendance'),
                  ),
                ],
              )
                  : ElevatedButton(
                onPressed: _showRegistrationForm, // Call the form function
                child: const Text("Enter Registration Number"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      print("xxx");
      setState(() {
        print("Setting new data");
        result = scanData;
      });
    });
  }

  /// Function to check location and submit the registration number
  Future<void> _checkLocationAndSubmit() async {
    // Extract coordinates from QR code data (e.g., "6.8256791,79.8732179")
    if (result == null) {
      _showErrorSnackBar('No QR code scanned!');
      return;
    }
    print({"result":result!.code});

    String? qrCodeData = result!.code;
    List<String> coordinates = qrCodeData!.split(',');

    if (coordinates.length != 2) {
      _showErrorSnackBar('Invalid QR code format!');
      return;
    }

    double scannedLatitude = double.tryParse(coordinates[0].trim()) ?? targetLatitude;
    double scannedLongitude = double.tryParse(coordinates[1].trim()) ?? targetLongitude;

    print({"***la":scannedLatitude});
    print({"***lo":scannedLongitude});

    // Use the utility function to check if within range
    bool isInRange = await _isWithinRange(scannedLatitude, scannedLongitude, allowedRange);
    print({"isw":isInRange});
    if (isInRange) {
      // Show registration form if within range
      _showRegistrationForm();
    } else {
      // Show an error message if not within range
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not within the required range.'),
        ),
      );
    }
  }

  /// Check if the device is within the specified range of the target location
  Future<bool> _isWithinRange(double targetLat, double targetLng, double rangeInMeters) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {

        _showErrorSnackBar('Location services are disabled.');
        return false;
      }
      print("Location enabled");

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied.');
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print("Position recived: ");

      print({"posl*":position.latitude});
      print({"poslo*":position.longitude});
      // Calculate distance between current position and target location
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );
      print({"Dis":distance});
      print({"Rng":rangeInMeters});

      // Check if the distance is within the specified range
      return distance <= rangeInMeters;
    } catch (e) {
      _showErrorSnackBar('Error checking location: $e');
      return false;
    }
  }

  /// Show error message in a snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  /// Show the form to input registration number
  void _showRegistrationForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Registration Number'),
          content: TextField(
            controller: _registrationNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Registration Number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _submitRegistrationNumber(); // Submit the form
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  /// Submit the registration number to the backend
  Future<void> _submitRegistrationNumber() async {
    String registrationNumber = _registrationNumberController.text.trim();

    if (registrationNumber.isNotEmpty) {
      try {
        print({"Sub"});
        var response = await http.post(
          Uri.parse('https://9b15d0kz-8000.asse.devtunnels.ms/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'registration_number': registrationNumber, // Send registration number
          }),

        );
        if (response.statusCode == 200) {
          var responseBody = response.body;
          print('Response body: $responseBody');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration submitted successfully!'),
            ),
          );
        } else {
          print('Response status code: ${response.statusCode}');
          print('Response body: ${response.body}'); // Log the server's response body for debugging
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit registration with status:;: ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        print('EError: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit registration'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration number cannot be empty'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _registrationNumberController.dispose(); // Dispose the controller
    controller?.dispose();
    super.dispose();
  }
}
