import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cotton/providers/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class UploadImageWidget extends StatefulWidget {
  const UploadImageWidget({super.key});

  @override
  State<UploadImageWidget> createState() => _UploadImageWidgetState();
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

class _UploadImageWidgetState extends State<UploadImageWidget> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  CroppedFile? _croppedFile;
  bool isImageUploaded = false;
  bool isBeingUploaded = false;

  late List<ChartData> chartData;

  double alpha = 1, beta = 1;
  double l1 = 0.0, d1 = 5.0, l2 = 0.0, d2 = 10.0;
  double cameraDistance = 7.3;
  var cottonType = "", station = "", lotNumber = "";
  late Uint8List imageBytes;
  double msfl = 0.0, ifl = 0.0, ml = 0.0;

  int method = 0;
  String _selectedLanguage = "English";

  final Map<String, Map<String, String>> localizedText = {
    'English': {
      'title': 'Cotton Fiber Length Measurement',
      'step1Title': 'Step 1: Calibrate the Camera',
      'step1Description':
      'Set your mobile camera at D1 = 5 cm and D2 = 10 cm and input the corresponding lengths L1 and L2 respectively, that span the horizontal width of your mobile\'s screen.',
      'step2Title': 'Step 2: Upload Cotton Fiber Image',
      'step2Description':
      'Click on the \'Upload\' button on the bottom right, select a method and upload an image of cotton fiber at D3 = 7.5 cm for analysis.',
      'calibrateButton': 'Calculate Alpha & Beta',
      'Alpha': 'Alpha',
      'Beta': 'Beta',
      'uploadButton': 'Upload',
      'Method': 'Method',
      'Camera': 'Camera',
      'Gallery': 'Gallery',
      'CottonType': 'Cotton Type',
      'Station': 'Station',
      'LotNumber': 'Lot Number',
    },
    'Hindi': {
      'title': 'कॉटन फाइबर की लंबाई मापन',
      'step1Title': 'चरण 1: कैमरे को अंशांकित करें',
      'step1Description':
      'अपने मोबाइल कैमरे को D1 = 5 सेमी और D2 = 10 सेमी पर सेट करें और स्क्रीन की क्षैतिज चौड़ाई में फैली संबंधित लंबाई L1 और L2 दर्ज करें।',
      'step2Title': 'चरण 2: कॉटन फाइबर की छवि अपलोड करें',
      'step2Description':
      'नीचे दाईं ओर दिए गए \'अपलोड\' बटन पर क्लिक करें, एक विधि चुनें और विश्लेषण के लिए D3 = 7.5 सेमी पर कपास के रेशे की एक छवि अपलोड करें।',
      'calibrateButton': 'अल्फा और बीटा की गणना करें',
      'Alpha': 'अल्फा',
      'Beta': 'बीटा',
      'uploadButton': 'अपलोड',
      'Method': 'विधि',
      'Camera': 'कैमरा',
      'Gallery': 'गैलरी',
      'CottonType': 'कपास का प्रकार',
      'Station': 'स्टेशन',
      'LotNumber': 'लॉट नंबर',
    },
  };


  @override
  void initState() {
    super.initState();
    loadAlphaBeta();
  }

  @override
  Widget build(BuildContext context) {
    final texts = localizedText[_selectedLanguage]!;

    return Scaffold(
      floatingActionButton: SpeedDial(
          label: Text(
            "${texts['uploadButton']}",
            style: const TextStyle(color: Colors.white),
          ),
          icon: Icons.camera_alt_outlined,
          //  backgroundColor: Colors.blue,
          children: [
            SpeedDialChild(
              // child: const Icon(Icons.,
              //     color: Colors.white),
              label: '${texts['Method']!} 1',
              backgroundColor: Colors.blueAccent,
              onTap: () => {
                setState(() {
                  method = 1;
                  isImageUploaded = false;
                }),
                showModalBottomSheet(
                  context: context,
                  builder: ((builder) => bottomSheet(1)),
                ),
              },
            ),
            SpeedDialChild(
              // child: const Icon(Icons.email, color: Colors.white),
              label: '${texts['Method']!} 2',
              backgroundColor: Colors.blueAccent,
              onTap: () => {
                setState(() {
                  method = 2;
                  isImageUploaded = false;
                }),
                showModalBottomSheet(
                  context: context,
                  builder: ((builder) => bottomSheet(2)),
                ),
              },
            ),
            SpeedDialChild(
              // child: const Icon(Icons.email, color: Colors.white),
              label: '${texts['Method']!} 3',
              backgroundColor: Colors.blueAccent,
              onTap: () => {
                setState(() {
                  method = 3;
                  isImageUploaded = false;
                }),
                showModalBottomSheet(
                  context: context,
                  builder: ((builder) => bottomSheet(3)),
                ),
              },
            ),
          ]),
      body: SafeArea(
        child: Padding(
          // Add margins on all sides
          padding: const EdgeInsets.all(50),
          child: SingleChildScrollView(
            child: Center(
              child: isBeingUploaded
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: isImageUploaded
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: isImageUploaded
                    ? [
                  method == 3
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.memory(imageBytes),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "RESULTS :-",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Machine Setting Fibre Length (MSFL)",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            Text("$msfl mm", style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text(
                              "Image based Fibre Length (IFL)",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            Text("$ifl mm", style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text(
                              "Mean Length (ML)",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            Text("$ml mm", style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  )
                      : SfCartesianChart(
                    primaryXAxis: const CategoryAxis(),
                    series: <ColumnSeries<ChartData, int>>[
                      ColumnSeries<ChartData, int>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                      ),
                    ],
                  )
                ]
                    : [
                  // Language Dropdown
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue!;
                      });
                    },
                    items: ['English', 'Hindi'].map<DropdownMenuItem<String>>((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    texts['title']!,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Step 1: Camera Calibration
                  Text(
                    texts['step1Title']!,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      texts['step1Description']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(labelText: "L1 (cm)"),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() => l1 = double.tryParse(value) ?? 0.0),
                        ),
                        TextField(
                          decoration: const InputDecoration(labelText: "L2 (cm)"),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() => l2 = double.tryParse(value) ?? 0.0),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    calculateAlphaBeta();
                                  });
                                },
                                child: Text("${localizedText[_selectedLanguage]!['calibrateButton']}"),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "${localizedText[_selectedLanguage]!['Alpha']} = $alpha",
                              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${localizedText[_selectedLanguage]!['Beta']} = $beta",
                              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Step 2: Upload Cotton Fiber Image
                  Text(
                    '${localizedText[_selectedLanguage]!['step2Title']}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${localizedText[_selectedLanguage]!['step2Description']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadAlphaBeta() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      alpha = prefs.getDouble('alpha') ?? 1.0;
      beta = prefs.getDouble('beta') ?? 1.0;
    });
  }

  void calculateAlphaBeta() async {
    if ((d1 - d2) != 0) {
      alpha = ((l1 - l2) / (d1 - d2)) * 10;
      beta = (l1 - ((l1 - l2) / (d1 - d2)) * d1) * 10;

      // Store in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('alpha', alpha);
      await prefs.setDouble('beta', beta);

      setState(() {
        alpha = alpha;
        beta = beta;
      });
    }
  }

  Widget bottomSheet(int method) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return DraggableScrollableSheet(
            initialChildSize: 1.0,  // 70% of screen height initially
            minChildSize: 0.3,       // Minimum 30% of screen height
            maxChildSize: 1.0,       // Maximum 100% of screen height
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),

                      // Method Title
                      Text(
                        method == 1
                            ? "${localizedText[_selectedLanguage]!['Method']} 1"
                            : (method == 2
                            ? "${localizedText[_selectedLanguage]!['Method']} 2 (Length Distribution)"
                            : "${localizedText[_selectedLanguage]!['Method']} 3 (Average Length)"),
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Conditional fields for Method 3
                      if (method == 3) ...[
                        // Cotton Type TextField
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "${localizedText[_selectedLanguage]!['CottonType']}",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            onChanged: (value) {
                              cottonType = value;
                            },
                          ),
                        ),

                        // Station TextField
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "${localizedText[_selectedLanguage]!['Station']}",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            onChanged: (value) {
                              station = value;
                            },
                          ),
                        ),

                        // Lot Number TextField
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "${localizedText[_selectedLanguage]!['LotNumber']}",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            onChanged: (value) {
                              lotNumber = value;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: <Widget>[
                          // Camera Button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  takePhoto(ImageSource.camera);
                                  Navigator.pop(context);
                                  setState(() {
                                    isBeingUploaded = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera),
                                    const SizedBox(width: 8),
                                    Text('${localizedText[_selectedLanguage]!['Camera']}'),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Gallery Button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  takePhoto(ImageSource.gallery);
                                  Navigator.pop(context);
                                  setState(() {
                                    isBeingUploaded = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image),
                                    const SizedBox(width: 8),
                                    Text('${localizedText[_selectedLanguage]!['Gallery']}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void takePhoto(ImageSource source) async {
    try {
      _imageFile = await _picker.pickImage(source: source);
    } catch (e) {
      rethrow;
    }
    if (_imageFile != null) {
      if (!mounted) return;
      _croppedFile = await ImageCropper()
          .cropImage(sourcePath: _imageFile!.path, aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0), uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(minimumAspectRatio: 1),
      ]);

      File finalImage = File(_croppedFile!.path);

      if (method == 1 || method == 2) {
        List response = await getImageDetails(finalImage, method);
        response = response[1];
        response.sort();

        chartData = [];
        double minVal = response[0], maxVal = response[response.length - 1];
        double gap = (maxVal - minVal) / 10;
        for (int i = 0; i < 10; i++) {
          double count = 0;
          for (double value in response) {
            if ((value < minVal + gap && value >= minVal) ||
                (value == maxVal && i == 9)) {
              count++;
            }
          }
          chartData.add(ChartData((minVal + gap / 2).toInt(), count));
          minVal += gap;
        }
      } else {
        img.Image? image = img.decodeImage(finalImage.readAsBytesSync());
        // print("********* Image Width: ${image!.width} ***********");
        Map<String, dynamic> response = await getImageDetails1(finalImage, (alpha * cameraDistance + beta) / image!.width, cottonType, lotNumber, station);
        setState(() {
          imageBytes = response["image"];
          msfl = response["msfl"];
          ifl = response["ifl"];
          ml = response["ml"];
        });
      }

      setState(() {
        isBeingUploaded = false;
        isImageUploaded = true;
      });
    }
  }
}
