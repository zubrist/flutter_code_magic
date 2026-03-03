import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Pricing"),
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
                  'Saamay Pricing Policy',
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeading('Price Range'),
                Text(
                  'At Saamay.in, we offer customized pricing based on the services you select. Detailed pricing information is provided upfront, reflecting the level of effort, efficiency, and quality of service provided. Typically, the range of transactions on applications varies from INR 100 to 1500 per user per session.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                _sectionHeading('Payment Schedule'),
                Text(
                  'Certain services are available for fixed durations, with each service’s duration clearly specified in its description. These usage periods may range from 1 to 6 months, depending on the service.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                _sectionHeading('Price Matching'),
                Text(
                  'At Saamay.in, we strive to provide the best possible prices. If you find a comparable service with a similar level of professionalism and features from another provider, we will gladly match their price.\n\nOur prices remain stable and are not influenced by market fluctuations, competitor pricing, or other external factors.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                Text(
                  'Offers and Promotions',
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _sectionHeading('Special Offers on Astrology Services'),
                Text(
                  'At Saamay, we provide sessional offers to make your experience more rewarding. Your first chat is free for up to 5 minutes. From the next session onwards, you can earn daily free minutes when you talk or chat for a minimum of 10 minutes or more in a single session. The number of free minutes offered may vary from time to time, and eligibility is strictly based on completing the minimum service duration requirement (currently set at 10 minutes or above). These offers are time-bound, promotional in nature, and subject to change at the sole discretion of DOTIDEA INFOTECH.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                _sectionHeading('Sale Adjustment'),
                Text(
                  'If a service you have booked reduces in price within one week of your booking, please note that we are unable to adjust the price. Additionally, once you have reserved a service slot for a specific date, it generally cannot be rescheduled, and cancelling the slot may incur charges. For more information, please refer to our cancellation policy.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                _sectionHeading('Pricing Errors'),
                Text(
                  'We strive for pricing accuracy but acknowledge that errors may occur. If a service is listed at a lower price than it should be, we reserve the right to cancel the booking and will notify you promptly in such cases.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                _sectionHeading('Service Use and Sale'),
                Text(
                  'Our services, provided by DOTIDEA Infotech, are intended for personal use only. Therefore, we reserve the right to refuse service to individuals we believe may misuse the offering.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'For any inquiries, please feel free to reach us at contact@saamay.in',
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
