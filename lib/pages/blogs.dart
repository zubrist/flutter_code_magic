import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this dependency

// Custom widget for better image handling with caching
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    Key? key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildLoadingWidget(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      httpHeaders: {'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)'},
      // Additional caching options
      cacheKey: imageUrl,
      // Remove memory cache size limits to preserve quality
      // memCacheWidth and memCacheHeight can reduce quality
      maxWidthDiskCache: 2000, // Increased for better quality
      maxHeightDiskCache: 2000, // Increased for better quality
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      ),
    );
  }
}

// Improved HTML parsing method
// REPLACE your _parseHtml function with this version that preserves spaces
String _parseHtml(dynamic input) {
  if (input is! String) {
    return '';
  }

  try {
    final document = html_parser.parse(input);
    final buffer = StringBuffer();

    void _processNode(
      dom.Node node, {
      bool insideStrong = false,
      bool insideItalic = false,
      bool insideUnderline = false,
    }) {
      if (node is dom.Text) {
        String text = node.text;
        // Don't trim here - preserve spaces
        if (text.isNotEmpty) {
          // Apply formatting based on parent tags
          if (insideStrong && insideItalic && insideUnderline) {
            buffer.write('<b><i><u>$text</u></i></b>');
          } else if (insideStrong && insideItalic) {
            buffer.write('<b><i>$text</i></b>');
          } else if (insideStrong && insideUnderline) {
            buffer.write('<b><u>$text</u></b>');
          } else if (insideItalic && insideUnderline) {
            buffer.write('<i><u>$text</u></i>');
          } else if (insideStrong) {
            buffer.write('<b>$text</b>');
          } else if (insideItalic) {
            buffer.write('<i>$text</i>');
          } else if (insideUnderline) {
            buffer.write('<u>$text</u>');
          } else {
            buffer.write(text);
          }
        }
      } else if (node is dom.Element) {
        String tag = node.localName?.toLowerCase() ?? '';

        switch (tag) {
          case 'p':
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('\n\n');
            break;

          case 'br':
            buffer.write('\n');
            break;

          case 'h1':
            buffer.write('<h1>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</h1>\n\n');
            break;

          case 'h2':
            buffer.write('<h2>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</h2>\n\n');
            break;

          case 'h3':
            buffer.write('<h3>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</h3>\n\n');
            break;

          case 'h4':
            buffer.write('<h4>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</h4>\n\n');
            break;

          case 'h5':
            buffer.write('<h5>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</h5>\n\n');
            break;

          case 'h6':
            buffer.write('<h6>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</h6>\n\n');
            break;

          case 'strong':
          case 'b':
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: true,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            break;

          case 'em':
          case 'i':
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: true,
                insideUnderline: insideUnderline,
              );
            }
            break;

          case 'u':
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: true,
              );
            }
            break;

          case 'ul':
            buffer.write('<ul>\n');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</ul>\n');
            break;

          case 'ol':
            buffer.write('<ol>\n');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</ol>\n');
            break;

          case 'li':
            buffer.write('<li>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</li>\n');
            break;

          case 'blockquote':
            buffer.write('<quote>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</quote>\n\n');
            break;

          case 'a':
            String href = node.attributes['href'] ?? '';
            buffer.write('<link href="$href">');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</link>');
            break;

          case 'code':
            buffer.write('<code>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</code>');
            break;

          case 'pre':
            buffer.write('<pre>');
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            buffer.write('</pre>\n\n');
            break;

          case 'span':
          case 'div':
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            break;

          default:
            for (var child in node.nodes) {
              _processNode(
                child,
                insideStrong: insideStrong,
                insideItalic: insideItalic,
                insideUnderline: insideUnderline,
              );
            }
            break;
        }
      }
    }

    for (var node in document.body?.nodes ?? []) {
      _processNode(node);
    }

    // Only trim the final result, not individual text nodes
    String result = buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Trim only leading and trailing whitespace, preserve internal spaces
    return result.trim();
  } catch (e) {
    //print('Error parsing HTML: $e');
    return input;
  }
}

// Updated Blog class with the fixed HTML parser
class Blog {
  final int blogId;
  final String writerName;
  final String summary;
  final String text;
  final String area;
  final String aboutWriter;
  final String? imageUrl;
  final int likeCount;

