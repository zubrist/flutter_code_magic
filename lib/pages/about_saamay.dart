import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lora_font.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';

class AboutSaamayPage extends StatelessWidget {
  const AboutSaamayPage({Key? key}) : super(key: key);

  Widget _sectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: loraHeadingStyle(fontSize: 20, color: const Color(0xFFDA4453)),
      ),
    );
  }

  Widget _sectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "About Saamay"),
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
                  'SAAMAY - Astrology and Mental Wellness Consultancy',
                  style: loraHeadingStyle(
                    fontSize: 24,
                    color: const Color(0xFFDA4453),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'At SAAMAY, we are committed to bringing synergy between mental well-being and astrological consultancy online. Our aim is to provide a holistic approach to personal growth and self-discovery through a unique blend of astrology and mental health practices.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 24),
                _sectionHeading('Story of Origins'),
                _sectionBody(
                  'The inception of SAAMAY stems from a profound understanding of the increasing demand for mental health support and spiritual guidance in today\'s fast-paced world. We recognized that many individuals seek answers and comfort through astrology, while also grappling with mental health challenges. Our founders, passionate about both astrology and mental wellness online services, envisioned a platform that integrates these two vital aspects of life. By combining our expertise in astrology with a commitment to mental well-being, we aim to create a safe and supportive space for individuals from various backgrounds to explore their spiritual journeys with soul astrological reading and strengthen their mental wellness with online sessions with expert counsellors in areas such as psychology, child with special needs, anger management, stress management, yoga, and meditation.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('Our Vision'),
                _sectionBody(
                  'We aspire to be a trusted and transformative source of holistic guidance, self-awareness, and personal growth supported by mental wellness practices and astrological insights through empathy, authenticity, and emerging technology.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('Our Mission'),
                _sectionBody(
                  'Bringing a platform to enable people for complete services around holistic healing and Astral guidance.',
                ),
                const SizedBox(height: 24),
                _sectionHeading('Discover our Offerings'),
                _sectionBody(
                  'Our offerings are around Astrology and Mental Wellness. Within Astrology, SAAMAY offers Vedic astrologer online, online tarot readings, numerology reading online, Astrology Remedy Offerings, online booking of various pujas, Daily Horoscope, Kundli matchmaking for marriage, and provides a reading corner for astrology-related blogs and articles.',
                ),
                const SizedBox(height: 8),
                _sectionBody(
                  'Within Mental Wellness, offerings from SAAMAY include Psychology Counselling, relationship advice online, online life coaching, anger management, stress management, guidance for children with special needs, parental guidance, motivational speaking, family services counselling, yoga, meditation, checking stress levels online, creating mental wellness journaling online, and providing a reading corner for mental wellness-related blogs and articles.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
