import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libras/helpers/translate_helper.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:libras/helpers/app_helper.dart';
import 'package:libras/helpers/camera_helper.dart';
import 'package:libras/helpers/tflite_helper.dart';
import 'package:libras/models/result.dart';

class DetectScreen extends StatefulWidget {
  DetectScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DetectScreenPageState createState() => _DetectScreenPageState();
}

class _DetectScreenPageState extends State<DetectScreen> {

  TranslateHelper tHelper;

  List<Result> outputs;
  String translate = "";

  void initState() {
    super.initState();

    TFLiteHelper.loadModel().then((value) {
      setState(() {
        TFLiteHelper.modelLoaded = true;
      });
    });

    CameraHelper.initializeCamera();

    TFLiteHelper.tfLiteResultsController.stream.listen(
        (value) {
          outputs = value;

          //Update results on screen
          setState(() {
            //Set bit to false to allow detection again
            CameraHelper.isDetecting = false;
          });
        },
        onDone: () {},
        onError: (error) {
          AppHelper.log("listen", error);
        });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<void>(
        future: CameraHelper.initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Stack(
              children: <Widget>[
                CameraPreview(CameraHelper.camera),
                _buildTranslatedTextWidget(width, outputs)
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    TFLiteHelper.disposeModel();
    CameraHelper.camera.dispose();
    AppHelper.log("dispose", "Clear resources.");
    super.dispose();
  }

  Widget _buildTranslatedTextWidget(double width, List<Result> outputs) {
    translate += " ${outputs.first.label}";
    //TODO: Salvar a primeira e no build, enviar o texto inteiro
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            height: 200.0,
            width: width,
            color: Colors.white,
            child: outputs != null && outputs.isNotEmpty
                ? Center(
                    child: Text(translate),
                  )
                : Center(
                    child: Text(
                      "Aguarde para a camera detectar os movimentos",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                      ),
                    ),
                  )),
      ),
    );
  }


}
