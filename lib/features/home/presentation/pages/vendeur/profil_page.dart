import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';
import 'package:yobante/core/routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../../injection_container.dart';
import '../../../../compte/presentation/bloc/compte_bloc.dart';
import '../../../../compte/presentation/bloc/compte_event.dart';
import '../../../../compte/presentation/bloc/compte_state.dart';
import '../../../../compte/presentation/pages/edit_profil_page.dart';
import '../../../../compte/presentation/pages/change_password_page.dart';
import '../../../../abonnement/presentation/pages/mon_abonnement_page.dart';
import '../../../../avis/presentation/pages/avis_recus_page.dart';
import '../../../../promotions/presentation/pages/mes_promotions_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../../vendeur/domain/usecases/get_vendeur_tableau_bord.dart';
import '../../../../vendeur/presentation/widgets/statut_chip.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const greenText  = Color(0xFF1E3A8A);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const surface    = Color(0xFFF7F9FC);
  static const border     = Color(0xFFEDF0F7);
  static const label      = Color(0xFF9AA3B2);
  static const sub        = Color(0xFF6B7280);
  static const placeholder= Color(0xFFC2C9D6);
  static const red        = Color(0xFFE53935);
  static const redLight   = Color(0xFFFEF3F2);
  static const blue       = Color(0xFF1976D2);
  static const blueLight  = Color(0xFFE3F2FD);
  static const orange     = Color(0xFFFF8F00);
  static const orangeLight= Color(0xFFFFF3E0);
}

// ══════════════════════════════════════════════════════════════════════════════
class ProfilPage extends StatefulWidget {
  final User? user;
  const ProfilPage({super.key, this.user});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  // Préférences
  bool _notifsProduits   = true;
  bool _notifsCommandes  = true;
  bool _twoFactor        = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  late final CompteBloc _compteBloc = sl<CompteBloc>();
  User? _liveUser;

