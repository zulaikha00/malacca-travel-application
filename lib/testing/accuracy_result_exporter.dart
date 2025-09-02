import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class AccuracyExporter {
  Future<void> exportToExcel(List<Map<String, dynamic>> data, {String filename = 'cbf_accuracy_results.xlsx'}) async {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Accuracy'];

    if (data.isEmpty) return;

    final headers = data.first.keys.toList();
    sheet.appendRow(headers);

    for (final row in data) {
      sheet.appendRow(headers.map((h) => row[h]).toList());
    }

    // ✅ Get Downloads folder path for Android
    final Directory? directory = await getExternalStorageDirectory(); // Internal app dir
    final downloadsPath = Directory('/storage/emulated/0/Download'); // External visible folder

    final file = File('${downloadsPath.path}/$filename');
    final bytes = excel.encode()!;
    await file.writeAsBytes(bytes);

    print('📁 Excel file saved to: ${file.path}');
  }
}
