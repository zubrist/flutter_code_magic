import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/KundliResult.dart';
import 'package:saamay/pages/config.dart';
import 'package:intl/intl.dart';

class KundliMatching extends StatefulWidget {
  @override
  _KundliMatchingState createState() => _KundliMatchingState();
}

class _KundliMatchingState extends State<KundliMatching> {
  final _formKey = GlobalKey<FormState>();

  // Form expansion states
  bool _isBoyFormExpanded = true;
  bool _isGirlFormExpanded = true;

  // Form controllers
  final TextEditingController _boyNameController = TextEditingController();
  final TextEditingController _boyDobController = TextEditingController();
  final TextEditingController _boyPlaceController = TextEditingController();

  final TextEditingController _girlNameController = TextEditingController();
  final TextEditingController _girlDobController = TextEditingController();
  final TextEditingController _girlPlaceController = TextEditingController();

  // Hours and minutes options for 24-hour format
  final List<String> _hours = List.generate(
    24,
    (index) => index.toString().padLeft(2, '0'),
  );
  final List<String> _minutes = List.generate(
    60,
    (index) => index.toString().padLeft(2, '0'),
  );

  // Selected values - Changed to nullable String? to allow for null initial values
  String? _boySelectedHour;
  String? _boySelectedMinute;
  String? _girlSelectedHour;
  String? _girlSelectedMinute;

  // Boy and Girl details
  Map<String, String> boyDetails = {
    'name': '',
    'day': '1',
    'month': '1',
    'year': '2000',
    'hour': '00',
    'minute': '00',
    'sec': '00',
    'place': '',
    'lat': '',
    'lon': '',
    'tzone': '',
  };

  Map<String, String> girlDetails = {
    'name': '',
    'day': '1',
    'month': '1',
    'year': '2000',
    'hour': '00',
    'minute': '00',
    'sec': '00',
    'place': '',
    'lat': '',
    'lon': '',
    'tzone': '',
  };

  // Place autocomplete
  List<Prediction> _boyPlaceSuggestions = [];
  List<Prediction> _girlPlaceSuggestions = [];
  Timer? _debounce;

  final FocusNode _boyPlaceFocusNode = FocusNode();
  final FocusNode _girlPlaceFocusNode = FocusNode();
  final LayerLink _boyLayerLink = LayerLink();
  final LayerLink _girlLayerLink = LayerLink();
  OverlayEntry? _boyOverlayEntry;
  OverlayEntry? _girlOverlayEntry;
  bool _isLoadingBoyPlaceSuggestions = false;
  bool _isLoadingGirlPlaceSuggestions = false;

  // Google Places API client
  late GoogleMapsPlaces places;

