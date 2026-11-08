import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsService {
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: false);
  }

  Future<String?> findContactNameByPhone(String phoneNumber) async {
    final hasPerm = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPerm) return null;

    final sanitizedTarget = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final sanitizedPhone = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (sanitizedPhone.endsWith(sanitizedTarget) || sanitizedTarget.endsWith(sanitizedPhone)) {
          return contact.displayName.isNotEmpty ? contact.displayName : null;
        }
      }
    }
    return null;
  }

  Future<bool> createContact({
    required String displayName,
    required String phoneNumber,
  }) async {
    final hasPerm = await FlutterContacts.requestPermission(readonly: false);
    if (!hasPerm) return false;

    // Split name into first and last if possible
    final parts = displayName.trim().split(' ');
    final first = parts.isNotEmpty ? parts.first : displayName;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final newContact = Contact()
      ..name.first = first
      ..name.last = last
      ..phones = [Phone(phoneNumber, label: PhoneLabel.mobile)];

    try {
      await newContact.insert();
      return true;
    } catch (e) {
      print('Errore salvataggio contatto: $e');
      return false;
    }
  }
}