  Blog({
    required this.blogId,
    required this.writerName,
    required this.summary,
    required this.text,
    required this.area,
    required this.aboutWriter,
    required this.imageUrl,
    required this.likeCount,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      blogId: json['blog_id'],
      writerName: json['blog_writer_name'],
      summary: json['blog_summary'],
      text: _parseHtml(json['blog_text']),
      area: json['area_of_blog'],
      aboutWriter: json['about_writer'],
      imageUrl: json['blog_image_url'] as String?,
      likeCount: json['like_count'] ?? 0,
    );
  }
}

// Updated method for displaying formatted blog content in BlogDetailPage
Widget _buildFormattedBlogContent(String text) {
  final lines = text.split('\n');
  List<Widget> contentWidgets = [];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      contentWidgets.add(const SizedBox(height: 8));
      continue;
    }

    if (line.startsWith('<h1>') && line.endsWith('</h1>')) {
      String headerText = line.substring(4, line.length - 5);
      contentWidgets.add(_buildSimpleHeader(headerText, 1));
    } else if (line.startsWith('<h2>') && line.endsWith('</h2>')) {
      String headerText = line.substring(4, line.length - 5);
      contentWidgets.add(_buildSimpleHeader(headerText, 2));
    } else if (line.startsWith('<h3>') && line.endsWith('</h3>')) {
      String headerText = line.substring(4, line.length - 5);
      contentWidgets.add(_buildSimpleHeader(headerText, 3));
    } else if (line.startsWith('<h4>') && line.endsWith('</h4>')) {
      String headerText = line.substring(4, line.length - 5);
      contentWidgets.add(_buildSimpleHeader(headerText, 4));
    } else if (line.startsWith('<h5>') && line.endsWith('</h5>')) {
      String headerText = line.substring(4, line.length - 5);
      contentWidgets.add(_buildSimpleHeader(headerText, 5));
    } else if (line.startsWith('<h6>') && line.endsWith('</h6>')) {
      String headerText = line.substring(4, line.length - 5);
      contentWidgets.add(_buildSimpleHeader(headerText, 6));
    } else if (line.startsWith('<ul>')) {
      List<String> listItems = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('</ul>')) {
        String listLine = lines[i].trim();
        if (listLine.startsWith('<li>') && listLine.endsWith('</li>')) {
          listItems.add(listLine.substring(4, listLine.length - 5));
        }
        i++;
      }
      contentWidgets.add(_buildUnorderedList(listItems));
      contentWidgets.add(const SizedBox(height: 16));
    } else if (line.startsWith('<ol>')) {
      List<String> listItems = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('</ol>')) {
        String listLine = lines[i].trim();
        if (listLine.startsWith('<li>') && listLine.endsWith('</li>')) {
          listItems.add(listLine.substring(4, listLine.length - 5));
        }
        i++;
      }
      contentWidgets.add(_buildOrderedList(listItems));
      contentWidgets.add(const SizedBox(height: 16));
    } else if (line.startsWith('<quote>') && line.endsWith('</quote>')) {
      String quoteText = line.substring(7, line.length - 8);
      contentWidgets.add(_buildBlockquote(quoteText));
      contentWidgets.add(const SizedBox(height: 16));
    } else if (line.startsWith('<pre>') && line.endsWith('</pre>')) {
      String preText = line.substring(5, line.length - 6);
      contentWidgets.add(_buildPreformattedText(preText));
      contentWidgets.add(const SizedBox(height: 16));
    } else {
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildEnhancedRichText(line),
        ),
      );
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: contentWidgets,
  );
}

// Updated header function with Lora font using Google Fonts
Widget _buildSimpleHeader(String text, int level) {
  double fontSize = 24 - (level * 2);
  if (fontSize < 14) fontSize = 14;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      text,
      style: GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    ),
  );
}

