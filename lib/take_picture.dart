import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:sample_pdf/picture_selector.dart';
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
          backgroundColor: accentColor,
          onPressed: () async {
            try {
              await _intializedControllerFuture;
              final documentDirectory = await getExternalStorageDirectory();
              final path = join(documentDirectory.path, 'photo_${DateTime.now()}.png');
              var status = await Permission.storage.status;

              if (status.isGranted) {
                await _controller.takePicture(path);
                final f = File(path);
                var bytes = await f.readAsBytes();
                await f.writeAsBytes(bytes);
              } else if (status.isDenied) {
                await Permission.storage.request();
                print('status.isDenied = ${status.isDenied}}');
              } else if (status.isUndetermined) {
                await Permission.storage.request();
                print('status.isUndetermined = ${status.isUndetermined}}');
              }
              await Navigator.push(
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
              await Navigator.pushNamed(context, '/add_photo', arguments: Source.CAMERA);
            }, 
            label: Text("Continue"),
            clipBehavior: Clip.antiAlias,
          ),
        )
      );
    }
}