import 'package:flutter/material.dart';
import 'logo_flor.dart';

/// Banner "EventBQ Premium" (se repite en Inicio y Explorar).
class BannerPremium extends StatelessWidget {
  final VoidCallback? onExplorar;

  const BannerPremium({super.key, this.onExplorar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF14105E), Color(0xFF5B2A55)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              LogoFlor(tamano: 22, color: Color(0xFFC77DFF)),
              SizedBox(width: 8),
              Text(
                'EventBQ Premium',
                style: TextStyle(
                  color: Color(0xFFE7C6FF),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Descubre todos los beneficios exclusivos\npara asistentes y organizadores',
            style: TextStyle(color: Color(0xFFE7C6FF), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFF7A8D4), Color(0xFFB79CFF)],
              ),
            ),
            child: TextButton(
              onPressed: onExplorar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text(
                'Explorar pases',
                style: TextStyle(
                  color: Color(0xFF14105E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
