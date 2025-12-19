import 'dart:convert';
import 'package:cotton/screens/home.dart';

import 'package:flutter/material.dart';
import 'package:cotton/providers/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class EventDetailsPage extends StatefulWidget {
  final int id;

  const EventDetailsPage({super.key, required this.id});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  var event = {};

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
    try {
      final response = await getDetails(widget.id);
      setState(() {
        event = json.decode(response)["content"]["data"];
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching event details: $e');
    }
  }
Future<bool> _onWillPop() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
    return false; // Prevents default pop (we handle it manually)
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          titleSpacing: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Event Details',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Container(
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bookmark,
                size: 30,
              ),
            ),
            const SizedBox(
              width: 30,
            ),
          ],
        ),
        body: event.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Stack(
                    children: [
                      event["banner_image"].endsWith('svg')
                          ? SvgPicture(
                              event["banner_image"],
                              fit: BoxFit.cover,
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: MediaQuery.of(context).size.width,
                            )
                          : Image.network(
                              event["banner_image"],
                              fit: BoxFit.cover,
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: MediaQuery.of(context).size.width,
                            ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xCC000000),
                              Color(0x00000000),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          event['title'],
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: event["organiser_icon"].endsWith('svg')
                                  ? SvgPicture.network(
                                      event["organiser_icon"],
                                      fit: BoxFit.cover,
                                      height: 50,
                                      width: 50,
                                    )
                                  : Image.network(
                                      event["organiser_icon"],
                                      fit: BoxFit.cover,
                                      height: 50,
                                      width: 50,
                                    ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event["organiser_name"],
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w400),
                                ),
                                const Text(
                                  "Organizer",
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w300),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  height: 50,
                                  width: 50,
                                  child: const Icon(Icons.calendar_month,
                                      color: Color.fromARGB(255, 33, 82, 243))),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    DateFormat('d MMMM, y').format(
                                        DateTime.parse(event["date_time"])),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400)),
                                Text(
                                    DateFormat('EEEE, h:mm a').format(
                                        DateTime.parse(event["date_time"])),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w300))
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  height: 50,
                                  width: 50,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color.fromARGB(255, 33, 82, 243),
                                  )),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event["venue_name"]),
                                Text(event["venue_city"] +
                                    ", " +
                                    event["venue_country"])
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'About Event',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          event['description'],
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 82, 243),
              borderRadius: BorderRadius.circular(20)),
          height: 60,
          width: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 0,
              ),
              const Text(
                "BOOK NOW",
                style: TextStyle(color: Colors.white),
              ),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 60, 230),
                    borderRadius: BorderRadius.circular(100)),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
