import '../models/company_profile.dart';

/// Company profile contract for recruiters.
///
/// `GET /api/companies/mine` returns the company of the signed-in account plus
/// `isCompanyAdmin`. Only an admin may write, through
/// `PUT /api/companies/{id}`.
abstract class ICompanyProfileRepository {
  Future<CompanyProfile> getMyCompany();

  Future<CompanyProfile> updateCompany(CompanyProfile company);
}

/// Failure of a company-profile call. [message] is Vietnamese copy ready for UI.
class CompanyProfileException implements Exception {
  final String message;

  const CompanyProfileException(this.message);

  @override
  String toString() => 'CompanyProfileException: $message';
}
