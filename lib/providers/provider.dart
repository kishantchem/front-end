import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String baseUrl = "http://103.118.50.200:5001";
String baseUrl1 = "https://sde-007.api.assignment.theinternetfolks.works/v1/event";

// ------------------------------ AUTH FUNCTIONS ------------------------------

Future<bool> checkTokenStatus() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");
  if (token == null) return false;

  final response = await http.get(Uri.parse(baseUrl), headers: {
    'Content-type': 'application/json',
    'Authorization': 'Bearer $token'
  });

  return response.statusCode == 200;
}

Future<bool> registerUser(String username, String password) async {
  final response = await http.post(
    Uri.parse("$baseUrl/register"),
    headers: {'Content-type': 'application/json'},
    body: json.encode({"username": username, "password": password}),
  );

  return response.statusCode == 201;
}

Future<bool> loginUser(String username, String password) async {
  final response = await http.post(
    Uri.parse("$baseUrl/login"),
    headers: {'Content-type': 'application/json'},
    body: json.encode({"username": username, "password": password}),
  );

  if (response.statusCode == 200) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("token", json.decode(response.body)["access_token"]);
    prefs.setBool("isLoggedIn", true);
    return true;
  }
  return false;
}

// ✅ NEW: Logout Function
Future<bool> logoutUser() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("isLoggedIn");
    return true;
  } catch (e) {
    print("Logout failed: $e");
    return false;
  }
}

// ------------------------------ API CALLS ------------------------------

Future<List> getImageDetails(File selectedImage, int method) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString("token")!;
  final Uri uri = Uri.parse("$baseUrl/api/v$method/upload");
  final request = http.MultipartRequest("POST", uri);
  final Map<String, String> headers = {
    "Authorization": 'Bearer $token',
    "Content-type": "multipart/form-data"
  };
  request.headers.addAll(headers);
  request.fields['method'] = method.toString();

  final fileStream = http.ByteStream(selectedImage.openRead());
  final fileLength = await selectedImage.length();
  final multipartFile = http.MultipartFile(
    'file',
    fileStream,
    fileLength,
    filename: selectedImage.path.split('/').last,
  );
  request.files.add(multipartFile);
  final response = await request.send();
  final res = await http.Response.fromStream(response);
  var length = json.decode(res.body)["length"];
  return length;
}

Future<String> getDetails(int id) async {
  final response = await http.get(Uri.parse('$baseUrl1/$id'));

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to fetch event details!');
  }
}

Future<String> getEvents() async {
  final response = await http.get(Uri.parse(baseUrl1));

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to fetch events!');
  }
}

Future<Map<String, dynamic>> getImageDetails1(
  File selectedImage,
  double calibrationFactor,
  var cottonType,
  var lotNumber,
  var station,
) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString("token")!;
  final Uri uri = Uri.parse("$baseUrl/api/v3/upload");
  final request = http.MultipartRequest("POST", uri);

  final Map<String, String> headers = {
    "Authorization": 'Bearer $token',
    "Content-type": "multipart/form-data"
  };
  request.headers.addAll(headers);

  final fileStream = http.ByteStream(selectedImage.openRead());
  final fileLength = await selectedImage.length();
  final multipartFile = http.MultipartFile(
    'file',
    fileStream,
    fileLength,
    filename: selectedImage.path.split('/').last,
  );
  request.files.add(multipartFile);

  request.fields['calibration_factor'] = (calibrationFactor / 2).toString();
  request.fields['cotton_type'] = cottonType.toString();
  request.fields['lot_number'] = lotNumber.toString();
  request.fields['station'] = station.toString();

  final streamedResponse = await request.send();

  if (streamedResponse.statusCode == 200) {
    final responseString = await streamedResponse.stream.bytesToString();
    final Map<String, dynamic> jsonResponse = jsonDecode(responseString);
    final String base64Image = jsonResponse["image"];
    final Uint8List imageBytes = base64Decode(base64Image);

    return {
      "image": imageBytes,
      "msfl": jsonResponse["msfl"],
      "ifl": jsonResponse["ifl"],
      "ml": jsonResponse["ml"],
    };
  } else {
    throw Exception("Failed to process image: ${streamedResponse.reasonPhrase}");
  }
}

Future<String> getImageDetailsAsCSV() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString("token")!;

  if (token.isEmpty) {
    throw Exception("No authentication token found.");
  }

  final Uri uri = Uri.parse("$baseUrl/api/v1/image_details");
  final response = await http.get(
    uri,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    final List<dynamic> data = jsonResponse["data"];
    if (data.isEmpty) {
      throw Exception("No image details found.");
    }

    List<String> headers = data.first.keys.toList();
    String csvString = "${headers.join(",")}\n";
    for (var item in data) {
      csvString += "${headers.map((header) => item[header]?.toString() ?? "").join(",")}\n";
    }
    return csvString;
  } else {
    throw Exception("Failed to fetch image details: ${response.reasonPhrase}");
  }
}