// Improved method for handling rich text with bold formatting - Updated with Poppins using Google Fonts
Widget _buildEnhancedRichText(String text, {TextStyle? baseStyle}) {
  final defaultStyle = baseStyle ??
      GoogleFonts.poppins(fontSize: 15, height: 1.6, color: Colors.black87);

  List<TextSpan> spans = [];

  // Define regex patterns for different formatting in order of complexity
  final patterns = [
    {
      'regex': RegExp(r'<b><i><u>(.*?)</u></i></b>'),
      'type': 'bold_italic_underline',
    },
    {'regex': RegExp(r'<b><i>(.*?)</i></b>'), 'type': 'bold_italic'},
    {'regex': RegExp(r'<b><u>(.*?)</u></b>'), 'type': 'bold_underline'},
    {'regex': RegExp(r'<i><u>(.*?)</u></i>'), 'type': 'italic_underline'},
    {'regex': RegExp(r'<b>(.*?)</b>'), 'type': 'bold'},
    {'regex': RegExp(r'<i>(.*?)</i>'), 'type': 'italic'},
    {'regex': RegExp(r'<u>(.*?)</u>'), 'type': 'underline'},
    {'regex': RegExp(r'<code>(.*?)</code>'), 'type': 'code'},
    {'regex': RegExp(r'<link href="([^"]*)">(.*?)</link>'), 'type': 'link'},
  ];

  int lastEnd = 0;

  // Find all matches for all patterns
  List<Map<String, dynamic>> allMatches = [];

  for (var pattern in patterns) {
    RegExp regex = pattern['regex'] as RegExp;
    String type = pattern['type'] as String;

    for (var match in regex.allMatches(text)) {
      allMatches.add({
        'start': match.start,
        'end': match.end,
        'match': match,
        'type': type,
      });
    }
  }

  // Sort matches by start position
  allMatches.sort((a, b) => a['start'].compareTo(b['start']));

  // Remove overlapping matches (keep the first one)
  List<Map<String, dynamic>> nonOverlappingMatches = [];
  int lastEndPos = 0;

  for (var matchData in allMatches) {
    RegExpMatch match = matchData['match'];
    if (match.start >= lastEndPos) {
      nonOverlappingMatches.add(matchData);
      lastEndPos = match.end;
    }
  }

  // Process non-overlapping matches
  lastEnd = 0;
  for (var matchData in nonOverlappingMatches) {
    RegExpMatch match = matchData['match'];
    String type = matchData['type'];

    // Add text before the match
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ),
      );
    }

    // Add formatted text based on type
    TextStyle formattedStyle = defaultStyle;
    String displayText = '';

    switch (type) {
      case 'bold_italic_underline':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.underline,
        );
        break;
      case 'bold_italic':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
        break;
      case 'bold_underline':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        );
        break;
      case 'italic_underline':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.underline,
        );
        break;
      case 'bold':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(fontWeight: FontWeight.bold);
        break;
      case 'italic':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(fontStyle: FontStyle.italic);
        break;
      case 'underline':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(
          decoration: TextDecoration.underline,
        );
        break;
      case 'code':
        displayText = match.group(1) ?? '';
        formattedStyle = defaultStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey[200],
          fontSize: defaultStyle.fontSize! - 1,
        );
        break;
      case 'link':
        displayText = match.group(2) ?? '';
        formattedStyle = defaultStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
        break;
    }

    spans.add(TextSpan(text: displayText, style: formattedStyle));
    lastEnd = match.end;
  }

  // Add any remaining text
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
  }

  // If no formatting was found, just use the entire text
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: defaultStyle));
  }

  return RichText(text: TextSpan(children: spans));
}

Widget _buildUnorderedList(List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: _buildEnhancedRichText(item)),
              ],
            ),
          ),
        )
        .toList(),
  );
}

Widget _buildOrderedList(List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}. ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: _buildEnhancedRichText(entry.value)),
              ],
            ),
          ),
        )
        .toList(),
  );
}

Widget _buildBlockquote(String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      border: Border(left: BorderSide(color: Colors.grey[400]!, width: 4)),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
    ),
    child: _buildEnhancedRichText(
      text,
      baseStyle: GoogleFonts.poppins(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        color: Colors.black87,
        height: 1.6,
      ),
    ),
  );
}

Widget _buildPreformattedText(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Colors.black87,
        height: 1.4,
      ),
    ),
  );
}

class SaamayBlogsPage extends StatefulWidget {
  const SaamayBlogsPage({super.key});

  @override
  State<SaamayBlogsPage> createState() => _SaamayBlogsPageState();
}

class _SaamayBlogsPageState extends State<SaamayBlogsPage> {
  late Future<List<Blog>> futureBlogs;
  final String apiUrl = '$api/blogs';

  @override
  void initState() {
    super.initState();
    futureBlogs = fetchBlogs();
  }

  Future<List<Blog>> fetchBlogs() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // Parse the response to get the wrapper object
      Map<String, dynamic> responseData = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      // Extract the 'data' array from the response
      List<dynamic> blogsJson = responseData['data'];

