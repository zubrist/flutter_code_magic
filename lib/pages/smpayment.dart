import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:saamay/pages/homescreen.dart';
import 'package:google_fonts/google_fonts.dart';

class AstrologerPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vendorData;
  final String mode;

  const AstrologerPaymentScreen({
    Key? key,
    required this.vendorData,
    required this.mode,
  }) : super(key: key);

  @override
  _AstrologerPaymentScreenState createState() =>
      _AstrologerPaymentScreenState();
}

class _AstrologerPaymentScreenState extends State<AstrologerPaymentScreen> {
  late double originalAmount;
  late double currentAmount;
  bool isPromoApplied = false;
  bool isLoading = false;
  bool isLoadingUserData = true;
  Map<String, dynamic>? paymentResponse;
  Map<String, dynamic>? userData;
  Razorpay _razorpay = Razorpay();

  @override
  void initState() {
    super.initState();
    originalAmount = double.parse(widget.vendorData['vendor_fees'] ?? '0.0');
    currentAmount = originalAmount;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _fetchUserData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoadingUserData = true;
      });

      final response = await http.get(
        Uri.parse('$api/user/own'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if status is Success and data exists
        if (responseData['status'] == 'Success' && responseData['data'] != null) {
          setState(() {
            userData = responseData['data']; // Access the 'data' field directly
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch user data. Invalid response format.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch user data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching user data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingUserData = false;
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _verifyPayment(response.paymentId!, response.orderId!, response.signature!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Failed: ${response.message ?? "Error occurred"}',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet Selected: ${response.walletName}'),
      ),
    );
  }

  Future<void> _verifyPayment(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse(
          '$api/verify_payment/puja/${userData?['user_id']}/$currentAmount',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
          'ref_promo_applied': false,
          'ref_promo': "",
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          try {
            // Explicitly log before placing order
            //print("Payment verified successfully, placing order now");

            // Place the order and wait for it to complete
            await _placeItemOrder();

            // Log after order placement succeeds
            //print("Order placed successfully");

            // Show success dialog only after both payment verification and order placement succeed
            _showPaymentSuccessDialog(context, responseData);
          } catch (orderError) {
            //print("Error in order placement: $orderError");
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(
            //         'Payment verified but order placement failed: ${orderError.toString()}'),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Payment verification failed.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        //print("Payment verification API error: ${response.statusCode}, ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment verification failed. Please contact support.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      //print("Exception in payment verification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _placeItemOrder() async {
    try {
      //print("Starting _placeItemOrder execution");
      final String sourceFlag = widget.mode == 'vendor' ? 'V' : 'C';
      final int id = widget.mode == 'vendor'
          ? widget.vendorData['vendor_id']
          : widget.vendorData['consultant_id'];
      //print("Placing order with: vendor_id=${widget.vendorData['vendor_id']}, item_id=${widget.vendorData['item_id']}, source=$sourceFlag");

      final orderResponse = await http.post(
        Uri.parse('$api/place_item_order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "promo_id": isPromoApplied ? widget.vendorData['promotion_id'] : null,
          "vendor_id": id,
          "item_id": widget.vendorData['item_id'],
          "referred_by": " ",
          "delivery_address": "video url",
          "source_flag": sourceFlag,
        }),
      );
      //print(sourceFlag);
      //print(widget.vendorData);
      // Log the API response for debugging
      //print("Order API response status: ${orderResponse.statusCode}");
      //print("Order API response body: ${orderResponse.body}");

      if (orderResponse.statusCode == 201) {
        final orderData = jsonDecode(orderResponse.body);
        if (orderData['status'] == 'Success') {
          //print("Order placed successfully!");
          return; // Success case, just return
        } else {
          throw Exception(
            'Order placement failed: ${orderData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to place order: ${orderResponse.statusCode}, ${orderResponse.body}',
        );
      }
    } catch (e) {
      //print("Exception in _placeItemOrder: $e");
      // Don't show snackbar here - let the calling function handle errors
      // This ensures we don't show error messages and then success screens
      rethrow; // Important: rethrow the error so the calling function knows there was a problem
    }
  }

  void _showPaymentSuccessDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PaymentSuccessSplashScreen(),
      ),
    );
  }

  void _applyPromoCode() {
    //print(currentAmount);
    if (widget.vendorData['promotion_id'] != null) {
      setState(() {
        double promoValue = widget.vendorData['item_promotion_value'] ?? 0.0;
        double discountPercentage = promoValue / 100;

        currentAmount = originalAmount - (originalAmount * discountPercentage);

        isPromoApplied = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promo "${widget.vendorData['item_promotion_code']}" applied: '
              '${widget.vendorData['item_promotion_description']}',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
    //print(currentAmount);
  }

  Future<void> _createPaymentOrder() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$api/create_payment_order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': currentAmount.toInt(), 'currency': 'INR'}),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          paymentResponse = responseData;
        });

        _openRazorpayCheckout(responseData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment order creation failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData) {
    final String rawContactNumber = userData?['user_mob'] ?? '';
    final String contactNumber = rawContactNumber.length >= 10
        ? rawContactNumber.substring(rawContactNumber.length - 10)
        : rawContactNumber;
    final String fullName = userData?['user_fullname'] ?? 'Customer';
    final String email = userData?['user_email'] ?? '';

    var options = {
      'key': razorpay,
      'amount': orderData['amount'],
      'name': 'SaamayRashi',
      'order_id': orderData['payment_id'],
      'description': 'Astrologer Consultation',
      'prefill': {'contact': contactNumber, 'email': email, 'name': fullName},
      'theme': {'color': '#89216B'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      //print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching user data
    if (isLoadingUserData) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar2(title: "Payment Details"),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String rawContactNumber = userData?['user_mob'] ?? 'N/A';
    final String contactNumber =
        rawContactNumber != 'N/A' && rawContactNumber.length >= 10
            ? rawContactNumber.substring(rawContactNumber.length - 10)
            : rawContactNumber;
    final String fullName = userData?['user_fullname'] ?? 'N/A';
    final String email = userData?['user_email'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Payment Details"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoRow('Full Name', fullName, 'Full Name'),
            SizedBox(height: 16),
            _buildInfoRow('E-mail', email, 'E-mail'),
            SizedBox(height: 16),
            _buildContactNumberRow(contactNumber),
            SizedBox(height: 16),
            _buildAmountRow(),
            if (widget.vendorData['promotion_id'] != null) _buildPromoCodeRow(),
            Spacer(),
            _buildPayNowButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String labelText, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(value, style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactNumberRow(String contactNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            'Contact Number',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      contactNumber != 'N/A' && contactNumber.length >= 10
                          ? contactNumber.substring(contactNumber.length - 10)
                          : contactNumber,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(color: Colors.black87),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            'Amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isPromoApplied
                      ? '₹ ${originalAmount.toStringAsFixed(2)}'
                      : '₹ ${currentAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.black87,
                    decoration: isPromoApplied
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              if (isPromoApplied)
                Text(
                  '₹ ${currentAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCodeRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton(
        onPressed: !isPromoApplied ? _applyPromoCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: !isPromoApplied ? AppColors.accent : Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          isPromoApplied
              ? 'Promo Applied: ${widget.vendorData['item_promotion_code']}'
              : 'Apply Promo Code: ${widget.vendorData['item_promotion_code']}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPayNowButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.button,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _createPaymentOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Pay now',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class PaymentSuccessSplashScreen extends StatefulWidget {
  const PaymentSuccessSplashScreen({super.key});

  @override
  State<PaymentSuccessSplashScreen> createState() =>
      _PaymentSuccessSplashScreenState();
}

class _PaymentSuccessSplashScreenState
    extends State<PaymentSuccessSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      // Navigate to HomeScreen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/icons/paymentDone.png"),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Your pooja booking has been successfully completed',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
