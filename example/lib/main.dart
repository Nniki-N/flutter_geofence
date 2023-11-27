import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_geofence/geofence.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    new FlutterLocalNotificationsPlugin();

void main() => runApp(MaterialApp(
      home: Scaffold(body: MyApp()),
    ));
BehaviorSubject<String> geoeventStream = BehaviorSubject();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final enterLocation1 = Geolocation(
    latitude: 48.16911,
    longitude: 11.53429,
    radius: 200,
    id: 'test_id1_enter',
  );
  final exitLocation1 = Geolocation(
    latitude: 48.16911,
    longitude: 11.53429,
    radius: 200,
    id: 'test_id1_exit',
  );
  final enterLocation2 = Geolocation(
    latitude: 48.17034,
    longitude: 11.53235,
    radius: 200,
    id: 'test_id2_enter',
  );
  final exitLocation2 = Geolocation(
    latitude: 48.17034,
    longitude: 11.53235,
    radius: 200,
    id: 'test_id2_exit',
  );
  final enterLocation3 = Geolocation(
    latitude: 48.16917,
    longitude: 11.5295,
    radius: 200,
    id: 'test_id3_enter',
  );
  final exitLocation3 = Geolocation(
    latitude: 48.16917,
    longitude: 11.5295,
    radius: 200,
    id: 'test_id3_exit',
  );
  String _message = "Message\n\n";
  late StreamSubscription<String> streamSubscription;

  @override
  void initState() {
    super.initState();
    _init();
    streamSubscription = geoeventStream.listen((event) {
      addLog(event);
      scheduleNotification('Event', event);
    });
    Geofence.onGeofenceEventReceived(geofenceEventCallback);
  }

  @override
  void dispose() {
    super.dispose();
    streamSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          alignment: AlignmentDirectional.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'test',
                style: TextStyle(fontSize: 30),
              ),
              MaterialButton(
                color: Colors.lightBlueAccent,
                child: Text('Add Coordinates'),
                onPressed: () {
                  addGeolocation(enterLocation1, GeolocationEvent.entry);
                  addGeolocation(exitLocation1, GeolocationEvent.exit);
                  addGeolocation(enterLocation2, GeolocationEvent.entry);
                  addGeolocation(exitLocation2, GeolocationEvent.exit);
                  addGeolocation(enterLocation3, GeolocationEvent.entry);
                  addGeolocation(exitLocation3, GeolocationEvent.exit);
                },
              ),
              MaterialButton(
                color: Colors.lightBlueAccent,
                child: Text('Remove Coordinates'),
                onPressed: () {
                  Geofence.removeAllGeolocations();
                },
              ),
              SingleChildScrollView(child: Text(_message))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();

    final list = sp.getStringList('key') ?? [];

    list.forEach(print);

    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS =
        DarwinInitializationSettings(onDidReceiveLocalNotification: null);
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (await Permission.location.request().isGranted) {
      final locationAlways =
          await Permission.locationAlways.request().isGranted;
      if (locationAlways) {
        Geofence.requestPermissions();
      } else {
        // don't continue missing permission access
        return;
      }
    }
    Geofence.startListeningForLocationChanges();
    await Geofence.removeAllGeolocations();
  }

  void addGeolocation(Geolocation geolocation, GeolocationEvent event) {
    Geofence.addGeolocation(geolocation, event).then((onValue) {
      final message =
          '${event.name.split('.').last}: Geofence added! ${geolocation.id}';
      print(message);
      addLog(message);
    }).catchError((error) {
      print('failed with $error');
    });
  }

  void showSnackbar(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  void addLog(String s) {
    setState(() {
      _message = _message + "-----------------------\n ${DateTime.now()}\n$s\n";
    });
  }

  Future<void> scheduleNotification(String title, String subtitle) async {
    print("scheduling one with $title and $subtitle");
    var rng = new Random();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name',
        importance: Importance.high, priority: Priority.high, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      rng.nextInt(100000),
      title,
      subtitle,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}

Future<void> geofenceEventCallback(
  Geolocation geolocation,
  GeolocationEvent event,
) async {
  print(
      'geofenceEventCallback: geolocation:${geolocation.id} event:${event.name}');
  geoeventStream.add('geolocation:${geolocation.id}');

  final sp = await SharedPreferences.getInstance();

  final list = sp.getStringList('key') ?? [];

  list.add('${DateTime.now()} ------------ ${geolocation.id} ------- geofence');

  sp.setStringList('key', list);

  var rng = new Random();
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name',
      importance: Importance.high, priority: Priority.high, ticker: 'ticker');
  var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    rng.nextInt(100000),
    'Callback from background',
    geolocation.id,
    platformChannelSpecifics,
    payload: 'item x',
  );
}