      return blogsJson.map((json) => Blog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load blogs.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromARGB(
                      255,
                      255,
                      250,
                      236,
                    ), // Starting color (your original beige)
                    Color.fromARGB(
                      255,
                      254,
                      233,
                      170,
                    ), // Middle color (example: gold)
                    Color.fromARGB(
                      255,
                      255,
                      250,
                      236,
                    ), // End color (example: orange)
                  ],
                ),
              ),
              child: Text(
                'SAAMAY BLOGS',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Blog Posts List
            Expanded(
              child: FutureBuilder<List<Blog>>(
                future: futureBlogs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No blogs available',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildBlogCard(snapshot.data![index]),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated getPreviewText function to strip HTML tags
  String getPreviewText(String text) {
    // First, remove all HTML tags
    String plainText = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Return first sentence or first 100 characters
    if (plainText.isEmpty) return '';

    int firstPeriod = plainText.indexOf('.');
    if (firstPeriod != -1 && firstPeriod < 100) {
      return plainText.substring(0, firstPeriod + 1);
    } else {
      return plainText.length > 100
          ? plainText.substring(0, 100) + '...'
          : plainText;
    }
  }

  Widget _buildBlogCard(Blog blog) {
    final imageUrl = blog.imageUrl;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogDetailPage(blog: blog)),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Tag - NOW WITH CACHING
            Stack(
              children: [
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedImageWidget(
                        imageUrl: imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        errorWidget: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.iconBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      blog.area.capitalize(),
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Title - Using Lora font for blog titles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                blog.summary,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDA4453), // CHANGED: New color
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Preview Text - HTML tags now properly stripped, using Poppins
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                getPreviewText(blog.text),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Author, Like count, and Read button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/pen.png',
                    width: 16,
                    height: 16,
                    color: AppColors.accent,
                  ),
                  // const SizedBox(width: 4),
                  Text(
                    blog.writerName,
                    style: GoogleFonts.poppins(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        blog.likeCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailPage(blog: blog),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Read now',
                            style: GoogleFonts.poppins(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogDetailPage extends StatefulWidget {
  final Blog blog;

  const BlogDetailPage({Key? key, required this.blog}) : super(key: key);

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late int likeCount;
  bool isLiking = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.blog.likeCount;
  }

  Future<void> _likeBlog() async {
    setState(() {
      isLiking = true;
    });
    try {
      final String likeUrl = '$api/blogs/${widget.blog.blogId}/like';
      final response = await http.put(Uri.parse(likeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          likeCount = data['like_count'] ?? likeCount;
        });
      }
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() {
        isLiking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blog = widget.blog;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Saamay Blogs"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with area tag - NOW WITH CACHING
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    CachedImageWidget(
                      imageUrl: blog.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      errorWidget: Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iconBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          blog.area.capitalize(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Author section

              // Author section with like count
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAEC).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE8D5B7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset('assets/icons/pen.png', width: 16, height: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        blog.writerName,
                        style: GoogleFonts.lora(
                          color: const Color(0xFFDA4453),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            likeCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFDA4453), Color(0xFF800000)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // Blog content
              Padding(
                padding: EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blog title - Using Lora font
                    Text(
                      blog.summary,
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content
                    _buildBlogContent(blog.text),
                    const SizedBox(height: 32),

                    // Like button above About Author
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton.icon(
                          onPressed: isLiking ? null : _likeBlog,
                          icon: Icon(Icons.favorite, color: Colors.red),
                          label: Text(
                            isLiking ? 'Liking...' : 'Like',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // About author section
                    Text(
                      'ABOUT AUTHOR',
                      style: GoogleFonts.lora(
                        color: Color(0xFF800000),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE8D5B7),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author header with icon
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF800000,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF800000),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        blog.writerName,
                                        style: GoogleFonts.lora(
                                          color: Color(0xFF800000),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Decorative divider
                            Container(
                              height: 2,
                              width: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF800000),
                                    Color(0xFFDA4453),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Author description - Using Poppins
                            Text(
                              blog.aboutWriter,
                              style: GoogleFonts.poppins(
                                color: Color(0xFF2C2C2C),
                                fontSize: 15,
                                height: 1.6,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Main method to build the blog content
  Widget _buildBlogContent(String text) {
    return _buildFormattedBlogContent(text);
  }
}

extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}
