import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared footer for WebHome and MobileHome.
class HomeFooter extends StatelessWidget {
  final bool isCompact;
  final void Function(String section)? onNavigate;

  const HomeFooter({super.key, this.isCompact = false, this.onNavigate});

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TravelContent>(
      future: TravelDataService.getContent(),
      builder: (context, snapshot) {
        final about = snapshot.data?.aboutInfo;
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/footer.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
          child: isCompact
              ? _buildCompactContent(context, about)
              : _buildContent(context, about),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AboutInfo? about) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 24 : 48,
            48,
            isNarrow ? 24 : 280,
            48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isNarrow
                  ? _buildStackedColumns(context, about)
                  : _buildMultiColumn(context, about),
              const SizedBox(height: 40),
              _SslRow(compact: isNarrow),
              const SizedBox(height: 32),
              _CopyrightBar(about: about),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMultiColumn(BuildContext context, AboutInfo? about) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _AboutColumn(about: about, onSocialTap: _launchUrl)),
        const SizedBox(width: 32),
        Expanded(child: _ServicesColumn(about: about)),
        const SizedBox(width: 32),
        Expanded(child: _LegalColumn(scaffoldContext: context)),
        const SizedBox(width: 32),
        Expanded(child: _ContactColumn(about: about)),
      ],
    );
  }

  Widget _buildStackedColumns(BuildContext context, AboutInfo? about) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AboutColumn(about: about, onSocialTap: _launchUrl),
        const SizedBox(height: 32),
        _ServicesColumn(about: about),
        const SizedBox(height: 24),
        _LegalColumn(scaffoldContext: context),
        const SizedBox(height: 24),
        _ContactColumn(about: about),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context, AboutInfo? about) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          _AboutColumn(about: about, onSocialTap: _launchUrl, compact: true),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MobileSectionCard(
                  child: _ServicesColumn(about: about, compact: true, alignStart: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MobileSectionCard(
                  child: _LegalColumn(scaffoldContext: context, compact: true, alignStart: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MobileSectionCard(
            child: _ContactColumn(about: about, compact: true, alignStart: true),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 24),
          _SslRow(compact: true),
          const SizedBox(height: 20),
          _CopyrightBar(about: about, compact: true),
        ],
      ),
    );
  }
}

class _MobileSectionCard extends StatelessWidget {
  final Widget child;

  const _MobileSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: child,
    );
  }
}

class _CopyrightBar extends StatelessWidget {
  final AboutInfo? about;
  final bool compact;

