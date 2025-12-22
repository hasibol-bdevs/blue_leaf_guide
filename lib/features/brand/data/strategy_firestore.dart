import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/strategy_item.dart';

/// One-time script to upload strategy template to Firestore
/// Call this function once from your app (e.g., from a hidden admin button)
/// After running once, you can update the data directly in Firestore console
Future<bool> uploadStrategyTemplateToFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    final templateItems = [
      StrategyItem(
        id: "branding_basics",
        title: "Branding Basics",
        sections: [
          StrategySection(
            subtitle: "Be Smart with brand building awareness:",
            bullets: [
              "Be Authentic",
              "Have a unique voice",
              "Build an email list",
              "Create a memorable slogan",
              "Empower and educate your customer",
            ],
          ),
          StrategySection(
            subtitle: "Associate yourself with strong brands:",
            bullets: [
              "Your School",
              "Products that you use",
              "Tools that you use",
            ],
          ),
          StrategySection(
            subtitle:
                "Build a clear website, grow your Instagram following, know your audience, and define your mission.",
            bullets: [],
          ),
        ],
      ),
      StrategyItem(
        id: "vision_mission",
        title: "Vision & Mission",
        sections: [
          StrategySection(
            subtitle: "Vision",
            isTextField: true,
            userInputs: [],
          ),
          StrategySection(
            subtitle: "Mission",
            isTextField: true,
            userInputs: [],
          ),
          StrategySection(
            subtitle: "Core Values",
            isTextField: true,
            userInputs: [],
          ),
        ],
      ),
      StrategyItem(
        id: "target_audience",
        title: "Target Audience",
        sections: [
          StrategySection(
            subtitle: "Age Range",
            isTextField: true,
            userInputs: [],
            fieldType: 'dropdown',
          ),
          StrategySection(
            subtitle: "Income Level",
            isTextField: true,
            userInputs: [],
            fieldType: 'dropdown',
          ),
          StrategySection(
            subtitle: "Location",
            isTextField: true,
            userInputs: [],
          ),
        ],
      ),
      StrategyItem(
        id: "brand_personality",
        title: "Brand Personality",
        sections: [
          StrategySection(
            subtitle: "Select 3-5 traits that define your brand",
            bullets: [
              "Sophisticated",
              "Playful",
              "Luxurious",
              "Approachable",
              "Bold",
              "Elegant",
              "Natural",
              "Modern",
              "Minimalist",
              "Glamorous",
            ],
            isTextField: false,
            fieldType: 'chips',
            userInputs: [],
          ),
        ],
      ),
      StrategyItem(
        id: "brand_story",
        title: "Brand Story",
        sections: [
          StrategySection(
            subtitle: "Your Brand Story",
            isTextField: true,
            userInputs: [],
          ),
        ],
      ),
    ];

    await firestore.collection('strategy_templates').doc('default').set({
      'items': templateItems.map((e) => e.toMap()).toList(),
      'version': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Strategy template uploaded successfully!');
    return true;
  } catch (e) {
    print('❌ Error uploading strategy template: $e');
    return false;
  }
}

/// Call this from anywhere in your app to initialize the template
/// Example: Add a hidden button in settings or call it once on app launch
void initializeStrategyTemplate() async {
  final success = await uploadStrategyTemplateToFirestore();
  if (success) {
    print(
      'Template is now in Firestore. You can update it anytime from Firebase Console.',
    );
  }
}

// Second Script ----
/// Update existing Strategy items with hint texts
/// This ONLY updates the hintText field without overwriting existing data
Future<bool> updateStrategyHintTexts() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Get the existing template document
    final docRef = firestore.collection('strategy_templates').doc('default');
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      print('❌ Template document does not exist.');
      return false;
    }

    // Get existing data
    final existingData = docSnapshot.data()!;
    final existingItems = List<Map<String, dynamic>>.from(
      existingData['items'] ?? [],
    );

    // Update only the Strategy items with hint texts
    for (var item in existingItems) {
      final itemId = item['id'];
      final sections = List<Map<String, dynamic>>.from(item['sections'] ?? []);

      // Update Vision & Mission item
      if (itemId == 'vision_mission') {
        for (var section in sections) {
          final subtitle = section['subtitle'] ?? '';

          if (subtitle == 'Vision') {
            section['hintText'] = 'Add your vision statement';
          } else if (subtitle == 'Mission') {
            section['hintText'] = 'Add your mission statement';
          } else if (subtitle == 'Core Values') {
            section['hintText'] = 'Core value 1';
          }
        }
      }

      // Update Target Audience item
      if (itemId == 'target_audience') {
        for (var section in sections) {
          final subtitle = section['subtitle'] ?? '';

          if (subtitle == 'Location') {
            section['hintText'] = 'Urban area';
          }
        }
      }

      // Update Brand Story item
      if (itemId == 'brand_story') {
        for (var section in sections) {
          final subtitle = section['subtitle'] ?? '';

          if (subtitle == 'Your Brand Story') {
            section['hintText'] =
                "Share your brand's story, inspiration, and what makes it unique";
          }
        }
      }

      // Update the sections back to the item
      item['sections'] = sections;
    }

    // Update Firestore with modified data
    await docRef.update({
      'items': existingItems,
      'version': (existingData['version'] ?? 1) + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Strategy hint texts updated successfully!');
    print('📊 Updated items: vision_mission, target_audience, brand_story');
    return true;
  } catch (e) {
    print('❌ Error updating hint texts: $e');
    return false;
  }
}

