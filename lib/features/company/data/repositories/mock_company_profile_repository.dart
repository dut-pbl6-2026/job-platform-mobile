import '../../../../core/constants/company_profile_strings.dart';
import '../../domain/models/company_profile.dart';
import '../../domain/repositories/company_profile_repository.dart';

/// Deterministic company data for tests and prototype previews.
class MockCompanyProfileRepository implements ICompanyProfileRepository {
  MockCompanyProfileRepository({
    CompanyProfile? company,
    this.failLoad = false,
    this.failUpdate = false,
    this.delay = Duration.zero,
  }) : _company = company ?? _seed;

  static const _seed = CompanyProfile(
    id: 'company-001',
    name: 'FPT Software',
    taxCode: '0101248141',
    verified: true,
    logoUrl: null,
    website: 'https://fptsoftware.com',
    description:
        'Công ty công nghệ thông tin hàng đầu Việt Nam với khách hàng toàn cầu.',
    address: 'Khu công nghệ cao Hòa Lạc, Hà Nội',
    industry: 'Công nghệ thông tin',
    size: '1000+ nhân viên',
    isCompanyAdmin: true,
  );

  CompanyProfile _company;
  bool failLoad;
  bool failUpdate;
  Duration delay;

  int updateCalls = 0;

  CompanyProfile get company => _company;

  @override
  Future<CompanyProfile> getMyCompany() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failLoad) {
      throw const CompanyProfileException(CompanyProfileStrings.loadFailed);
    }
    return _company;
  }

  @override
  Future<CompanyProfile> updateCompany(CompanyProfile company) async {
    updateCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failUpdate) {
      throw const CompanyProfileException(CompanyProfileStrings.saveFailed);
    }
    _company = company;
    return _company;
  }
}
