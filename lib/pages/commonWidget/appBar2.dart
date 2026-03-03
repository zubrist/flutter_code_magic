import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool centerTitle;
  final double height;

  const CustomAppBar2({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.centerTitle = true,
    this.height = kToolbarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      flexibleSpace: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          // Overlay PNG image on top of gradient
          Positioned.fill(
            child: Image.asset('assets/images/BG.png', fit: BoxFit.cover),
          ),
        ],
      ),
      title: Text(
        title,
        style: GoogleFonts.lora(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

// AppBar(
//         centerTitle: true,
//         flexibleSpace: Stack(
//           children: [
//             Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF89216B), Color(0xFFDA4453)],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//             ),
//             Positioned.fill(
//               child: Image.asset(
//                 'assets/images/BG.png',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ],
//         ),
//         title: const Text(
//           'Kundali Matching',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
