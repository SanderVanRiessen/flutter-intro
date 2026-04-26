import 'dart:collection';

import 'package:flutter/cupertino.dart';

import 'contact.dart';

class ContactGroup {
  factory ContactGroup({
    required int id,
    required String label,
    bool permanent = false,
    String? title,
    List<Contact>? contacts,
  }) {
    final contactsCopy = contacts ?? <Contact>[];
    _sortContacts(contactsCopy);
    return ContactGroup._internal(
      id: id,
      label: label,
      permanent: permanent,
      title: title,
      contacts: contactsCopy,
    );
  }

  ContactGroup._internal({
    required this.id,
    required this.label,
    this.permanent = false,
    String? title,
    List<Contact>? contacts,
  }) : title = title ?? label,
       _contacts = contacts ?? const <Contact>[];

  final int id;
  final bool permanent;
  final String label;
  final String title;
  final List<Contact> _contacts;

  List<Contact> get contacts => _contacts;

  AlphabetizedContactMap get alphabetizedContacts {
    final contactsMap = AlphabetizedContactMap();
    for (final contact in _contacts) {
      final lastInitial = contact.lastName[0].toUpperCase();
      if (contactsMap.containsKey(lastInitial)) {
        contactsMap[lastInitial]!.add(contact);
      } else {
        contactsMap[lastInitial] = [contact];
      }
    }
    return contactsMap;
  }
}

typedef AlphabetizedContactMap = SplayTreeMap<String, List<Contact>>;

void _sortContacts(List<Contact> contacts) {
  contacts.sort((a, b) {
    final checkLastName = a.lastName.compareTo(b.lastName);
    if (checkLastName != 0) {
      return checkLastName;
    }

    final checkFirstName = a.firstName.compareTo(b.firstName);
    if (checkFirstName != 0) {
      return checkFirstName;
    }

    if (a.middleName != null && b.middleName != null) {
      final checkMiddleName = a.middleName!.compareTo(b.middleName!);
      if (checkMiddleName != 0) {
        return checkMiddleName;
      }
    } else if (a.middleName != null || b.middleName != null) {
      return a.middleName != null ? 1 : -1;
    }

    return a.id.compareTo(b.id);
  });
}

final allPhone = ContactGroup(
  id: 0,
  permanent: true,
  label: 'All iphone',
  title: 'iPhone',
  contacts: allContacts.toList(),
);

final friends = ContactGroup(
  id: 1,
  label: 'Friends',
  contacts: [allContacts.elementAt(3)],
);

final work = ContactGroup(id: 2, label: 'Work');

List<ContactGroup> generateSeedData() {
  return [allPhone, friends, work];
}

class ContactGroupsModel {
  ContactGroupsModel() : _listNotifier = ValueNotifier(generateSeedData());

  final ValueNotifier<List<ContactGroup>> _listNotifier;

  ValueNotifier<List<ContactGroup>> get listNotifier => _listNotifier;

  List<ContactGroup> get lists => _listNotifier.value;

  ContactGroup findContactList(int id) {
    return lists[id];
  }

  void dispose() {
    _listNotifier.dispose();
  }
}
