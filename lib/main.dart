import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/contact_provider.dart';
import 'package:flutter_application_1/models/contact.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ContactList(),
    );
  }
}

class ContactList extends StatefulWidget {
  const ContactList({super.key});

  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  final List<Contact> _contacts = [];
  final ContactProvider _contactProvider = ContactProvider();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final existingData = await _contactProvider.readContacts();
    setState(() {
      _contacts.clear();
      for (var contact in existingData) {
        if (contact.length == 3) {
          _contacts.add(Contact(
            name: contact[0],
            address: contact[1],
            phone: contact[2],
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Manager')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(contact.name),
                    subtitle: Text('${contact.address} | ${contact.phone}'),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _exportToCSV,
                child: const Text('Export to CSV'),
              ),
              ElevatedButton(
                onPressed: _openCSV,
                child: const Text('Open CSV'),
              ),
              ElevatedButton(
                onPressed: _showAddContactBottomSheet,
                child: const Text('Add Contact'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddContactBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return AddContactForm(
          onContactAdded: (contact) {
            setState(() {
              _contacts.add(contact);
            });
            _contactProvider.exportContacts([
              ['Name', 'Address', 'Phone'],
              [contact.name, contact.address, contact.phone],
            ]);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    final List<List<dynamic>> contactsData = [
      ['Name', 'Address', 'Phone'],
      ..._contacts
          .map((contact) => [contact.name, contact.address, contact.phone]),
    ];

    await _contactProvider.exportContacts(contactsData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV exported successfully.')),
    );
  }

  Future<void> _openCSV() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/contacts.csv');
      if (await file.exists()) {
        final result = await OpenFile.open(file.path);
        if (result.message != 'Success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Could not open the file: ${result.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('CSV file does not exist. Export it first.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
    }
  }
}

class AddContactForm extends StatefulWidget {
  final Function(Contact) onContactAdded;

  const AddContactForm({super.key, required this.onContactAdded});

  @override
  _AddContactFormState createState() => _AddContactFormState();
}

class _AddContactFormState extends State<AddContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Contact',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a phone number' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addContact,
                  child: const Text('Add Contact'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addContact() {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
      );

      widget.onContactAdded(contact);
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
