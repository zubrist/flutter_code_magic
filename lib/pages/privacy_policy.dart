import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lora_font.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Privacy Policy"),
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
                  'PRIVACY POLICY',
                  style: loraHeadingStyle(
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SAAMAY (“WE”, “DOTIDEA INFOTECH”) IS COMMITTED TO PROTECTING THE PRIVACY OF ITS USERS (ASTROLOGERS , MENTAL WELLBEING PROFESSIONALS AND CUSTOMERS, WHETHER REGISTERED OR NOT). PLEASE READ THIS POLICY TO UNDERSTAND HOW YOUR INFORMATION IS USED BY SAAMAY.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 24),
                _sectionHeading('USER CONSENT'),
                _sectionBody(
                  'This policy, updated periodically, outlines how SAAMAY collects and uses personal details such as identification, contact information, and birth details. By using SAAMAY, you agree to this policy. Continued use confirms your consent to these terms.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('INFORMATION COLLECTION'),
                _sectionBody(
                  'Creating a profile requires a phone number, email ID, ensuring secure registration. We also collect the date of birth only for the purpose of analyzing astrological predictions.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('PURPOSE AND USE OF DATA'),
                _sectionBody(
                  'Data collected helps personalize user profiles. Even without providing a date of birth, users can access some of SAAMAY’s services.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('DATA DELETION'),
                _sectionBody(
                  'To delete your SAAMAY profile, select "Delete Your Account" from the menu and follow the prompts.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('VOICE RECORDING PERMISSION'),
                _sectionBody(
                  'Our app allows you to ask questions via voice and video recordings, enhancing user experience. This feature requires microphone access for voice data processing.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('SECURITY COMMITMENT'),
                _sectionBody(
                  'SAAMAY prioritizes user privacy and ensures no misuse of personal data. Personal data is used solely for providing services and will not be sold or rented.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('CHILDREN’S PRIVACY'),
                _sectionBody(
                  'Users must be 18 or older. SAAMAY does not knowingly collect data from children under 13. Parents should take care of registration of child data on their behalf if required for accessing specific services which need birth details.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('SAFETY AND SECURITY'),
                _sectionBody(
                  'SAAMAY employs robust encryption to protect users\' personal and financial data, ensuring safe transactions.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('DISCLAIMER'),
                _sectionBody(
                  'SAAMAY is not liable for user interactions with third-party sites, even if links are provided on its platform.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('GRIEVANCE MAIL ID'),
                _sectionBody('Email: contact@saamay.com'),
                const SizedBox(height: 8),
                _sectionBody(
                  'For concerns or discrepancies, email the grievances in line with the Information Technology Act, 2000.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for section headings
  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFDA4453),
        ),
      ),
    );
  }

  // Helper for section body
  Widget _sectionBody(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 16)),
      );
}
