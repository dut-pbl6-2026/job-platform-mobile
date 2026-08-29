# Job Platform Mobile

Dự án ứng dụng di động đa nền tảng phục vụ nhu cầu tìm kiếm việc làm và tuyển dụng, được xây dựng bằng **Flutter**. Dự án thuộc hệ sinh thái **Vietnam Job Platform** (`pbl6`) của tổ chức [`dut-pbl6-2026`](https://github.com/dut-pbl6-2026).

---

## 📋 Yêu cầu hệ thống

Để chạy dự án này, bạn cần cài đặt và cấu hình các công cụ sau:

- **Flutter SDK**: Phiên bản ổn định (Stable version).
- **IDE**: Visual Studio Code hoặc Android Studio với Flutter & Dart plugins.
- **Android**:
  - Android Studio với SDK & Build Tools phù hợp.
  - JDK 17+ (Lưu ý: Không commit các đường dẫn local như cấu hình riêng trong `gradle.properties` vào Git).
  - Khuyến nghị môi trường kiểm thử: Android 12+ (API 31+).
- **iOS**:
  - macOS với Xcode phiên bản mới nhất.
  - Yêu cầu iOS Deployment Target **16.0+**.

---

## 🚀 Hướng dẫn bắt đầu

### 1. Cài đặt dự án

```bash
# Clone repository
git clone https://github.com/dut-pbl6-2026/job-platform-mobile.git

# Di chuyển vào thư mục dự án
cd job-platform-mobile

# Cài đặt các thư viện phụ thuộc
flutter pub get
```

### 2. Cấu hình môi trường

- Đảm bảo biến môi trường `JAVA_HOME` được thiết lập chính xác trên máy của bạn thay vì hardcode đường dẫn cục bộ trong tệp `android/gradle.properties`.
- Kiểm tra và thiết lập các cấu hình cần thiết trong file `.env` (nếu có).
- **Kết nối Backend**: Ứng dụng giao tiếp độc quyền thông qua **API Gateway (YARP)**, nghiêm cấm gọi trực tiếp vào các cổng microservices nội bộ.

### 3. Chạy dự án

```bash
# Kiểm tra các thiết bị khả dụng
flutter devices

# Chạy ứng dụng trên thiết bị đang kết nối
flutter run
```

---

## 🛠 Lưu ý cho nhà phát triển

- **Branching Flow (Trunk-Based)**:
  - Quy trình phân nhánh: `feature/*` / `fix/*` $\rightarrow$ `main` — mỗi repo chỉ có nhánh `main` duy nhất, CI chạy trên `main` (`.github/workflows/ci.yml`).
  - Vui lòng tạo branch mới theo định dạng `feature/[tên-tính-năng]` hoặc `fix/[tên-lỗi]` và mở PR vào `main`.
- **Quản lý công việc**: Theo dõi nhiệm vụ trên Jira tại [skid.atlassian.net](https://skid.atlassian.net).
- **Cấu hình Debug / Release**:
  - Luôn đảm bảo các cấu hình debug (như `debugLogDiagnostics`, logging) được bao bọc bởi `kDebugMode` để tránh lộ thông tin nhạy cảm.
- **Tuân thủ tiêu chuẩn & bảo mật**:
  - Tuân thủ các quy tắc bảo mật (SEC) và tiêu chuẩn SRS đề ra (ví dụ: quy định về độ mạnh mật khẩu, mã hóa token, thời hạn session, phân quyền 3 nhóm người dùng: Admin, Recruiter, User).
