import 'dart:io';

import 'package:yobante/core/routes/app_router.dart';
import 'package:yobante/features/auth/presentation/widgets/PasswordTextField.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

// ─── Palette (identique LoginPage) ───────────────────────────────────────────
class _C {
  static const green       = Color(0xFF163A9E);
  static const greenLight  = Color(0xFFEAEEF9);
  static const greenBorder = Color(0xFFC3D0EE);
  static const greenText   = Color(0xFF1E3A8A);
  static const black       = Color(0xFF1A1A1A);
  static const white       = Color(0xFFFFFFFF);
  static const bg          = Color(0xFFF5F7FB);
  static const surface     = Color(0xFFF7F9FC);
  static const border      = Color(0xFFDDE3EF);
  static const label       = Color(0xFF1A1A1A);
  static const placeholder = Color(0xFFC2C9D6);
  static const sub         = Color(0xFF6B7280);
  static const divider     = Color(0xFFEDF0F7);
  static const error       = Color(0xFFE53935);
  static const orange      = Color(0xFFFF9800);
}

// ─── Rôle ─────────────────────────────────────────────────────────────────────
enum _Role { acheteur, vendeur }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // ── Contrôleurs champs communs ────────────────────────────────────────────
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _phoneController     = TextEditingController();
  final _addressController   = TextEditingController();
  final _passwordController  = TextEditingController();

  // ── Contrôleurs champs vendeur ────────────────────────────────────────────
  final _shopNameController        = TextEditingController();
  final _shopDescController        = TextEditingController();
  final _shopLocationController    = TextEditingController();
  final _shopOpenController        = TextEditingController();
  final _shopCloseController       = TextEditingController();
  final _shopPhoneController       = TextEditingController();

  // ── Focus nodes ───────────────────────────────────────────────────────────
  final _firstNameFocus     = FocusNode();
  final _lastNameFocus      = FocusNode();
  final _emailFocus         = FocusNode();
  final _addressFocus       = FocusNode();
  final _passwordFocus      = FocusNode();
  final _shopNameFocus      = FocusNode();
  final _shopDescFocus      = FocusNode();
  final _shopLocationFocus  = FocusNode();
  final _shopOpenFocus      = FocusNode();
  final _shopCloseFocus     = FocusNode();
  final _shopPhoneFocus     = FocusNode();

  final _formKey = GlobalKey<FormState>();

  String? _completePhoneNumber;
  File?   _profileImage;
  _Role   _selectedRole = _Role.acheteur;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _masterCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _vendeurCtrl;   // pour les champs vendeur
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _cardFade;
  late Animation<Offset>   _cardSlide;
  late Animation<double>   _vendeurFade;
  late Animation<double>   _vendeurScale;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _vendeurCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _fadeAnim  = CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOutCubic));

    _cardFade  = CurvedAnimation(parent: _cardCtrl,  curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _vendeurFade  = CurvedAnimation(parent: _vendeurCtrl, curve: Curves.easeOut);
    _vendeurScale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _vendeurCtrl, curve: Curves.easeOutBack));

    _masterCtrl.forward();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _cardCtrl.forward();
    });

    // Ecoute focus
    for (final n in [
      _firstNameFocus, _lastNameFocus, _emailFocus, _addressFocus,
      _passwordFocus, _shopNameFocus, _shopDescFocus, _shopLocationFocus,
      _shopOpenFocus, _shopCloseFocus, _shopPhoneFocus,
    ]) {
      n.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController, _lastNameController, _emailController,
      _phoneController, _addressController, _passwordController,
      _shopNameController, _shopDescController, _shopLocationController,
      _shopOpenController, _shopCloseController, _shopPhoneController,
    ]) { c.dispose(); }

    for (final n in [
      _firstNameFocus, _lastNameFocus, _emailFocus, _addressFocus,
      _passwordFocus, _shopNameFocus, _shopDescFocus, _shopLocationFocus,
      _shopOpenFocus, _shopCloseFocus, _shopPhoneFocus,
    ]) { n.dispose(); }

    _masterCtrl.dispose();
    _cardCtrl.dispose();
    _vendeurCtrl.dispose();
    super.dispose();
  }

  // ── Sélection photo profil ────────────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // ── Changement de rôle ────────────────────────────────────────────────────
  void _onRoleChanged(_Role role) {
    setState(() => _selectedRole = role);
    if (role == _Role.vendeur) {
      _vendeurCtrl.forward();
    } else {
      _vendeurCtrl.reverse();
    }
  }

  // ── Sélection heure ───────────────────────────────────────────────────────
  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.green,
            onPrimary: _C.white,
            onSurface: _C.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = picked.format(context);
    }
  }

  // ── Soumission ────────────────────────────────────────────────────────────
  // ⚠️ Sécurité : l'inscription publique crée TOUJOURS un compte client
  // (rôle « Acheteur »). Un profil « Vendeur » ne peut être créé que par un
  // super admin depuis le dashboard web — jamais via cette page.
  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _lastNameController.text.trim(),
          prenom: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          mot_de_passe: _passwordController.text,
          adresse: _addressController.text.trim(),
          telephone: _completePhoneNumber ?? _phoneController.text.trim(),
          role: 'Acheteur', // forcé : impossible de s'inscrire comme vendeur
          nomBoutique: null,
          description: null,
          localisation: null,
          heureOuverture: null,
          heureFermeture: null,
          telephoneBoutique: null,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev != curr,
        listener: (context, state) {
          if (state is AuthSuccess) {
            FocusScope.of(context).unfocus();
            showToast(context, 'Inscription réussie',
                'Bienvenue sur Yobante Boutique !',
                ToastificationType.success);
            context.read<AuthBloc>().add(ResetAuthState());
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.acheteurRoute,
              (_) => false,
            );
          } else if (state is AuthFailure) {
            showToast(context, "Échec de l'inscription", state.message,
                ToastificationType.error);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildTopBar(),
                          const SizedBox(height: 24),
                          _buildHeader(),
                          const SizedBox(height: 28),
                          // ── Photo profil ──────────────────────────────
                          _buildProfilePicker(),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _cardFade,
                            child: SlideTransition(
                              position: _cardSlide,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Prénom / Nom ──────────────────
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildField(
                                            label: 'Prénom',
                                            hint: 'Jane',
                                            controller: _firstNameController,
                                            focusNode: _firstNameFocus,
                                            icon: Icons.person_outline_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildField(
                                            label: 'Nom',
                                            hint: 'Doe',
                                            controller: _lastNameController,
                                            focusNode: _lastNameFocus,
                                            icon: Icons.badge_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Téléphone ─────────────────────
                                    _buildPhoneField(),
                                    const SizedBox(height: 16),

                                    // ── E-mail ────────────────────────
                                    _buildField(
                                      label: 'Adresse e-mail',
                                      hint: 'exemple@gmail.com',
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Champ requis';
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                          return 'E-mail invalide';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Mot de passe ──────────────────
                                    _buildPasswordField(),
                                    const SizedBox(height: 16),

                                    // ── Adresse ───────────────────────
                                    _buildField(
                                      label: 'Adresse complète',
                                      hint: 'Dakar, Sénégal',
                                      controller: _addressController,
                                      focusNode: _addressFocus,
                                      icon: Icons.location_on_outlined,
                                    ),
                                    const SizedBox(height: 20),

                                    // Yobante Boutique = application 100% client :
                                    // l'inscription crée toujours un compte client
                                    // (rôle « Acheteur »). Le sélecteur de rôle et la
                                    // section boutique/vendeur sont volontairement
                                    // retirés — la gestion se fait via le dashboard web.
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitButton(isLoading),
                          const SizedBox(height: 22),
                          _buildLoginLink(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS INTERNES
  // ══════════════════════════════════════════════════════════════════════════

  // ── Fond décoratif ─────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100, left: -80,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [
                const Color(0xFF163A9E).withOpacity(0.06),
                const Color(0xFF163A9E).withOpacity(0.0),
              ]),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -120, right: -90,
          child: Container(
            width: 320, height: 320,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [
                const Color(0xFF163A9E).withOpacity(0.07),
                const Color(0xFF163A9E).withOpacity(0.0),
              ]),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Motif de points
        Positioned(
          top: 60, right: 20,
          child: Opacity(
            opacity: 0.10,
            child: SizedBox(
              width: 80, height: 80,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8,
                ),
                itemCount: 25,
                itemBuilder: (_, __) => Container(
                  decoration: const BoxDecoration(
                    color: _C.green, shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ── Barre du haut ──────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _C.black),
          ),
        ),
      ],
    );
  }

  // ── En-tête ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _C.greenLight,
            border: Border.all(color: _C.greenBorder, width: 1.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.2), shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: _C.green, shape: BoxShape.circle,
                  ),
                ),
              ]),
              const SizedBox(width: 8),
              Text(
                'Inscription gratuite',
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _C.greenText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Créez votre\n',
              style: GoogleFonts.sora(
                fontSize: 30, fontWeight: FontWeight.w800,
                color: _C.black, height: 1.2, letterSpacing: -1.0,
              ),
            ),
            TextSpan(
              text: 'compte !',
              style: GoogleFonts.sora(
                fontSize: 30, fontWeight: FontWeight.w800,
                color: _C.green, height: 1.2, letterSpacing: -1.0,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
          'Remplissez vos informations pour\naccéder à la plateforme.',
          style: GoogleFonts.dmSans(
            fontSize: 14, color: _C.sub, height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Photo de profil ────────────────────────────────────────────────────────
  Widget _buildProfilePicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.surface,
                    border: Border.all(
                      color: _profileImage != null ? _C.green : _C.border,
                      width: _profileImage != null ? 2.5 : 1.5,
                    ),
                    image: _profileImage != null
                        ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _profileImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 32, color: _C.placeholder),
                    ],
                  )
                      : null,
                ),
                // Bouton + en bas à droite
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: _C.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: _C.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photo de profil',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _C.label,
            ),
          ),
          if (_profileImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Photo sélectionnée ✓',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sélecteur de rôle ──────────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mon rôle', required: true),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: _Role.acheteur,
                icon: Icons.shopping_bag_outlined,
                title: 'Acheteur',
                subtitle: 'J\'achete des produits',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                role: _Role.vendeur,
                icon: Icons.storefront_outlined,
                title: 'Vendeur',
                subtitle: 'Je vends mes produits',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required _Role role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _onRoleChanged(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _C.greenLight : _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _C.green : _C.border,
            width: selected ? 2.0 : 1.5,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: _C.green.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? _C.green : _C.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected ? _C.white : _C.label,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _C.green : _C.surface,
                    border: Border.all(
                      color: selected ? _C.green : _C.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: _C.white, size: 12)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? _C.greenText : _C.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: selected ? _C.greenText : _C.sub,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section champs vendeur (animée) ────────────────────────────────────────
  Widget _buildVendeurSection() {
    return FadeTransition(
      opacity: _vendeurFade,
      child: ScaleTransition(
        scale: _vendeurScale,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _selectedRole == _Role.vendeur
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.greenLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.greenBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        color: _C.green, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Informations de votre boutique',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.greenText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Nom boutique
              _buildField(
                label: 'Nom de la boutique',
                hint: 'Nom de votre boutique',
                controller: _shopNameController,
                focusNode: _shopNameFocus,
                icon: Icons.store_outlined,
                isVendeur: true,
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextAreaField(
                label: 'Description',
                hint: 'Décrivez votre boutique en quelques mots…',
                controller: _shopDescController,
                focusNode: _shopDescFocus,
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              // Localisation
              _buildField(
                label: 'Localisation',
                hint: 'Plateau, Dakar',
                controller: _shopLocationController,
                focusNode: _shopLocationFocus,
                icon: Icons.place_outlined,
                isVendeur: true,
              ),
              const SizedBox(height: 16),

              // Heure ouverture / fermeture côte à côte
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Ouverture',
                      hint: '08:00',
                      controller: _shopOpenController,
                      focusNode: _shopOpenFocus,
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Fermeture',
                      hint: '22:00',
                      controller: _shopCloseController,
                      focusNode: _shopCloseFocus,
                      icon: Icons.nights_stay_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Téléphone boutique
              _buildField(
                label: 'Téléphone boutique',
                hint: '+221 77 000 00 00',
                controller: _shopPhoneController,
                focusNode: _shopPhoneFocus,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isVendeur: true,
              ),
              const SizedBox(height: 4),
            ],
          )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ── Label ──────────────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String text,
      {bool required = false, bool isVendeur = false}) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isVendeur ? _C.greenText : _C.label,
            letterSpacing: 0.8,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _C.error,
            ),
          ),
      ],
    );
  }

  // ── Champ texte générique ──────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    bool isVendeur = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required: true, isVendeur: isVendeur),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.transparent,
              error: Colors.transparent,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 52,
            decoration: BoxDecoration(
              color: focused ? _C.white : _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused
                    ? (isVendeur ? _C.green : _C.green)
                    : (isVendeur ? _C.greenBorder : _C.border),
                width: focused ? 2.0 : 1.5,
              ),
              boxShadow: focused
                  ? [
                BoxShadow(
                  color: _C.green.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(focused),
                    size: 18,
                    color: focused ? _C.green : _C.placeholder,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    cursorColor: _C.green,
                    style: GoogleFonts.dmSans(
                      color: _C.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.dmSans(
                        color: _C.placeholder, fontSize: 14,
                      ),
                      border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.zero),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.zero),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.zero),
                      errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.zero),
                      focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.zero),
                      filled: false,
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.only(right: 14, top: 14, bottom: 14),
                      errorStyle:
                      const TextStyle(height: 0, fontSize: 0),
                    ),
                    validator: validator ??
                            (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Zone de texte (description) ────────────────────────────────────────────
  Widget _buildTextAreaField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
  }) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required: true, isVendeur: true),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.transparent,
              error: Colors.transparent,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: focused ? _C.white : _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused ? _C.green : _C.greenBorder,
                width: focused ? 2.0 : 1.5,
              ),
              boxShadow: focused
                  ? [
                BoxShadow(
                  color: _C.green.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Icon(icon, size: 18,
                        color: focused ? _C.green : _C.placeholder),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 3,
                      minLines: 3,
                      cursorColor: _C.green,
                      style: GoogleFonts.dmSans(
                        color: _C.black, fontSize: 14, fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: GoogleFonts.dmSans(
                            color: _C.placeholder, fontSize: 14),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.zero),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.zero),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.zero),
                        errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.zero),
                        focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.zero),
                        filled: false,
                        contentPadding: const EdgeInsets.only(
                            right: 14, top: 12, bottom: 12),
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Champ heure (TimePicker) ───────────────────────────────────────────────
  Widget _buildTimeField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
  }) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required: true, isVendeur: true),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickTime(controller),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 52,
            decoration: BoxDecoration(
              color: controller.text.isNotEmpty ? _C.greenLight : _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: controller.text.isNotEmpty ? _C.green : _C.greenBorder,
                width: controller.text.isNotEmpty ? 2.0 : 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(icon, size: 18,
                    color: controller.text.isNotEmpty
                        ? _C.green
                        : _C.placeholder),
                const SizedBox(width: 10),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, val, __) => Text(
                      val.text.isEmpty ? hint : val.text,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: val.text.isEmpty ? _C.placeholder : _C.black,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.access_time_rounded,
                      size: 16, color: _C.placeholder),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Champ téléphone ────────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Téléphone', required: true),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _C.green,
              error: Colors.transparent,
            ),
          ),
          child: IntlPhoneField(
            controller: _phoneController,
            initialCountryCode: 'SN',
            cursorColor: _C.green,
            style: GoogleFonts.dmSans(
              color: _C.black, fontSize: 14, fontWeight: FontWeight.w500,
            ),
            dropdownTextStyle: GoogleFonts.dmSans(
              color: _C.black, fontSize: 14, fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '77 123 45 67',
              hintStyle: GoogleFonts.dmSans(color: _C.placeholder, fontSize: 14),
              filled: true,
              fillColor: _C.surface,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _C.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _C.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _C.green, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _C.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _C.error, width: 1.5),
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            onChanged: (phone) {
              setState(() => _completePhoneNumber = phone.completeNumber);
            },
            validator: (phone) {
              if (phone == null || phone.number.isEmpty) return 'Numéro requis';
              if (phone.number.length < 7) return 'Numéro invalide';
              return null;
            },
          ),
        ),
      ],
    );
  }

  // ── Champ mot de passe ─────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    final focused = _passwordFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mot de passe', required: true),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            color: focused ? _C.white : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? _C.green : _C.border,
              width: focused ? 2.0 : 1.5,
            ),
            boxShadow: focused
                ? [
              BoxShadow(
                color: _C.green.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.lock_outline_rounded,
                  key: ValueKey(focused),
                  size: 18,
                  color: focused ? _C.green : _C.placeholder,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PasswordTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hintText: 'Créez un mot de passe sécurisé',
                  height: 52,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(0),
                  style: GoogleFonts.dmSans(
                    color: _C.black, fontSize: 14, fontWeight: FontWeight.w500,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Au moins une majuscule';
                    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Au moins un chiffre';
                    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
                      return 'Au moins un caractère spécial';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordStrength(),
      ],
    );
  }

  // ── Force du mot de passe ──────────────────────────────────────────────────
  Widget _buildPasswordStrength() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _passwordController,
      builder: (_, value, __) {
        final len = value.text.length;
        if (len == 0) return const SizedBox.shrink();
        final strength = len < 6 ? 0 : len < 10 ? 1 : 2;
        final colors  = [_C.error, _C.orange, _C.green];
        final labels  = ['Faible', 'Moyen', 'Fort'];
        return Row(
          children: [
            ...List.generate(3, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i <= strength ? colors[strength] : _C.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
            const SizedBox(width: 8),
            Text(
              labels[strength],
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: colors[strength],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Bouton S'inscrire ──────────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isLoading ? _C.black.withOpacity(0.75) : _C.black,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _submitRegistration,
          borderRadius: BorderRadius.circular(18),
          splashColor: _C.green.withOpacity(0.25),
          highlightColor: _C.green.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(_C.white),
                    ),
                  )
                else ...[
                  Text(
                    'Créer mon compte',
                    style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: _C.white, letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _C.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.green.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: _C.white, size: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lien connexion ────────────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: 'Déjà un compte ? ',
            style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w500, color: _C.label,
            ),
          ),
          TextSpan(
            text: 'Se connecter',
            style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700, color: _C.green,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).pop(),
          ),
        ]),
      ),
    );
  }
}