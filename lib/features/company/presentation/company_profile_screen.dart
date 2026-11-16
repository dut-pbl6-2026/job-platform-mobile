import 'package:flutter/material.dart';

import '../../../core/constants/company_profile_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_company_profile_repository.dart';
import '../domain/models/company_profile.dart';
import '../domain/repositories/company_profile_repository.dart';

/// Recruiter company profile (GET /api/companies/mine).
///
/// Every member can read the company; only `isCompanyAdmin` may edit it through
/// PUT /api/companies/{id}. The screen always resolves loading, error or data,
/// so a malformed/missing field shows retry instead of an endless spinner.
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key, this.repository});

  final ICompanyProfileRepository? repository;

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _industryController = TextEditingController();
  final _sizeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final ICompanyProfileRepository _repository;

  CompanyProfile? _company;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiCompanyProfileRepository();
    _fetchCompany();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxCodeController.dispose();
    _industryController.dispose();
    _sizeController.dispose();
    _websiteController.dispose();
    _logoUrlController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompany() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final company = await _repository.getMyCompany();
      if (!mounted) return;
      if (!company.isUsable) {
        setState(() {
          _isLoading = false;
          _errorMessage = CompanyProfileStrings.loadFailed;
        });
        return;
      }
      setState(() {
        _company = company;
        _isLoading = false;
      });
    } on CompanyProfileException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = CompanyProfileStrings.loadFailed;
      });
    }
  }

  void _startEditing() {
    final company = _company;
    if (company == null || !company.isCompanyAdmin) return;
    _nameController.text = company.name;
    _taxCodeController.text = company.taxCode ?? '';
    _industryController.text = company.industry ?? '';
    _sizeController.text = company.size ?? '';
    _websiteController.text = company.website ?? '';
    _logoUrlController.text = company.logoUrl ?? '';
    _addressController.text = company.address ?? '';
    _descriptionController.text = company.description ?? '';
    setState(() {
      _isEditing = true;
      _saveError = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _saveError = null;
    });
  }

  Future<void> _save() async {
    final company = _company;
    if (company == null || !company.isCompanyAdmin) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updated = CompanyProfile(
      id: company.id,
      name: _nameController.text.trim(),
      taxCode: _valueOrNull(_taxCodeController),
      verified: company.verified,
      logoUrl: _valueOrNull(_logoUrlController),
      website: _valueOrNull(_websiteController),
      description: _valueOrNull(_descriptionController),
      address: _valueOrNull(_addressController),
      industry: _valueOrNull(_industryController),
      size: _valueOrNull(_sizeController),
      isCompanyAdmin: company.isCompanyAdmin,
    );

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final saved = await _repository.updateCompany(updated);
      if (!mounted) return;
      setState(() {
        _company = saved;
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text(CompanyProfileStrings.saved),
        ),
      );
    } on CompanyProfileException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = CompanyProfileStrings.saveFailed;
      });
    }
  }

  static String? _valueOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final company = _company;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          CompanyProfileStrings.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading &&
              _errorMessage == null &&
              company != null &&
              company.isCompanyAdmin &&
              !_isEditing)
            IconButton(
              key: const Key('company_profile_edit_icon'),
              tooltip: CompanyProfileStrings.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _startEditing,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(company)),
    );
  }

  Widget _buildBody(CompanyProfile? company) {
    if (_isLoading) {
      return const Center(
        key: Key('company_profile_loading'),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null || company == null) {
      return Center(
        key: const Key('company_profile_error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_outlined,
                size: 56,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? CompanyProfileStrings.loadFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('company_profile_retry'),
                onPressed: _fetchCompany,
                child: const Text(CompanyProfileStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCompany,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(company),
            const SizedBox(height: 16),
            if (!company.isCompanyAdmin) ...[
              _buildMemberNotice(),
              const SizedBox(height: 12),
            ],
            if (_isEditing)
              _buildEditForm(company)
            else ...[
              _buildReadOnlyDetails(company),
              if (company.isCompanyAdmin) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('company_profile_edit'),
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text(CompanyProfileStrings.edit),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('company_profile_edit_disabled'),
                    onPressed: null,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text(CompanyProfileStrings.edit),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CompanyProfileStrings.adminOnlyReason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CompanyProfile company) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: company.logoUrl?.isNotEmpty == true
                  ? Image.network(
                      company.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _logoFallback(),
                    )
                  : _logoFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip(
                      company.verified
                          ? CompanyProfileStrings.verified
                          : CompanyProfileStrings.notVerified,
                      company.verified
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    if ((company.industry ?? '').isNotEmpty)
                      Text(
                        company.industry!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() => Container(
    color: AppColors.primaryLight,
    alignment: Alignment.center,
    child: const Icon(Icons.business_rounded, color: AppColors.primary),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _buildMemberNotice() => Container(
    key: const Key('company_profile_member_notice'),
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            CompanyProfileStrings.adminOnlyReason,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildReadOnlyDetails(CompanyProfile company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(CompanyProfileStrings.generalSection),
        _card(
          children: [
            _readOnlyRow(CompanyProfileStrings.taxCodeLabel, company.taxCode),
            _divider(),
            _readOnlyRow(CompanyProfileStrings.industryLabel, company.industry),
            _divider(),
            _readOnlyRow(CompanyProfileStrings.sizeLabel, company.size),
            _divider(),
            _readOnlyRow(CompanyProfileStrings.websiteLabel, company.website),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(CompanyProfileStrings.contactSection),
        _card(
          children: [
            _readOnlyRow(CompanyProfileStrings.addressLabel, company.address),
            _divider(),
            _readOnlyRow(CompanyProfileStrings.logoUrlLabel, company.logoUrl),
            _divider(),
            _readOnlyRow(
              CompanyProfileStrings.descriptionLabel,
              company.description,
            ),
          ],
        ),
      ],
    );
  }

  Widget _readOnlyRow(String label, String? value) {
    final text = value?.trim();
    final hasValue = text != null && text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasValue ? text : CompanyProfileStrings.notUpdated,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: hasValue ? AppColors.textPrimary : AppColors.textHint,
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(CompanyProfile company) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_saveError != null) ...[
            Container(
              key: const Key('company_profile_save_error'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _saveError!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _sectionTitle(CompanyProfileStrings.generalSection),
          _card(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      key: const Key('company_profile_name_field'),
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.nameLabel,
                        hintText: CompanyProfileStrings.nameHint,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? CompanyProfileStrings.nameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('company_profile_tax_code_field'),
                      controller: _taxCodeController,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.taxCodeLabel,
                        hintText: CompanyProfileStrings.taxCodeHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('company_profile_industry_field'),
                      controller: _industryController,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.industryLabel,
                        hintText: CompanyProfileStrings.industryHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('company_profile_size_field'),
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.sizeLabel,
                        hintText: CompanyProfileStrings.sizeHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('company_profile_website_field'),
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.websiteLabel,
                        hintText: CompanyProfileStrings.websiteHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(CompanyProfileStrings.contactSection),
          _card(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      key: const Key('company_profile_logo_field'),
                      controller: _logoUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.logoUrlLabel,
                        hintText: CompanyProfileStrings.logoUrlHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('company_profile_address_field'),
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.addressLabel,
                        hintText: CompanyProfileStrings.addressHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('company_profile_description_field'),
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: CompanyProfileStrings.descriptionLabel,
                        hintText: CompanyProfileStrings.descriptionHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!company.verified) ...[
            const SizedBox(height: 12),
            const Text(
              CompanyProfileStrings.notVerified,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('company_profile_cancel'),
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text(CompanyProfileStrings.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('company_profile_save'),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(CompanyProfileStrings.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    decoration: _cardDecoration(),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    color: AppColors.divider,
    indent: 16,
    endIndent: 16,
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  );
}
