import 'package:flutter/material.dart';
import 'package:saamay/pages/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 0; // Initial rating
  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image banner section
            Container(
              width: double.infinity,
              child: Image.network(
                'https://romerolab.com.br/wp-content/uploads/2021/04/9-Dicas-para-melhorar-os-seus-feedbacks-e-engajar-os-seus-colaboradores-1.png', // Placeholder for the banner image
                fit: BoxFit.cover,
              ),
            ),

            // Text section with title and description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Accessible Anytime',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Seek guidance whenever you need it most. DivineTalk provides 24/7 live astrology consultations anytime, anywhere.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Rating stars
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Share your experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),

            // Feedback text input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _feedbackController,
                maxLength: 96,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Type your experience here...',
                ),
              ),
            ),

            // Submit feedback button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // Handle feedback submission logic
                  String feedback = _feedbackController.text;
                  //print('Rating: $_rating');
                  //print('Feedback: $feedback');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: AppColors.secondary,
                ),
                child: Text('Submit Feedback'),
              ),
            ),

            // Footer section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Saamay', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: FeedbackPage()));
}
