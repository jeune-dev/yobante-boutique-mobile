import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../../injection_container.dart';

/// Cloche de notifications avec pastille du nombre de non-lues.
///
/// Le compteur est tenu par NotificationService et partagé par toutes les
/// interfaces : la pastille se met à jour sans que l'écran ait à s'en occuper.
class ClocheNotifications extends StatelessWidget {
  final VoidCallback onTap;
  final Color couleurIcone;
  final Color couleurFond;

  const ClocheNotifications({
    super.key,
    required this.onTap,
    this.couleurIcone = const Color(0xFF163A9E),
    this.couleurFond = const Color(0xFFF5F7FB),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: couleurFond,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_none_rounded, color: couleurIcone, size: 22),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: ValueListenableBuilder<int>(
                valueListenable: sl<NotificationService>().nonLues,
                builder: (context, nombre, _) {
                  if (nombre == 0) return const SizedBox.shrink();
                  // Au-delà de 99, le nombre exact n'apporte plus rien.
                  final texte = nombre > 99 ? '99+' : '$nombre';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      texte,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
