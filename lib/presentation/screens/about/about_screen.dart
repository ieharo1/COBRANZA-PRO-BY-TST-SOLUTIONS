import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'COBRANZA PRO',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'BY TST SOLUTIONS',
                      style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Versión 1.0.0',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
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
                        Icon(Icons.business, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'TST Solutions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '"Te Solucionamos Todo"',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Tecnología que funciona. Soluciones que escalan.',
                      style: TextStyle(fontSize: 14),
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
                        Icon(Icons.contact_mail, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Información de Contacto',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      icon: Icons.location_on,
                      label: 'Ubicación',
                      value: 'Quito - Ecuador',
                      onTap: () => _openUrl('https://www.google.com/maps/place/Quito,+Ecuador'),
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.phone,
                      label: 'WhatsApp',
                      value: AppConstants.whatsappNumber,
                      onTap: () => _openWhatsApp(),
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.send,
                      label: 'Telegram',
                      value: '@${AppConstants.telegramUsername}',
                      onTap: () => _openTelegram(),
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: AppConstants.email,
                      onTap: () => _openEmail(),
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.language,
                      label: 'Sitio Web',
                      value: AppConstants.website,
                      onTap: () => _openUrl(AppConstants.website),
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      value: 'Facebook',
                      onTap: () => _openUrl(AppConstants.facebook),
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.alternate_email,
                      label: 'Twitter/X',
                      value: '@SolutionsT95698',
                      onTap: () => _openUrl(AppConstants.twitter),
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
                        Icon(Icons.description, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Descripción',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'COBRANZA PRO es una aplicación móvil de gestión de deudas y cobros que te permite gestionar tus clientes, registrar deudas, controlar pagos y generar reportes PDF de forma profesional.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Diseñada especialmente para:\n• Comerciantes pequeños\n• Tiendas de barrio\n• Venta a crédito\n• Prestamistas informales\n• Emprendedores\n• Distribuidores\n• Técnicos que cobran por servicio',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2026 COBRANZA PRO BY TST SOLUTIONS',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Todos los derechos reservados',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = AppConstants.whatsappNumber.replaceAll('+', '').replaceAll(' ', '');
    final url = 'https://wa.me/$phone';
    await _openUrl(url);
  }

  Future<void> _openTelegram() async {
    final url = 'https://t.me/${AppConstants.telegramUsername}';
    await _openUrl(url);
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.email,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
