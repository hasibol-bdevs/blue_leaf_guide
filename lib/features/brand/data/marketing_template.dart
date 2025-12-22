import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marketing_item.dart';

Future<bool> uploadMarketingTemplateToFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    final templateItems = [
      // 1. Marketing Collateral
      MarketingItem(
        id: "marketing_collateral",
        title: "Marketing Collateral",
        sections: [
          MarketingSection(
            subtitle: "Select collateral",
            checkboxOptions: [
              "Product packaging design",
              "Product labels with ingredients",
              "Card & promotions materials",
            ],
            fieldType: 'checkbox',
            checkboxStates: [false, false, false],
          ),
        ],
      ),

      // 2. Email Marketing
      MarketingItem(
        id: "email_marketing",
        title: "Email Marketing",
        sections: [
          MarketingSection(
            subtitle: "Email Service Provider",
            isTextField: true,
            fieldType: 'text',
            hintText: "Mailchimp, Klaviyo, ConvertKit",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "Email Setup",
            checkboxOptions: [
              "Business email templates designed",
              "Welcome email sequence created",
              "Newsletter schedule established",
            ],
            fieldType: 'checkbox',
            checkboxStates: [false, false, false],
          ),
        ],
      ),

      // 3. Social Media Marketing
      MarketingItem(
        id: "social_media_marketing",
        title: "Social Media Strategy",
        sections: [
          MarketingSection(
            subtitle: "Instagram",
            isTextField: true,
            fieldType: 'text',
            hintText: "@username",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "TikTok",
            isTextField: true,
            fieldType: 'text',
            hintText: "@username",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "Pinterest",
            isTextField: true,
            fieldType: 'text',
            hintText: "@username",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "",
            checkboxOptions: ["Profile picture, bios, and link optimized"],
            fieldType: 'checkbox',
            checkboxStates: [false],
          ),
          MarketingSection(
            subtitle: "Branded Hashtag",
            isTextField: true,
            fieldType: 'text',
            hintText: "#YourBrandName",
            userInputs: [],
          ),
        ],
      ),

      // 4. Website
      MarketingItem(
        id: "website",
        title: "Website Setup",
        sections: [
          MarketingSection(
            subtitle: "Domain",
            isTextField: true,
            fieldType: 'text',
            hintText: "www.yourbrand.com",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "Platform",
            isTextField: true,
            fieldType: 'text',
            hintText: "Shopify, WordPress, WIX",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "Website Setup Checklist",
            checkboxOptions: [
              "Homepage with value proposition",
              "Product pages with quality images",
              "About page with brand story",
              "Shop/E-commerce functionality",
              "Blog for content marketing",
            ],
            fieldType: 'checkbox',
            checkboxStates: [false, false, false, false, false],
          ),
        ],
      ),

      // 5. SEO & Content Strategy
      MarketingItem(
        id: "seo_content_strategy",
        title: "SEO & Content Strategy",
        sections: [
          MarketingSection(
            subtitle: "SEO Essentials",
            checkboxOptions: [
              "Meta titles & descriptions",
              "Image alt text added",
              "Google Analytics installed",
            ],
            fieldType: 'checkbox',
            checkboxStates: [false, false, false],
          ),
          MarketingSection(
            subtitle: "Core Pillars",
            isTextField: true,
            fieldType: 'multi_text',
            hintText: "Core pillar 1",
            userInputs: [""], // Start with one empty field
          ),
        ],
      ),

      // 6. Offline Marketing & Social Impact
      MarketingItem(
        id: "offline_marketing",
        title: "Offline Marketing & Social Impact",
        sections: [
          MarketingSection(
            subtitle: "Event & Retails",
            checkboxOptions: [
              "Research local beauty events & markets",
              "Design booth display & create samples",
              "Create press kit with brand story",
              "Build wholesale partnerships",
            ],
            fieldType: 'checkbox',
            checkboxStates: [false, false, false, false],
          ),
          MarketingSection(
            subtitle: "Mission",
            isTextField: true,
            fieldType: 'textarea',
            hintText: "Describe your social impact mission...",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "Charity Partner",
            isTextField: true,
            fieldType: 'text',
            hintText: "www.yourbrand.com",
            userInputs: [],
          ),
          MarketingSection(
            subtitle: "",
            checkboxOptions: [
              "Donate percentage of profits",
              "Eco-friendly and ethical practices",
            ],
            fieldType: 'checkbox',
            checkboxStates: [false, false],
          ),
        ],
      ),
    ];

    await firestore.collection('marketing_templates').doc('default').set({
      'items': templateItems.map((e) => e.toMap()).toList(),
      'version': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Marketing template uploaded successfully!');
    return true;
  } catch (e) {
    print('❌ Error uploading marketing template: $e');
    return false;
  }
}

void initializeMarketingTemplate() async {
  final success = await uploadMarketingTemplateToFirestore();
  if (success) {
    print('Marketing template is now in Firestore.');
  }
}

/// Upload Planning template to Firestore
Future<bool> uploadPlanningTemplateToFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    await firestore.collection('planning_templates').doc('default').set({
      'month1': {
        'title': '1st Month Plan',
        'items': [
          "Finalize brand strategy, logo, and colors",
          "Create business cards and collateral",
          "Set up social media accounts",
        ],
      },
      'month2': {
        'title': '2nd Month Plan',
        'items': [
          "Launch website and implement SEO",
          "Begin consistent content posting",
          "Launch first email campaign",
        ],
      },
      'month3': {
        'title': '3rd Month Plan',
        'items': [
          "Partner with influencers",
          "Plan first event or pop-up",
          "Launch charitable initiative",
          "Analyse metrics and plan next 90 days",
        ],
      },
      'version': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Planning template uploaded successfully!');
    return true;
  } catch (e) {
    print('❌ Error uploading planning template: $e');
    return false;
  }
}

/// Upload all templates at once
Future<Map<String, bool>> uploadAllTemplates() async {
  print('📤 Uploading all templates to Firestore...');

  final marketingSuccess = await uploadMarketingTemplateToFirestore();
  final planningSuccess = await uploadPlanningTemplateToFirestore();

  return {'marketing': marketingSuccess, 'planning': planningSuccess};
}

void initializeAllTemplates() async {
  final results = await uploadAllTemplates();

  print('\n📊 Upload Results:');
  print('Marketing: ${results['marketing'] == true ? '✅' : '❌'}');
  print('Planning: ${results['planning'] == true ? '✅' : '❌'}');

  if (results.values.every((success) => success == true)) {
    print('\n🎉 All templates uploaded successfully!');
  } else {
    print('\n⚠️ Some templates failed to upload. Check errors above.');
  }
}
