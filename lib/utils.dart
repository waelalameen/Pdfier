import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:sample_pdf/picture_selector.dart';

final accentColor = Color.fromRGBO(136, 14, 79, 1);

final Map<int, Color> colorMap = {
    50: Color.fromRGBO(136, 14, 79, .1),
    100: Color.fromRGBO(136, 14, 79, .2),
    200: Color.fromRGBO(136, 14, 79, .3),
    300: Color.fromRGBO(136, 14, 79, .4),
    400: Color.fromRGBO(136, 14, 79, .5),
    500: Color.fromRGBO(136, 14, 79, .6),
    600: Color.fromRGBO(136, 14, 79, .7),
    700: Color.fromRGBO(136, 14, 79, .8),
    800: Color.fromRGBO(136, 14, 79, .9),
    900: Color.fromRGBO(136, 14, 79, 1),
};

Future<void> convertToPdfFiles(List<File> images) async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = join(directory.path, 'doc_${DateTime.now()}.pdf');
    final pdf = pw.Document();
    var file;

    images.forEach((image) async {
      final imagePath = image.path;
      file = File(imagePath);

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
                ),
              )
            );
          }
        )
      );
    });

    file = File(savePath);
    await file.writeAsBytes(pdf.save());
    print('file path : ${file.path}');
  }

Future<void> convertToPdfFile(imagePath) async {
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
}

Future<void> openGallery(context) async {
  File file = await FilePicker.getFile(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png']
  );
  
  try {
    final documentDirectory = await getExternalStorageDirectory();
    final path = join(documentDirectory.path, 'photo_${DateTime.now()}.png');
    var status = await Permission.storage.status;

    if (status.isGranted) {
      var bytes = await file.readAsBytes();
      final f = File(path);
      f.writeAsBytesSync(bytes);
      await Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => PictrueSelector(source: Source.GALLERY))
      );
    } else if (status.isDenied) {
      await Permission.storage.request();
      status = await Permission.storage.status;
      if (status.isGranted) {
        var bytes = await file.readAsBytes();
        final f = File(path);
        f.writeAsBytesSync(bytes);
        await Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => PictrueSelector(source: Source.GALLERY))
        );
      }      
    } else if (status.isUndetermined) {
      await Permission.storage.request();
      status = await Permission.storage.status;
      if (status.isGranted) {
        var bytes = await file.readAsBytes();
        final f = File(path);
        f.writeAsBytesSync(bytes);
        await Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => PictrueSelector(source: Source.GALLERY))
        );
      } 
    }
  } catch (e) {
    print(e);
  }
}