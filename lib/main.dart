import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:location/location.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
      home: const Scaffold(
        body: MyHomePage(),
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key,}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
            child: const CupertinoSearchTextField(
              placeholder: 'Find Location',
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
            child: TextButton(
              child: const Text(
                'Copy Your Location',
                textAlign: TextAlign.end,
              ),
              onPressed:() {},
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Compass()
            )
          ),
        ]
      ),
    );
  }
}class Compass extends StatefulWidget {

	Compass({Key? key}) : super(key: key);

	@override
	_CompassState createState() => _CompassState();
}

class _CompassState extends State<Compass> with SingleTickerProviderStateMixin {

	double _heading = 0;

	String get _readout => _heading.toStringAsFixed(0) + '°';

	@override
	void initState() {
		
		super.initState();
		FlutterCompass.events!.listen(_onData);
	}
	
	void _onData(CompassEvent x) => setState(() { _heading = x.heading!; });

	final TextStyle _style = const TextStyle(
		color: Colors.red, 
		fontSize: 32, 
		fontWeight: FontWeight.w200,
	);

	@override
	Widget build(BuildContext context) {

		return CustomPaint(
			foregroundPainter: CompassPainter(angle: _heading),
			child: Center(child: Text(_readout, style: _style))
		);
	}
}

class CompassPainter extends CustomPainter {

	CompassPainter({ required this.angle }) : super();

  final double angle;
	double get rotation => -2 * pi * (angle / 360);

	Paint get _brush => Paint()
		..style = PaintingStyle.stroke
		..strokeWidth = 2.0;

	@override
	void paint(Canvas canvas, Size size) {

		Paint circle = _brush
			..color = Colors.indigo[400]!.withOpacity(0.6);

		Paint needle = _brush
			..color = Colors.red[400]!;
		
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