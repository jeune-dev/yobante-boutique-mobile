import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../../data/datasources/vendeur_produit_datasource.dart';
import '../../data/models/categorie_model.dart';
import '../widgets/statut_chip.dart';

/// Formulaire de demande de publication.
///
/// Le vendeur ne publie pas : il prépare la fiche produit (photos, description,
/// prix, stock souhaité) et l'envoie à l'administration, qui décide. Un message
/// libre permet d'expliquer la demande à qui la relira.
class ProduitFormPage extends StatefulWidget {
  final ProduitModel? produit;
  const ProduitFormPage({super.key, this.produit});

  @override
  State<ProduitFormPage> createState() => _ProduitFormPageState();
}

class _ProduitFormPageState extends State<ProduitFormPage> {
  static const _maxImages = 5; // le backend n'en accepte pas davantage

  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  final _ds = sl<VendeurProduitDataSource>();

  List<CategorieModel> _categories = [];
  String? _categorieId;
  bool _chargementCats = true;
  String? _erreurCats;

  /// Photos choisies sur l'appareil. Les envoyer remplace l'intégralité de la
  /// galerie côté backend : en modification, on ne les touche que si le vendeur
  /// en sélectionne de nouvelles.
  final List<String> _nouvellesImages = [];
  late List<ProduitImage> _imagesExistantes;

  bool _envoiEnCours = false;

