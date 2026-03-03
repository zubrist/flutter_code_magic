import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({Key? key}) : super(key: key);

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

  Widget _bulletList(List<String> items, {double indent = 16}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(left: indent, bottom: 8),
              child: Text("• $item", style: GoogleFonts.poppins(fontSize: 16)),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Disclaimer"),
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
                  'Our Disclaimer',
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _bulletList([
                  'The content and data on the Saamay website should be used at user’s own discretion. Any predictions or messages received are not substitutes for advice, programs, or treatment from licensed professionals, including lawyers, doctors, psychiatrists, or financial advisors. Saamay.in makes no guarantees, implied warranties, or assurances of any kind and will not be liable for any interpretations or use of the provided information and data.',
                  'Users acknowledge that the Website provides services without warranties and that advice is based on the varied expertise of consultants, subject to personal interpretation.',
                  'The Website offers services through verified astrologers who may suggest remedies. While given in good faith, no guarantee is provided for service outcomes, accuracy, or error correction.',
                  'Services and content on the Website are provided "as is" without any express or implied warranties, including those of merchantability or fitness for a particular purpose.',
                  'The Website is not liable for content-related issues, unauthorized account use, or errors. It does not guarantee uninterrupted or error-free service and accepts no responsibility for user data loss or damage from downloads.',
                  'The Website is not liable for service interruptions due to maintenance or unforeseen technical issues beyond its control.',
                ]),
                _sectionHeading('Liability Limits'),
                _bulletList([
                  'Users download or obtain data at their own risk, accepting responsibility for any resulting damage.',
                  'Services include content, consultations, reports, and products from Saamay Mall, services with charges on a per-minute/session basis. The Website holds no liability for the effects of these services on users.',
                  'Advisors are independent members, not employees. While their credentials are verified, the Website does not guarantee the validity or quality of their advice.',
                  'The Website is not a suicide helpline. Users facing emergencies should seek immediate help from appropriate services like AASRA (91-22-27546669).',
                  'The Website disclaims liability for data errors, delays, or damages arising from service inadequacies, unauthorized data access, or service suspension.',
                ]),
                const SizedBox(height: 8),
                Text(
                  'Saamay’s liability, if any, is limited to the amount paid by the User for the service during their membership period.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Moreover, Saamay.in is not a registered firm. It is a product of DOTIDEA INFOTECH. All the transaction and gathered data is / will be accessed by DOTIDEA INFOTECH.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
