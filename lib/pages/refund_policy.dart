import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({Key? key}) : super(key: key);

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
      appBar: CustomAppBar2(title: "Refund & Cancellation Policy"),
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
                  'Delivery, Cancellation & Refund',
                  style: GoogleFonts.lora(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                const SizedBox(height: 16),
                _bulletList([
                  'Refunds will not be issued for report orders that have entered the “processing” stage (assigned to an astrologer).',
                  'Refunds will not be issued once an order has been placed and executed. Cancellation requests must be made within one hour of payment.',
                  'Technical delays or glitches during processing do not qualify for refunds.',
                  'Refunds will not be processed for incorrect or inaccurate information provided by the user.',
                  'No refunds will be processed for the return of damaged products. Cash on Delivery orders may incur charges for returned products.',
                  'Refunds may be considered on a pro-rata basis for delays in activating subscription services and verified refunds will be processed within 10 business days.',
                  'Display images of products are for reference only; refunds will not be issued if products differ slightly from images.',
                ]),
                _sectionHeading('Service Refund Conditions'),
                _bulletList([
                  'The services and products provided do not replace medical, philosophical, or emotional treatments.',
                  'No refund will be given for incorrect contact details for “Call with Astrologer/Mental Wellness Practitioners”.',
                  'Refunds, if applicable, will be issued after deducting transaction fees, shipping/courier charges, customs duties, and processing costs.',
                  'Server-related issues on the Website or payment gateway must be verified with customer care before any second payment.',
                  'Refunds for multiple payments made for the same order will be issued in full, retaining only one intended payment.',
                  'The Website reserves the right to cancel any order at its discretion; refunded amounts will be credited if cancelled.',
                  'By requesting a refund, users consent to allow the quality audit team to access chat or call recordings.',
                  'Quality audit team may issue partial or full refunds to users’ wallets if consultant quality standards are not met. Processing may take up to one week.',
                ]),
                const SizedBox(height: 8),
                Text(
                  'Note: All refunds are credited to the user’s Saamay wallet.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Refunds will only be considered for the following reasons:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                _bulletList([
                  'Network issues affecting chat/call quality or causing disconnection.',
                  'Consultant’s inability to communicate fluently in the stated language.',
                  'Consultant provides irrelevant or inappropriate responses.',
                ]),
                const SizedBox(height: 8),
                Text(
                  'Important: No refunds will be issued for consultation accuracy. Saamay does not guarantee factual accuracy for consultations.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Physical products from the Saamay Store are only shipped within India; no international shipping is available.',
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
