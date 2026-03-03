// terms_and_condition_page.dart
// Full expanded Terms & Conditions page converted from the provided HTML.
// This file preserves the exact wording (line-to-line, word-to-word) from your HTML content.
// Helpers `_sectionHeading`, `_sectionBody`, `_bulletList` are used as requested.
// NOTE: This file assumes you have these imports and styles available in your project:
//  - google_fonts
//  - loraHeadingStyle(fontSize:, color:)
//  - AppColors.background
//  - CustomAppBar2(title:)
// Adjust imports if your project structure differs.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/pricing.dart';
import 'lora_font.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';

class TermsAndConditionPage extends StatelessWidget {
  const TermsAndConditionPage({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, String route) {
    // Try named route first, fallback to direct widget navigation
    try {
      Navigator.of(context).pushNamed(route);
    } catch (e) {
      if (route == '/pricing') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PricingPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Terms and Conditions"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms and Conditions of Usage',
                  style: loraHeadingStyle(
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                const SizedBox(height: 16),

                // Paragraph 1
                Text(
                  'These Terms and Conditions of Use (hereinafter referred to as “Terms of Usage”) outline and govern the User\'s access to the content and services provided by DOTIDEA Infotech through www.saamay.in (hereinafter referred to as “We,” “Saamay,” “us,” “our,” “Saamay application,” or “Website”). Individuals who register on the Saamay website by providing the required details will be referred to as “Users.”',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Updation
                _sectionHeading('Updation'),
                _sectionBody(
                  'The Website may update/amend/modify these Terms of Usage from time to time. The User is responsible for checking the Terms of Usage periodically to remain in compliance with these terms.',
                ),
                const SizedBox(height: 16),

                // User Consent
                _sectionHeading('User Consent'),
                _sectionBody(
                  'By accessing and using this Website, you (“User”) acknowledge that you understand and expressly consent to the Terms of Usage of this Website. If you do not agree with these Terms, please refrain from clicking the “I AGREE” button. We recommend that you carefully read the Terms of Usage before using or registering on the Website, or accessing any materials, information, or services provided through it. Your use of the Website, including any future amendments, will signify your acceptance of these Terms and your agreement to be legally bound by them.',
                ),
                const SizedBox(height: 16),

                // GENERAL DESCRIPTION
                _sectionHeading('GENERAL DESCRIPTION'),
                _sectionBody(
                  'The Website is an internet-based platform available on the World Wide Web, mobile applications, and other electronic media, providing astrological and mental wellness content, reports, data, chat and telephone or video consultations (collectively referred to as “Content”). The Website offers both “Free Services” and “Paid Services” (together referred to as “Services”). To access personalized astrological and mental wellness services, receive additional Content, or use the Free and Paid Services, an individual must register as a User on the portal. By registering, the  User agrees to:',
                ),
                _bulletList([
                  'Provide current, complete, and accurate information as prompted by the Website.',
                  'Maintain and update the provided information as needed to ensure its accuracy, currency, and completeness.',
                ]),
                const SizedBox(height: 16),

                // Registration and Eligibility
                _sectionHeading('Registration and Eligibility'),
                _bulletList([
                  'By accessing this website, you confirm that you are at least 18 years old and legally capable of entering into a binding contract under the Indian Contract Act, 1872. The Website disclaims any responsibility for misuse by any user, including minors, accessing its services. However, questions related to minors within your family are allowed under the terms set forth in this policy.',
                  'To use the services, users must register on the Website and agree to provide current, accurate, and updated information in the registration form. This information and any updates are collectively referred to as “Registration Data.”',
                  'You can create an account using your valid email address and the password you choose. By creating an account, you affirm that the provided information is accurate and complete and agree to keep it updated. Using another person’s account for services is strictly prohibited. The Website reserves the right to suspend or terminate accounts and deny future access if the information provided is found to be inaccurate, incomplete, or not current.',
                  'The right to use this Website is personal and non-transferable. Users are responsible for maintaining the confidentiality of their passwords and other registration details and for all activities under their account. The Website is not liable for any loss or damage due to failure to keep this information secure. Users should notify the Website of any unauthorized account use or security breaches and log out after each session.',
                  'When using any service, users will be informed if the service is directly provided by the Website or a third party. The Website does not control or monitor third-party information shared through its platform.',
                  'Users acknowledge that personal data, including payment details shared online, may be vulnerable to misuse, hacking, or fraud. The Website and its Payment Service Providers do not have control over such risks.',
                  Text.rich(
                    TextSpan(
                      text:
                          'The Website prohibits the use of its services in the following cases:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color.fromARGB(255, 222, 108, 108),
                      ),
                    ),
                  ),
                  [
                    'Users residing in jurisdictions that do not permit the use of the services offered.',
                    'Users from states or countries where laws, regulations, or treaties restrict trade relations.',
                    'Due to any religious prohibitions.',
                    'Users creating multiple accounts using different phone numbers. Only one active account is allowed per user.',
                  ],
                ]),
                const SizedBox(height: 16),

                // WEBSITE CONTENT
                _sectionHeading('WEBSITE CONTENT'),
                _bulletList([
                  'The Website and any individual Websites which may be available through external hyperlinks with the Website are private property.',
                  'All interaction on this Website inclusive of the guidance and advice received directly from the Licensed Provider must comply with these Terms of Usage.',
                  'The User shall not post or transmit through this Website any material which violates or infringes in any way upon the rights of others, or any material which is unlawful, abusive, defamatory, invasive of privacy, vulgar, obscene, profane or otherwise objectionable, which encourages conduct that would constitute a criminal offence, give rise to civil liability or otherwise violate any law.',
                  'The Website shall have a right to suspend or terminate access by such User or terminate the User’s registration and such User shall not gain access to the Website.',
                  'The Website reserves the right to terminate the access or to change or discontinue any aspect or feature of the Website including, but not limited to, content, graphics, deals, offers, settings, etc.',
                  'Any information other than the guidance and advice received directly from the Third-Party Service Provider, the educational, graphics, research sources and other incidental information on the Site, the content, should not be considered as medical advice.',
                  'The Website does not take a guarantee regarding the medical advice, if provided, by the third-party service provider inclusive of registered astrologers and mental wellness service providers with the site. The User should always talk to an appropriately qualified health care professional for diagnosis and treatment including information regarding which medications or treatment may be appropriate for the User. None of the Content represents or warrants that any particular medication or treatment is safe, appropriate, or effective for you. Saamay does not endorse any specific tests, medications, products or procedures.',
                  'The Website does not take a guarantee regarding the medical advice, if provided, by the third-party service provider inclusive of registered astrologers and mental wellness service providers with the site. The User should always talk to an appropriately qualified health care professional for diagnosis and treatment including information regarding which medications or treatment may be appropriate for the User. None of the Content represents or warrants that any particular medication or treatment is safe, appropriate, or effective for you. Saamay does not endorse any specific tests, medications, products or procedures.',
                  'The Website does not guarantee any untoward incident that may happen to the User after seeking the Service. The Website or the Service Provider providing the advice is not liable and does not guarantee any results as expected by the User and accessing the Website in such a scenario is purely at the risk of the User.',
                  'By using the Site, Application or Services, User hereby agrees that any legal remedy or liability that you seek to obtain for actions or omissions of other Members inclusive of the service provider registered with the Website or other third parties linked with the Website shall be limited to claim against such particular party who may have caused any harm. You agree not to attempt to impose liability on or seek any legal remedy from the Website with respect to such actions or omissions.',
                ]),
                const SizedBox(height: 16),

                // USER ACCOUNT ACCESS
                _sectionHeading('USER ACCOUNT ACCESS'),
                _sectionBody(
                  'The Website reserves the right to access user accounts and information created by users to ensure and uphold the quality of services and to address customer needs efficiently. By using the Website, users consent to unrestricted access to their accounts by the Website, including its employees, agents, or authorized personnel for these purposes. To address complaints or investigate reports of potential misuse, the Website may review records on a case-by-case basis. Users are advised to review the Privacy Policy for details related to such record-keeping and access.',
                ),
                const SizedBox(height: 16),

                // PRIVACY POLICY
                _sectionHeading('PRIVACY POLICY'),
                _sectionBody(
                  'The User hereby consents, expresses and agrees that the User has read and fully understands the Privacy Policy of the Website. The User further consents that the terms and contents of such Privacy policy are acceptable to the User inclusive of any update/alteration/change made and duly displayed on the Website.',
                ),
                const SizedBox(height: 16),

                // BREACH AND TERMINATION
                _sectionHeading('BREACH AND TERMINATION'),
                _sectionBody(
                  'The Website reserves the right to modify, change, discontinue, or alter services or user accounts, in whole or in part, without prior notice to the User. This action may be taken with or without explanation or notification.\nAny violation of the Terms of Usage will result in the immediate cancellation of the User\'s registration. The Website holds the right to terminate accounts and take prompt action if:',
                ),
                _bulletList([
                  'It is unable to verify or authenticate the Registration Data or other relevant information provided by the User.',
                  'It believes the User’s actions may result in legal liability for the Website, other users, or any associated service providers.',
                  'It suspects that the User has provided false or misleading Registration Data, disrupted other users or the administration of services, or violated the Website’s Privacy Policy.',
                ]),
                const SizedBox(height: 16),

                // DELIVERY, CANCELLATION AND REFUND
                _sectionHeading('DELIVERY, CANCELLATION AND REFUND'),
                _sectionBody(
                  'Refunds will not be issued for report orders that have entered the “processing” stage (assigned to an astrologer). Users are solely responsible for any hasty or careless ordering, and the Website holds no liability once processing has begun.\n\nRefunds will not be issued once an order has been placed and executed. If a user wishes to cancel a successfully placed order before it is executed, they must contact customer support within one hour of payment. The decision to issue a refund remains at the discretion of the Website.\n            \nTechnical delays or glitches that occur during the processing of requests, including report generation by astrologers, do not qualify for refunds. Users acknowledge that timelines are approximate, and all efforts will be made to adhere to the displayed timelines.\n            \nRefunds will not be processed for incorrect or inaccurate information provided by the user. Users must ensure they check all entered information before submitting. Changes to incorrect data may be requested within one hour of the service execution by contacting customer care.\n            \nNo refunds will be processed for the return of damaged products. Users agree that they are responsible for any damage to products after delivery. For “Cash on Delivery” orders, users will be charged the product cost and applicable shipping/customs charges if a product is returned.\n            \nRefunds may be considered on a pro-rata basis for delays in activating subscription services. Damages during transit will be handled by the Website and its partners and verified refunds will be processed within 10 business days.\n            \nDisplay images of products are for reference only. The Website aims to deliver products as shown but does not guarantee identical matches. Refunds will not be issued on these grounds.\n            \nThe services and products provided do not replace any philosophical, emotional, or medical treatments. The Website disclaims any responsibility for the effects of astrological practices on health. Orders for such services or products are placed at the user’s discretion, and no refunds will be issued on these grounds.\n            \nNo refund will be given for incorrect contact details provided for the “Call with Astrologer” feature. Users must ensure their contact information is correct and be available to answer calls. Refunds are not issued for calls that have connected.\n            \nRefunds, if applicable, will be issued after deducting transaction fees, shipping/courier charges, customs duties, and any processing costs incurred.\n            \nIn cases of server-related issues (e.g., slowdowns, failures, timeouts) on the Website or payment gateway, users must check their bank accounts before initiating a second payment. If debited, users should not pay again and should contact customer care for confirmation. If not debited, a new payment can be initiated.\n            \nRefunds for multiple payments made for the same order will be issued in full, with only one payment retained for the intended order.\n            \nThe Website reserves the right to cancel any order at its discretion, including for reasons such as service unavailability, pricing errors, or other issues. If an order is cancelled after payment, the user will receive a refund for the amount paid.\n            \nBy requesting a refund, users consent to allow Saamay’s quality audit team to access chat or call recordings of consultations to determine refund eligibility.',
                ),
                const SizedBox(height: 8),

                Text(
                  'Saamay’s quality audit team may, at their discretion, issue partial or full refunds to users’ wallets if consultant quality standards are not met. Refunds may take up to one week to process.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text:
                        'Note: All refunds are credited to the user’s Saamay wallet.',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Refunds will only be considered for the following reasons:',
                ),
                _bulletList([
                  'Network issues affecting chat/call quality or causing disconnection.',
                  'The consultant’s inability to communicate fluently in the stated language.',
                  'The consultant provides irrelevant or inappropriate responses.',
                ]),
                const SizedBox(height: 8),
                _sectionBody(
                  'Important: No refunds will be issued for consultation accuracy. Saamay does not guarantee factual accuracy for consultations.',
                ),
                const SizedBox(height: 8),
                _sectionBody(
                  'Physical products from the Saamay Store are only shipped within India; no international shipping is available.',
                ),
                const SizedBox(height: 16),

                // User Obligation
                _sectionHeading('User Obligation'),
                _sectionBody(
                  'Users, including astrologers and customer members, must adhere to the Website’s privacy policy, terms, and conditions. Users confirm they are individuals, not corporations or business entities. The rights to use the Website are personal to each User, who must comply with the following obligations:',
                ),
                _bulletList([
                  'Users shall not post, publish, or transmit false, misleading, defamatory, harmful, threatening, harassing, offensive, or discriminatory content, nor content that infringes on others\' rights or violates laws.',
                  'Users shall not share content they do not have the right to share or that infringes on intellectual property rights unless adhering to Fair Use.',
                  'Collecting screen names or emails for advertising or spamming is prohibited.',
                  'Sending unsolicited emails or promotions is not allowed.',
                  'Users shall not upload files containing viruses or harmful software.',
                  'Users must not engage in activities that disrupt Website access or attempt unauthorized access to any part of the Website.',
                  'Users must comply with all applicable laws and refrain from using services for commercial purposes without consent.',
                  'Users must not reverse-engineer, copy, modify, or resell the Website’s content.',
                ]),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Users agree to:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _bulletList([
                  'Receive communication via various channels (email, SMS, WhatsApp) regarding app/Website use.',
                  'Avoid transmitting offensive, abusive, or illegal material or encouraging unlawful conduct.',
                  'Report misuse or violations to Customer Care. False complaints may lead to account termination without a refund.',
                  'Respect other Users\' experiences on the Website.',
                ]),
                const SizedBox(height: 8),

                _sectionBody(
                  'The Website reserves the right to suspend or terminate services to Users who are unreasonable or abusive. If violations continue despite warnings, Users may be banned from the platform, with any wallet balance refunded after applicable charges are deducted.',
                ),
                const SizedBox(height: 16),

                // Bank Account Information
                _sectionHeading('Bank Account Information'),
                _sectionBody(
                  'Users must provide accurate banking details when required and agree to the following obligations:',
                ),
                _bulletList([
                  'Users confirm that the debit/credit card details they provide for services are correct, valid, and authorized for use by them.',
                  'Payments can be made using a debit/credit card or online banking, and Users affirm they are entitled to use these accounts for transactions.',
                  'Users must ensure their payment details are accurate and that their account has sufficient funds to complete transactions.',
                ]),
                const SizedBox(height: 8),

                _sectionBody(
                  'If any terms are deemed invalid under applicable laws, they will be replaced with enforceable terms that match the original intent, with the rest of the terms remaining effective.',
                ),
                const SizedBox(height: 16),

                // LIABILITY LIMITS
                _sectionHeading('Liability Limits'),
                _bulletList([
                  'Users download or obtain data at their own risk, accepting responsibility for any resulting damage.',
                  'Services include astrological content, consultations, reports, and products from Saamay Shop, with charges on a per-minute/session basis. The Website holds no liability for the effects of these services on users.',
                  'Advisors are independent members, not employees. While their credentials are verified, the Website does not guarantee the validity or quality of their advice.',
                  'The Website is not a suicide helpline. Users facing emergencies should seek immediate help from appropriate services like AASRA (91-22-27546669).',
                  'The Website disclaims liability for data errors, delays, or damages arising from service inadequacies, unauthorized data access, or service suspension.',
                  'Saamay’s liability, if any, is limited to the amount paid by the User for the service during their membership period.',
                ]),
                const SizedBox(height: 16),

                // Indemnification
                _sectionHeading('Indemnification'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'The User shall indemnify, defend, and hold harmless the Website and its parent, subsidiaries, affiliates, officers, directors, employees, suppliers, consultants, and agents from any and all third-party claims, liability, damages and/or costs (including, but not limited to, attorney’s fees) arising from Your use of the Services, Your violation of the Privacy Policy or these Terms of Service, or Your violation of any third party\'s rights, including without limitation, infringement by You or any other user of Your account of any intellectual property or other right of any person or entity.These Terms of Service will inure to the benefit of the Website’s successors, assigns, and licensees.',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // Proprietary Rights to Content
                _sectionHeading('Proprietary Rights to Content'),
                _sectionBody(
                  'The User acknowledges that the Content—such as text, software, music, sound, photographs, videos, graphics, or other materials in sponsor advertisements or distributed via email, as well as commercially produced information provided by the Website, its suppliers, or advertisers—is protected by copyright, trademarks, service marks, patents, and other proprietary rights and laws. Users are not allowed to copy, use, reproduce, distribute, perform, display, or create derivative works from the Content without explicit authorization from the Website, its suppliers, or advertisers. Additionally, content like images, text, and designs on the Website\'s portals may be sourced from various online sites such as Google Images / Pixabay / Pexels. DOTIDEA Infotech holds no liability for the copyrights of such content or data.',
                ),

                const SizedBox(height: 8),

                Text(
                  'All images displayed on this website, including promotional graphics, banners, and product visuals, are **AI-generated and do not depict real individuals or events**. These images have been custom-created using artificial intelligence technologies to represent conceptual scenarios and are not based on copyrighted photographs or likenesses of actual people.\n\nYou are authorized to use these images on this website for commercial, promotional, and illustrative purposes without restriction, as they are generated specifically for this site and do not infringe on any third-party copyrights.\n\nNote: While these images are designed to appear realistic, any resemblance to actual persons, living or dead, is purely coincidental and unintentional.\n\nIf you have questions regarding the image usage rights, please contact our support team at contact@saamay.in',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 8),

                Text(
                  'Notices\nUnless otherwise stated in these Terms of Service, all notices must be in writing and sent either via email or standard mail. Notices will be considered delivered 24 hours after an email is sent or 3 days after mailing to the User\'s address provided during registration, or to the Website at:\n “Taruchaya Apartment, 16 A Bose Para Road, Kolkata- 700008, India”',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Restricted Content
                _sectionHeading('Restricted Content'),
                Text.rich(
                  TextSpan(
                    text: 'Child Endangerment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Our site strictly prohibits content involving child exploitation or abuse, resulting in immediate account deletion. This includes child sexual abuse materials. Report any such content on the Saamay site. We do not permit the use of the Saamay site to endanger children, including:',
                ),
                _bulletList([
                  'Inappropriate interactions or grooming behaviour aimed at children.',
                  'Sexualization or exploitation of minors.',
                  'Threats or blackmail involving children (sextortion).',
                  'Child trafficking.',
                ]),
                const SizedBox(height: 8),
                _sectionBody(
                  'Content that appeals to children but includes adult themes (e.g., excessive violence, and harmful activities) is also banned. Content promoting negative body image or depicting cosmetic alterations for entertainment is prohibited.',
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Inappropriate Content',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'To maintain a respectful platform, harmful or inappropriate content is not allowed.',
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Sexual Content and Profanity',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _bulletList([
                  'Sexual nudity or suggestive imagery.',
                  'Sex acts depicted in illustrations or text.',
                  'Sexual aids, fetishes, or illegal themes.',
                  'Lewd language, profanities, and explicit text.',
                  'Bestiality or escort services.',
                  'Content degrading individuals or simulating clothing removal.',
                  'Non-consensual sexual content or threats.',
                ]),
                const SizedBox(height: 8),

                _sectionBody(
                  'Accounts violating these rules may be deleted immediately.',
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Hate Speech',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _bulletList([
                  'Hateful language or slurs targeting protected groups.',
                  'Content inciting discrimination or depicting hate symbols.',
                ]),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Violence',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Apps showing excessive violence or promoting dangerous activities are banned. Examples include:',
                ),
                _bulletList([
                  'Realistic depictions of violence or violent threats.',
                  'Content promoting self-harm or life-threatening acts.',
                ]),
                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    text: 'Terrorist Content',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Terrorist organizations cannot use our platform for any purpose, including recruitment or content promoting terrorism.',
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Dangerous Organizations and Movements',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Content related to groups that endorse violence against civilians is prohibited.',
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Sensitive Events',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Content that exploits or trivializes significant social, cultural, or political events is banned. Violations include:',
                ),
                _bulletList([
                  'Insensitivity toward deaths or tragic events.',
                  'Denial of documented tragic events.',
                  'Profiting from such events without benefit to victims.',
                ]),
                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    text: 'Bullying and Harassment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Content that includes threats, bullying, or harassment is prohibited. Violations include:',
                ),
                _bulletList([
                  'Bullying related to religious or international conflicts.',
                  'Exploitative behaviour such as blackmail.',
                  'Public humiliation or harassment targeting victims of the tragedy.',
                ]),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Dangerous Products',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Users are not allowed to facilitate the sale or manufacture of:',
                ),
                _bulletList([
                  'Explosives, firearms, or ammunition.',
                  'Firearm conversion instructions.',
                  'Psychotropic drugs or tobacco products.',
                ]),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Black Magic, Witchcraft, Voodoo, and Tantrism',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 222, 108, 108),
                    ),
                  ),
                ),
                _sectionBody(
                  'Our organization prohibits any involvement in black magic, witchcraft, voodoo, or tantrism. Accounts found engaging in these activities will be deleted.',
                ),
                const SizedBox(height: 16),

                // Saamay Services
                _sectionHeading('Saamay Services:'),
                _sectionBody(
                  'These Terms of Service apply to all users of Saamay Services Private Limited. Information provided by users through Saamay may include links to third-party websites that Saamay does not own or control. Saamay is not responsible for the content, privacy practices, or policies of these third-party sites and assumes no liability for errors, defamation, falsehoods, obscenity, or inappropriate content from users or third parties. Saamay cannot censor or edit such content, and users acknowledge that Saamay is not liable for any damages or claims related to third-party content.',
                ),
                const SizedBox(height: 8),

                _sectionBody('Errors, Corrections, and Service Modifications:'),
                _sectionBody(
                  'Saamay does not guarantee that its site will be error-free, virus-free, or that any defects will be fixed. We do not warrant the accuracy or reliability of the information on Saamay. We may modify site features, content, or services at any time and reserve the right to edit or remove any content. Saamay can modify or discontinue the Services or site without notice and holds no liability for such changes.',
                ),
                const SizedBox(height: 8),

                // Pricing link (tappable)
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(text: ''),
                      TextSpan(
                        text: 'SAAMAY Pricing Policy',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // deep link or external link - adjust as needed
                            // using in-app navigation to '/pricing' as placeholder
                            _navigateTo(context, '/pricing');
                          },
                      ),
                      TextSpan(text: ''),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GOVERNING LAW AND JURISDICTION
                _sectionHeading('GOVERNING LAW AND JURISDICTION'),
                _bulletList([
                  'Any dispute related to these Terms of Usage, including their scope or applicability, shall be resolved through arbitration in India by a mutually appointed sole arbitrator. Arbitration will follow the Arbitration and Conciliation Act, 1996, with the seat in New Delhi, and all proceedings will be conducted in English. The arbitrator\'s award will be final and binding.',
                  'Either party may seek interim relief from a competent court in Kolkata to protect their rights while arbitration is pending. Both parties agree to the exclusive jurisdiction of Indian courts in Kolkata for such proceedings. If one party files a contrary action, the other may recover up to One Lakh Rupees in attorneys\' fees and costs.',
                  'These Terms of Usage are governed by Indian law, without regard to any conflicting legal principles. If a court finds any provision unenforceable, it will be modified to meet legal objectives, while the remainder of the Terms will remain effective. Headings are for reference only and do not define the scope of sections. Waivers must be in writing and signed by Saamay. These Terms constitute the entire agreement between the parties and supersede any prior agreements.',
                  'Your use of the Services and these Terms will be interpreted under Indian law, excluding conflict-of-law rules. Disputes will be submitted to a New Delhi court, where parties can seek injunctive or equitable relief to protect their intellectual property rights.',
                ]),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for section headings
  Widget _sectionHeading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: loraHeadingStyle(fontSize: 20, color: const Color(0xFFDA4453)),
        ),
      );

  // Helper for section body
  Widget _sectionBody(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 16)),
      );

  // Helper for bullet lists
  Widget _bulletList(List<dynamic> items, {double indent = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        if (item is String) {
          return Padding(
            padding: EdgeInsets.only(left: indent, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(item, style: GoogleFonts.poppins(fontSize: 16)),
                ),
              ],
            ),
          );
        } else if (item is Widget) {
          // Directly render widgets like Text.rich
          return Padding(
            padding: EdgeInsets.only(left: indent, bottom: 6),
            child: item,
          );
        } else if (item is List) {
          // Handle nested sub-bullets
          return _bulletList(item, indent: indent + 24);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
