import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:cloud_firestore/cloud_firestore.dart";

class DataUploader extends StatefulWidget {
  @override
  _DataUploaderState createState() => _DataUploaderState();
}

class _DataUploaderState extends State<DataUploader> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  Future<void> uploadData() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    try {
      // 1. Load the JSON from assets
      final jsonString = await rootBundle.loadString("assets/exercises.json");
      final jsonData = jsonDecode(jsonString) as List<dynamic>;

      // 2. Configure Firestore
      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection("exercises"); // Replace with your collection name
      final batchSize = 50; // Tune this based on testing
      final totalDocuments = jsonData.length;

      // 3. Iterate and Batch Write
      for (int i = 0; i < totalDocuments; i += batchSize) {
        WriteBatch batch = firestore.batch();
        final end = (i + batchSize < totalDocuments) ? i + batchSize : totalDocuments;

        for (int j = i; j < end; j++) {
          final documentData = jsonData[j] as Map<String, dynamic>;

          // **IMPORTANT:** Generate a document ID.
          // You should have an 'id' field in your JSON data, or generate one:
          final documentId = documentData['id'] as String? ?? firestore.collection("exercises").doc().id;

          final docRef = collectionRef.doc(documentId);
          batch.set(docRef, documentData);
        }

        // 4. Commit the Batch
        await batch.commit();

        // 5. Update Progress
        setState(() {
          _uploadProgress = (end / totalDocuments).toDouble();
        });

        print("Uploaded batch from $i to $end");
      }

      print("Data upload complete!");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data upload complete!")));
    } catch (e) {
      print("Error uploading data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading data: $e")));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data Uploader")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%"),
              ),
            ] else
              ElevatedButton(
                onPressed: uploadData,
                child: Text("Upload Data"),
              ),
          ],
        ),
      ),
    );
  }
}