import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sample_pdf/utils.dart';

class TakePicture extends StatefulWidget {

  final CameraDescription camera;

  const TakePicture({
    Key key,
    @required this.camera
  }) : super(key: key);

  @override
  _TakePictureState createState() => _TakePictureState();
}

class _TakePictureState extends State<TakePicture> {

  CameraController _controller;
  Future<void> _intializedControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
        widget.camera,
        ResolutionPreset.veryHigh,
        enableAudio: false
    );

    _intializedControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
          future: _intializedControllerFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final size = MediaQuery.of(context).size;
              // final deviceRatio = size.width / size.height;
              return Transform.scale(
                scale: _controller.value.aspectRatio / size.aspectRatio,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.photo_camera),
          onPressed: () async {
            try {
              await _intializedControllerFuture;
              final path = join((await getTemporaryDirectory()).path, 'photo_${DateTime.now()}.png');
              await _controller.takePicture(path);

              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => DisplayPicture(imagePath: path))
              );
            } catch (e) {
              print(e);
            }
          },
        ),
    );
  }
}

class DisplayPicture extends StatelessWidget {

  final String imagePath;

  DisplayPicture({
    Key key,
    this.imagePath
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.black87
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_a_photo), 
            onPressed: () {
              
            }
          )
        ],
        title: Text(
          '${imagePath.substring(imagePath.lastIndexOf('/'))}',
          style: TextStyle(
            color: Colors.black87
          ),
        ),
      ),
      body: Container(
        width: size.width,
        height: size.height,
        child: Image.file(File(imagePath), fit: BoxFit.fill)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: FloatingActionButton.extended(
            backgroundColor: accentColor,
            onPressed: () async {
                final savePath = join((await getApplicationDocumentsDirectory()).path, 'doc_${DateTime.now()}.pdf');
                var file = File(imagePath);

                final pdf = pw.Document();
                final pdfImage = PdfImage.file(
                  pdf.document,
                  bytes: file.readAsBytesSync()
                );

                pdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat.a4,
                    build: (pw.Context context) {
                      return pw.Center(
                        child: pw.Expanded(
                          child: pw.Image(
                            pdfImage,
                            fit: pw.BoxFit.cover
                          )
                        )
                      );
                    }
                  )
                );

                file = File(savePath);
                await file.writeAsBytes(pdf.save());
                print('file path : ${file.path}');
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
            }, 
            label: Text("Convert to PDF"),
            clipBehavior: Clip.antiAlias,
          ),
        )
      );
    }
}