  bool get _isEdit => widget.produit != null;
  int get _nbImages => _imagesExistantes.length + _nouvellesImages.length;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _imagesExistantes = List<ProduitImage>.from(p?.images ?? const []);
    if (p != null) {
      _nomCtrl.text = p.nom;
      _descCtrl.text = p.description;
      _prixCtrl.text = p.prix;
      _stockCtrl.text = p.stockAlloue > 0 ? p.stockAlloue.toString() : '';
      _messageCtrl.text = p.messageVendeur;
    }
    _chargerCategories();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _prixCtrl.dispose();
    _stockCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerCategories() async {
    setState(() {
      _chargementCats = true;
      _erreurCats = null;
    });
    try {
      final cats = await _ds.categories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _chargementCats = false;
        if (_isEdit) {
          final match = cats.where((c) => c.nom == widget.produit!.categorie);
          if (match.isNotEmpty) _categorieId = match.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargementCats = false;
        _erreurCats = e.toString();
      });
    }
  }

  Future<void> _ajouterPhotos() async {
    final restant = _maxImages - _nbImages;
    if (restant <= 0) {
      _message('Maximum $_maxImages photos');
      return;
    }
    final fichiers = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1400);
    if (fichiers.isEmpty || !mounted) return;
    setState(() {
      _nouvellesImages.addAll(fichiers.take(restant).map((f) => f.path));
    });
    if (fichiers.length > restant) {
      _message('Seules $restant photo(s) ont été ajoutées (maximum $_maxImages)');
    }
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texte),
        backgroundColor: erreur ? VendeurCouleurs.rouge : null,
      ),
    );
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      _message('Choisissez une catégorie', erreur: true);
      return;
    }
    if (_nbImages == 0) {
      _message('Ajoutez au moins une photo du produit', erreur: true);
      return;
    }

    setState(() => _envoiEnCours = true);
    try {
      final prix = num.tryParse(_prixCtrl.text.trim()) ?? 0;
      final stockDemande = int.tryParse(_stockCtrl.text.trim()) ?? 0;
      final message = _messageCtrl.text.trim();

      if (_isEdit) {
        await _ds.modifierProduit(
          id: widget.produit!.id,
          nom: _nomCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          prix: prix,
          stockAlloue: stockDemande,
          categorieId: _categorieId,
          messageVendeur: message,
          imagePaths: _nouvellesImages,
        );
      } else {
        await _ds.ajouterProduit(
          nom: _nomCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          prix: prix,
          stockAlloue: stockDemande,
          categorieId: _categorieId!,
          messageVendeur: message,
          imagePaths: _nouvellesImages,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _message('Envoi impossible : $e', erreur: true);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendeurCouleurs.fond,
      appBar: AppBar(
        backgroundColor: VendeurCouleurs.blanc,
        elevation: 0.5,
        foregroundColor: VendeurCouleurs.noir,
        title: Text(_isEdit ? 'Modifier la demande' : 'Nouvelle demande'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _rappel(),
            const SizedBox(height: 20),
            _titre('Photos du produit', obligatoire: true),
            const SizedBox(height: 4),
            const Text(
              'Jusqu\'à $_maxImages photos. La première sert de visuel principal.',
              style: TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
            ),
            const SizedBox(height: 10),
            _galerie(),
            const SizedBox(height: 22),
            _titre('Nom du produit', obligatoire: true),
            const SizedBox(height: 8),
            _champ(
              controller: _nomCtrl,
              hint: 'Ex. Sac en cuir cousu main',
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Indiquez un nom d\'au moins 3 caractères' : null,
            ),
            const SizedBox(height: 18),
            _titre('Catégorie', obligatoire: true),
            const SizedBox(height: 8),
            _selecteurCategorie(),
            const SizedBox(height: 18),
            _titre('Description', obligatoire: true),
            const SizedBox(height: 4),
            const Text(
              'Matière, dimensions, coloris… c\'est ce que lira le client.',
              style: TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
            ),
            const SizedBox(height: 8),
            _champ(
              controller: _descCtrl,
              hint: 'Décrivez votre produit',
              lignes: 5,
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Une description d\'au moins 10 caractères aide à la validation'
                  : null,
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titre('Prix (FCFA)', obligatoire: true),
                      const SizedBox(height: 8),
                      _champ(
                        controller: _prixCtrl,
                        hint: '12000',
                        clavier: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          final prix = num.tryParse(v?.trim() ?? '');
                          if (prix == null || prix <= 0) return 'Prix invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titre('Stock souhaité', obligatoire: true),
                      const SizedBox(height: 8),
                      _champ(
                        controller: _stockCtrl,
                        hint: '50',
                        clavier: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          final stock = int.tryParse(v?.trim() ?? '');
                          if (stock == null || stock <= 0) return 'Stock invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Le stock souhaité est une demande : l\'administration fixe la quantité '
              'finalement mise en vente.',
              style: TextStyle(fontSize: 11.5, color: VendeurCouleurs.gris, height: 1.35),
            ),
            const SizedBox(height: 22),
            _titre('Message à l\'administration'),
            const SizedBox(height: 4),
            const Text(
              'Facultatif — précisez ce qui peut aider à valider votre demande.',
              style: TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
            ),
            const SizedBox(height: 8),
            _champ(
              controller: _messageCtrl,
              hint: 'Ex. Produit fabriqué localement, stock disponible immédiatement.',
              lignes: 4,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _envoiEnCours ? null : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendeurCouleurs.bleu,
                  foregroundColor: VendeurCouleurs.blanc,
                  disabledBackgroundColor: VendeurCouleurs.bordure,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: _envoiEnCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'Renvoyer la demande' : 'Envoyer la demande',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Blocs ─────────────────────────────────────────────────────────────
  Widget _rappel() => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: VendeurCouleurs.bleuClair,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 19, color: VendeurCouleurs.bleu),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isEdit
                    ? 'La modification renvoie le produit en validation : il sera de '
                        'nouveau relu avant d\'être publié.'
                    : 'Vous préparez la fiche produit. Elle ne sera visible des clients '
                        'qu\'après validation par l\'administration.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: VendeurCouleurs.bleu,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _titre(String texte, {bool obligatoire = false}) => RichText(
        text: TextSpan(
          text: texte,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: VendeurCouleurs.noir,
          ),
          children: obligatoire
              ? const [TextSpan(text: ' *', style: TextStyle(color: VendeurCouleurs.rouge))]
              : null,
        ),
      );

  Widget _galerie() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_nbImages < _maxImages)
            GestureDetector(
              onTap: _ajouterPhotos,
              child: Container(
                width: 92,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: VendeurCouleurs.blanc,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: VendeurCouleurs.bordure, width: 1.4),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: VendeurCouleurs.bleu, size: 22),
                    SizedBox(height: 6),
                    Text(
                      'Ajouter',
                      style: TextStyle(fontSize: 11, color: VendeurCouleurs.bleu),
                    ),
                  ],
                ),
              ),
            ),
          for (final image in _imagesExistantes)
            _vignette(
              enfant: Image.network(image.url, fit: BoxFit.cover, width: 92, height: 92),
              onSupprimer: () => setState(() => _imagesExistantes.remove(image)),
            ),
          for (final chemin in _nouvellesImages)
            _vignette(
              enfant: Image.file(File(chemin), fit: BoxFit.cover, width: 92, height: 92),
              onSupprimer: () => setState(() => _nouvellesImages.remove(chemin)),
            ),
        ],
      ),
    );
  }

  Widget _vignette({required Widget enfant, required VoidCallback onSupprimer}) => Container(
        width: 92,
        margin: const EdgeInsets.only(right: 10),
        child: Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(13), child: enfant),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onSupprimer,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _selecteurCategorie() {
    if (_chargementCats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_erreurCats != null) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Catégories indisponibles',
              style: TextStyle(fontSize: 12.5, color: VendeurCouleurs.rouge),
            ),
          ),
          TextButton(onPressed: _chargerCategories, child: const Text('Réessayer')),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: VendeurCouleurs.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendeurCouleurs.bordure),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _categorieId,
          isExpanded: true,
          hint: const Text(
            'Choisir une catégorie',
            style: TextStyle(fontSize: 13.5, color: VendeurCouleurs.gris),
          ),
          items: [
            for (final c in _categories)
              DropdownMenuItem(
                value: c.id,
                child: Text(c.nom, style: const TextStyle(fontSize: 13.5)),
              ),
          ],
          onChanged: (v) => setState(() => _categorieId = v),
        ),
      ),
    );
  }

  Widget _champ({
    required TextEditingController controller,
    required String hint,
    int lignes = 1,
    TextInputType? clavier,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lignes,
      keyboardType: clavier,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(fontSize: 13.5, color: VendeurCouleurs.noir),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: VendeurCouleurs.gris),
        filled: true,
        fillColor: VendeurCouleurs.blanc,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendeurCouleurs.bordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendeurCouleurs.bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendeurCouleurs.bleu, width: 1.4),
        ),
      ),
    );
  }
}
