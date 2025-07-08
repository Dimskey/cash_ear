import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../models/sale_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Pagi';
  final _otherIncomeController = TextEditingController();
  final _otherIncomeDescController = TextEditingController();
  final _expenseDescController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _startCashController = TextEditingController();
  final _kasirNameController = TextEditingController();
  List<Map<String, dynamic>> _otherIncomes = [];
  List<Map<String, dynamic>> _expenses = [];
  double _startCash = 0;

  @override
  void dispose() {
    _otherIncomeController.dispose();
    _otherIncomeDescController.dispose();
    _expenseDescController.dispose();
    _expenseAmountController.dispose();
    _startCashController.dispose();
    _kasirNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final dailySales = salesProvider.getDailySales(_selectedDate);
    final paymentSummary = <String, double>{};
    double totalSales = 0;
    for (var sale in dailySales) {
      totalSales += sale.total;
      paymentSummary[sale.paymentMethod] =
          (paymentSummary[sale.paymentMethod] ?? 0) + sale.total;
    }
    double totalOtherIncome = _otherIncomes.fold(0, (sum, item) => sum + item['amount']);
    double totalExpense = _expenses.fold(0, (sum, item) => sum + item['amount']);
    double endCash = _startCash + totalSales + totalOtherIncome - totalExpense;
    final auth = Provider.of<AuthProvider>(context);
    if (_kasirNameController.text.isEmpty && auth.currentUser?.name != null) {
      _kasirNameController.text = auth.currentUser!.name;
    }
    final kasirName = _kasirNameController.text;

    return Scaffold(
      appBar: AppBar(title: Text('Laporan Harian')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilih tanggal dan export PDF
            Row(
              children: [
                Text('Tanggal: '),
                TextButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _exportPdf(context, dailySales, paymentSummary, totalSales, totalOtherIncome, totalExpense, endCash, kasirName),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Export PDF'),
                ),
              ],
            ),
            // 1. Identitas Laporan
            Text('Identitas Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Business Name: '),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: 'Enter your business name'),
                  ),
                ),
              ],
            ),
            Text('Nama Warkop: Warkop TATA'),
            Row(
              children: [
                Text('Kasir: '),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _kasirNameController,
                    decoration: InputDecoration(hintText: 'Nama kasir'),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
              ],
            ),
            Text('Tanggal Laporan: ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)}'),
            Row(
              children: [
                Text('Shift: '),
                DropdownButton<String>(
                  value: _selectedShift,
                  items: ['Pagi', 'Sore', 'Malam'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedShift = val!),
                ),
              ],
            ),
            SizedBox(height: 16),
            // 2. Rincian Penjualan
            Text('Rincian Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FixedColumnWidth(32),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(60),
                4: FixedColumnWidth(90),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.brown[100]),
                  children: [
                    tableCell('No', bold: true),
                    tableCell('Nama Produk', bold: true),
                    tableCell('Harga', bold: true),
                    tableCell('Qty', bold: true),
                    tableCell('Subtotal', bold: true),
                  ],
                ),
                ..._buildSaleItemRows(dailySales),
                TableRow(children: [
                  tableCell(''),
                  tableCell(''),
                  tableCell(''),
                  tableCell('Total', bold: true),
                  tableCell('Rp${NumberFormat('#,###').format(totalSales)}', bold: true),
                ]),
              ],
            ),
            SizedBox(height: 16),
            // 3. Pemasukan Lain
            Text('Pemasukan Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ..._otherIncomes.map((item) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['desc']),
                Text('Rp${NumberFormat('#,###').format(item['amount'])}'),
              ],
            )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _otherIncomeDescController,
                    decoration: InputDecoration(labelText: 'Keterangan'),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _otherIncomeController,
                    decoration: InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_otherIncomeDescController.text.isNotEmpty && _otherIncomeController.text.isNotEmpty) {
                      setState(() {
                        _otherIncomes.add({
                          'desc': _otherIncomeDescController.text,
                          'amount': double.tryParse(_otherIncomeController.text) ?? 0,
                        });
                        _otherIncomeDescController.clear();
                        _otherIncomeController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // 4. Metode Pembayaran
            Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...paymentSummary.entries.map((e) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key),
                Text('Rp${NumberFormat('#,###').format(e.value)}'),
              ],
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pemasukan', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp${NumberFormat('#,###').format(totalSales + totalOtherIncome)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            // 5. Pengeluaran Harian
            Text('Pengeluaran Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ..._expenses.asMap().entries.map((entry) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entry.key + 1}. ${entry.value['desc']}'),
                Text('Rp${NumberFormat('#,###').format(entry.value['amount'])}'),
              ],
            )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expenseDescController,
                    decoration: InputDecoration(labelText: 'Keterangan'),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _expenseAmountController,
                    decoration: InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_expenseDescController.text.isNotEmpty && _expenseAmountController.text.isNotEmpty) {
                      setState(() {
                        _expenses.add({
                          'desc': _expenseDescController.text,
                          'amount': double.tryParse(_expenseAmountController.text) ?? 0,
                        });
                        _expenseDescController.clear();
                        _expenseAmountController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp${NumberFormat('#,###').format(totalExpense)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            // 6. Rekap Kas Harian
            Text('Rekap Kas Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                Text('Saldo Awal Kas: '),
                SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _startCashController,
                    decoration: InputDecoration(labelText: 'Saldo Awal'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _startCash = double.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('+ Penjualan Hari Ini'),
                Text('Rp${NumberFormat('#,###').format(totalSales)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('- Pengeluaran Hari Ini'),
                Text('Rp${NumberFormat('#,###').format(totalExpense)}'),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('= Saldo Akhir Kas', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp${NumberFormat('#,###').format(endCash)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _buildSaleItemRows(List<SaleModel> sales) {
    List<TableRow> rows = [];
    int no = 1;
    for (var sale in sales) {
      for (var item in sale.items) {
        rows.add(TableRow(children: [
          tableCell(no.toString()),
          tableCell(item.productName),
          tableCell('Rp${NumberFormat('#,###').format(item.price)}'),
          tableCell(item.quantity.toString()),
          tableCell('Rp${NumberFormat('#,###').format(item.subtotal)}'),
        ]));
        no++;
      }
    }
    return rows;
  }

  Widget tableCell(String text, {bool bold = false, int colspan = 1}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Text(
          text,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  void _exportPdf(BuildContext context, List<SaleModel> dailySales, Map<String, double> paymentSummary, double totalSales, double totalOtherIncome, double totalExpense, double endCash, String kasirName) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text('Laporan Harian', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Nama Warkop: Warkop TATA'),
          pw.Text('Kasir: $kasirName'),
          pw.Text('Tanggal Laporan: ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)}'),
          pw.Text('Shift: $_selectedShift'),
          pw.SizedBox(height: 16),
          pw.Text('Rincian Penjualan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['No', 'Nama Produk', 'Harga', 'Qty', 'Subtotal'],
            data: [
              for (var i = 0, no = 1; i < dailySales.length; i++)
                for (var item in dailySales[i].items)
                  [
                    no++,
                    item.productName,
                    'Rp${NumberFormat('#,###').format(item.price)}',
                    item.quantity.toString(),
                    'Rp${NumberFormat('#,###').format(item.subtotal)}',
                  ]
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total: Rp${NumberFormat('#,###').format(totalSales)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Pemasukan Lain', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (_otherIncomes.isEmpty)
            pw.Text('-'),
          ..._otherIncomes.map((item) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(item['desc']),
              pw.Text('Rp${NumberFormat('#,###').format(item['amount'])}'),
            ],
          )),
          pw.SizedBox(height: 12),
          pw.Text('Metode Pembayaran', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...paymentSummary.entries.map((e) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.key),
              pw.Text('Rp${NumberFormat('#,###').format(e.value)}'),
            ],
          )),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Pemasukan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Rp${NumberFormat('#,###').format(totalSales + totalOtherIncome)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Pengeluaran Harian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (_expenses.isEmpty)
            pw.Text('-'),
          ..._expenses.asMap().entries.map((entry) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${entry.key + 1}. ${entry.value['desc']}'),
              pw.Text('Rp${NumberFormat('#,###').format(entry.value['amount'])}'),
            ],
          )),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Pengeluaran', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Rp${NumberFormat('#,###').format(totalExpense)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Rekap Kas Harian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Row(
            children: [
              pw.Text('Saldo Awal Kas: '),
              pw.Text('Rp${NumberFormat('#,###').format(_startCash)}'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('+ Penjualan Hari Ini'),
              pw.Text('Rp${NumberFormat('#,###').format(totalSales)}'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('- Pengeluaran Hari Ini'),
              pw.Text('Rp${NumberFormat('#,###').format(totalExpense)}'),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('= Saldo Akhir Kas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Rp${NumberFormat('#,###').format(endCash)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
} 