import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/strategy_item.dart';

class StrategyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's strategy data merged with template
  Future<List<StrategyItem>> getUserStrategyItems(String userId) async {
    try {
      // 1. Always fetch the template first (this has hintText)
      final templateItems = await _getTemplateStrategyItems();

      if (templateItems.isEmpty) {
        print('No template found in Firestore.');
        return [];
      }

      // 2. Try to get user's saved data
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('strategy')
          .doc('items')
          .get();

      // 3. If user has no saved data, return template as-is
      if (!userDoc.exists || userDoc.data() == null) {
        return templateItems;
      }

      // 4. Merge template with user data
      final userData = userDoc.data()!;
      final userItemsList = userData['items'] as List<dynamic>?;

      if (userItemsList == null || userItemsList.isEmpty) {
        return templateItems;
      }

      // Convert user items to map for easy lookup
      final userItemsMap = <String, Map<String, dynamic>>{};
      for (var item in userItemsList) {
        final itemMap = item as Map<String, dynamic>;
        userItemsMap[itemMap['id']] = itemMap;
      }

      // Merge: Template provides structure + hintText, User provides userInputs + isCompleted
      final mergedItems = <StrategyItem>[];

      for (var templateItem in templateItems) {
        final userItemData = userItemsMap[templateItem.id];

        if (userItemData != null) {
          // User has saved this item, merge the data
          final userSections = List<Map<String, dynamic>>.from(
            userItemData['sections'] ?? [],
          );

          // Merge sections
          final mergedSections = <StrategySection>[];
          for (int i = 0; i < templateItem.sections.length; i++) {
            final templateSection = templateItem.sections[i];

            // Find matching user section by subtitle
            final userSection = userSections.firstWhere(
              (s) => s['subtitle'] == templateSection.subtitle,
              orElse: () => <String, dynamic>{},
            );

            // Create merged section
            mergedSections.add(
              StrategySection(
                subtitle: templateSection.subtitle,
                bullets: templateSection.bullets,
                isTextField: templateSection.isTextField,
                fieldType: templateSection.fieldType,
                hintText: templateSection.hintText, // From template
                userInputs: userSection.isNotEmpty
                    ? List<String>.from(userSection['userInputs'] ?? [])
                    : templateSection.userInputs, // From user or template
              ),
            );
          }

          mergedItems.add(
            StrategyItem(
              id: templateItem.id,
              title: templateItem.title,
              sections: mergedSections,
              isCompleted: userItemData['isCompleted'] ?? false,
            ),
          );
        } else {
          // User hasn't saved this item yet, use template
          mergedItems.add(templateItem);
        }
      }

      return mergedItems;
    } catch (e) {
      print('Error fetching strategy items: $e');
      return await _getTemplateStrategyItems();
    }
  }

  // Fetch template strategy items from Firestore
  Future<List<StrategyItem>> _getTemplateStrategyItems() async {
    try {
      final doc = await _firestore
          .collection('strategy_templates')
          .doc('default')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final itemsList = data['items'] as List<dynamic>?;

        if (itemsList != null && itemsList.isNotEmpty) {
          return itemsList
              .map((item) => StrategyItem.fromMap(item as Map<String, dynamic>))
              .toList();
        }
      }

      print('No template found in Firestore. Please add template data.');
      return [];
    } catch (e) {
      print('Error fetching template strategy items: $e');
      return [];
    }
  }

  // Save or update a single strategy item
  Future<bool> saveStrategyItem(String userId, StrategyItem item) async {
    try {
      // Get existing items (this will be the merged data)
      final existingItems = await getUserStrategyItems(userId);

      // Find and update the item
      final index = existingItems.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        existingItems[index] = item;
      } else {
        existingItems.add(item);
      }

      // Save back to Firestore
      // Note: We save the complete item including hintText so it's preserved
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('strategy')
          .doc('items')
          .set({
            'items': existingItems.map((e) => e.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving strategy item: $e');
      return false;
    }
  }

  // Save all strategy items at once
  Future<bool> saveAllStrategyItems(
    String userId,
    List<StrategyItem> items,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('strategy')
          .doc('items')
          .set({
            'items': items.map((e) => e.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('Error saving all strategy items: $e');
      return false;
    }
  }

  // Get a single strategy item
  Future<StrategyItem?> getStrategyItem(String userId, String itemId) async {
    try {
      final items = await getUserStrategyItems(userId);
      return items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => StrategyItem(id: itemId, title: '', sections: []),
      );
    } catch (e) {
      print('Error fetching strategy item: $e');
      return null;
    }
  }
}
