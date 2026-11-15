/// Vietnamese copy for the company self-serve flows (AUTH-01-06, AUTH-01-09,
/// AUTH-01-10 to AUTH-01-15). Kept as Dart constants because the mobile app has
/// no localisation package yet (the owner has not chosen an i18n approach).
library;

/// Copy for the company sign-up form (AUTH-01-10, AUTH-01-11).
abstract final class CompanySignUpStrings {
  static const title = 'Đăng ký doanh nghiệp';
  static const subtitle =
      'Tạo tài khoản quản trị cho công ty bằng email công ty của bạn.';
  static const companyNameLabel = 'Tên công ty';
  static const companyNameHint = 'Nhập tên công ty';
  static const taxCodeLabel = 'Mã số thuế (không bắt buộc)';
  static const taxCodeHint = 'Nhập mã số thuế nếu có';
  static const emailLabel = 'Email công ty';
  static const emailHint = 'ten@congty.vn';
  static const emailHelper =
      'Dùng email công ty, không dùng email miễn phí như Gmail hay Yahoo.';
  static const fullNameLabel = 'Họ và tên người quản trị';
  static const fullNameHint = 'Nhập họ và tên';
  static const passwordLabel = 'Mật khẩu';
  static const passwordHint = 'Tạo mật khẩu';
  static const confirmPasswordLabel = 'Xác nhận mật khẩu';
  static const confirmPasswordHint = 'Nhập lại mật khẩu';
  static const submit = 'Đăng ký công ty';
  static const backToLogin = 'Quay về đăng nhập';

  /// Link shown on the login and register screens.
  static const signUpLink = 'Đăng ký công ty';
  static const signUpLinkPrompt = 'Bạn đại diện cho doanh nghiệp?';
  static const loginPrompt = 'Đã có tài khoản?';

  /// One response for every outcome of `register-company` (AUTH-01-10). It never
  /// says whether the company, tax code or email already exists.
  static const accepted = 'Hãy kiểm tra email để xác minh tài khoản của bạn.';

  static const companyNameRequired = 'Vui lòng nhập tên công ty';
  static const emailRequired = 'Vui lòng nhập email công ty';
  static const emailInvalid = 'Email không đúng định dạng';
  static const fullNameRequired = 'Vui lòng nhập họ và tên';
  static const passwordRequired = 'Vui lòng nhập mật khẩu';
  static const passwordTooWeak =
      'Mật khẩu tối thiểu 8 ký tự, gồm ít nhất 1 chữ hoa và 1 chữ số';
  static const confirmRequired = 'Vui lòng xác nhận lại mật khẩu';
  static const confirmMismatch = 'Mật khẩu xác nhận không khớp';
  static const taxCodeTooLong = 'Mã số thuế tối đa 32 ký tự';

  static const workEmailRequired =
      'Cần dùng email công ty để đăng ký doanh nghiệp.';
  static const serviceUnavailable =
      'Hệ thống tạm thời không khả dụng. Vui lòng thử lại sau.';
  static const retry = 'Thử lại';
}

/// Copy for issuing recruiter invite codes bound to one email (AUTH-01-09,
/// AUTH-01-15).
abstract final class InviteCodeStrings {
  static const title = 'Mã mời đăng ký';
  static const description =
      'Cấp mã mời để đồng nghiệp đăng ký nhà tuyển dụng cho công ty. '
      'Mỗi mã chỉ dùng được một lần, cho đúng email đã cấp, và hết hạn sau 7 ngày.';
  static const emailLabel = 'Email người được mời';
  static const emailHint = 'ten@congty.vn';
  static const emailRequired = 'Vui lòng nhập email người được mời';
  static const emailInvalid = 'Email không đúng định dạng';
  static const submit = 'Tạo mã mời';
  static const issuedTitle = 'Mã mời mới';
  static const copy = 'Sao chép mã';
  static const copied = 'Đã sao chép mã mời';
  static const showOnce =
      'Mã chỉ hiển thị một lần. Hãy sao chép và gửi cho đúng người sở hữu '
      'email ở trên; sau khi rời màn hình bạn không xem lại được mã này.';
  static const noCompany =
      'Tài khoản của bạn chưa gắn với công ty nên chưa tạo được mã mời.';
  static const expiresPrefix = 'Hết hạn ngày';
  static const notCreator = 'Chỉ người tạo công ty mới được cấp mã mời.';
  static const emailRejected =
      'Email người được mời không hợp lệ. Vui lòng kiểm tra lại.';
  static const failed = 'Không tạo được mã mời. Vui lòng thử lại.';
}

/// Copy for join requests on both sides: the company admin deciding, and the
/// requester watching the status (AUTH-01-12 to AUTH-01-14).
abstract final class JoinRequestStrings {
  static const adminTitle = 'Yêu cầu tham gia công ty';
  static const adminDescription =
      'Duyệt hoặc từ chối những người dùng email công ty đăng ký tham gia '
      'công ty của bạn.';
  static const adminEmpty = 'Chưa có yêu cầu tham gia nào.';
  static const approve = 'Duyệt';
  static const reject = 'Từ chối';
  static const approved = 'Đã duyệt yêu cầu tham gia.';
  static const rejected = 'Đã từ chối yêu cầu tham gia.';
  static const rejectReasonLabel = 'Lý do từ chối (không bắt buộc)';
  static const rejectReasonHint = 'Ví dụ: không thuộc công ty';
  static const rejectConfirm = 'Xác nhận từ chối';
  static const cancel = 'Hủy';
  static const noCompany =
      'Tài khoản của bạn chưa gắn với công ty nên chưa xem được yêu cầu tham gia.';
  static const retry = 'Thử lại';

  static const myTitle = 'Yêu cầu tham gia công ty';
  static const statusLabel = 'Trạng thái yêu cầu';
  static const requesterRefPrefix = 'Người dùng';
  static const myEmpty =
      'Bạn chưa có yêu cầu tham gia công ty nào. Yêu cầu được tạo khi bạn '
      'xác minh email công ty của một doanh nghiệp đã có trên hệ thống.';
  static const escalate = 'Gửi hỗ trợ';
  static const escalating = 'Đang gửi…';
  static const escalated =
      'Đã gửi yêu cầu tới bộ phận hỗ trợ. Vui lòng chờ phản hồi.';
  static const escalateHint =
      'Yêu cầu đã hết hạn chờ. Bạn có thể gửi một lần tới bộ phận hỗ trợ để '
      'được xem xét thủ công.';
  static const expiresLabel = 'Hết hạn';
  static const createdLabel = 'Ngày tạo';
  static const refresh = 'Làm mới';
  static const reasonLabel = 'Lý do';

  static const statusPending = 'Đang chờ duyệt';
  static const statusApproved = 'Đã được duyệt';
  static const statusRejected = 'Bị từ chối';
  static const statusExpired = 'Đã hết hạn';
  static const statusEscalated = 'Đang chờ hỗ trợ';
  static const statusSupportApproved = 'Hỗ trợ đã duyệt';
  static const statusSupportRejected = 'Hỗ trợ đã từ chối';
  static const statusUnknown = 'Không xác định';
}
