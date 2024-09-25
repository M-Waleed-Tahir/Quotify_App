import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Motivational Quote",
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late String quote, owner, imglink;
  bool working = false;
  final grey = Colors.blueGrey;
  late ScreenshotController screenshotController;

  @override
  void initState() {
    super.initState();
    screenshotController = ScreenshotController();
    quote = "";
    owner = "";
    imglink = "";
    getQuote();
  }

  Future<void> getQuote() async {
    setState(() {
      working = true;
      quote = owner = imglink = "";
    });

    try {
      var response = await http.post(
        Uri.parse('http://api.forismatic.com/api/1.0/'),
        body: {"method": "getQuote", "format": "json", "lang": "en"},
      );

      var res = jsonDecode(response.body);
      owner = res["quoteAuthor"]?.toString().trim() ?? "Unknown";
      quote = res["quoteText"].replaceAll("ấ", " ");
      getImg(owner);
    } catch (e) {
      offline();
    }
  }

  void offline() {
    setState(() {
      owner = "Janet Fitch";
      quote = "The internet is a dangerous place to be.";
      imglink = "";
      working = false;
    });
  }

  Future<void> copyQuote(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '$quote\n-$owner'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quote copied to clipboard!')),
    );
  }

  Future<void> shareQuote() async {
    final directory = await getApplicationDocumentsDirectory();
    String path =
        '${directory.path}/Screenshots${DateTime.now().toIso8601String()}.png';

    final image = await screenshotController.capture();

    if (image != null) {
      final file = File(path);
      await file.writeAsBytes(image);
      await Share.shareXFiles([XFile(file.path)], text: quote);
    } else {
      print('Failed to capture the screenshot');
    }
  }

  Future<void> getImg(String name) async {
    var image = await http.get(
      Uri.parse(
          "https://upload.wikimedia.org/wikipedia/commons/4/4f/Tony_Robbins_seminar.jpg$name&format=json"),
    );

    setState(() {
      try {
        var res = json.decode(image.body)["query"]["pages"];
        res = res[res.keys.first];
        imglink = res["thumbnail"]["source"] ?? "";
      } catch (e) {
        imglink = "";
      }
      working = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Screenshot(
        controller: screenshotController,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.6, 1],
                  colors: [
                    grey.withAlpha(70),
                    grey.withAlpha(220),
                    grey.withAlpha(155),
                  ],
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: quote.isNotEmpty ? '"' : "",
                      style: TextStyle(
                        color: const Color.fromRGBO(36, 122, 39, 1),
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                      ),
                      children: [
                        TextSpan(
                          text: quote,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                          ),
                        ),
                        TextSpan(
                          text: quote.isNotEmpty ? '"' : "",
                          style: TextStyle(
                            color: const Color.fromRGBO(36, 122, 39, 1),
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    owner.isNotEmpty ? "\n$owner" : "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            AppBar(
              title: Text(
                "Quote Generator",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 27),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh, size: 34, color: Colors.white),
            onPressed: !working ? getQuote : null,
          ),
          IconButton(
            icon: Icon(Icons.content_copy, size: 34, color: Colors.white),
            onPressed: () => quote.isNotEmpty ? copyQuote(context) : null,
          ),
          IconButton(
            icon: Icon(Icons.share, size: 34, color: Colors.white),
            onPressed: quote.isNotEmpty ? shareQuote : null,
          ),
        ],
      ),
    );
  }
}
