import 'package:flutter/foundation.dart';

/// Configuration and data structures for commercial job search filters
/// Aligned with the production TypeScript JobFilterConfig contract.

@immutable
class FilterOption {
  final String id;
  final String label;

  const FilterOption({required this.id, required this.label});
}

@immutable
class LocationProvince {
  final String code;
  final String name;
  final String region; // 'Miền Bắc', 'Miền Trung - Tây Nguyên', 'Miền Nam'

  const LocationProvince({
    required this.code,
    required this.name,
    required this.region,
  });
}

@immutable
class InternationalLocation {
  final String code;
  final String name;
  final List<String> regions;

  const InternationalLocation({
    required this.code,
    required this.name,
    this.regions = const [],
  });
}

@immutable
class JobSpecialization {
  final String id;
  final String name;

  const JobSpecialization({required this.id, required this.name});
}

@immutable
class JobCategoryGroup {
  final String id;
  final String name;
  final List<JobSpecialization> specializations;

  const JobCategoryGroup({
    required this.id,
    required this.name,
    this.specializations = const [],
  });
}

@immutable
class SalaryRangeConfig {
  final String id;
  final String label;
  final num? min;
  final num? max;
  final String currency; // 'VND' or 'JPY'

  const SalaryRangeConfig({
    required this.id,
    required this.label,
    this.min,
    this.max,
    required this.currency,
  });
}

/// Master commercial filter dataset
class JobFilterData {
  const JobFilterData._();

  // 1. Hình thức làm việc
  static const List<FilterOption> jobTypes = [
    FilterOption(id: 'internship', label: 'Thực tập sinh (Internship)'),
    FilterOption(id: 'part_time', label: 'Bán thời gian (Part-time)'),
    FilterOption(id: 'full_time', label: 'Toàn thời gian (Full-time)'),
    FilterOption(id: 'freelance', label: 'Freelance / Hợp đồng dự án'),
  ];

  // 2. Địa điểm (34 tỉnh thành: 11 giữ nguyên + 23 sau sáp nhập)
  static const List<LocationProvince> domesticLocations = [
    // Miền Bắc (15 tỉnh/thành phố)
    LocationProvince(code: 'HN', name: 'Hà Nội', region: 'Miền Bắc'),
    LocationProvince(code: 'HP', name: 'Hải Phòng', region: 'Miền Bắc'),
    LocationProvince(code: 'QN', name: 'Quảng Ninh', region: 'Miền Bắc'),
    LocationProvince(code: 'BN', name: 'Bắc Ninh', region: 'Miền Bắc'),
    LocationProvince(code: 'HY', name: 'Hưng Yên', region: 'Miền Bắc'),
    LocationProvince(code: 'TN', name: 'Thái Nguyên', region: 'Miền Bắc'),
    LocationProvince(code: 'PT', name: 'Phú Thọ', region: 'Miền Bắc'),
    LocationProvince(code: 'NB', name: 'Ninh Bình', region: 'Miền Bắc'),
    LocationProvince(code: 'TQ', name: 'Tuyên Quang', region: 'Miền Bắc'),
    LocationProvince(code: 'LC', name: 'Lào Cai', region: 'Miền Bắc'),
    LocationProvince(code: 'LCH', name: 'Lai Châu', region: 'Miền Bắc'),
    LocationProvince(code: 'DB', name: 'Điện Biên', region: 'Miền Bắc'),
    LocationProvince(code: 'SL', name: 'Sơn La', region: 'Miền Bắc'),
    LocationProvince(code: 'LS', name: 'Lạng Sơn', region: 'Miền Bắc'),
    LocationProvince(code: 'CB', name: 'Cao Bằng', region: 'Miền Bắc'),

    // Miền Trung - Tây Nguyên (11 tỉnh/thành phố)
    LocationProvince(
      code: 'DN',
      name: 'Đà Nẵng',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'HUE',
      name: 'Huế',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'TH',
      name: 'Thanh Hóa',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'NA',
      name: 'Nghệ An',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'HT',
      name: 'Hà Tĩnh',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'QT',
      name: 'Quảng Trị',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'QNG',
      name: 'Quảng Ngãi',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'GL',
      name: 'Gia Lai',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'KH',
      name: 'Khánh Hòa',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'DL',
      name: 'Đắk Lắk',
      region: 'Miền Trung - Tây Nguyên',
    ),
    LocationProvince(
      code: 'LD',
      name: 'Lâm Đồng',
      region: 'Miền Trung - Tây Nguyên',
    ),

    // Miền Nam (8 tỉnh/thành phố)
    LocationProvince(code: 'HCM', name: 'Hồ Chí Minh', region: 'Miền Nam'),
    LocationProvince(code: 'DNA', name: 'Đồng Nai', region: 'Miền Nam'),
    LocationProvince(code: 'TNI', name: 'Tây Ninh', region: 'Miền Nam'),
    LocationProvince(code: 'CT', name: 'Cần Thơ', region: 'Miền Nam'),
    LocationProvince(code: 'VL', name: 'Vĩnh Long', region: 'Miền Nam'),
    LocationProvince(code: 'DT', name: 'Đồng Tháp', region: 'Miền Nam'),
    LocationProvince(code: 'CM', name: 'Cà Mau', region: 'Miền Nam'),
    LocationProvince(code: 'AG', name: 'An Giang', region: 'Miền Nam'),
  ];

