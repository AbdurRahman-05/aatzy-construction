import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:construction_app/core/widgets/bento.dart';

/// Help & Support — bento layout.
/// Contact actions open the phone dialer, WhatsApp or the email app.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _supportPhone = '+918122558115';
  static const _supportPhoneDisplay = '+91 81225 58115';
  static const _supportEmail = 'support@connectzy.com';

  static const _faqs = [
    (
      q: 'How do I request a quote?',
      a: 'Create a project from the home screen (New project). Verified partners in your city and category get notified and send you quotes, which you can compare side by side under Compare quotes.',
    ),
    (
      q: 'Are partners verified?',
      a: 'Yes. Registration details, including PAN, Aadhaar and business documents, are reviewed by our team before a partner gets the Verified badge.',
    ),
    (
      q: 'What is the cost estimator?',
      a: 'It projects material, labour and approval costs from your plot size, building type, location and finish level, so you know a realistic budget before you ask for quotes.',
    ),
    (
      q: 'How do I track my project?',
      a: 'Once you accept a quote, the project moves to tracking. Open it from My projects to see stages, tasks, updates and photos from your partner.',
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri, String failMessage) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }

  void _call() => _launch(Uri(scheme: 'tel', path: _supportPhone), 'Could not open the dialer. Call $_supportPhoneDisplay.');

  void _whatsapp() => _launch(
        Uri.parse('https://wa.me/${_supportPhone.replaceAll('+', '')}?text=${Uri.encodeComponent('Hi Connectzy support, I need help with ')}'),
        'Could not open WhatsApp. Message $_supportPhoneDisplay.',
      );

  void _email({String subject = 'Connectzy support request', String body = ''}) => _launch(
        Uri(
          scheme: 'mailto',
          path: _supportEmail,
          query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
        ),
        'Could not open your email app. Write to $_supportEmail.',
      );

  void _sendMessage() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    _email(
      subject: 'Support request from $name',
      body: '${_messageController.text.trim()}\n\n— $name',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BentoAppBar(title: Text('Help & support')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
            children: [
              // Hero
              BentoCard(
                gradient: Bento.inkGradient,
                padding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    const Positioned(right: -50, top: -60, child: BentoGlow(size: 190)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BentoPill(
                            label: 'WE\'RE HERE TO HELP',
                            color: Bento.accentLight,
                            background: Bento.accentLight.withValues(alpha: 0.14),
                            icon: Icons.support_agent_rounded,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'How can we help\nyou today?',
                            style: TextStyle(color: Colors.white, fontSize: 24, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -0.7),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Support hours: Mon – Fri · 9 AM – 6 PM',
                            style: TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Bento.gap),

              // Quick contact tiles
              Row(
                children: [
                  Expanded(child: _contactTile(dark, Icons.call_rounded, 'Call', Bento.accent, _call)),
                  const SizedBox(width: Bento.gap),
                  Expanded(child: _contactTile(dark, Icons.chat_rounded, 'WhatsApp', const Color(0xFF22C55E), _whatsapp)),
                  const SizedBox(width: Bento.gap),
                  Expanded(child: _contactTile(dark, Icons.mail_rounded, 'Email', Bento.violet, () => _email())),
                ],
              ),
              const SizedBox(height: 28),

              const BentoSectionHeader(title: 'Common questions'),
              for (final faq in _faqs) ...[
                BentoCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor: Bento.accentText(dark),
                      leading: BentoIconBubble(icon: Icons.help_rounded, color: Bento.accent, size: 36),
                      title: Text(
                        faq.q,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                      ),
                      children: [
                        Text(faq.a, style: TextStyle(fontSize: 13, color: Bento.muted(dark), height: 1.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 18),

              const BentoSectionHeader(title: 'Send us a message', subtitle: 'Opens your email app with the message ready'),
              BentoCard(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_rounded)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'How can we help?',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe your request' : null,
                      ),
                      const SizedBox(height: 16),
                      BentoButton(label: 'Send message', icon: Icons.send_rounded, expand: true, onTap: _sendMessage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '$_supportEmail · $_supportPhoneDisplay',
                  style: TextStyle(fontSize: 12, color: Bento.muted(dark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactTile(bool dark, IconData icon, String label, Color color, VoidCallback onTap) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: onTap,
      child: Column(
        children: [
          BentoIconBubble(icon: icon, color: color, size: 44),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Bento.text(dark))),
        ],
      ),
    );
  }
}
