import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/config.dart';

class AppointmentBookingDialog extends StatefulWidget {
  final int consultantId;
  final int service;
  final VoidCallback? onAppointmentConfirmed;

  const AppointmentBookingDialog({
    Key? key,
    required this.consultantId,
    required this.service,
    this.onAppointmentConfirmed,
  }) : super(key: key);

  @override
  State<AppointmentBookingDialog> createState() =>
      _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends State<AppointmentBookingDialog> {
  bool isLoading = true;
  bool isPlacingOrder = false;
  String? errorMessage;
  Map<String, dynamic>? consultantData;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  String? selectedPromotion;
  Map<String, dynamic>? selectedPromotionData;

  // Available dates based on schedules
  List<DateTime> availableDates = [];

  // Available time slots for the selected date
  List<Map<String, String>> availableTimeSlots = [];

  // Available promotions
  List<Map<String, dynamic>> promotions = [];

  // Selected time slot raw data
  String? rawStartTime;
  String? rawEndTime;

  @override
  void initState() {
    super.initState();
    fetchConsultantData();
  }

  Future<void> fetchConsultantData() async {
    try {
      final response = await http.get(
        Uri.parse('$api/consultants_schedules/${widget.consultantId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'Success') {
          setState(() {
            consultantData = jsonData['data'];
            isLoading = false;

            // Process the data
            processAvailableDates();
            processPromotions();
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load consultant data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void processAvailableDates() {
    if (consultantData == null || consultantData!['schedules'] == null) return;

    final Set<String> uniqueDates = {};

    // Extract unique dates from schedules
    for (var schedule in consultantData!['schedules']) {
      final startTime = DateTime.parse(schedule['conSchedules_startTime']);
      final date = DateTime(startTime.year, startTime.month, startTime.day);
      uniqueDates.add(DateFormat('yyyy-MM-dd').format(date));
    }

    // Convert to DateTime objects
    availableDates =
        uniqueDates.map((dateStr) => DateTime.parse(dateStr)).toList();

    // Sort dates
    availableDates.sort((a, b) => a.compareTo(b));
  }

  void processPromotions() {
    if (consultantData == null || consultantData!['promotions'] == null) return;

    promotions = List<Map<String, dynamic>>.from(consultantData!['promotions']);
  }

  void updateAvailableTimeSlots() {
    if (selectedDate == null || consultantData == null) {
      availableTimeSlots = [];
      return;
    }

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    availableTimeSlots = [];

    // Check if selected date is today
    final now = DateTime.now();
    final isToday = selectedDate!.year == now.year &&
        selectedDate!.month == now.month &&
        selectedDate!.day == now.day;

    // Use valid_schedules for time slots
    if (consultantData!['valid_schedules'] != null) {
      for (var slot in consultantData!['valid_schedules']) {
        final startTime = DateTime.parse(slot['start']);
        final slotDateStr = DateFormat('yyyy-MM-dd').format(startTime);

        // Only include slots for the selected date
        if (slotDateStr == selectedDateStr) {
          // If today, only show time slots that are in the future
          if (isToday && startTime.isBefore(now)) {
            continue; // Skip this time slot as it's in the past
          }

          final formattedStartTime = DateFormat('h:mm a').format(startTime);
          final formattedEndTime = DateFormat(
            'h:mm a',
          ).format(DateTime.parse(slot['end']));

          availableTimeSlots.add({
            'start': formattedStartTime,
            'end': formattedEndTime,
            'raw_start': slot['start'],
            'raw_end': slot['end'],
          });
        }
      }
    }

    // Sort time slots
    availableTimeSlots.sort((a, b) {
      return DateTime.parse(
        a['raw_start']!,
      ).compareTo(DateTime.parse(b['raw_start']!));
    });
  }

  Future<void> placeOrder() async {
    if (selectedDate == null || rawStartTime == null || rawEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot')),
      );
      return;
    }

    setState(() {
      isPlacingOrder = true;
    });

    try {
      // Extract date and time components
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);

      // Parse selected time slot raw data for time components
      final startDateTime = DateTime.parse(rawStartTime!);
      final endDateTime = DateTime.parse(rawEndTime!);

      // Format time as HH:MM:SS
      final startTimeStr = DateFormat('HH:mm:ss').format(startDateTime);
      final endTimeStr = DateFormat('HH:mm:ss').format(endDateTime);

      // Get promotion ID
      int? promoId;
      if (selectedPromotionData != null) {
        promoId = selectedPromotionData!['promo_id'];
      }

      // Create payload
      final payload = {
        "consultant_id": widget.consultantId.toString(),
        "con_category": consultantData!['category'] ?? "Consultation",
        "session_rate": consultantData!['rate'] ?? 0,
        "date": dateStr,
        "start_time": startTimeStr,
        "end_time": endTimeStr,
        "session_status": "Scheduled",
        "service_id": widget.service,
        if (promoId != null) "promo_id": promoId,
      };

      // Send POST request
      final response = await http.post(
        Uri.parse('$api/placeorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      setState(() {
        isPlacingOrder = false;
      });

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'Success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment booked successfully!')),
          );

          if (widget.onAppointmentConfirmed != null) {
            widget.onAppointmentConfirmed!();
          }
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to book appointment: ${jsonData['message'] ?? "Unknown error"}',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isPlacingOrder = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking appointment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // For alignment
                const Column(
                  children: [
                    Image(
                      image: AssetImage("assets/icons/calenderWT.png"),
                      height: 60,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Book Appointment",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selection
                  const Text(
                    "Select Date",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  // Date chips
                  SizedBox(
                    height: 80,
                    child: availableDates.isEmpty
                        ? const Center(child: Text("No available dates"))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableDates.length,
                            itemBuilder: (context, index) {
                              final date = availableDates[index];
                              final isSelected =
                                  selectedDate?.day == date.day &&
                                      selectedDate?.month == date.month &&
                                      selectedDate?.year == date.year;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedDate = date;
                                      selectedTimeSlot = null;
                                      rawStartTime = null;
                                      rawEndTime = null;
                                      updateAvailableTimeSlots();
                                    });
                                  },
                                  child: Container(
                                    width: 70,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF8B4513)
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isSelected
                                          ? const Color(0xFFFFF8E1)
                                          : Colors.white,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM').format(date),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('E').format(date),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFFD700,
                                            ).withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Available',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF8B4513),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Time slot selection
                  const Text(
                    "Select Time Slot",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  // Time slot dropdown
                  GestureDetector(
                    onTap: () {
                      if (selectedDate != null) {
                        _showTimeSlotsDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a date first'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 254, 249, 1),
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTimeSlot ?? 'Select time slot',
                            style: TextStyle(
                              color: selectedTimeSlot != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Promotion selection
                  if (promotions.isNotEmpty) ...[
                    const Text(
                      "Select Promotion",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _showPromotionsDialog(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 254, 249, 1),
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedPromotion ??
                                  'Select promotion (optional)',
                              style: TextStyle(
                                color: selectedPromotion != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Consultant rate
                  if (consultantData != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Consultant Rate:",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "RS${consultantData!['rate']}/session",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Confirm button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppColors.button,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed:
                          (selectedDate != null && selectedTimeSlot != null)
                              ? isPlacingOrder
                                  ? null
                                  : () => placeOrder()
                              : null,
                      icon: isPlacingOrder
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Image(
                              image: AssetImage("assets/icons/confirm.png"),
                              height: 24,
                            ),
                      label: Text(
                        isPlacingOrder
                            ? 'Processing...'
                            : 'Confirm Appointment',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTimeSlotsDialog(BuildContext context) {
    if (availableTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots for selected date'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Select Time Slot'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Scrollbar(
              // Add this Scrollbar widget
              thumbVisibility:
                  true, // Makes the scroll indicator always visible
              thickness: 6, // Adjust thickness as needed
              radius: Radius.circular(10), // Rounded corners for the scrollbar
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = availableTimeSlots[index];
                  final displayText =
                      "${timeSlot['start']} - ${timeSlot['end']}";

                  return ListTile(
                    title: Text(displayText),
                    onTap: () {
                      setState(() {
                        selectedTimeSlot = displayText;
                        rawStartTime = timeSlot['raw_start'];
                        rawEndTime = timeSlot['raw_end'];
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPromotionsDialog(BuildContext context) {
    if (promotions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No promotions available')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Select Promotion'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promotion = promotions[index];

                return ListTile(
                  title: Text(promotion['promotion_code']),
                  subtitle: Text(promotion['promo_description']),
                  onTap: () {
                    setState(() {
                      selectedPromotion = promotion['promotion_code'];
                      selectedPromotionData = promotion;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedPromotion = null;
                  selectedPromotionData = null;
                });
                Navigator.pop(context);
              },
              child: const Text('No Promotion'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// Extension method to show the appointment booking dialog from anywhere
extension AppointmentBookingDialogExtension on BuildContext {
  Future<void> showAppointmentBookingDialog({
    required int consultantId,
    required int service,
    VoidCallback? onAppointmentConfirmed,
  }) {
    return showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AppointmentBookingDialog(
          consultantId: consultantId,
          service: service,
          onAppointmentConfirmed: onAppointmentConfirmed,
        ),
      ),
    );
  }
}
