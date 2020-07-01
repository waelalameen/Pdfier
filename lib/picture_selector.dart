import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sample_pdf/utils.dart';

class PictrueSelector extends StatefulWidget {
  final source;

  PictrueSelector({
    Key key,
    this.source = Source.CAMERA
  });

  @override
  _PictrueSelectorState createState() => _PictrueSelectorState();
}

enum Source {
  CAMERA, GALLERY
}

class _PictrueSelectorState extends State<PictrueSelector>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  bool _isDeleting = false;
  List<File> selectedFiles = List<File>();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _deleteAll(selectedFiles);
    _controller.dispose();
  }

  Future<List<String>> _loadPhotos() async {
    var filePaths = List<String>(); 
    final path = join((await getExternalStorageDirectory()).path);
    final directory = Directory(path);
    List<FileSystemEntity> systemFiles = directory.listSync();

    selectedFiles.clear();

    systemFiles.forEach((systemFile) { 
      filePaths.add(systemFile.path);
      selectedFiles.add(File(systemFile.path));
    });
     
    return filePaths;
  }

  Future<void> _deleteAll(List<File> files) async {
    files.forEach((file) async {
      try {
        await file.delete();
      } catch(e) {
        print(e);
      }
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _deleteAll(selectedFiles);
        await Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => true);
        return Future.value(true);
      },
          child: Scaffold(
          appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.black87
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.remove_circle), 
              onPressed: () {
                setState(() {
                  _isDeleting = !_isDeleting;
                });
              }
            ),
            IconButton(
              icon: Icon(Icons.add_a_photo), 
              onPressed: () async {
                widget.source == Source.CAMERA ? 
                Navigator.pushNamed(context, '/camera') : 
                await openGallery(context);
              }
            )
          ],
          title: Text(
            'Select Photos',
            style: TextStyle(
              color: Colors.black87
            ),
          ),
        ),
        body: Center(
          child: FutureBuilder<List<String>>(
            future: _loadPhotos(),
            builder: (index, snapshot) {
              var orientation = MediaQuery.of(context).orientation;
              var length = snapshot.data != null ? snapshot.data.length : 0;

              if (snapshot.connectionState == ConnectionState.done) {
                if (length > 0) {
                  return InkWell(
                    child: GridView.count(
                      crossAxisCount: orientation == Orientation.portrait ? 3 : 4,
                      padding: const EdgeInsets.all(8.0),
                      children: snapshot.data.map((item) {
                        return GridTile(
                          child: Card(
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.file(File(item), fit: BoxFit.cover),
                                Opacity(
                                  opacity: _isDeleting ? 1.0 : 0.0,
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 12.0,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                            size: 24.0,
                                          ), 
                                          onPressed: () {
                                            setState(() {
                                              File(item).delete();
                                              _isDeleting = false;
                                            });
                                          }
                                      ),
                                    )
                                  ),
                                )
                              ],
                            )
                          )
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return Center(
                    child: Text(
                      'No Photos Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  );
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                return Center(
                  child: Text(
                    'No Photos Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600
                    ),
                  ),
                );
              }
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: FloatingActionButton.extended(
              backgroundColor: accentColor,
              label: Text('Convert To PDF'),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircularProgressIndicator(),
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text('Generating PDF Files ...'),
                          )
                        ],
                      ),
                    );
                  }
                );
                await convertToPdfFiles(selectedFiles);
                //await _deleteAll(selectedFiles);
                await Future.delayed(Duration(seconds: 2));
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
              },
            )
        )
      ),
    );
  }
}