  const _CopyrightBar({this.about, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final name = about?.companyName ?? 'Travel Talk BD';
    return Center(
      child: Text(
        '© $year $name. All rights reserved.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}

class _AboutColumn extends StatelessWidget {
  final AboutInfo? about;
  final Future<void> Function(String?) onSocialTap;
  final bool compact;

  const _AboutColumn({required this.about, required this.onSocialTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final name = about?.companyName ?? 'Travel Talk BD';
    final tagline = about?.tagline ?? '';
    final socialLinks = about?.socialLinks ?? {};

    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (tagline.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            tagline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: compact ? 13 : 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          children: [
            if (socialLinks['facebook']?.toString().isNotEmpty == true)
              _SocialIcon(
                icon: FontAwesomeIcons.facebook,
                onTap: () => onSocialTap(socialLinks['facebook']?.toString()),
              ),
            if (socialLinks['instagram']?.toString().isNotEmpty == true)
              _SocialIcon(
                icon: FontAwesomeIcons.instagram,
                onTap: () => onSocialTap(socialLinks['instagram']?.toString()),
              ),
            if (socialLinks['whatsapp']?.toString().isNotEmpty == true)
              _SocialIcon(
                icon: FontAwesomeIcons.whatsapp,
                onTap: () => onSocialTap(socialLinks['whatsapp']?.toString()),
              ),
            if (socialLinks['twitter']?.toString().isNotEmpty == true)
              _SocialIcon(
                icon: FontAwesomeIcons.xTwitter,
                onTap: () => onSocialTap(socialLinks['twitter']?.toString()),
              ),
            if (socialLinks['linkedin']?.toString().isNotEmpty == true)
              _SocialIcon(
                icon: FontAwesomeIcons.linkedin,
                onTap: () => onSocialTap(socialLinks['linkedin']?.toString()),
              ),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Legal & support document keys and placeholder content for footer dialog.
class _LegalContent {
  static const Map<String, String> _documents = {
    'Terms & Conditions': '''
Welcome to Travel Talk BD. By using our website and services, you agree to these terms.

1. **Services** – We provide travel packages, visa processing, hotel and flight bookings, and related services. All bookings are subject to availability and our booking policy.

2. **User obligations** – You must provide accurate information, be at least 18 years old to book, and comply with applicable laws.

3. **Payments** – Prices are as displayed at booking. Payment terms and refunds are governed by our Refund Policy.

4. **Limitation** – We are not liable for circumstances beyond our control (e.g. weather, visa refusal, force majeure). Liability is limited to the amount paid for the service in question.

5. **Changes** – We may update these terms. Continued use after changes constitutes acceptance.

Contact us for any questions regarding these terms.
''',
    'Privacy Policy': '''
Travel Talk BD respects your privacy. This policy explains how we collect, use, and protect your data.

1. **Information we collect** – Name, email, phone, address, passport/details when you book or contact us. We may collect usage data on our website.

2. **How we use it** – To process bookings, send confirmations, respond to inquiries, improve our services, and comply with legal obligations.

3. **Sharing** – We may share data with partners (e.g. airlines, hotels) only as needed to fulfil your booking. We do not sell your personal data.

4. **Security** – We use appropriate technical and organisational measures to protect your data.

5. **Your rights** – You may request access, correction, or deletion of your data by contacting us.

6. **Cookies** – Our website may use cookies for functionality and analytics. You can manage cookie preferences in your browser.

For questions, contact us using the details in the footer.
''',
    'FAQ': '''
**How do I book a package?**  
Browse packages on our site, select your preferred option, and complete the booking form. We will confirm availability and payment details.

**What payment methods do you accept?**  
We accept bank transfer, bKash, and other methods as indicated at checkout. Details are provided after you submit a booking request.

**Can I cancel or modify my booking?**  
Cancellation and modification rules depend on the service and timing. See our Refund Policy and Booking Policy for details. Contact us for specific requests.

**Do you help with visas?**  
Yes. We offer visa processing for several countries. Submit an inquiry or select a visa package to get started.

**How can I contact support?**  
Use the contact details or chat option in the footer. We aim to respond within 24–48 hours on business days.
''',
    'Refund Policy': '''
Travel Talk BD refund policy:

1. **Eligibility** – Refunds depend on the type of service, timing of cancellation, and any non-refundable fees from third parties (airlines, hotels, etc.).

2. **Tour packages** – Cancellation deadlines and refund amounts will be stated at booking. Generally, earlier cancellation results in a higher refund; late cancellations may receive no refund.

3. **Visa fees** – Visa and processing fees are often non-refundable once submitted. We will inform you before payment.

4. **Requesting a refund** – Contact us in writing with your booking reference. We will process eligible refunds within a reasonable period (e.g. 14–30 days) to the original payment method where possible.

5. **Disputes** – If you are not satisfied, contact us first. We will try to resolve the matter fairly.

For your specific booking, please refer to the terms you received at the time of booking or contact us.
''',
    'Booking Policy': '''
Booking policy of Travel Talk BD:

1. **Reservations** – A booking is confirmed only after we confirm availability and (where applicable) receive the required payment or deposit.

2. **Pricing** – Prices are subject to change until confirmed. Quotes are valid for the period we specify.

3. **Deposits & payment** – Some bookings require a deposit to hold. Full payment deadlines will be communicated at booking. Non-payment by the deadline may result in cancellation.

4. **Documents** – You are responsible for valid passport, visa, and other travel documents. We can assist with visa processing where offered.

5. **Changes** – Modification requests are subject to availability and may incur fees. See terms for the specific product.

6. **Cancellation** – Cancellation rules and fees depend on the service and date of cancellation. See our Refund Policy.

Contact us for booking-related questions.
''',
  };

  static String getBody(String title) {
    final raw = _documents[title] ?? 'Content for $title will be available soon.';
    return raw.replaceAll(RegExp(r'\*\*'), '');
  }
}

class _LegalColumn extends StatelessWidget {
  final BuildContext scaffoldContext;
  final bool compact;
  final bool alignStart;

  const _LegalColumn({
    required this.scaffoldContext,
    this.compact = false,
    this.alignStart = false,
  });

  void _onLegalTap(String label) {
    showDialog<void>(
      context: scaffoldContext,
      builder: (context) => _LegalDocumentDialog(title: label, body: _LegalContent.getBody(label)),
    );
  }

  @override
  Widget build(BuildContext _) {
    final align = alignStart ? CrossAxisAlignment.start : (compact ? CrossAxisAlignment.center : CrossAxisAlignment.start);
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Legal & Support',
          style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _FooterLink(label: 'Terms & Conditions', onTap: () => _onLegalTap('Terms & Conditions')),
        _FooterLink(label: 'Privacy Policy', onTap: () => _onLegalTap('Privacy Policy')),
        _FooterLink(label: 'FAQ', onTap: () => _onLegalTap('FAQ')),
        _FooterLink(label: 'Refund Policy', onTap: () => _onLegalTap('Refund Policy')),
        _FooterLink(label: 'Booking Policy', onTap: () => _onLegalTap('Booking Policy')),
      ],
    );
  }
}

/// Dialog that shows a legal/support document title and scrollable body.
class _LegalDocumentDialog extends StatelessWidget {
  final String title;
  final String body;

  const _LegalDocumentDialog({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SelectableText(
                  body.trim(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FooterLink({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
        ),
      ),
    );
  }
}

class _ServicesColumn extends StatelessWidget {
  final AboutInfo? about;
  final bool compact;
  final bool alignStart;

  const _ServicesColumn({this.about, this.compact = false, this.alignStart = false});

  static const _defaultServices = [
    'Tour Packages',
    'Visa Processing',
    'Hotel Booking',
    'Flight Tickets',
    'Travel Insurance',
  ];

  @override
  Widget build(BuildContext context) {
    final services = about?.services ?? [];
    final items = services.isNotEmpty
        ? services.map((s) => s.title).where((t) => t.isNotEmpty).toList()
        : _defaultServices;
    final align = alignStart ? CrossAxisAlignment.start : (compact ? CrossAxisAlignment.center : CrossAxisAlignment.start);

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Our Services',
          style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...items.take(6).map((label) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
          ),
        )),
      ],
    );
  }
}

class _ContactColumn extends StatelessWidget {
  final AboutInfo? about;
  final bool compact;
  final bool alignStart;

  const _ContactColumn({this.about, this.compact = false, this.alignStart = false});

  @override
  Widget build(BuildContext context) {
    final contact = about?.contact ?? {};
    final align = alignStart ? CrossAxisAlignment.start : (compact ? CrossAxisAlignment.center : CrossAxisAlignment.start);

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Contact Us',
          style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Address first and more prominent
        if (contact['address'] != null) ...[
          _AddressRow(
            text: contact['address'].toString(),
            compact: compact,
          ),
          const SizedBox(height: 16),
        ],
        if (contact['phone'] != null) ...[
          _PhoneRow(text: contact['phone'].toString(), compact: compact),
          const SizedBox(height: 12),
        ],
        if (contact['email'] != null) ...[
          _ContactRow(icon: Icons.email_outlined, text: contact['email'].toString()),
        ],
      ],
    );
  }
}

/// Prominent phone row - larger text, more visible.
class _PhoneRow extends StatelessWidget {
  final String text;
  final bool compact;

  const _PhoneRow({required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.phone_outlined,
          color: Colors.white.withValues(alpha: 0.95),
          size: compact ? 20 : 22,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: compact ? 15 : 17,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Prominent address row - larger text, allows wrap, more visible.
class _AddressRow extends StatelessWidget {
  final String text;
  final bool compact;

  const _AddressRow({required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_outlined,
          color: Colors.white.withValues(alpha: 0.95),
          size: compact ? 20 : 22,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: compact ? 15 : 17,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SslRow extends StatelessWidget {
  final bool compact;

  const _SslRow({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/ssl.png',
          height: compact ? 90 : 140,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.lock, color: Colors.green.shade400, size: compact ? 48 : 64),
        ),
      ),
    );
  }
}