  static const List<InternationalLocation> internationalLocations = [
    InternationalLocation(
      code: 'JP',
      name: 'Nhật Bản (Japan)',
      regions: [
        'Tokyo',
        'Osaka',
        'Aichi (Nagoya)',
        'Fukuoka',
        'Kanagawa (Yokohama)',
        'Saitama',
        'Chiba',
        'Kyoto',
        'Hyogo (Kobe)',
        'Khác',
      ],
    ),
  ];

  // 3. Ngành nghề & Chuyên ngành chi tiết (Phân cấp cha - con)
  static const List<JobCategoryGroup> categories = [
    JobCategoryGroup(
      id: 'it_software',
      name: 'Công nghệ thông tin & Phần mềm',
      specializations: [
        JobSpecialization(
          id: 'software_engineer',
          name: 'Software Engineer / Developer (Backend, Frontend, Fullstack)',
        ),
        JobSpecialization(id: 'brse', name: 'Bridge System Engineer (BrSE)'),
        JobSpecialization(
          id: 'it_communicator',
          name: 'IT Communicator (Comtor)',
        ),
        JobSpecialization(
          id: 'mobile_dev',
          name: 'Mobile App Developer (iOS, Android, Flutter, React Native)',
        ),
        JobSpecialization(
          id: 'ai_data',
          name: 'AI / Machine Learning / Data Engineer / Data Scientist',
        ),
        JobSpecialization(
          id: 'qa_qc',
          name: 'QA / QC / Software Tester (Manual & Automation)',
        ),
        JobSpecialization(
          id: 'devops_cloud',
          name: 'DevOps / Cloud Engineer / SysAdmin',
        ),
        JobSpecialization(
          id: 'embedded_iot',
          name: 'Embedded Systems / IoT Engineer',
        ),
        JobSpecialization(
          id: 'security',
          name: 'Cybersecurity / Information Security',
        ),
        JobSpecialization(
          id: 'ui_ux',
          name: 'UI/UX Designer / Product Designer',
        ),
        JobSpecialization(
          id: 'product_management',
          name: 'Product Owner / Product Manager / Scrum Master',
        ),
        JobSpecialization(id: 'it_helpdesk', name: 'IT Helpdesk / IT Support'),
      ],
    ),
    JobCategoryGroup(
      id: 'marketing_media',
      name: 'Marketing, Truyền thông & Quảng cáo',
      specializations: [
        JobSpecialization(
          id: 'digital_marketing',
          name: 'Digital Marketing / Performance Marketing',
        ),
        JobSpecialization(
          id: 'content_seo',
          name: 'Content Creator / Copywriter / SEO Specialist',
        ),
        JobSpecialization(
          id: 'social_media',
          name: 'Social Media / Community Management',
        ),
        JobSpecialization(
          id: 'brand_marketing',
          name: 'Brand Management / Trade Marketing',
        ),
        JobSpecialization(
          id: 'graphic_design',
          name: 'Graphic Designer / 2D-3D Motion / Video Editor',
        ),
        JobSpecialization(
          id: 'pr_event',
          name: 'PR / Event Planner / Truyền thông nội bộ',
        ),
      ],
    ),
    JobCategoryGroup(
      id: 'finance_accounting',
      name: 'Tài chính, Kế toán & Ngân hàng',
      specializations: [
        JobSpecialization(
          id: 'general_accounting',
          name: 'Kế toán tổng hợp / Kế toán thuế / Kế toán nội bộ',
        ),
        JobSpecialization(
          id: 'auditing',
          name: 'Kiểm toán (Internal / External Audit)',
        ),
        JobSpecialization(
          id: 'financial_analysis',
          name: 'Chuyên viên Phân tích Tài chính (Financial Analyst)',
        ),
        JobSpecialization(
          id: 'banking_credit',
          name: 'Ngân hàng / Tín dụng / Quản trị rủi ro',
        ),
        JobSpecialization(
          id: 'investment_fintech',
          name: 'Chứng khoán / Đầu tư / FinTech',
        ),
      ],
    ),
    JobCategoryGroup(
      id: 'sales_business_dev',
      name: 'Kinh doanh, Bán hàng & Chăm sóc khách hàng',
      specializations: [
        JobSpecialization(id: 'b2b_sales', name: 'B2B Sales / Corporate Sales'),
        JobSpecialization(
          id: 'b2c_retail',
          name: 'B2C Sales / Bán lẻ / Showroom',
        ),
        JobSpecialization(
          id: 'business_development',
          name: 'Phát triển kinh doanh (Business Development)',
        ),
        JobSpecialization(
          id: 'customer_service',
          name: 'Chăm sóc khách hàng / Telesales / Call Center',
        ),
        JobSpecialization(
          id: 'account_management',
          name: 'Quản trị quan hệ khách hàng (Account Executive)',
        ),
      ],
    ),
    JobCategoryGroup(
      id: 'hr_admin',
      name: 'Nhân sự & Hành chính',
      specializations: [
        JobSpecialization(
          id: 'talent_acquisition',
          name: 'Tuyển dụng (Talent Acquisition / IT Headhunter)',
        ),
        JobSpecialization(id: 'c_and_b', name: 'Lương & Phúc lợi (C&B)'),
        JobSpecialization(
          id: 'hr_generalist',
          name: 'Nhân sự tổng hợp / Đào tạo & Phát triển (L&D)',
        ),
        JobSpecialization(
          id: 'administration',
          name: 'Hành chính văn phòng / Thư ký / Trợ lý',
        ),
      ],
    ),
    JobCategoryGroup(
      id: 'logistics_supply_chain',
      name: 'Xuất nhập khẩu, Chuỗi cung ứng & Kho vận',
      specializations: [
        JobSpecialization(
          id: 'import_export',
          name: 'Nhân viên Xuất nhập khẩu / Chứng từ (Docs)',
        ),
        JobSpecialization(
          id: 'logistics_coordination',
          name: 'Logistics Operations / Forwarder',
        ),
        JobSpecialization(
          id: 'procurement',
          name: 'Thu mua (Purchasing / Procurement)',
        ),
        JobSpecialization(
          id: 'warehouse_inventory',
          name: 'Quản lý kho bãi / Vận hành chuỗi cung ứng',
        ),
      ],
    ),
    JobCategoryGroup(
      id: 'engineering_manufacturing',
      name: 'Kỹ thuật, Điện tử & Sản xuất',
      specializations: [
        JobSpecialization(
          id: 'mechanical_engineer',
          name: 'Kỹ sư Cơ khí / Chế tạo máy / CAD-CAM',
        ),
        JobSpecialization(
          id: 'electrical_engineer',
          name: 'Kỹ sư Điện - Điện tử / Tự động hóa (PLC)',
        ),
        JobSpecialization(
          id: 'civil_construction',
          name: 'Xây dựng / Kiến trúc / Giám sát công trình',
        ),
        JobSpecialization(
          id: 'qa_qc_manufacturing',
          name: 'QA/QC Quản lý chất lượng nhà xưởng',
        ),
        JobSpecialization(id: 'rd_engineer', name: 'Kỹ sư R&D sản phẩm'),
      ],
    ),
    JobCategoryGroup(
      id: 'foreign_languages_translation',
      name: 'Ngoại ngữ & Biên phiên dịch',
      specializations: [
        JobSpecialization(
          id: 'jp_translator',
          name: 'Biên/Phiên dịch tiếng Nhật (N1, N2, N3)',
        ),
        JobSpecialization(
          id: 'en_translator',
          name: 'Biên/Phiên dịch tiếng Anh',
        ),
        JobSpecialization(
          id: 'cn_kr_translator',
          name: 'Biên/Phiên dịch tiếng Hàn / tiếng Trung',
        ),
      ],
    ),
    JobCategoryGroup(
      id: 'hospitality_tourism',
      name: 'Du lịch, Nhà hàng & Khách sạn',
      specializations: [
        JobSpecialization(
          id: 'hotel_reception',
          name: 'Lễ tân / Quản trị buồng phòng',
        ),
        JobSpecialization(
          id: 'tour_guide',
          name: 'Điều hành tour / Hướng dẫn viên du lịch',
        ),
        JobSpecialization(id: 'fb_service', name: 'Quản lý / Phục vụ F&B'),
      ],
    ),
    JobCategoryGroup(
      id: 'education_training',
      name: 'Giáo dục & Đào tạo',
      specializations: [
        JobSpecialization(
          id: 'language_teacher',
          name: 'Giáo viên ngoại ngữ (IELTS, Nhật N-level,...)',
        ),
        JobSpecialization(
          id: 'academic_counselor',
          name: 'Tư vấn giáo dục / Du học',
        ),
        JobSpecialization(
          id: 'curriculum_developer',
          name: 'Nghiên cứu & Thiết kế chương trình đào tạo',
        ),
      ],
    ),
  ];

