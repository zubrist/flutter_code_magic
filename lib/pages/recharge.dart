import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saamay/pages/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/login.dart';
//import 'package:saamay/pages/AstrologersPage.dart';
import 'package:saamay/pages/astrologers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

// Pack Model
class Pack {
  final int packId;
  final String title;
  final double price;
  final double originalPrice;
  final String discount;
  final String period;
  final String badge;
  final List<String> features;
  final int packMnts;
  final String packType;
  final int packValidity;
  final String packCategory;
  bool isEligible;
  bool isCheckingEligibility;
  bool isExpanded;

  Pack({
    required this.packId,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.period,
    required this.badge,
    required this.features,
    required this.packMnts,
    required this.packType,
    required this.packValidity,
    required this.packCategory,
    this.isEligible = true,
    this.isCheckingEligibility = false,
    this.isExpanded = false,
  });

  // Factory constructor to create Pack from API response
  factory Pack.fromJson(Map<String, dynamic> json) {
    // Parse pack_desc (which contains features) into a list
    List<String> featuresList = [];
    if (json['pack_desc'] != null && json['pack_desc'].toString().isNotEmpty) {
      featuresList = json['pack_desc']
          .toString()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList();
    }

    return Pack(
      packId: json['pack_id'] ?? 0,
      title: json['pack_name'] ?? '',
      price: (json['pack_value'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['pack_original_value'] as num?)?.toDouble() ?? 0.0,
      discount: json['pack_discount'] ?? '',
      period: 'Valid for ${json['pack_validity'] ?? 0} days',
      badge: json['pack_feature'] ?? '',
      features: featuresList,
      packMnts: json['pack_mnts'] ?? 0,
      packType: json['pack_type'] ?? '',
      packValidity: json['pack_validity'] ?? 0,
      packCategory: json['pack_category'] ?? '',
    );
  }
}

class RechargePage extends StatefulWidget {
  const RechargePage({Key? key}) : super(key: key);

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  // Controllers
  late final TextEditingController _amountController;
  late final TextEditingController _referralController;
  late final ScrollController _scrollController;
  late final Razorpay _razorpay;

  // Constants
  static const double _gstPercentage = 18.0;
  static const double _minAmount = 10.0;
  static const List<String> _quickAmounts = [
    '25',
    '50',
    '100',
    '200',
    '500',
    '2000',
    '3000',
    '4000',
    '8000',
    '15000',
    '25000',
    '50000'
  ];

  // Subscription Packs
  List<Pack> _Packs = [];
  bool _isLoadingPacks = true;

  // State variables
  double _selectedAmount = 0;
  bool _showPaymentDetails = false;
  bool _isReferralApplied = false;
  String _referralMessage = '';
  bool _isValidatingReferral = false;
  bool _isLoading = false;
  double _userWalletBalance = 0.0;
  bool _isLoadingBalance = true;
  bool _referredFlag = false;
  String _amountErrorMessage = '';
  Map<String, dynamic> _paymentResponse = {};
  int? _selectedPackIndex;

