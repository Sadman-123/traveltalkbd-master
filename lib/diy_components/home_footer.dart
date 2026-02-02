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
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text('$label - Coming soon'), duration: const Duration(seconds: 2)),
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
