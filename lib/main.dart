import 'package:camera/camera.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:sample_pdf/picture_selector.dart';
import 'dart:io' show Directory, File, Platform;
import 'package:sample_pdf/take_picture.dart';
import 'package:sample_pdf/utils.dart';

var firstCamera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());

  final cameras = await availableCameras();
  firstCamera = cameras.first;
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => MaterialHome(title: 'Photo to PDF'),
          '/camera': (context) => TakePicture(camera: firstCamera),
          '/add_photo': (context) => PictrueSelector(), 
        },
        debugShowCheckedModeBanner: false,
        title: 'Photo to PDF',
        theme: ThemeData(
          primarySwatch: MaterialColor(0xFFFFFFFF, colorMap),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      );
    } else {
      return CupertinoApp(
        initialRoute: '/',
        routes: {
          '/': (context) => MaterialHome(title: 'Photo to PDF'),
          '/camera': (context) => TakePicture(camera: firstCamera)
        },
        debugShowCheckedModeBanner: false,
        title: 'Photo to PDF',
        theme: CupertinoThemeData(
            barBackgroundColor: Colors.indigo, brightness: Brightness.light),
      );
    }
  }
}

class MaterialHome extends StatefulWidget {
  MaterialHome({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MaterialHomeState createState() => _MaterialHomeState();
}

class _MaterialHomeState extends State<MaterialHome> {

  Future<List<File>> loadDocuments() async {
    final files = List<File>();
    final directoryPath = await getApplicationDocumentsDirectory();
    final path = directoryPath.path;
    final directory = Directory(path);
    final systemFiles = directory.listSync();

    systemFiles.forEach((systemFile) {
      var ext = systemFile.path.substring(systemFile.path.lastIndexOf('.'));
      if (ext == ".pdf") {
        final file = File(systemFile.path);
        files.insert(0, file);
      }
    });
    return files;
  }

  void shareFile(String fileName, File file) async {
    final title = 'Share PDF File';
    final bytes = await file.readAsBytes();
    await Share.file(title, fileName, bytes, '*/*');
  }

  void deleteFile(File file) async {
    await file.delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<List<File>>(
          future: loadDocuments(),
          builder: (context, snapshot) {
            var length = snapshot.data != null ? snapshot.data.length : 0;
            if (snapshot.connectionState == ConnectionState.done) {
              if (length > 0) {
                return _renderFilesList(snapshot);
              } else {
                return Center(
                  child: Text(
                    'No Files Added',
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
                  'No Files Added',
                  style: TextStyle(
                    fontWeight: FontWeight.w600
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(136, 14, 79, 1),
        onPressed: () async {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  content: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        InkWell(
                          child: Container(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.camera,
                                  color: Colors.black,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                  child: Text(
                                    "Capture From Camera",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () async {
                            // Navigator.pushNamed(context, '/camera').then((result) => {
                            //   Navigator.of(context, rootNavigator: true).pop('dialog')
                            // });
                            await Navigator.pushNamed(context, '/camera');
                            Navigator.of(context, rootNavigator: true).pop('dialog');
                            setState(() {});
                          },
                        ),
                        InkWell(
                          child: Container(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.photo_library,
                                  color: Colors.black,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                  child: Text(
                                    "Choose From Gallery",
                                  ),
                                ),
                              ],
                            )
                          ),
                          onTap: () async {
                            await openGallery(context);
                            Navigator.of(context, rootNavigator: true).pop('dialog');
                          },
                        ),
                      ],
                    ),
                  ), 
                );
              });
        },
        tooltip: 'Capture Image',
        child: Icon(Icons.photo_camera),
      ),
    );
  }

  Widget _renderFilesList(snapshot) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 64.0),
      itemCount: snapshot.data != null ? snapshot.data.length : 0,
      separatorBuilder: (context, index) => Divider(color: Colors.grey, height: 1,),
      itemBuilder: (context, index) {
        final file = snapshot.data[index];
        final path = snapshot.data[index].path;
        final fileName = path.substring(path.lastIndexOf('/') + 1);
        final size = file.lengthSync() / 1024;
        return InkWell(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(flex: 1, child: Icon(Icons.picture_as_pdf, color: Colors.red)),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                          child: Text(
                            fileName,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 2,
                            style: TextStyle(
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Text('size ${size.toInt()} kB'),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: IconButton(
                      icon: Icon(Icons.share), 
                      onPressed: () {
                        shareFile(fileName, file);
                      }
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: IconButton(
                      icon: Icon(Icons.delete_outline), 
                      onPressed: () {
                        showDialog(
                          context: context, 
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Delete $fileName'),
                              content: Text('Are you sure you want to delete this file?'),
                              actions: <Widget>[
                                FlatButton(
                                  onPressed: () => Navigator.pop(context, false), 
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey
                                    ),
                                  )
                                ),
                                FlatButton(
                                  onPressed: () {
                                    deleteFile(file);
                                    Navigator.pop(context, false);
                                  }, 
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: accentColor
                                    ),
                                  )
                                ),
                              ],
                            );
                        });
                        //await file.delete();
                        //setState(() {});
                      }
                    ),
                  )
                ],
              )
            ),
            onTap: () async {
              Navigator.push(context, 
                MaterialPageRoute(builder: (context) => PDFView(title: fileName, file: file))
            );
          },
        );
      }, 
    );
  }
}

class PDFView extends StatefulWidget {
  final title;
  final file;

  PDFView({Key key, this.title, this.file});

  @override
  _PDFViewState createState() => _PDFViewState();
}

class _PDFViewState extends State<PDFView>
    with SingleTickerProviderStateMixin {

  bool isLoading = false;
  PDFDocument doc;

  void _loadDocument() async {
    setState(() {
      isLoading = true;
    });
    doc = await PDFDocument.fromFile(widget.file);
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.black87
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.black87
          ),
        ),
      ),
      body: Center(
        child: Container(
          child: isLoading ? 
            CircularProgressIndicator() : 
            PDFViewer(
              document: doc,
              showPicker: doc.count > 1,
            )
        ),
      ),
    );
  }
}