  // 4. Các bộ lọc bổ sung quan trọng cho Job Board
  static const List<FilterOption> experienceLevels = [
    FilterOption(id: 'no_exp', label: 'Chưa có kinh nghiệm'),
    FilterOption(id: 'fresher', label: 'Dưới 1 năm / Fresher'),
    FilterOption(id: 'junior', label: '1 - 3 năm'),
    FilterOption(id: 'middle', label: '3 - 5 năm'),
    FilterOption(id: 'senior', label: 'Trên 5 năm / Lead'),
  ];

  static const List<FilterOption> workplaceTypes = [
    FilterOption(id: 'on_site', label: 'Tại văn phòng (On-site)'),
    FilterOption(id: 'hybrid', label: 'Kết hợp (Hybrid)'),
    FilterOption(
      id: 'remote',
      label: 'Làm việc từ xa (Remote / Work from home)',
    ),
  ];

  static const List<SalaryRangeConfig> salaryRanges = [
    SalaryRangeConfig(id: 'negotiable', label: 'Thỏa thuận', currency: 'VND'),
    SalaryRangeConfig(
      id: 'under_10m',
      label: 'Dưới 10 triệu',
      max: 10000000,
      currency: 'VND',
    ),
    SalaryRangeConfig(
      id: '10m_20m',
      label: '10 - 20 triệu',
      min: 10000000,
      max: 20000000,
      currency: 'VND',
    ),
    SalaryRangeConfig(
      id: '20m_40m',
      label: '20 - 40 triệu',
      min: 20000000,
      max: 40000000,
      currency: 'VND',
    ),
    SalaryRangeConfig(
      id: 'over_40m',
      label: 'Trên 40 triệu',
      min: 40000000,
      currency: 'VND',
    ),
    SalaryRangeConfig(
      id: 'jp_200k_300k',
      label: '20 - 30 vạn Yên (Nhật Bản)',
      min: 200000,
      max: 300000,
      currency: 'JPY',
    ),
    SalaryRangeConfig(
      id: 'jp_over_300k',
      label: 'Trên 30 vạn Yên (Nhật Bản)',
      min: 300000,
      currency: 'JPY',
    ),
  ];
}
