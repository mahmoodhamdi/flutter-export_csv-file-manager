// contact_provider.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class ContactProvider {
  final String _fileName = 'contacts.csv';

  Future<List<List<dynamic>>> readContacts() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');

    if (await file.exists()) {
      final existingCsv = await file.readAsString();
      return const CsvToListConverter().convert(existingCsv);
    }

    return []; // Return an empty list if the file does not exist
  }

  Future<void> writeContacts(List<List<dynamic>> contactsData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');

    String csv = const ListToCsvConverter().convert(contactsData);
    await file.writeAsString(csv);
  }

  Future<void> exportContacts(List<List<dynamic>> newContactsData) async {
    final existingData = await readContacts();

    // Remove header row if it exists
    if (existingData.isNotEmpty) {
      existingData.removeAt(0);
    }

    final combinedData = existingData + newContactsData.skip(1).toList();

    // Write back to the file including header
    await writeContacts([
      ['Name', 'Address', 'Phone'], // Add header back
      ...combinedData,
    ]);
  }
}