/// Update the complete Strategy template with hint texts (Alternative approach)
/// This creates the complete Strategy data structure with hint texts
Future<bool> updateCompleteStrategyTemplate() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Get the existing template document
    final docRef = firestore.collection('strategy_templates').doc('default');
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      print('❌ Template document does not exist.');
      return false;
    }

    // Get existing data
    final existingData = docSnapshot.data()!;
    final existingItems = List<Map<String, dynamic>>.from(
      existingData['items'] ?? [],
    );

    // Find and update each Strategy item
    for (int i = 0; i < existingItems.length; i++) {
      final item = existingItems[i];
      final itemId = item['id'];

      if (itemId == 'vision_mission') {
        // Update Vision & Mission with hint texts
        existingItems[i] = {
          'id': 'vision_mission',
          'title': 'Vision & Mission',
          'isCompleted': item['isCompleted'] ?? false,
          'sections': [
            {
              'subtitle': 'Vision',
              'bullets': [],
              'isTextField': true,
              'fieldType': 'text',
              'userInputs': item['sections'][0]['userInputs'] ?? [],
              'hintText': 'Add your vision statement',
            },
            {
              'subtitle': 'Mission',
              'bullets': [],
              'isTextField': true,
              'fieldType': 'text',
              'userInputs': item['sections'][1]['userInputs'] ?? [],
              'hintText': 'Add your mission statement',
            },
            {
              'subtitle': 'Core Values',
              'bullets': [],
              'isTextField': true,
              'fieldType': 'text',
              'userInputs': item['sections'][2]['userInputs'] ?? [],
              'hintText': 'Core value 1',
            },
          ],
        };
      } else if (itemId == 'target_audience') {
        // Preserve existing sections and add hint text to Location
        final sections = List<Map<String, dynamic>>.from(
          item['sections'] ?? [],
        );
        for (var section in sections) {
          if (section['subtitle'] == 'Location') {
            section['hintText'] = 'Urban area';
          }
        }
        existingItems[i]['sections'] = sections;
      } else if (itemId == 'brand_story') {
        // Update Brand Story with hint text
        existingItems[i] = {
          'id': 'brand_story',
          'title': 'Brand Story',
          'isCompleted': item['isCompleted'] ?? false,
          'sections': [
            {
              'subtitle': 'Your Brand Story',
              'bullets': [],
              'isTextField': true,
              'fieldType': 'text',
              'userInputs': item['sections'][0]['userInputs'] ?? [],
              'hintText':
                  "Share your brand's story, inspiration, and what makes it unique",
            },
          ],
        };
      }
    }

    // Update Firestore
    await docRef.update({
      'items': existingItems,
      'version': (existingData['version'] ?? 1) + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Complete Strategy template updated with hint texts!');
    return true;
  } catch (e) {
    print('❌ Error updating template: $e');
    return false;
  }
}

/// Example usage in your app:
/// 
/// Add a button in your settings or admin screen:
/// 
/// ElevatedButton(
///   onPressed: () async {
///     final success = await updateStrategyHintTexts();
///     if (success) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Hint texts updated successfully!')),
///       );
///     }
///   },
///   child: Text('Update Strategy Hint Texts'),
/// ),
/// 
/// Or use the complete update approach:
/// 
/// ElevatedButton(
///   onPressed: () async {
///     await updateCompleteStrategyTemplate();
///   },
///   child: Text('Update Complete Strategy Template'),
/// ),