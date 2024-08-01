import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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
                    onPressed: _markAttendance,
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
      setState(() {
        result = scanData;
      });
    });
  }

  Future<void> _markAttendance() async {
    if (result != null) {
      String? qrCodeData = result!.code;

      // Send the QR code data to your backend server to mark attendance
      try {
        var response = await http.post(
          Uri.parse('https://9b15d0kz-8000.asse.devtunnels.ms/'),
          headers: {
            'Content-Type': 'application/json', // Set the correct content type
          },
          body: jsonEncode({
            'user_id': FirebaseAuth.instance.currentUser?.uid,
            'qr_code_data': qrCodeData, // Removed quotes for the variable
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark attendance with status: ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark attendance'),
          ),
        );
      }
    }
  }

  /// Function to test the POST request with a simple message
  Future<void> _testPostRequest() async {
    try {
      // Prepare the request headers and body
      final headers = {
        'Content-Type': 'application/json', // Ensure JSON content type
      };

      final body = jsonEncode({
        'message': 'yooo', // The text you want to send
      });

      // Send the POST request
      var response = await http.post(
        Uri.parse('https://9b15d0kz-8000.asse.devtunnels.ms/'),
        headers: headers,
        body: body,
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        var responseBody = response.body;
        print('Response body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('POST request successful: $responseBody'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('POST request failed with status: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send POST request'),
        ),
      );
    }
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
        var response = await http.post(
          Uri.parse('https://9b15d0kz-8000.asse.devtunnels.ms'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'registration_number': registrationNumber, // Send registration number
            // 'message': 'yooo', // Additional message if needed
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
              content: Text('Failed to submit registration with status: ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        print('Error: $e');
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
