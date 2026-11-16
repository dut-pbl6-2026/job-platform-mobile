/// Vietnamese copy for the recruiter company profile screen.
///
/// Backend contract: `GET /api/companies/mine` and `PUT /api/companies/{id}`.
/// Field names are the ones job-svc expects: `name` (required), `taxCode`,
/// `logoUrl`, `website`, `description`, `address`, `industry`, `size`.
library;

abstract final class CompanyProfileStrings {
  static const title = 'Hồ sơ công ty';
  static const loadFailed =
      'Không tải được thông tin công ty. Vui lòng thử lại.';
  static const saveFailed =
      'Không lưu được thông tin công ty. Vui lòng thử lại.';
  static const retry = 'Thử lại';
  static const edit = 'Chỉnh sửa thông tin';
  static const save = 'Lưu thay đổi';
  static const saving = 'Đang lưu...';
  static const cancel = 'Hủy';
  static const saved = 'Đã cập nhật thông tin công ty.';
  static const verified = 'Đã xác minh';
  static const notVerified = 'Chưa xác minh';
  static const adminOnlyReason =
      'Chỉ quản trị viên công ty được sửa thông tin công ty';
  static const readOnlyHint =
      'Bạn đang xem thông tin công ty ở chế độ chỉ đọc.';

  static const generalSection = 'Thông tin chung';
  static const contactSection = 'Liên hệ & giới thiệu';

  static const nameLabel = 'Tên công ty';
  static const nameHint = 'Nhập tên công ty';
  static const nameRequired = 'Vui lòng nhập tên công ty';
  static const taxCodeLabel = 'Mã số thuế';
  static const taxCodeHint = 'Nhập mã số thuế';
  static const industryLabel = 'Ngành nghề';
  static const industryHint = 'Ví dụ: Công nghệ thông tin';
  static const sizeLabel = 'Quy mô';
  static const sizeHint = 'Ví dụ: 50-200 nhân viên';
  static const websiteLabel = 'Website';
  static const websiteHint = 'https://congty.vn';
  static const logoUrlLabel = 'Đường dẫn logo';
  static const logoUrlHint = 'https://congty.vn/logo.png';
  static const addressLabel = 'Địa chỉ';
  static const addressHint = 'Nhập địa chỉ trụ sở';
  static const descriptionLabel = 'Giới thiệu công ty';
  static const descriptionHint = 'Mô tả ngắn về công ty, sản phẩm và văn hóa';
  static const notUpdated = 'Chưa cập nhật';
}
