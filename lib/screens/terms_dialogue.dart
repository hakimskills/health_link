import 'package:flutter/material.dart';

class TermsDialogue extends StatelessWidget {
  final bool isTerms;
  final Color tealColor = Color(0xFF008080);

  TermsDialogue({Key? key, required this.isTerms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tealColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isTerms ? Icons.description : Icons.privacy_tip,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isTerms ? 'Terms of Use' : 'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTerms ? _getTermsContent() : _getPrivacyContent(),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'I Understand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTermsContent() {
    return """HealthLink Terms of Use

1. Purpose and Contractual Relationship
The purpose of these General Terms and Conditions of Use is to define the terms and conditions governing the use of the HealthLink platform by individuals or entities wishing to buy or sell new or used medical equipment through the HealthLink application or website.

The Service connects Users, including doctors, laboratories, dentists, and suppliers with other Users seeking to purchase medical equipment in Algeria.

Access to and use of the Service are subject to these Conditions, which Users must read and accept before using the Platform. Acceptance of these Conditions establishes a contractual relationship between the User and HealthLink.

HealthLink acts as an intermediary between Buyers and Sellers and does not assume the role of a medical equipment manufacturer, distributor, or healthcare provider.

2. Who Offers the HealthLink Service
The HealthLink Service is offered by:
Company: HealthLink EURL
Postal Address: Lot No. 15, Zone d'Activité, Bab Ezzouar, Algiers, Algeria
Email Address: support@healthlink.dz
Customer Support: +213 21 123 456

3. Definitions
• Platform: The HealthLink application and website at www.healthlink.dz
• Account: The user account created to access the Platform's services
• User: Any individual or entity using the Platform to buy or sell medical equipment
• Seller: A User offering medical equipment via a store on the Platform
• Buyer: A User purchasing medical equipment through the Platform
• Store: A virtual storefront created by a Seller to list medical equipment

4. Access to the Platform and Service
The Service is accessible to:
• Individuals with full legal capacity under Algerian law
• Legal entities acting through authorized individuals
• Users must be at least 18 years old to create a HealthLink Account

5. Registration on the Platform
To access the Service, Users must register on the Platform by completing the registration form, providing all mandatory information (name, phone number, email). HealthLink verifies phone numbers before creating a User profile.

6. Description of Service
The Service connects Buyers with Sellers to facilitate the purchase and sale of new and used medical equipment through the Platform in Algeria. Sellers create virtual stores to list equipment, while Buyers browse and purchase products.

7. Obligations of Users
Users undertake to:
• Provide accurate, up-to-date information during registration
• Ensure respectful interactions with other Users
• Pay Sellers the full amount displayed at checkout
• Comply with Algerian laws and not infringe third-party rights
• Use the Service personally and protect Accounts against unauthorized access

8. Prohibited Behavior
Users must not:
• Use the Platform for purposes other than buying/selling medical equipment
• Violate Algerian laws or public order
• List or purchase illegal, unsafe, or non-compliant medical equipment
• Post false, misleading, or harmful content
• Engage in abusive, harassing, or disrespectful behavior

9. Intellectual Property
All Platform content is protected by intellectual property laws. Unauthorized reproduction, distribution, or use of Platform elements is prohibited.

10. Applicable Law and Jurisdiction
These Conditions are governed by Algerian law. Disputes shall be resolved by the competent courts in Algiers, Algeria.

By using HealthLink, you acknowledge that you have read, understood, and agree to be bound by these Terms of Use.""";
  }

  String _getPrivacyContent() {
    return """Privacy Charter for the Protection of Personal Data – HealthLink

1. Preamble
This Privacy Charter is governed by Algerian Law 18-07 of June 10, 2018, concerning the protection of individuals with regard to the processing of personal data.

During your use of the HealthLink platform, we may collect personal data about you, including information that identifies you, such as your name, contact details, professional credentials, and product usage data.

2. Purpose of this Charter
This Charter explains how we collect, use, and protect your personal data, in accordance with Algerian data protection laws.

3. Identity of the Data Controller
The data controller responsible for your personal data is:
HealthLink (Company)
Email: contact@healthlink.dz

4. Purpose of Collecting Personal Data
Your personal data is collected for the following purposes:
• Manage access to HealthLink's services for healthcare professionals and suppliers
• Perform user account verification and approval processes
• Facilitate order processing, delivery, and payment management
• Send service-related communications and notifications
• Generate business statistics to improve services
• Fulfill legal and regulatory obligations

5. Data Recipients
Authorized HealthLink staff and subcontractors handling data processing may access your data for the purposes listed above. Regulatory bodies may also access your data in compliance with legal obligations.

6. Data Transfer
Your personal data may be transferred to third-party service providers (payment gateways, logistics partners) for operational purposes. HealthLink ensures these parties maintain strict data protection standards.

7. Data Retention
Your personal data will be retained only as long as necessary to provide our services, comply with legal obligations, or resolve disputes. After this period, data will be securely deleted or anonymized.

8. Security Measures
HealthLink implements robust technical and organizational measures to protect personal data against unauthorized access, loss, or alteration. This includes data encryption, secure authentication, and regular audits.

9. Cookies and Tracking
HealthLink uses cookies to improve user experience and platform functionality. These may include session cookies, functional cookies, and analytics cookies. You can manage cookie preferences through your browser settings.

10. Consent
By using the HealthLink platform, you consent to the collection and use of your personal data as outlined in this Charter. You also consent to receiving notifications and communications via email or SMS related to your activities on HealthLink.

11. User Rights
You have the right to access, rectify, or delete your personal data. You may also object to data processing for legitimate reasons. To exercise these rights, contact:
Email: contact@healthlink.dz

12. Complaints
Users can file complaints with the Algerian Data Protection Authority (ANPDP) if they believe their data rights have been violated.

13. Modifications
HealthLink reserves the right to update this Privacy Charter in accordance with changes to the platform or legal requirements. Changes will take effect upon publication, and continued use of HealthLink indicates acceptance of the updated policy.

14. Effective Date
This Charter takes effect from the date of its publication on the HealthLink platform.

By using HealthLink, you acknowledge that you have read and understood this Privacy Policy and consent to the collection and processing of your personal data as described herein.""";
  }
}
