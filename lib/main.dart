import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  String res;
  var modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _startTflite();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      controller.startImageStream((image) {
        if (!modelLoaded) return;
        _classifyImg(image);
      });
    });
  }

  _classifyImg(CameraImage img) {
    print('${img.height} x ${img.width}');
    Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
      return plane.bytes;
    }).toList());
  }

  _startTflite() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/labels.txt",
    )
    .then((value) =>  modelLoaded = true);
  }

  @override
  dispose() async {
    controller?.dispose();
    await Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller));
  }
}
