import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:convert'; // Add this line
import 'package:url_launcher/url_launcher.dart'; // Add this line
import 'package:flutter/services.dart'; // Add this line

class Contact {
  final String name;
  final List<String> phoneNumbers;
  final Map<String, String> otherFields;

  Contact({required this.name, required this.phoneNumbers, required this.otherFields});
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts', // Change this line
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          onPrimary: Colors.white, // Add this line
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Contacts'),
      debugShowCheckedModeBanner: false, // Add this line to remove the debug banner
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredContacts = List.from(_contacts); // Show all contacts when search is empty
      } else {
        _filteredContacts = _contacts.where((contact) =>
          contact.name.toLowerCase().contains(searchTerm) ||
          contact.phoneNumbers.any((phone) => phone.toLowerCase().contains(searchTerm)) ||
          contact.otherFields.values.any((value) => value.toLowerCase().contains(searchTerm))
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search contacts',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
        // actions: [
        //   CircleAvatar(
        //     backgroundColor: Colors.orange,
        //     child: Text('A', style: TextStyle(color: Colors.white)),
        //   ),
        //   SizedBox(width: 16),
        // ],
      ),
      body: Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Row(
          //     children: [
          //       Icon(Icons.person),
          //       SizedBox(width: 8),
          //       Expanded(child: Text('n170222@rguktn.ac.in')),
          //       Icon(Icons.arrow_drop_down),
          //     ],
          //   ),
          // ),
          Expanded(
            child: _filteredContacts.isEmpty && _searchController.text.isEmpty
                ? Center(child: Text('No contacts uploaded.'))
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      print(contact.phoneNumbers);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(index),
                          child: Text(
                            contact.name[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(contact.name),
                        subtitle: contact.phoneNumbers.isNotEmpty
                            ? Text(contact.phoneNumbers[0])
                            : Text('No phone number'), // Add this line
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailPage(contact: contact),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   items: [
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Contacts'),
      //     BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Highlights'),
      //     BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Organize'),
      //   ],
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickCsvFile,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.pink,
      Colors.blue,
      Colors.orange,
      Colors.green,
    ];
    return colors[index % colors.length];
  }

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        List<List<dynamic>> rows = contents.split('\n').map((line) => line.split(',')).toList();
        print(rows);

        if (rows.isNotEmpty) {
          List<String> headers = rows.first.map((header) => header.trim()).toList().cast<String>();
          int nameIndex = headers.indexOf('Name');
          List<int> phoneIndices = [
            headers.indexOf('Phone 1 - Value'),
            headers.indexOf('Phone 2 - Value'),
            headers.indexOf('Phone 3 - Value'),
            headers.indexOf('Phone 4 - Value'),
          ].where((index) => index != -1).toList();

          List<Contact> contacts = [];
          for (var i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length > nameIndex) {
              String name = row[nameIndex].toString().trim();
              List<String> phones = phoneIndices
                  .map((index) => index < row.length ? row[index].toString().trim() : '')
                  .where((phone) => phone.isNotEmpty)
                  .toList();
              
              Map<String, String> otherFields = {};
              for (var j = 0; j < headers.length; j++) {
                if (j != nameIndex && !phoneIndices.contains(j)) {
                  otherFields[headers[j]] = j < row.length ? row[j].toString().trim() : '';
                }
              }

              if (name.isNotEmpty) {
                contacts.add(Contact(name: name, phoneNumbers: phones, otherFields: otherFields));
              }
            }
          }

          setState(() {
            _contacts = contacts;
            _filterContacts(); // Apply the current search filter to the new contacts
          });
        }
      }
    } catch (e) {
      print('Error picking or reading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to access document. Please check your connection and try again.')),
      );
    }
  }
}

class ContactDetailPage extends StatelessWidget {
  final Contact contact;

  const ContactDetailPage({Key? key, required this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: () {}),
          IconButton(icon: Icon(Icons.star_border), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.yellow,
              child: Text(
                contact.name[0].toUpperCase(),
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Text(
              contact.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(context, Icons.call, 'Call', () => _makePhoneCall(contact.phoneNumbers.first, context)),
                _buildActionButton(context, Icons.message, 'Text', () => _sendSMS(contact.phoneNumbers.first, context)),
                _buildActionButton(context, Icons.video_call, 'Video', () => _makeVideoCall(contact.phoneNumbers.first, context)),
              ],
            ),
            SizedBox(height: 24),
            _buildContactInfo(context),
            _buildLabels(),
            _buildContactSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          child: IconButton(
            icon: Icon(icon, color: Colors.black),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Contact info', style: Theme.of(context).textTheme.titleMedium),
        ),
        // Phone numbers
        for (var phone in contact.phoneNumbers)
          ListTile(
            leading: Icon(Icons.phone),
            title: Text(phone),
            subtitle: Text('Mobile'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.message),
                  onPressed: () => _sendSMS(phone, context),
                ),
                IconButton(
                  icon: Icon(Icons.call),
                  onPressed: () => _makePhoneCall(phone, context),
                ),
              ],
            ),
          ),
        // Other fields
        for (var entry in contact.otherFields.entries)
          if (entry.value.isNotEmpty)
            ListTile(
              leading: _getIconForField(entry.key),
              title: Text(entry.value),
              subtitle: Text(entry.key),
            ),
      ],
    );
  }

  Icon _getIconForField(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'email':
        return Icon(Icons.email);
      case 'address':
        return Icon(Icons.home);
      case 'birthday':
        return Icon(Icons.cake);
      case 'company':
        return Icon(Icons.business);
      case 'title':
        return Icon(Icons.work);
      case 'website':
        return Icon(Icons.language);
      default:
        return Icon(Icons.info);
    }
  }

  Widget _buildLabels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Labels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text('Imported on 2/24'),
                avatar: Icon(Icons.label_outline, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Contact settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: Icon(Icons.voicemail),
          title: Text('Route to voicemail'),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await _launchUrl(launchUri, context);
  }

  Future<void> _sendSMS(String phoneNumber, BuildContext context) async {
    final Uri smsUri = Uri.parse('sms:$phoneNumber?body=');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      print('Error launching SMS: $e');
      // Show dialog with copy option
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Unable to launch SMS'),
            content: Text('Would you like to copy the phone number to clipboard?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phoneNumber));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone number copied to clipboard')),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _launchUrl(Uri url, BuildContext context) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      showErrorSnackBar(context, 'Unable to open ${url.scheme} link. Please make sure you have a compatible app installed.');
    }
  }

  Future<void> _makeVideoCall(String phoneNumber, BuildContext context) async {
    // Implement video call functionality here
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video call functionality not implemented yet')),
    );
  }
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// Remove this function as it's now redundant
// void showErrorMessage(BuildContext context, String url) {
//   // ...
// }