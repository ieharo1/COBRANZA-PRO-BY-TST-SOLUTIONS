import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';
import '../../providers/payment_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _selectedClientId;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generar Reporte PDF',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona un cliente para generar su reporte completo',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    clients.when(
                      data: (clientList) {
                        if (clientList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('No hay clientes registrados'),
                          );
                        }
                        return DropdownButtonFormField<int>(
                          value: _selectedClientId,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Cliente',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: clientList.map((client) {
                            return DropdownMenuItem(
                              value: client.id,
                              child: Text(client.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedClientId = value);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedClientId == null || _isGenerating ? null : _generatePdf,
                        icon: _isGenerating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(_isGenerating ? 'Generando...' : 'Generar PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Información del Reporte',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person, 'Datos del cliente'),
                    _buildInfoRow(Icons.receipt_long, 'Lista de deudas'),
                    _buildInfoRow(Icons.payment, 'Pagos realizados'),
                    _buildInfoRow(Icons.account_balance, 'Saldo actual'),
                    _buildInfoRow(Icons.warning, 'Total vencido'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (_selectedClientId == null) return;

    setState(() => _isGenerating = true);

    try {
      final client = await ref.read(selectedClientProvider(_selectedClientId!).future);
      final debts = await ref.read(clientDebtsProvider(_selectedClientId!).future);
      final payments = await ref.read(clientPaymentsProvider(_selectedClientId!).future);

      if (client == null) throw Exception('Cliente no encontrado');

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            _buildPdfClientInfo(client),
            pw.SizedBox(height: 20),
            _buildPdfDebtsTable(debts),
            pw.SizedBox(height: 20),
            _buildPdfPaymentsTable(payments),
            pw.SizedBox(height: 20),
            _buildPdfSummary(debts, payments),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Reporte_${client.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'COBRANZA PRO',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
              pw.Text('BY TST SOLUTIONS', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Reporte de Cliente', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            AppConstants.pdfFooter,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfClientInfo(client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Datos del Cliente', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nombre: ${client.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    if (client.phone != null) pw.Text('Teléfono: ${client.phone}'),
                    if (client.address != null) pw.Text('Dirección: ${client.address}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDebtsTable(List debts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Historial de Deudas', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: ['Concepto', 'Monto', 'Pagado', 'Pendiente', 'Estado', 'Vence'],
          data: debts.map((d) => [
            d.concept,
            '\$${d.totalAmount.toStringAsFixed(2)}',
            '\$${d.paidAmount.toStringAsFixed(2)}',
            '\$${d.remainingAmount.toStringAsFixed(2)}',
            d.calculatedStatus.displayName,
            d.dueDate != null ? DateFormat('dd/MM/yyyy').format(d.dueDate!) : '-',
          ]).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPdfPaymentsTable(List payments) {
    if (payments.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Historial de Pagos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: ['Fecha', 'Monto', 'Método'],
          data: payments.map((p) => [
            DateFormat('dd/MM/yyyy').format(p.createdAt),
            '\$${p.amount.toStringAsFixed(2)}',
            p.method.displayName,
          ]).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummary(List debts, List payments) {
    final totalDebt = debts.fold<double>(0, (sum, d) => sum + d.totalAmount);
    final totalPaid = debts.fold<double>(0, (sum, d) => sum + d.paidAmount);
    final totalPending = totalDebt - totalPaid;
    final overdueDebts = debts.where((d) => d.isOverdue).toList();
    final totalOverdue = overdueDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Resumen', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Deudas: \$${totalDebt.toStringAsFixed(2)}'),
                    pw.Text('Total Pagado: \$${totalPaid.toStringAsFixed(2)}'),
                    pw.Text('Saldo Pendiente: \$${totalPending.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Deudas Vencidas: ${overdueDebts.length}'),
                    pw.Text('Total Vencido: \$${totalOverdue.toStringAsFixed(2)}', 
                      style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
