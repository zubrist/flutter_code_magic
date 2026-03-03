import 'package:flutter/material.dart';
import 'package:saamay/pages/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackPopup extends StatefulWidget {
  final String consultantName;
  final Function(int rating, String feedback) onSubmit;

  const FeedbackPopup({
    Key? key,
    required this.consultantName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<FeedbackPopup> createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final int _maxWords = 50;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "1",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Share Feedback",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    _selectedRating > index ? Icons.star : Icons.star_border,
                    size: 40,
                    color: _selectedRating > index ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us your experience in $_maxWords words',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) {
                // Force a rebuild to update word count
                setState(() {});
              },
            ),
          ),
          if (_countWords(_feedbackController.text) > _maxWords)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please limit your feedback to $_maxWords words',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.button,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'Submit',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedRating == 0 ||
                      _feedbackController.text.trim().isEmpty ||
                      _countWords(_feedbackController.text) > _maxWords
                  ? null
                  : () {
                      widget.onSubmit(
                        _selectedRating,
                        _feedbackController.text,
                      );
                      Navigator.pop(context);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension method to easily show the feedback popup
extension FeedbackDialogExtension on BuildContext {
  Future<void> showFeedbackPopup({
    required String consultantName,
    required Function(int rating, String feedback) onFeedbackSubmitted,
  }) async {
    return showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FeedbackPopup(
          consultantName: consultantName,
          onSubmit: onFeedbackSubmitted,
        ),
      ),
    );
  }
}
