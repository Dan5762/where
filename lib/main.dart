import 'dart:math';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:location/location.dart';
import 'package:flutter_compass/flutter_compass.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Where',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const  Scaffold(
        body: MyHomePage(),
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController textController = TextEditingController();
  bool targetLocSet = false;
  LocationData deviceLoc =  LocationData.fromMap({
    'latitude':  0.0,
    'longitude': 0.0
  });
  late StreamSubscription<LocationData> locationSubscription;
  LocationData targetLoc = LocationData.fromMap({
    'latitude':  52.09751281363889,
    'longitude': 0.2826702658818725
  });
  
  _initLocationService() async {
    Location location = Location();

    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) {
        return;
      }
    }

    var permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) {
        return;
      }
    }

    var loc = await location.getLocation();
    setState(() {
      deviceLoc = loc;
      targetLocSet = true;
    });

    location.onLocationChanged.listen((loc) { 
      print("${loc.latitude} ${loc.longitude}");
      setState(() {
        deviceLoc = loc;
      });
    });
  }

  Future<LocationData> getLocation() async {
    var location = Location();
    var loc = await location.getLocation();
    return loc;
  }

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  double calculateAngle(LocationData loc1, LocationData loc2) {
    double dLon = (loc2.longitude! - loc1.longitude!);

    double y = sin(dLon) * cos(loc2.latitude!);
    double x = cos(loc1.latitude!) * sin(loc2.latitude!) - sin(loc1.latitude!) * cos(loc2.latitude!) * cos(dLon);

    double angle = atan2(y, x);

    print("Angle: $angle");

    return angle;
  }

  double calculateDistance(LocationData loc1, LocationData loc2) {
    double phi1 = loc1.latitude! * pi/180;
    double phi2 = loc2.latitude! * pi/180;

    double dphi = (loc2.latitude! - loc1.latitude!) * pi/180;
    double dlambda = (loc2.longitude! - loc1.longitude!) * pi/180;

    double a = sin(dphi / 2) * sin(dphi / 2) + cos(phi1) * cos(phi2) * sin(dlambda / 2) * sin(dlambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double R = 6371000;
    double distance = R * c;

    print("Distance: $distance");

    return distance;
  }

  @override
  Widget build(BuildContext context) {
    var angle = calculateAngle(deviceLoc, targetLoc);
    var distance = calculateDistance(deviceLoc, targetLoc);
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: CupertinoSearchTextField(
              controller: textController,
              placeholder: 'Find Location',
              onSubmitted: (value) => {
                setState(() => {
                  targetLocSet = true,
                  targetLoc = LocationData.fromMap({
                    'latitude': double.parse(textController.text.split(',')[0]),
                    'longitude': double.parse(textController.text.split(',')[1])
                  }),
                })
              },
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
            child: CupertinoButton(
              child: const Text(
                'Copy Your Location',
                textAlign: TextAlign.end,
              ),
              onPressed:() async {
                var loc = await getLocation();
                print("${loc.latitude},${loc.longitude}");
                await Clipboard.setData(ClipboardData(text: "${loc.latitude},${loc.longitude}"));
              },
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child:  targetLocSet ? Compass(angle: angle, distance: distance) : Container()
            )
          ),
        ]
      ),
    );
  }
}

class Compass extends StatefulWidget {
  double angle;
  double distance;
  
	Compass({Key? key, required this.angle, required this.distance}) : super(key: key);

	@override
	_CompassState createState() => _CompassState();
}

class _CompassState extends State<Compass> with SingleTickerProviderStateMixin {

	double deviceAngle = 0;
	
	@override
	void initState() {
		super.initState();
		FlutterCompass.events!.listen(_onData);
	}

	void _onData(CompassEvent x) {
    setState(() {
      deviceAngle = (-pi) - pi * (x.heading!) / 180;
    });
  }

	final TextStyle _style = const TextStyle(
		color: Colors.deepPurple, 
		fontSize: 32,
		fontWeight: FontWeight.w200,
	);

	@override
	Widget build(BuildContext context) {
		return CustomPaint(
			foregroundPainter: CompassPainter(angle: deviceAngle + widget.angle),
			child: Center(child: Text(widget.distance.toStringAsPrecision(2) + 'm', style: _style))
		);
	}
}

class CompassPainter extends CustomPainter {

	CompassPainter({ required this.angle }) : super();

  final double angle;
	double get rotation => angle;

	Paint get _brush => Paint()
		..style = PaintingStyle.stroke
		..strokeWidth = 2.0;

	@override
	void paint(Canvas canvas, Size size) {

		Paint circle = _brush
			..color = Colors.indigo[400]!.withOpacity(0.6);

		Paint needle = _brush
			..color = Colors.deepPurple[400]!;
		
		double radius = min(size.width / 2, size.height / 2);
		Offset center = Offset(size.width / 2, size.height / 2);
		Offset centerL = Offset(size.width / 2 - 5, size.height / 2);
		Offset centerR = Offset(size.width / 2 + 5, size.height / 2);
    Offset point = Offset(center.dx, center.dy + radius);
		Offset startL = Offset.lerp(centerL, point, 0.3)!;
		Offset startR = Offset.lerp(centerR, point, 0.3)!;
		Offset end = Offset.lerp(center, point, 0.9)!;
		
		canvas.translate(center.dx, center.dy);
		canvas.rotate(rotation);
		canvas.translate(-center.dx, -center.dy);
		canvas.drawLine(startR, end, needle);
		canvas.drawLine(startL, end, needle);
		canvas.drawCircle(center, radius, circle);
	}

	@override
	bool shouldRepaint(CustomPainter oldDelegate) => true;
}