  // Gradient for the app
  final Gradient _customGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF89216B), Color(0xFFDA4453), // #AE0074
    ],
  );

  @override
  void initState() {
    super.initState();
    places = GoogleMapsPlaces(apiKey: gapi2);

    // Initialize controllers with default values
    _boyPlaceController.text = boyDetails['place']!;
    _girlPlaceController.text = girlDetails['place']!;

    // Set up place autocomplete listeners
    _boyPlaceController.addListener(
      () => _onPlaceInputChanged(_boyPlaceController, true),
    );
    _girlPlaceController.addListener(
      () => _onPlaceInputChanged(_girlPlaceController, false),
    );

    // Set up focus listeners
    _boyPlaceFocusNode.addListener(() {
      if (!_boyPlaceFocusNode.hasFocus) {
        Future.delayed(Duration.zero, () {
          _removeOverlay(true);
        });
      }
    });

    _girlPlaceFocusNode.addListener(() {
      if (!_girlPlaceFocusNode.hasFocus) {
        Future.delayed(Duration.zero, () {
          _removeOverlay(false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _boyNameController.dispose();
    _boyDobController.dispose();
    _boyPlaceController.dispose();
    _girlNameController.dispose();
    _girlDobController.dispose();
    _girlPlaceController.dispose();
    _boyPlaceFocusNode.dispose();
    _girlPlaceFocusNode.dispose();
    _removeOverlay(true);
    _removeOverlay(false);
    super.dispose();
  }

  // Debounce for place autocomplete
  Future<void> _onPlaceInputChanged(
    TextEditingController controller,
    bool isBoy,
  ) async {
    final query = controller.text;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length > 2) {
      setState(() {
        if (isBoy) {
          _isLoadingBoyPlaceSuggestions = true;
        } else {
          _isLoadingGirlPlaceSuggestions = true;
        }
      });

      _debounce = Timer(const Duration(milliseconds: 500), () async {
        // Only proceed if the text hasn't changed (user stopped typing)
        if (query == controller.text) {
          try {
            final response = await places.autocomplete(
              query,
              //types: ['(cities)'],
              //components: [Component(Component.country, 'in')],
            );

            if (response.status == 'OK' && response.predictions.isNotEmpty) {
              setState(() {
                if (isBoy) {
                  _boyPlaceSuggestions = response.predictions;
                  _isLoadingBoyPlaceSuggestions = false;
                } else {
                  _girlPlaceSuggestions = response.predictions;
                  _isLoadingGirlPlaceSuggestions = false;
                }
              });

              // Show the overlay if we have suggestions and focus
              if (isBoy &&
                  _boyPlaceFocusNode.hasFocus &&
                  _boyPlaceSuggestions.isNotEmpty) {
                _showSuggestionsOverlay(true);
              } else if (!isBoy &&
                  _girlPlaceFocusNode.hasFocus &&
                  _girlPlaceSuggestions.isNotEmpty) {
                _showSuggestionsOverlay(false);
              }
            } else {
              setState(() {
                if (isBoy) {
                  _boyPlaceSuggestions = [];
                  _isLoadingBoyPlaceSuggestions = false;
                } else {
                  _girlPlaceSuggestions = [];
                  _isLoadingGirlPlaceSuggestions = false;
                }
              });
              _removeOverlay(isBoy);
            }
          } catch (e) {
            print('Error getting place suggestions: $e');
            setState(() {
              if (isBoy) {
                _boyPlaceSuggestions = [];
                _isLoadingBoyPlaceSuggestions = false;
              } else {
                _girlPlaceSuggestions = [];
                _isLoadingGirlPlaceSuggestions = false;
              }
            });
            _removeOverlay(isBoy);
          }
        }
      });
    } else {
      setState(() {
        if (isBoy) {
          _boyPlaceSuggestions = [];
          _isLoadingBoyPlaceSuggestions = false;
        } else {
          _girlPlaceSuggestions = [];
          _isLoadingGirlPlaceSuggestions = false;
        }
      });
      _removeOverlay(isBoy);
    }
  }

  void _showSuggestionsOverlay(bool isBoy) {
    _removeOverlay(isBoy);

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final suggestions = isBoy ? _boyPlaceSuggestions : _girlPlaceSuggestions;
    final layerLink = isBoy ? _boyLayerLink : _girlLayerLink;
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, 55.0), // Adjust this offset as needed
          child: Material(
            elevation: 4.0,
            color: const Color(0xFFFCF7EF),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    title: Text(
                      suggestion.description ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    tileColor: const Color(0xFFFCF7EF),
                    onTap: () {
                      if (isBoy) {
                        _boyPlaceController.text = suggestion.description ?? '';
                        _getPlaceDetails(suggestion.placeId!, boyDetails, true);
                      } else {
                        _girlPlaceController.text =
                            suggestion.description ?? '';
                        _getPlaceDetails(
                          suggestion.placeId!,
                          girlDetails,
                          false,
                        );
                      }
                      _removeOverlay(isBoy);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (isBoy) {
      _boyOverlayEntry = overlayEntry;
    } else {
      _girlOverlayEntry = overlayEntry;
    }

    Overlay.of(context).insert(isBoy ? _boyOverlayEntry! : _girlOverlayEntry!);
  }

  void _removeOverlay(bool isBoy) {
    if (isBoy && _boyOverlayEntry != null) {
      try {
        _boyOverlayEntry?.remove();
      } catch (e) {
        print('Error removing boy overlay: $e');
      } finally {
        _boyOverlayEntry = null;
      }
    } else if (!isBoy && _girlOverlayEntry != null) {
      try {
        _girlOverlayEntry?.remove();
      } catch (e) {
        print('Error removing girl overlay: $e');
      } finally {
        _girlOverlayEntry = null;
      }
    }
  }

  // Get place details from Google Places API
  Future<void> _getPlaceDetails(
    String placeId,
    Map<String, String> details,
    bool isBoy,
  ) async {
    try {
      final response = await places.getDetailsByPlaceId(placeId);
      if (response.status == 'OK' && response.result.geometry != null) {
        final location = response.result.geometry!.location;

        setState(() {
          details['place'] = response.result.formattedAddress ?? '';
          details['lat'] = location.lat.toString();
          details['lon'] = location.lng.toString();

          if (isBoy) {
            _boyPlaceController.text = details['place']!;
            _boyPlaceSuggestions = [];
          } else {
            _girlPlaceController.text = details['place']!;
            _girlPlaceSuggestions = [];
          }
        });

        await _getTimezone(location.lat, location.lng, details);
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  Future<void> _getTimezone(
    double lat,
    double lng,
    Map<String, String> details,
  ) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/timezone/json?location=$lat,$lng&timestamp=$timestamp&key=$gapi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'OK') {
          // Calculate timezone offset in hours
          final rawOffset = jsonData['rawOffset'] as int;
          final dstOffset = jsonData['dstOffset'] as int;
          final offsetHours = (rawOffset + dstOffset) / 3600;

          setState(() {
            details['tzone'] = offsetHours.toString();
          });
        }
      }
    } catch (e) {
      print('Error getting timezone: $e');
    }
  }

  // ===== Form Building Methods =====

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.red[900]),
        prefixIcon: Icon(icon, color: Colors.red[900]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[900]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator ??
          (value) => (value == null || value.isEmpty)
              ? 'This field is required'
              : null,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required Map<String, String> details,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.red[900]),
        prefixIcon: Icon(Icons.calendar_today, color: Colors.red[900]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[900]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'Please select date of birth'
          : null,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.red[900]!,
                  surface: const Color(0xFFFCF7EF),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.text = DateFormat('dd/MM/yyyy').format(date);
          setState(() {
            details['day'] = date.day.toString();
            details['month'] = date.month.toString();
            details['year'] = date.year.toString();
          });
        }
      },
    );
  }

  Widget _buildPlaceField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required LayerLink layerLink,
  }) {
    return CompositedTransformTarget(
      link: layerLink,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.poppins(color: Colors.black),
        decoration: InputDecoration(
          labelText: 'Place of Birth',
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          floatingLabelStyle: GoogleFonts.poppins(color: Colors.red[900]),
          prefixIcon: Icon(Icons.location_on, color: Colors.red[900]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[900]!),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => (value == null || value.isEmpty)
            ? 'Please enter place of birth'
            : null,
      ),
    );
  }

  // Modified dropdown method to match the appearance of other input fields
  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: GoogleFonts.poppins(color: Colors.black),
      dropdownColor: const Color(0xFFFCF7EF),
      decoration: InputDecoration(
        // Always use labelText for consistent appearance with other fields
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.red[900]),
        prefixIcon: Icon(icon, color: Colors.red[900]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[900]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: GoogleFonts.poppins(color: Colors.black)),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down, color: Colors.red[900]),
      validator: (value) => value == null ? 'Please select $label' : null,
      // Remove hint since we always use labelText
      isExpanded: true, // Ensures dropdown text doesn't overflow
    );
  }

  Widget _buildPersonForm({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required Function(bool) onToggleExpanded,
    required TextEditingController nameController,
    required TextEditingController dobController,
    required TextEditingController placeController,
    required FocusNode placeFocusNode,
    required LayerLink layerLink,
    required String? selectedHour,
    required String? selectedMinute,
    required Function(String) onHourChanged,
    required Function(String) onMinuteChanged,
    required Function(String) onNameChanged,
    required Map<String, String> details,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle button
          InkWell(
            onTap: () => onToggleExpanded(!isExpanded),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _customGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isExpanded ? Radius.zero : Radius.circular(16),
                  bottomRight: isExpanded ? Radius.zero : Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        title,
                        style: GoogleFonts.lora(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // Collapsible form content
          AnimatedCrossFade(
            duration: Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    onChanged: onNameChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildDateField(controller: dobController, details: details),
                  SizedBox(height: 16),
                  _buildPlaceField(
                    controller: placeController,
                    focusNode: placeFocusNode,
                    layerLink: layerLink,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: selectedHour,
                          label: 'Hour',
                          icon: Icons.access_time,
                          items: _hours,
                          onChanged: (value) {
                            if (value != null) {
                              onHourChanged(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          value: selectedMinute,
                          label: 'Minute',
                          icon: Icons.access_time,
                          items: _minutes,
                          onChanged: (value) {
                            if (value != null) {
                              onMinuteChanged(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            secondChild: Container(height: 0),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (boyDetails['lat']!.isEmpty || girlDetails['lat']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select valid birth places',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    // Set default values for hour and minute if not selected
    if (_boySelectedHour == null) {
      boyDetails['hour'] = '00';
    }

    if (_boySelectedMinute == null) {
      boyDetails['minute'] = '00';
    }

    if (_girlSelectedHour == null) {
      girlDetails['hour'] = '00';
    }

    if (_girlSelectedMinute == null) {
      girlDetails['minute'] = '00';
    }

    final body = {
      "p1_full_name": boyDetails['name'],
      "p1_day": boyDetails['day'],
      "p1_month": boyDetails['month'],
      "p1_year": boyDetails['year'],
      "p1_hour": boyDetails['hour'],
      "p1_min": boyDetails['minute'],
      "p1_sec": boyDetails['sec'],
      "p1_gender": "male",
      "p1_place": boyDetails['place'],
      "p1_lat": boyDetails['lat'],
      "p1_lon": boyDetails['lon'],
      "p1_tzone": boyDetails['tzone'],
      "p2_full_name": girlDetails['name'],
      "p2_day": girlDetails['day'],
      "p2_month": girlDetails['month'],
      "p2_year": girlDetails['year'],
      "p2_hour": girlDetails['hour'],
      "p2_min": girlDetails['minute'],
      "p2_sec": girlDetails['sec'],
      "p2_gender": "female",
      "p2_place": girlDetails['place'],
      "p2_lat": girlDetails['lat'],
      "p2_lon": girlDetails['lon'],
      "p2_tzone": girlDetails['tzone'],
      "lan": "hi",
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KundliMatchingResult(matchData: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: Colors.red[900]!, // This will affect input label colors
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF7EF),
        appBar: AppBar(
          title: Text(
            "Kundli Matching",
            style: GoogleFonts.lora(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: _customGradient),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPersonForm(
                  title: "Boy's Details",
                  icon: Icons.male,
                  isExpanded: _isBoyFormExpanded,
                  onToggleExpanded: (expanded) =>
                      setState(() => _isBoyFormExpanded = expanded),
                  nameController: _boyNameController,
                  dobController: _boyDobController,
                  placeController: _boyPlaceController,
                  placeFocusNode: _boyPlaceFocusNode,
                  layerLink: _boyLayerLink,
                  selectedHour: _boySelectedHour,
                  selectedMinute: _boySelectedMinute,
                  onHourChanged: (value) => setState(() {
                    _boySelectedHour = value;
                    boyDetails['hour'] = value;
                  }),
                  onMinuteChanged: (value) => setState(() {
                    _boySelectedMinute = value;
                    boyDetails['minute'] = value;
                  }),
                  onNameChanged: (value) => setState(() {
                    boyDetails['name'] = value;
                  }),
                  details: boyDetails,
                ),
                _buildPersonForm(
                  title: "Girl's Details",
                  icon: Icons.female,
                  isExpanded: _isGirlFormExpanded,
                  onToggleExpanded: (expanded) =>
                      setState(() => _isGirlFormExpanded = expanded),
                  nameController: _girlNameController,
                  dobController: _girlDobController,
                  placeController: _girlPlaceController,
                  placeFocusNode: _girlPlaceFocusNode,
                  layerLink: _girlLayerLink,
                  selectedHour: _girlSelectedHour,
                  selectedMinute: _girlSelectedMinute,
                  onHourChanged: (value) => setState(() {
                    _girlSelectedHour = value;
                    girlDetails['hour'] = value;
                  }),
                  onMinuteChanged: (value) => setState(() {
                    _girlSelectedMinute = value;
                    girlDetails['minute'] = value;
                  }),
                  onNameChanged: (value) => setState(() {
                    girlDetails['name'] = value;
                  }),
                  details: girlDetails,
                ),
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _customGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Match Kundli',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
