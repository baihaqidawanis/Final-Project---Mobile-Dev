import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class MitraRegisterScreen extends StatefulWidget {
  const MitraRegisterScreen({super.key});

  @override
  State<MitraRegisterScreen> createState() => _MitraRegisterScreenState();
}

class _MitraRegisterScreenState extends State<MitraRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _selectedRole = 'caregiver';
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  final List<Map<String, dynamic>> _mitraTypes = [
    {'value': 'caregiver', 'label': 'Caregiver', 'icon': Icons.medical_services_outlined},
    {'value': 'hospital', 'label': 'Rumah Sakit', 'icon': Icons.local_hospital_outlined},
    {'value': 'pharmacy', 'label': 'Farmasi', 'icon': Icons.medication_outlined},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose();
    _specializationCtrl.dispose(); _priceCtrl.dispose();
    _areaCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final auth = context.read<AuthProvider>();

    Map<String, dynamic>? mitraProfile;
    if (_selectedRole == 'caregiver') {
      mitraProfile = {
        'specialization': _specializationCtrl.text.trim(),
        'pricePerHour': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'area': _areaCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      };
    }

    final error = await auth.registerMitra(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      role: _selectedRole,
      mitraProfile: mitraProfile,
    );

    if (mounted) {
      setState(() { _isLoading = false; _error = error; });
      if (error == null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Daftar sebagai Mitra'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jenis Mitra', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                // Mitra type selector
                Row(
                  children: _mitraTypes.map((m) {
                    final selected = _selectedRole == m['value'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = m['value']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(m['icon'] as IconData,
                                  color: selected ? AppColors.primary : AppColors.textSecondary,
                                  size: 22),
                              const SizedBox(height: 6),
                              Text(m['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                const Text('Informasi Akun', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap / Nama Instansi',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                ),

                // Extra fields for caregiver
                if (_selectedRole == 'caregiver') ...[
                  const SizedBox(height: 24),
                  const Text('Profil Caregiver', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Info ini akan ditampilkan ke pengguna',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _specializationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Spesialisasi',
                      hintText: 'cth: Elderly Care, Post-Surgery',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    validator: (v) => (_selectedRole == 'caregiver' && (v == null || v.isEmpty))
                        ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga per Jam (Rp)',
                      hintText: 'cth: 75000',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (v) => (_selectedRole == 'caregiver' && (v == null || v.isEmpty))
                        ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Daerah Operasional',
                      hintText: 'cth: Jakarta Selatan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => (_selectedRole == 'caregiver' && (v == null || v.isEmpty))
                        ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Diri',
                      hintText: 'Ceritakan pengalaman dan keahlianmu...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.description_outlined),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cancelled.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.cancelled)),
                  ),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Daftar sebagai Mitra'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
