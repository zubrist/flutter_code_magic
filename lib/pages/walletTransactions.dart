import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/login.dart';
import 'package:saamay/pages/recharge.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

// Custom exception classes for better error categorization
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, [this.statusCode]);
}

class DataParsingException implements Exception {
  final String message;
  DataParsingException(this.message);
}

class WalletPage extends StatefulWidget {
  final int initialTabIndex;
  const WalletPage({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  final String transactionsApiUrl = "$api/txns";
  final String ordersApiUrl = "$api/orders_for_user";
  final String userOwnApiUrl = "$api/user/own";
  List<dynamic> transactions = [];
  List<dynamic> orders = [];
  List<dynamic> packs = [];
  TabController? _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoading = true;
  bool _isTransactionsLoading = true;
  bool _isPacksLoading = true;
  bool _isBalanceLoading = true;
  double balance = 0;
  String? _lastError;
  int? userId;
  // Error handling utility methods
  void _showErrorSnackBar(String message, {bool isRetryable = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (isRetryable)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _retryAllOperations();
                },
                child: Text('Retry', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: isRetryable ? 6 : 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Exception _categorizeHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return AuthException('Your session has expired. Please login again.');
      case 403:
        return AuthException(
          'You don\'t have permission to perform this action.',
        );
      case 404:
        return ServerException('The requested resource was not found.', 404);
      case 429:
        return ServerException(
          'Too many requests. Please try again later.',
          429,
        );
      case 500:
        return ServerException('Server error. Please try again later.', 500);
      case 502:
      case 503:
      case 504:
        return ServerException(
          'Service temporarily unavailable. Please try again.',
          response.statusCode,
        );
      default:
        return ServerException(
          'Request failed with status ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  Exception _categorizeNetworkError(dynamic error) {
    if (error is SocketException) {
      return NetworkException(
        'No internet connection. Please check your network and try again.',
      );
    } else if (error is HttpException) {
      return NetworkException('Network error occurred. Please try again.');
    } else if (error is FormatException) {
      return DataParsingException('Invalid data received from server.');
    } else {
      return NetworkException(
        'Connection failed. Please check your internet connection.',
      );
    }
  }

  void _handleError(dynamic error, String operation, {bool showRetry = true}) {
    String message;
    bool isRetryable = true;

    if (error is AuthException) {
      message = error.message;
      isRetryable = false;
      // Auto redirect to login after showing error
      Future.delayed(Duration(seconds: 2), () => redirectToLogin(context));
    } else if (error is NetworkException) {
      message = error.message;
    } else if (error is ServerException) {
      message = error.message;
      isRetryable = error.statusCode != 404; // Don't retry 404s
    } else if (error is DataParsingException) {
      message = error.message;
    } else {
      message =
          'An unexpected error occurred during $operation. Please try again.';
    }

    setState(() {
      _lastError = message;
    });

    _showErrorSnackBar(message, isRetryable: showRetry && isRetryable);
  }

  void _retryAllOperations() {
    setState(() {
      _lastError = null;
      _isLoading = true;
      _isTransactionsLoading = true;
      _isBalanceLoading = true;
      _isPacksLoading = true;
    });

    fetchTransactions();
    fetchOrders();
    fetchBalance();
    fetchUserIdAndPacks();
  }

  Future<void> redirectToLogin(BuildContext context) async {
    if (!mounted) return;

    try {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      //print('Error navigating to login: $e');
    }
  }

  Future<void> fetchUserIdAndPacks() async {
    try {
      // First, get user_id from /user/own
      final userResponse = await http.get(
        Uri.parse(userOwnApiUrl),
        headers: {'Authorization': token},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () =>
        throw NetworkException('Request timed out. Please try again.'),
      );

      if (userResponse.statusCode == 200) {
        try {
          final userData = json.decode(userResponse.body);
          if (userData == null || userData['data'] == null) {
            throw DataParsingException('Invalid user data received.');
          }

          userId = userData['data']['user_id'];

          if (userId == null) {
            throw DataParsingException('User ID not found.');
          }

          // Now fetch packs using the user_id
          await fetchPacks(userId!);
        } catch (e) {
          throw DataParsingException('Failed to parse user data.');
        }
      } else {
        throw _categorizeHttpError(userResponse);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPacksLoading = false;
        });
      }

      dynamic categorizedError = e;
      if (e is! AuthException &&
          e is! NetworkException &&
          e is! ServerException &&
          e is! DataParsingException) {
        categorizedError = _categorizeNetworkError(e);
      }

      _handleError(categorizedError, 'fetching user data');
    }
  }

  // NEW: Fetch packs for the user
  Future<void> fetchPacks(int userId) async {
    try {

      final response = await http.get(
        Uri.parse("$api/user_packs/$userId"),
        headers: {'Authorization': token},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () =>
        throw NetworkException('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData == null || jsonData['data'] == null) {
            throw DataParsingException('Invalid packs data received.');
          }

          if (mounted) {
            setState(() {
              // Sort packs by start_dt descending (latest first)
              packs = (jsonData['data'] as List)..sort((a, b) {
                DateTime dateA = DateTime.parse(a['start_dt']);
                DateTime dateB = DateTime.parse(b['start_dt']);
                return dateB.compareTo(dateA); // Descending order
              });
              _isPacksLoading = false;
            });
          }
        } catch (e) {
          throw DataParsingException('Failed to parse packs data.');
        }
      } else if (response.statusCode == 404) {
        // 404 means no packs exist - not an error
        if (mounted) {
          setState(() {
            packs = [];
            _isPacksLoading = false;
          });
        }
      } else {
        throw _categorizeHttpError(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPacksLoading = false;
        });
      }

      dynamic categorizedError = e;
      if (e is! AuthException &&
          e is! NetworkException &&
          e is! ServerException &&
          e is! DataParsingException) {
        categorizedError = _categorizeNetworkError(e);
      }

      _handleError(categorizedError, 'fetching packs');
    }
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse(transactionsApiUrl),
          headers: {'Authorization': token}).timeout(
        Duration(seconds: 30),
        onTimeout: () =>
            throw NetworkException('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData == null || jsonData['data'] == null) {
            throw DataParsingException('Invalid response format received.');
          }

          if (mounted) {
            setState(() {
              transactions = jsonData['data'];
              _isTransactionsLoading = false;
            });
          }
        } catch (e) {
          throw DataParsingException('Failed to parse transaction data.');
        }
      } else if (response.statusCode == 404) {
        // 404 for transactions just means no transactions exist - not an error
        if (mounted) {
          setState(() {
            transactions = [];
            _isTransactionsLoading = false;
          });
        }
      } else {
        throw _categorizeHttpError(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTransactionsLoading = false;
        });
      }

      dynamic categorizedError = e;
      if (e is! AuthException &&
          e is! NetworkException &&
          e is! ServerException &&
          e is! DataParsingException) {
        categorizedError = _categorizeNetworkError(e);
      }

      _handleError(categorizedError, 'fetching transactions');
    }
  }

  Future<void> fetchBalance() async {
    try {
      final response = await http.get(
          Uri.parse("$api/user_wallet_balance"),
          headers: {'Authorization': token}
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () =>
        throw NetworkException('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);

          if (jsonData == null || jsonData is! Map<String, dynamic>) {
            throw DataParsingException('Invalid balance data received.');
          }

          // Check for success status
          if (jsonData['status'] != 'Success') {
            throw DataParsingException('Failed to retrieve balance data.');
          }

          final walletData = jsonData['wallet_balance'];
          if (walletData == null) {
            throw DataParsingException('Wallet data not found.');
          }

          if (mounted) {
            setState(() {
              balance = double.tryParse(walletData.toString()) ?? 0.0;
              _isBalanceLoading = false;
            });
          }
        } catch (e) {
          throw DataParsingException('Failed to parse balance data.');
        }
      } else {
        throw _categorizeHttpError(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBalanceLoading = false;
        });
      }

      dynamic categorizedError = e;
      if (e is! AuthException &&
          e is! NetworkException &&
          e is! ServerException &&
          e is! DataParsingException) {
        categorizedError = _categorizeNetworkError(e);
      }

      _handleError(categorizedError, 'fetching balance');
    }
  }

  Future<void> fetchOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http.get(Uri.parse(ordersApiUrl),
          headers: {'Authorization': token}).timeout(
        Duration(seconds: 30),
        onTimeout: () =>
            throw NetworkException('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData == null || jsonData['data'] == null) {
            throw DataParsingException('Invalid orders data received.');
          }

          if (mounted) {
            setState(() {
              orders = jsonData['data'];
              _isLoading = false;
            });
          }
        } catch (e) {
          throw DataParsingException('Failed to parse orders data.');
        }
      } else {
        throw _categorizeHttpError(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      dynamic categorizedError = e;
      if (e is! AuthException &&
          e is! NetworkException &&
          e is! ServerException &&
          e is! DataParsingException) {
        categorizedError = _categorizeNetworkError(e);
      }

      _handleError(categorizedError, 'fetching orders');

      // Only redirect to login for auth errors
      if (categorizedError is AuthException) {
        Future.delayed(Duration(seconds: 2), () => redirectToLogin(context));
      }
    }
  }

  Future<void> _openInvoiceUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _showErrorSnackBar('Invoice not available for this transaction.');
      return;
    }

    try {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw Exception('Failed to launch URL');
        }
      } else {
        throw Exception('Cannot launch this URL');
      }
    } catch (e) {
      _showErrorSnackBar('Unable to open invoice. Please try again later.');
      //print('Error opening invoice URL: $e');
    }
  }

  void _showFeedbackForm(dynamic order) {
    double rating = 0;
    final TextEditingController feedbackController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> submitFeedback() async {
              if (!formKey.currentState!.validate() || rating == 0) {
                _showErrorSnackBar(
                  rating == 0
                      ? 'Please provide a rating'
                      : 'Please provide feedback',
                );
                return;
              }

              setState(() {
                isSubmitting = true;
              });

              try {
                final response = await http
                    .post(
                      Uri.parse('$api/submit_feedback'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': token,
                      },
                      body: json.encode({
                        "order_id": order['id'] ?? order['order_id'] ?? 0,
                        "rating": rating.toInt(),
                        "feedback": feedbackController.text.trim(),
                        "service_id": order['service_id'] ?? 1,
                      }),
                    )
                    .timeout(
                      Duration(seconds: 30),
                      onTimeout: () => throw NetworkException(
                        'Request timed out. Please try again.',
                      ),
                    );

                if (response.statusCode == 201) {
                  try {
                    final responseData = json.decode(response.body);
                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccessSnackBar(
                        responseData['Message'] ??
                            'Feedback submitted successfully',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Feedback submitted successfully');
                    }
                  }
                } else {
                  throw _categorizeHttpError(response);
                }
              } catch (e) {
                dynamic categorizedError = e;
                if (e is! AuthException &&
                    e is! NetworkException &&
                    e is! ServerException) {
                  categorizedError = _categorizeNetworkError(e);
                }
                _handleError(
                  categorizedError,
                  'submitting feedback',
                  showRetry: false,
                );
              } finally {
                if (mounted) {
                  setState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Write Feedback',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Order details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['order_id'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            order['display_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 30),
                    // Rating stars
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate your experience',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: RatingBar.builder(
                              initialRating: 0,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemSize: 40,
                              itemPadding: EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              itemBuilder: (context, _) =>
                                  Icon(Icons.star, color: Colors.amber),
                              onRatingUpdate: (newRating) {
                                setState(() {
                                  rating = newRating;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Feedback text field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: feedbackController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Share your feedback...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppColors.text,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide some feedback';
                            }
                            if (value.trim().length < 10) {
                              return 'Feedback must be at least 10 characters long';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Spacer(),
                    // Submit button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.text,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Submit Feedback',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetails(dynamic order) {
    // Get status and determine color
    String statusText = order['session_status'] ?? 'Pending';
    Color statusColor = Colors.grey;

    if (statusText == 'Completed' || statusText == 'Delivered') {
      statusColor = const Color.fromARGB(255, 0, 131, 35);
    } else if (statusText == 'Scheduled') {
      statusColor = const Color.fromARGB(255, 222, 167, 0);
    }

    // Function to cancel an order
    Future<void> cancelOrder() async {
      try {
        // Show confirmation dialog first
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Cancel Order'),
            content: Text('Are you sure you want to cancel this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // Show loading indicator
        _showLoadingDialog('Cancelling order...');

        final orderId = order['order_id'];
        if (orderId == null) {
          throw DataParsingException('Order ID not found.');
        }

        final response = await http.delete(
          Uri.parse('$api/ordercancel/$orderId'),
          headers: {'Authorization': token},
        ).timeout(
          Duration(seconds: 30),
          onTimeout: () => throw NetworkException(
            'Request timed out. Please try again.',
          ),
        );

        _hideLoadingDialog();

        if (response.statusCode == 200) {
          try {
            final responseData = json.decode(response.body);

            if (mounted) {
              Navigator.pop(context); // Close order details modal
              fetchOrders(); // Refresh orders
              _showSuccessSnackBar('Order cancelled successfully');
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              fetchOrders();
              _showSuccessSnackBar('Order cancelled successfully');
            }
          }
        } else {
          throw _categorizeHttpError(response);
        }
      } catch (e) {
        _hideLoadingDialog();

        dynamic categorizedError = e;
        if (e is! AuthException &&
            e is! NetworkException &&
            e is! ServerException &&
            e is! DataParsingException) {
          categorizedError = _categorizeNetworkError(e);
        }

        _handleError(categorizedError, 'cancelling order', showRetry: false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),
              // Header card with order details title and status
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Main card with order information
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          context,
                          'Order ID',
                          '#${order['order_id'] ?? 'N/A'}',
                          Icons.receipt_outlined,
                        ),
                        SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Customer',
                          order['display_name'] ?? 'Unknown',
                          Icons.person_outline,
                        ),
                        SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Service Category',
                          order['con_category'] ?? 'Unknown',
                          Icons.category_outlined,
                        ),
                        SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Start Time',
                          _formatDateTimeFromAPI(order['start_time'] ?? ''),
                          Icons.access_time,
                        ),
                        SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'End Time',
                          _formatDateTimeFromAPI(order['end_time'] ?? ''),
                          Icons.timer_outlined,
                        ),
                        if (order['feedback'] != null &&
                            order['feedback'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            'Feedback',
                            order['feedback'].toString(),
                            Icons.feedback_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    if (statusText == 'Scheduled')
                      OutlinedButton(
                        onPressed: cancelOrder,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          minimumSize: Size(double.infinity, 50),
                          side: BorderSide(color: AppColors.text, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel Order',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (statusText == 'Completed' || statusText == 'Delivered')
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.button,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close details sheet
                            _showFeedbackForm(order); // Open feedback form
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            minimumSize: Size(double.infinity, 50),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Write Feedback',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget to build info card items
  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.text, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for formatting date and time like in the screenshot
  String _formatDateTimeFromAPI(String dateString) {
    try {
      if (dateString.isEmpty) return 'Not available';
      DateTime dateTime = DateTime.parse(dateString);
      return '${DateFormat('d MMM yyyy').format(dateTime)}, ${DateFormat('h:mm a').format(dateTime)}';
    } catch (e) {
      //print('Error formatting date: $dateString, Error: $e');
      return 'Not available';
    }
  }

  // Filter orders based on search query
  List<dynamic> getFilteredOrders() {
    if (_searchQuery.isEmpty) {
      return orders;
    }

    try {
      return orders.where((order) {
        final name = order['display_name']?.toString().toLowerCase() ?? '';
        final category = order['con_category']?.toString().toLowerCase() ?? '';
        final orderId = order['order_id']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            category.contains(query) ||
            orderId.contains(query);
      }).toList();
    } catch (e) {
      //print('Error filtering orders: $e');
      return orders; // Return unfiltered list if filtering fails
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: widget.initialTabIndex,
      );

      // Initialize data fetching
      fetchTransactions();
      fetchOrders();
      fetchBalance();
      fetchUserIdAndPacks();

      // Set up search listener with error handling
      _searchController.addListener(() {
        try {
          if (mounted) {
            setState(() {
              _searchQuery = _searchController.text;
            });
          }
        } catch (e) {
          //print('Error updating search query: $e');
        }
      });
    } catch (e) {
      //print('Error in initState: $e');
      _handleError(e, 'initializing page', showRetry: false);
    }
  }

  @override
  void dispose() {
    try {
      _tabController?.dispose();
      _searchController.dispose();
    } catch (e) {
      //print('Error in dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Transaction"),
      body: Column(
        children: [
          // Balance Container with gradient background
          Container(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    _isBalanceLoading
                        ? SizedBox(
                      height: 32,
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Color(0xFFD81B60),
                        size: 20,
                      ),
                    )
                        : Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RechargePage()),
                      );
                    } catch (e) {
                      _showErrorSnackBar(
                        'Unable to open recharge page. Please try again.',
                      );
                    }
                  },
                  child: GradientText(
                    'Recharge',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message banner
          if (_lastError != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastError!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: _retryAllOperations,
                    child: Text(
                      'Retry',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            ),

          // Tab Bar - UPDATED with 3 tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.text,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.text,
            tabs: [
              Tab(text: 'Wallet'),
              Tab(text: 'Packs'),
              Tab(text: 'Orders'),
            ],
          ),

          // Tab Content - UPDATED with 3 tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _walletTab(),
                _packsTab(), // NEW TAB VIEW
                _ordersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packsTab() {
    if (_isPacksLoading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Color(0xFFD81B60),
          size: 50,
        ),
      );
    }

    if (packs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No packs found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Your purchased packs will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await fetchUserIdAndPacks();
      },
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          try {
            var pack = packs[index];
            return _packItem(pack);
          } catch (e) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Error loading pack'),
                subtitle: Text('Unable to display this pack'),
                leading: Icon(Icons.error_outline, color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }

  // NEW: Pack item widget
  Widget _packItem(dynamic pack) {
    try {
      final packDetails = pack['pack_details'];
      final packName = packDetails['pack_name'] ?? 'Unknown Pack';
      final packDesc = packDetails['pack_desc'] ?? '';
      final packValue = packDetails['pack_value'] ?? 0.0;
      final packMinutes = pack['pack_minutes'] ?? 0;
      final usedMinutes = pack['used_minutes'] ?? 0;
      final remainingMinutes = pack['remaining_minutes'] ?? 0;
      final isActive = pack['is_active'] ?? false;

      // Format dates
      String startDate = 'N/A';
      String endDate = 'N/A';

      try {
        if (pack['start_dt'] != null) {
          DateTime startDt = DateTime.parse(pack['start_dt']);
          startDate = DateFormat('dd MMM yyyy').format(startDt);
        }
        if (pack['end_dt'] != null) {
          DateTime endDt = DateTime.parse(pack['end_dt']);
          endDate = DateFormat('dd MMM yyyy').format(endDt);
        }
      } catch (e) {
        //print('Error formatting pack dates: $e');
      }

      // Calculate progress
      double progress = packMinutes > 0 ? usedMinutes / packMinutes : 0.0;

      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? AppColors.text.withOpacity(0.3) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RechargePage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pack name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        packName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Expired',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Pack value
                Text(
                  '₹${packValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),

                SizedBox(height: 12),

                // Minutes info
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Total: ${packMinutes} mins',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Used: ${usedMinutes} mins',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Remaining minutes with progress bar
                Row(
                  children: [
                    Icon(Icons.timelapse, size: 16, color: AppColors.text),
                    SizedBox(width: 4),
                    Text(
                      'Remaining: ${remainingMinutes} mins',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? AppColors.text : Colors.grey,
                    ),
                    minHeight: 6,
                  ),
                ),

                SizedBox(height: 12),

                // Validity period
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            startDate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            endDate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.black87 : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pack description (if available)
                if (packDesc.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'Details:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    packDesc,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      //print('Error building pack item: $e');
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text('Error loading pack'),
          subtitle: Text('Unable to display this pack'),
          leading: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }
  }

  Widget _walletTab() {
    if (_isTransactionsLoading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Color(0xFFD81B60),
          size: 50,
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await fetchTransactions();
        await fetchBalance();
      },
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          try {
            var transaction = transactions[index];
            return _transactionItem(
              transaction['txn_desc'] ?? 'Unknown Transaction',
              transaction['txn_type'] == 'CR'
                  ? '+ ₹${transaction['amount'] ?? '0'}'
                  : '- ₹${transaction['amount'] ?? '0'}',
              _formatDate(transaction['txn_date'] ?? ''),
              transaction['txn_type'] == 'CR' ? Colors.green : Colors.red,
              transaction['invoice_url'],
            );
          } catch (e) {
            //print('Error building transaction item at index $index: $e');
            return ListTile(
              title: Text('Error loading transaction'),
              subtitle: Text('Unable to display this transaction'),
              leading: Icon(Icons.error_outline, color: Colors.red),
            );
          }
        },
      ),
    );
  }

  Widget _ordersTab() {
    // Get orders matching search, then filter to only completed
    final filteredOrders = getFilteredOrders()
        .where(
          (order) =>
              (order['session_status']?.toString().toLowerCase() ?? '') ==
              'completed',
        )
        .toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your order here',
              prefixIcon: Icon(
                Icons.search,
                color: Color.fromRGBO(107, 85, 5, 1),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color.fromRGBO(199, 198, 194, 1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color.fromRGBO(199, 198, 194, 1)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Color.fromRGBO(255, 254, 249, 1),
            ),
            onChanged: (value) {
              try {
                setState(() {
                  _searchQuery = value;
                });
              } catch (e) {
                //print('Error updating search: $e');
              }
            },
          ),
        ),

        // Orders List
        Expanded(
          child: _isLoading
              ? Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Color(0xFFD81B60),
                    size: 50,
                  ),
                )
              : filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            orders.isEmpty
                                ? 'No orders found'
                                : 'No completed orders',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            orders.isEmpty
                                ? 'Your orders will appear here'
                                : 'Try adjusting your search terms',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                          if (orders.isNotEmpty) ...[
                            SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: Text('Clear Search'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchOrders,
                      child: ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          try {
                            var order = filteredOrders[index];
                            return _orderItem(
                                order, filteredOrders.length - index);
                          } catch (e) {
                            //print('Error building order item at index $index: $e');
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text('Error loading order'),
                                subtitle: Text('Unable to display this order'),
                                leading: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _orderItem(dynamic order, int displayNumber) {
    try {
      // Convert status to display format
      String statusText = order['session_status'] ?? 'Pending';
      Color statusColor = Colors.grey;

      if (statusText == 'Completed' || statusText == 'Delivered') {
        statusColor = const Color.fromARGB(255, 0, 131, 35);
      } else if (statusText == 'Scheduled') {
        statusColor = const Color.fromARGB(255, 222, 167, 0);
      }

      // Extract display name and category with null safety
      String name = order['display_name'] ?? 'Unknown';
      String category = order['con_category'] ?? '';
      String serviceCategory = "";

      // Different styling for puja vs astrology
      if (category.toLowerCase().contains("puja")) {
        serviceCategory = "Dosh Shanti Puja";
      } else {
        serviceCategory = "Astrology Discussion";
      }

      // Format the date properly
      String formattedDate = order['start_time'] != null
          ? _formatDateFromAPI(order['start_time'])
          : 'Date not available';

      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Id',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '#${order['order_id'] ?? displayNumber}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(254, 244, 239, 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  serviceCategory,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Order placed at $formattedDate',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      try {
                        _showOrderDetails(order);
                      } catch (e) {
                        _showErrorSnackBar(
                          'Unable to show order details. Please try again.',
                        );
                        //print('Error showing order details: $e');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Feedback',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size(0, 28),
                      side: BorderSide(color: AppColors.text, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      //print('Error building order item: $e');
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text('Error loading order'),
          subtitle: Text('Unable to display this order'),
          leading: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }
  }

  Widget _transactionItem(
    String title,
    String amount,
    String date,
    Color amountColor,
    String? invoiceUrl,
  ) {
    try {
      return InkWell(
        onTap: () => _openInvoiceUrl(invoiceUrl),
        child: ListTile(
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date),
              if (invoiceUrl != null && invoiceUrl.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.receipt_outlined, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'View Invoice',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          trailing: Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      //print('Error building transaction item: $e');
      return ListTile(
        title: Text('Error loading transaction'),
        subtitle: Text('Unable to display transaction details'),
        leading: Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return 'Date not available';
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      //print('Error formatting date: $dateString, Error: $e');
      return 'Date not available';
    }
  }

  String _formatDateFromAPI(String dateString) {
    try {
      if (dateString.isEmpty) return 'Invalid date';
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      //print('Error formatting API date: $dateString, Error: $e');
      return 'Invalid date';
    }
  }
}