  // Computed properties
  double get _gstAmount => _selectedAmount * _gstPercentage / 100;
  double get _totalAmount => _selectedAmount + _gstAmount;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _referralController = TextEditingController();
    _scrollController = ScrollController();
    _amountController.addListener(_updateAmount);
    _initializeRazorpay();
    _fetchUserBalance();
    _fetchPacks();
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmount);
    _amountController.dispose();
    _referralController.dispose();
    _scrollController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _fetchPacks() async {
    setState(() => _isLoadingPacks = true);

    try {
      final response = await http.get(
        Uri.parse('$api/packs_by_category/astrology'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'successful' &&
            responseData['data'] != null) {
          final List<dynamic> packsJson = responseData['data'];

          if (mounted) {
            setState(() {
              _Packs = packsJson
                  .map((json) => Pack.fromJson(json))
                  .where((pack) => pack.packCategory == 'Astrology')
                  .toList();
              _isLoadingPacks = false;
            });

            // Check eligibility for all packs after fetching
            _checkAllPacksEligibility();
          }
          return;
        }
      }

      // Handle error
      if (mounted) {
        setState(() {
          _Packs = [];
          _isLoadingPacks = false;
        });
        _showErrorSnackBar('Failed to fetch packs');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _Packs = [];
          _isLoadingPacks = false;
        });
        _showErrorSnackBar('Network error: ${e.toString()}');
      }
    }
  }

  Future<void> _checkAllPacksEligibility() async {
    try {
      final userId = responseList['user_data']['user_id'];

      // Single API call to get all user packs
      final response = await http.get(
        Uri.parse('$api/user_packs/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'successful' &&
            responseData['data'] != null) {
          // Extract active pack IDs from the response
          final List<dynamic> userPacks = responseData['data'];
          final Set<int> activePackIds = {};

          for (var userPack in userPacks) {
            if (userPack['is_active'] == true &&
                userPack['pack_details'] != null) {
              activePackIds.add(userPack['pack_details']['pack_id'] as int);
            }
          }

          // Update eligibility for all packs
          if (mounted) {
            setState(() {
              for (var pack in _Packs) {
                // If pack_id exists in active packs, mark as ineligible
                pack.isEligible = !activePackIds.contains(pack.packId);
                pack.isCheckingEligibility = false;
              }
            });
          }
          return;
        }
      }

      // If API fails or returns error, default all packs to eligible
      if (mounted) {
        setState(() {
          for (var pack in _Packs) {
            pack.isEligible = true;
            pack.isCheckingEligibility = false;
          }
        });
      }
    } catch (e) {
      print('Error checking pack eligibility: $e');

      // Default to eligible if there's an error
      if (mounted) {
        setState(() {
          for (var pack in _Packs) {
            pack.isEligible = true;
            pack.isCheckingEligibility = false;
          }
        });
      }
    }
  }

  Future<void> _purchasePackApi(int packId) async {
    try {
      final response = await http.post(
        Uri.parse('$api/user/purchase_pack'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': responseList['user_data']['user_id'],
          'pack_id': packId,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          final packRechargeId = responseData['data']['pack_recharge_id'];
          print('Pack purchased successfully! Recharge ID: $packRechargeId');
          // You can store this ID or use it as needed
        } else {
          _showErrorSnackBar('Pack purchase recording failed');
        }
      } else {
        _showErrorSnackBar('Failed to record pack purchase');
      }
    } catch (e) {
      _showErrorSnackBar('Error recording pack purchase: ${e.toString()}');
    }
  }

  Future<void> _fetchUserBalance() async {
    setState(() => _isLoadingBalance = true);

    try {
      final response = await http.get(
        Uri.parse('$api/user_wallet_balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        if (userData['status'] == 'Success') {
          if (mounted) {
            setState(() {
              _userWalletBalance =
                  (userData['wallet_balance'] as num).toDouble();
              _isLoadingBalance = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoadingBalance = false);
        _showErrorSnackBar('Failed to fetch wallet balance');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
        _showErrorSnackBar('Network error: ${e.toString()}');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _showSuccessSnackBar('Payment successful!');
    _verifyPayment(response.paymentId!, response.orderId!, response.signature!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorSnackBar('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showInfoSnackBar('External wallet selected: ${response.walletName}');
  }

  Future<void> _verifyPayment(
      String paymentId, String orderId, String signature) async {
    try {
      // Determine which API endpoint to use based on whether a pack was selected
      String apiEndpoint;
      if (_selectedPackIndex != null) {
        // Pack purchase
        apiEndpoint =
            '$api/verify_payment/pack/${responseList['user_data']['user_id']}/${_totalAmount.toInt()}';
      } else {
        // Wallet recharge
        apiEndpoint =
            '$api/verify_payment/recharge/${responseList['user_data']['user_id']}/${_totalAmount.toInt()}';
      }

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'ref_promo': _isReferralApplied ? _referralController.text : '',
          'ref_promo_applied': _isReferralApplied,
        }),
      );

      if (response.statusCode == 200) {
        // Check if a pack was selected and call the purchase API
        if (_selectedPackIndex != null) {
          final selectedPack = _Packs[_selectedPackIndex!];
          await _purchasePackApi(selectedPack.packId);
        }

        await _fetchUserBalance();
        await _logFacebookEvent();
        _showSuccessSnackBar('Recharge successful!');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _navigateToHomeScreen();
      } else {
        _showErrorSnackBar(
            'Payment verification failed. Please contact support.');
      }
    } catch (e) {
      _showErrorSnackBar('Verification error: ${e.toString()}');
    }
  }

  Future<void> _logFacebookEvent() async {
    final now = DateTime.now();
    final facebookAppEvents = FacebookAppEvents();
    await facebookAppEvents.logEvent(
      name: 'wallet_recharge',
      parameters: {
        'time': "${now.hour}:${now.minute}:${now.second}",
        'date': "${now.year}-${now.month}-${now.day}",
        'amount': _totalAmount,
      },
    );
  }

  Future<void> _createPaymentOrder() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$api/create_payment_order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': _totalAmount, 'currency': 'INR'}),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() => _paymentResponse = responseData);
        _openRazorpayCheckout(responseData);
      } else {
        _showErrorSnackBar('Payment order creation failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _openRazorpayCheckout(Map orderData) {
    final userData = responseList['user_data'] ?? {};
    final options = {
      'key': razorpay,
      'amount': orderData['amount'],
      'name': 'Saamay Rashi',
      'order_id': orderData['payment_id'],
      'description': 'Astrology Recharge',
      'prefill': {
        'contact': userData['user_name'] ?? '',
        'email': userData['user_email'] ?? '',
        'name': userData['user_fullname'] ?? 'Customer',
      },
      'theme': {'color': '#89216B'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _updateAmount() {
    final inputText = _amountController.text;

    if (inputText.isEmpty) {
      setState(() {
        _selectedAmount = 0;
        _showPaymentDetails = false;
        _amountErrorMessage = '';
        _resetReferral();
      });
      return;
    }

    final amount = double.tryParse(inputText) ?? 0;

    setState(() {
      if (amount > 0 && amount < _minAmount) {
        _selectedAmount = 0;
        _showPaymentDetails = false;
        _amountErrorMessage = 'Minimum amount is ₹${_minAmount.toInt()}';
        _resetReferral();
      } else if (amount >= _minAmount) {
        _selectedAmount = amount;
        _showPaymentDetails = true;
        _amountErrorMessage = '';
        _resetReferral();
      } else {
        _selectedAmount = 0;
        _showPaymentDetails = false;
        _amountErrorMessage = '';
        _resetReferral();
      }
    });
  }

  void _selectPredefinedAmount(String amount) {
    setState(() {
      _selectedAmount = double.parse(amount);
      _amountController.text = amount;
      _showPaymentDetails = true;
      _amountErrorMessage = '';
      _selectedPackIndex = null; // Deselect pack when custom amount is chosen
      _resetReferral();
    });
  }

  void _selectPack(int index) {
    final pack = _Packs[index];

    setState(() {
      // Toggle expansion for any pack (eligible or not)
      pack.isExpanded = !pack.isExpanded;

      // Only handle selection logic if pack is eligible
      if (pack.isEligible) {
        if (_selectedPackIndex == index) {
          // Deselect if already selected
          _selectedPackIndex = null;
        } else {
          // Deselect previous pack if any
          if (_selectedPackIndex != null) {
            _Packs[_selectedPackIndex!].isExpanded = false;
          }

          _selectedPackIndex = index;
          _selectedAmount = pack.price;
          _amountController.text = pack.price.toInt().toString();
          _showPaymentDetails = true;
          _amountErrorMessage = '';
          _resetReferral();
        }
      }
      // If pack is not eligible, it will just expand/collapse without selection
      // No error message shown
    });
  }

  void _resetReferral() {
    _isReferralApplied = false;
    _referralMessage = '';
    _referredFlag = false;
    _referralController.clear();
  }

  Future<void> _proceedWithAmount() async {
    if (_selectedAmount < _minAmount) return;

    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _showPaymentDetails = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted && _scrollController.hasClients) {
      try {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _applyReferral() async {
    final referralCode = _referralController.text.trim();

    if (referralCode.isEmpty) {
      setState(() {
        _referralMessage = 'Please enter a referral code';
        _isReferralApplied = false;
      });
      return;
    }

    setState(() => _isValidatingReferral = true);

    try {
      final response = await http.post(
        Uri.parse('$api/referral_promo/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'promo_code': referralCode,
          'recharge_amount': _selectedAmount,
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          if (response.statusCode == 200 && data['status'] == 'success') {
            _isReferralApplied = true;
            _referralMessage = data['message'];
            _referredFlag = data['referred_flag'] == 1;
          } else {
            _referralMessage =
                data['message'] ?? 'Failed to apply referral code';
            _isReferralApplied = false;
          }
          _isValidatingReferral = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _referralMessage = 'Error validating referral code: $e';
          _isReferralApplied = false;
          _isValidatingReferral = false;
        });
      }
    }
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => const AstrologersPage(
                title: 'All',
              )),
      (route) => false,
    );
  }

  // Helper methods for SnackBars
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3)),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2)),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _navigateToHomeScreen();
          return false; // Prevents default back navigation
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: const CustomAppBar2(title: "Recharge"),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _fetchUserBalance,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16,
                        16 + MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CurrentBalanceCard(
                          balance: _userWalletBalance,
                          isLoading: _isLoadingBalance,
                          onRefresh: _fetchUserBalance,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Enter custom Amount (min ${_minAmount.toInt()})",
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _AmountInputSection(
                          controller: _amountController,
                          selectedAmount: _selectedAmount,
                          minAmount: _minAmount,
                          errorMessage: _amountErrorMessage,
                          onProceed: _proceedWithAmount,
                        ),
                        const SizedBox(height: 24),

                        // pack
                        _PacksList(
                          packs: _Packs,
                          selectedIndex: _selectedPackIndex,
                          onSelect: _selectPack,
                        ),
                        const SizedBox(height: 12),
                        _QuickAmountGrid(
                          amounts: _quickAmounts,
                          selectedAmount: _selectedAmount,
                          onSelect: _selectPredefinedAmount,
                        ),
                        const SizedBox(height: 8),
                        if (_showPaymentDetails && _selectedAmount > 0) ...[
                          _ReferralSection(
                            controller: _referralController,
                            isApplied: _isReferralApplied,
                            isValidating: _isValidatingReferral,
                            message: _referralMessage,
                            referredFlag: _referredFlag,
                            onApply: _applyReferral,
                            onRemove: _resetReferral,
                          ),
                          const SizedBox(height: 16),
                          _PaymentDetailsCard(
                            amount: _selectedAmount,
                            gstPercentage: _gstPercentage,
                            gstAmount: _gstAmount,
                            totalAmount: _totalAmount,
                          ),
                          const SizedBox(height: 24),
                          _CheckoutButton(
                            totalAmount: _totalAmount,
                            isLoading: _isLoading,
                            onPressed: () {
                              if (token == '') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginPage()));
                              } else {
                                _createPaymentOrder();
                              }
                            },
                          ),
                          SizedBox(height: 64),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ));
  }
}

