import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marketing_item.dart';

class MarketingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's marketing data merged with template
  Future<List<MarketingItem>> getUserMarketingItems(String userId) async {
    try {
      final templateItems = await _getTemplateMarketingItems();

      if (templateItems.isEmpty) {
        print('No marketing template found in Firestore.');
        return [];
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('marketing')
          .doc('items')
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        return templateItems;
      }

      final userData = userDoc.data()!;
      final userItemsList = userData['items'] as List<dynamic>?;

      if (userItemsList == null || userItemsList.isEmpty) {
        return templateItems;
      }

      final userItemsMap = <String, Map<String, dynamic>>{};
      for (var item in userItemsList) {
        final itemMap = item as Map<String, dynamic>;
        userItemsMap[itemMap['id']] = itemMap;
      }

      final mergedItems = <MarketingItem>[];

      for (var templateItem in templateItems) {
        final userItemData = userItemsMap[templateItem.id];

        if (userItemData != null) {
          final userSections = List<Map<String, dynamic>>.from(
            userItemData['sections'] ?? [],
          );

          final mergedSections = <MarketingSection>[];
          for (int i = 0; i < templateItem.sections.length; i++) {
            final templateSection = templateItem.sections[i];

            final userSection = userSections.firstWhere(
              (s) => s['subtitle'] == templateSection.subtitle,
              orElse: () => <String, dynamic>{},
            );

            mergedSections.add(
              MarketingSection(
                subtitle: templateSection.subtitle,
                checkboxOptions: templateSection.checkboxOptions,
                isTextField: templateSection.isTextField,
                fieldType: templateSection.fieldType,
                hintText: templateSection.hintText,
                userInputs: userSection.isNotEmpty
                    ? List<String>.from(userSection['userInputs'] ?? [])
                    : templateSection.userInputs,
                checkboxStates: userSection.isNotEmpty
                    ? List<bool>.from(userSection['checkboxStates'] ?? [])
                    : templateSection.checkboxStates,
              ),
            );
          }

          mergedItems.add(
            MarketingItem(
              id: templateItem.id,
              title: templateItem.title,
              sections: mergedSections,
              isCompleted: userItemData['isCompleted'] ?? false,
            ),
          );
        } else {
          mergedItems.add(templateItem);
        }
      }

      return mergedItems;
    } catch (e) {
      print('Error fetching marketing items: $e');
      return await _getTemplateMarketingItems();
    }
  }

  Future<List<MarketingItem>> _getTemplateMarketingItems() async {
    try {
      final doc = await _firestore
          .collection('marketing_templates')
          .doc('default')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final itemsList = data['items'] as List<dynamic>?;

        if (itemsList != null && itemsList.isNotEmpty) {
          return itemsList
              .map(
                (item) => MarketingItem.fromMap(item as Map<String, dynamic>),
              )
              .toList();
        }
      }

      print('No marketing template found in Firestore.');
      return [];
    } catch (e) {
      print('Error fetching template marketing items: $e');
      return [];
    }
  }

  Future<bool> saveMarketingItem(String userId, MarketingItem item) async {
    try {
      final existingItems = await getUserMarketingItems(userId);

      final index = existingItems.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        existingItems[index] = item;
      } else {
        existingItems.add(item);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('marketing')
          .doc('items')
          .set({
            'items': existingItems.map((e) => e.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving marketing item: $e');
      return false;
    }
  }

  Future<MarketingItem?> getMarketingItem(String userId, String itemId) async {
    try {
      final items = await getUserMarketingItems(userId);
      return items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => MarketingItem(id: itemId, title: '', sections: []),
      );
    } catch (e) {
      print('Error fetching marketing item: $e');
      return null;
    }
  }
}