  // KPIs réels (GET /vendeurs/statistiques)
  int    _nbProduits = 0;
  int    _nbFavoris  = 0;
  String _note       = '—';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _compteBloc.add(LoadCompte());
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final result = await sl<GetVendeurTableauBord>().statsProduits();
      if (!mounted) return;
      result.fold(
        (_) {},
        (stats) => setState(() {
          _nbProduits = (stats['total'] as num?)?.toInt() ?? 0;
          _nbFavoris  = (stats['enAttente'] as num?)?.toInt() ?? 0;
          _note       = ((stats['valides'] as num?)?.toInt() ?? 0).toString();
        }),
      );
    } catch (_) {/* on garde les valeurs par défaut */}
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _compteBloc.close();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  User? get _user => _liveUser ?? widget.user;

  Future<void> _onEditProfil() async {
    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(builder: (_) => EditProfilePage(user: _user)),
    );
    if (updated != null) setState(() => _liveUser = updated);
  }

  void _onChangerMotDePasse() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  String get _nomComplet {
    if (_user == null) return 'Invité';
    return '${_user!.prenom ?? ''} ${_user!.nom ?? ''}'.trim();
  }

  String get _initiales {
    if (_user == null) return '?';
    final p = _user!.prenom?.isNotEmpty == true ? _user!.prenom![0] : '';
    final n = _user!.nom?.isNotEmpty == true    ? _user!.nom![0]    : '';
    return '$p$n'.toUpperCase();
  }

  String get _email    => _user?.email     ?? 'Non renseigné';
  String get _telephone=> _user?.telephone ?? 'Non renseigné';
  String get _adresse  => _user?.adresse   ?? 'Non renseignée';

  void _onLogout() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: VendeurCouleurs.rouge,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Se déconnecter ?',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vous devrez vous reconnecter pour accéder à votre compte.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.loginRoute, (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendeurCouleurs.rouge,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Se déconnecter',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompteBloc, CompteState>(
      bloc: _compteBloc,
      listener: (context, state) {
        if (state is CompteLoaded) {
          setState(() => _liveUser = state.user);
        } else if (state is CompteAccountDeleted) {
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.loginRoute, (_) => false,
          );
        } else if (state is CompteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                child: Column(
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 10),
                    _buildBoutiqueCard(),
                    const SizedBox(height: 10),
                    _buildSecuriteCard(),
                    const SizedBox(height: 10),
                    _buildPreferencesCard(),
                    const SizedBox(height: 10),
                    _buildAideCard(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                    const SizedBox(height: 12),
                    _buildVersion(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      color: _C.black,
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -50, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -10,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + bouton éditer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Retour affiché seulement si la page a été empilée :
                          // elle s'ouvre depuis l'avatar de l'entête vendeur.
                          if (Navigator.of(context).canPop())
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 36, height: 36,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: _C.white, size: 15),
                              ),
                            ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'Mon ',
                                style: GoogleFonts.sora(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  color: _C.white, letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Profil',
                                style: GoogleFonts.sora(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  color: _C.green, letterSpacing: -0.5,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _onEditProfil,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: _C.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar + infos
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: _C.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _C.green.withOpacity(0.35),
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _initiales,
                                style: GoogleFonts.sora(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: _C.green,
                                ),
                              ),
                            ),
                          ),
                          // Badge vérifié
                          Positioned(
                            bottom: -2, right: -2,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _C.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _C.black, width: 2),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: _C.white, size: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nomComplet,
                              style: GoogleFonts.sora(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: _C.white, letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _email,
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: _C.label,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Badge rôle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _C.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _C.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined,
                                      color: _C.green, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    _user?.role ?? 'Utilisateur',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: _C.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      Expanded(child: _buildStatBox(_nbProduits.toString(), 'Produits')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatBox(_nbFavoris.toString(), 'Favoris')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatBox(_note, 'Note moy.')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.sora(
              fontSize: 18, fontWeight: FontWeight.w800, color: _C.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10, color: _C.label, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Informations personnelles ──────────────────────────────────────────────
  Widget _buildInfoCard() {
    return _SectionCard(
      iconBg: _C.greenLight,
      icon: Icons.person_outline_rounded,
      iconColor: _C.green,
      title: 'Informations personnelles',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.person_outline_rounded,
          label: _nomComplet,
          sub: 'Prénom & Nom',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.email_outlined,
          label: _email,
          sub: 'Adresse e-mail',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.phone_outlined,
          label: _telephone,
          sub: 'Téléphone',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.location_on_outlined,
          label: _adresse,
          sub: 'Adresse',
          onTap: () {},
          isLast: true,
        ),
      ],
    );
  }

  // ── Mon activité (abonnement, avis, promotions, notifs, messages) ─────────
  Widget _buildBoutiqueCard() {
    return _SectionCard(
      iconBg: _C.greenLight,
      icon: Icons.storefront_outlined,
      iconColor: _C.green,
      title: 'Mon activité',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.workspace_premium_outlined,
          label: 'Mon abonnement',
          sub: 'Statut et renouvellement',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MonAbonnementPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.star_border_rounded,
          label: 'Avis reçus',
          sub: 'Avis clients et réponses',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AvisRecusPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.local_offer_outlined,
          label: 'Mes promotions',
          sub: 'Créer et gérer vos promotions',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MesPromotionsPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          sub: 'Vos alertes récentes',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Messages',
          sub: 'Vos conversations avec les acheteurs',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConversationsPage()),
          ),
          isLast: true,
        ),
      ],
    );
  }

  // ── Sécurité ───────────────────────────────────────────────────────────────
  Widget _buildSecuriteCard() {
    return _SectionCard(
      iconBg: _C.blueLight,
      icon: Icons.shield_outlined,
      iconColor: _C.blue,
      title: 'Sécurité',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.lock_outline_rounded,
          label: 'Mot de passe',
          sub: 'Modifier votre mot de passe',
          onTap: _onChangerMotDePasse,
        ),
        _RowToggle(
          iconBg: _C.surface,
          icon: Icons.security_outlined,
          label: 'Authentification 2FA',
          sub: _twoFactor ? 'Activé' : 'Non activé',
          value: _twoFactor,
          onChanged: (v) => setState(() => _twoFactor = v),
        ),
        _RowItem(
          iconBg: _C.redLight,
          icon: Icons.delete_outline_rounded,
          label: 'Supprimer mon compte',
          sub: 'Suppression définitive de vos données',
          onTap: _onSupprimerCompte,
          isLast: true,
        ),
      ],
    );
  }

  // ── Suppression de compte (irréversible) ───────────────────────────────────
  Future<void> _onSupprimerCompte() async {
    final confirme = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _C.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Supprimer votre compte ?',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Cette action est irréversible : votre profil, votre boutique et vos données personnelles seront supprimés. Si vous avez des commandes en cours, vous devrez d\'abord les finaliser.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _C.sub,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Supprimer définitivement',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _C.sub,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirme == true && mounted) {
      _compteBloc.add(DeleteAccountRequested());
    }
  }

  // ── Préférences ────────────────────────────────────────────────────────────
  Widget _buildPreferencesCard() {
    return _SectionCard(
      iconBg: _C.orangeLight,
      icon: Icons.notifications_outlined,
      iconColor: _C.orange,
      title: 'Préférences',
      children: [
        _RowToggle(
          iconBg: _C.surface,
          icon: Icons.restaurant_outlined,
          label: 'Alertes nouveaux produits',
          sub: _notifsProduits ? 'Activées' : 'Désactivées',
          value: _notifsProduits,
          onChanged: (v) => setState(() => _notifsProduits = v),
        ),
        _RowToggle(
          iconBg: _C.surface,
          icon: Icons.shopping_bag_outlined,
          label: 'Suivi de commandes',
          sub: _notifsCommandes ? 'Activé' : 'Désactivé',
          value: _notifsCommandes,
          onChanged: (v) => setState(() => _notifsCommandes = v),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.language_outlined,
          label: 'Langue',
          sub: 'Français',
          onTap: () {},
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFDDE3EF)),
            ),
            child: Text(
              'FR',
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: _C.sub,
              ),
            ),
          ),
          isLast: true,
        ),
      ],
    );
  }

  // ── Aide & Support ─────────────────────────────────────────────────────────
  Widget _buildAideCard() {
    return _SectionCard(
      iconBg: const Color(0xFFF3E5F5),
      icon: Icons.help_outline_rounded,
      iconColor: const Color(0xFF7B1FA2),
      title: 'Aide & Support',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.help_outline_rounded,
          label: 'Centre d\'aide',
          sub: 'FAQ et guides',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Nous contacter',
          sub: 'Support client',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.star_border_rounded,
          label: 'Noter l\'application',
          sub: 'Votre avis compte',
          onTap: () {},
          isLast: true,
        ),
      ],
    );
  }

  // ── Bouton déconnexion ─────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _onLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.redLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.red.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _C.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: _C.red, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Se déconnecter',
                style: GoogleFonts.sora(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _C.red,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _C.red, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Version ────────────────────────────────────────────────────────────────
  Widget _buildVersion() {
    return Center(
      child: Text(
        'Yobante Boutique v1.0.0',
        style: GoogleFonts.dmSans(
          fontSize: 11, color: _C.placeholder,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG DÉCONNEXION
// ══════════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════════
// COMPOSANTS RÉUTILISABLES
// ══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final List<Widget> children;

  const _SectionCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        children: [
          // En-tête section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: _C.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F7FB)),
          ...children,
        ],
      ),
    );
  }
}

// ── Ligne standard avec chevron ────────────────────────────────────────────────
class _RowItem extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final String   label;
  final String   sub;
  final VoidCallback onTap;
  final bool     isLast;
  final Widget?  trailing;

  const _RowItem({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.isLast   = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: Color(0xFFF5F7FB)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: _C.label),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _C.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.dmSans(
                      fontSize: 11, color: _C.label,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else
              const Icon(Icons.chevron_right_rounded,
                  color: _C.placeholder, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Ligne avec toggle switch ───────────────────────────────────────────────────
class _RowToggle extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final String   label;
  final String   sub;
  final bool     value;
  final ValueChanged<bool> onChanged;
  final bool     isLast;

  const _RowToggle({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(color: Color(0xFFF5F7FB)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _C.label),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _C.black,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: value ? _C.green : _C.label,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Switch custom
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44, height: 24,
              decoration: BoxDecoration(
                color: value ? _C.green : const Color(0xFFDDE3EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _C.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}