// NEW: Subscription Packs List Widget
class _PacksList extends StatelessWidget {
  final List<Pack> packs;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _PacksList({
    required this.packs,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        packs.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _PackCard(
            pack: packs[index],
            isSelected: selectedIndex == index,
            onTap: () => onSelect(index),
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatefulWidget {
  final Pack pack;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackCard({
    required this.pack,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _wasExpanded = false; // Track previous expansion state

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _wasExpanded = widget.pack.isExpanded;
    if (_wasExpanded) {
      _controller.value = 1.0; // Start expanded if needed
    }
  }

  @override
  void didUpdateWidget(_PackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if expansion state changed
    if (widget.pack.isExpanded != _wasExpanded) {
      if (widget.pack.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      _wasExpanded = widget.pack.isExpanded;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, // Allow tap for all packs
      child: Opacity(
        opacity: widget.pack.isEligible ? 1.0 : 0.6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.grey.shade50
                : (widget.pack.isEligible
                    ? Colors.white
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.red.shade900
                  : (widget.pack.isEligible
                      ? Colors.grey.shade300
                      : Colors.red.shade200),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Radio Button
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.pack.isEligible
                                  ? (widget.isSelected
                                      ? Colors.red.shade900
                                      : Colors.grey.shade400)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            color: widget.isSelected
                                ? Colors.red.shade900
                                : Colors.transparent,
                          ),
                          child: widget.pack.isCheckingEligibility
                              ? Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey.shade400,
                                    ),
                                  ),
                                )
                              : (widget.isSelected
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                  : null),
                        ),
                        const SizedBox(width: 12),

                        // Pack Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pack.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.pack.isEligible
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.pack.period,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '₹${widget.pack.price.toInt()}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: widget.pack.isEligible
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '₹${widget.pack.originalPrice.toInt()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.pack.discount,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expandable Features Section
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const Text(
                            'Features:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.pack.features.map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Top-Left: Ineligible Badge
              if (!widget.pack.isEligible)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'ACTIVE PACK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Top-Right: Badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.button,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.pack.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extracted Widgets for better performance
class _CurrentBalanceCard extends StatelessWidget {
  final double balance;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _CurrentBalanceCard({
    required this.balance,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.button,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Balance',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 24,
                              backgroundColor: Colors.transparent,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : Text('₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
              ),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: onRefresh,
                  tooltip: 'Refresh Balance'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AmountInputSection extends StatelessWidget {
  final TextEditingController controller;
  final double selectedAmount;
  final double minAmount;
  final String errorMessage;
  final VoidCallback onProceed;

  const _AmountInputSection({
    required this.controller,
    required this.selectedAmount,
    required this.minAmount,
    required this.errorMessage,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                width: 2,
                color: errorMessage.isNotEmpty
                    ? Colors.red.shade300
                    : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                        hintText:
                            'Enter Amount in INR (min ${minAmount.toInt()})',
                        border: InputBorder.none),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ),
              if (selectedAmount >= minAmount)
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: AppColors.button,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: TextButton(
                    onPressed: onProceed,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: const Size(80, 40),
                    ),
                    child: const Text('Proceed',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
            ],
          ),
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 6),
                Text(errorMessage,
                    style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickAmountGrid extends StatelessWidget {
  final List<String> amounts;
  final double selectedAmount;
  final ValueChanged<String> onSelect;

  const _QuickAmountGrid({
    required this.amounts,
    required this.selectedAmount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        (amounts.length / 3).ceil(),
        (rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: List.generate(
              3,
              (colIndex) {
                final index = rowIndex * 3 + colIndex;
                if (index >= amounts.length) return const Spacer();
                final amount = amounts[index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: colIndex < 2 ? 8 : 0),
                    child: _AmountButton(
                        amount: amount,
                        isSelected: selectedAmount.toString() == amount,
                        onTap: () => onSelect(amount)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountButton extends StatelessWidget {
  final String amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmountButton(
      {required this.amount, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        ),
        child: Text('₹$amount',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black)),
      ),
    );
  }
}

class _ReferralSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isApplied;
  final bool isValidating;
  final String message;
  final bool referredFlag;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _ReferralSection({
    required this.controller,
    required this.isApplied,
    required this.isValidating,
    required this.message,
    required this.referredFlag,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apply Referral Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isApplied && !isValidating,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter referral code',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 45,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isApplied ? null : AppColors.button,
                    color: isApplied ? Colors.red.shade50 : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: !isApplied
                        ? [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: TextButton(
                    onPressed:
                        isValidating ? null : (isApplied ? onRemove : onApply),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: isValidating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    isApplied ? Colors.red : Colors.white)),
                          )
                        : Text(isApplied ? 'Remove' : 'Apply',
                            style: TextStyle(
                                color: isApplied ? Colors.red : Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: isApplied ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
          if (isApplied) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    referredFlag
                        ? 'Referral code applied successfully!'
                        : 'You\'ve used a referral code!',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentDetailsCard extends StatelessWidget {
  final double amount;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;

  const _PaymentDetailsCard({
    required this.amount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _PaymentDetailRow('Amount', '₹${amount.toStringAsFixed(2)}'),
          _PaymentDetailRow('GST (${gstPercentage.toStringAsFixed(0)}%)',
              '₹${gstAmount.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _PaymentDetailRow(
              'Total Amount', '₹${totalAmount.toStringAsFixed(2)}',
              isBold: true),
        ],
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PaymentDetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isBold ? 16 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isBold ? 16 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final double totalAmount;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CheckoutButton(
      {required this.totalAmount,
      required this.isLoading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.button,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text('Pay ₹${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
