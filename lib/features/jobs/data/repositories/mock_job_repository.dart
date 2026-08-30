import 'dart:async';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';
import '../../domain/repositories/job_repository.dart';

/// Mock implementation of [IJobRepository] with realistic Vietnamese job dataset.
class MockJobRepository implements IJobRepository {
  // In-memory bookmark set
  final Set<String> _savedJobIds = {'job-1', 'job-4'};

  // Realistic mock dataset conforming to SRS JOB-01, SEARCH-01, and MOB-01-02
  static final List<JobModel> _mockJobs = [
    JobModel(
      id: 'job-1',
      title: 'Senior Flutter Developer (Cross-Platform)',
      companyName: 'FPT Software',
      location: 'Đà Nẵng',
      salaryMin: 30000000,
      salaryMax: 45000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.hybrid,
      experienceLevel: ExperienceLevel.senior,
      skills: ['Flutter', 'Dart', 'Bloc', 'Clean Architecture', 'REST API'],
      description:
          'Chúng tôi tìm kiếm Senior Flutter Developer tham gia phát triển siêu ứng dụng tài chính và tuyển dụng hàng đầu cho thị trường APAC.',
      requirements:
          'Tối thiểu 3+ năm kinh nghiệm phát triển Flutter/Dart. Thành thạo State Management, Material 3, CI/CD và tối ưu hóa hiệu năng 60fps.',
      benefits:
          'Lương tháng 13 + thưởng hiệu suất (1-3 tháng), bảo hiểm FPT Care cho bản thân và gia đình, cơ hội onsite Nhật Bản & Singapore.',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isSaved: true,
      viewCount: 1420,
      applicationCount: 38,
    ),
    JobModel(
      id: 'job-2',
      title: 'Backend Golang Engineer (High Throughput)',
      companyName: 'VNG Corporation',
      location: 'TP. Hồ Chí Minh',
      salaryMin: 35000000,
      salaryMax: 55000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.senior,
      skills: ['Golang', 'gRPC', 'Kafka', 'PostgreSQL', 'Redis', 'Docker'],
      description:
          'Phát triển hệ thống Microservices xử lý hàng triệu concurrent users cho nền tảng Zalo / ZaloPay.',
      requirements:
          '3+ năm kinh nghiệm Golang, hiểu sâu về Concurrency, Event-Driven Architecture với Kafka và Database Optimization.',
      benefits:
          'Gói phúc lợi VNG Campus cao cấp (Gym, hồ bơi, cafeteria miễn phí), bảo hiểm sức khỏe quốc tế, thưởng ESOP hàng năm.',
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
      viewCount: 980,
      applicationCount: 24,
    ),
    JobModel(
      id: 'job-3',
      title: 'AI & Data Science Specialist',
      companyName: 'Viettel Solutions',
      location: 'Hà Nội',
      salaryMin: 25000000,
      salaryMax: 42000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.middle,
      skills: ['Python', 'PyTorch', 'NLP', 'LLM', 'FastAPI', 'Elasticsearch'],
      description:
          'Nghiên cứu và triển khai các mô hình AI Copilot, Resume Scoring và Recommendation System cho các nền tảng chuyển đổi số quốc gia.',
      requirements:
          'Tốt nghiệp ĐH chuyên ngành CNTT/Toán-Tin. Có kinh nghiệm với Large Language Models (LLM), Vector DB, RAG pipeline.',
      benefits:
          'Môi trường nghiên cứu chuyên nghiệp, tài trợ tham gia các hội nghị AI quốc tế, thưởng dự án đột xuất.',
      postedAt: DateTime.now().subtract(const Duration(hours: 8)),
      viewCount: 750,
      applicationCount: 19,
    ),
    JobModel(
      id: 'job-4',
      title: 'Product Manager (Fintech Mobile)',
      companyName: 'MoMo (M_Service)',
      location: 'TP. Hồ Chí Minh',
      salaryMin: 40000000,
      salaryMax: 65000000,
      category: 'Kinh doanh',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.lead,
      skills: ['Product Management', 'Data-Driven', 'Fintech', 'Agile/Scrum', 'UX Research'],
      description:
          'Định hình chiến lược sản phẩm và dẫn dắt tính năng thanh toán & tiện ích trên ứng dụng MoMo với 30M+ người dùng.',
      requirements:
          '4+ năm kinh nghiệm Product Management trong mảng Fintech, E-commerce hoặc Consumer Tech. Kỹ năng tư duy logic và phân tích dữ liệu xuất sắc.',
      benefits:
          'Mức lương cạnh tranh nhất thị trường, thưởng KPI vượt trội, môi trường làm việc trẻ trung, năng động tại Phú Mỹ Hưng.',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
      isSaved: true,
      viewCount: 2100,
      applicationCount: 45,
    ),
    JobModel(
      id: 'job-5',
      title: 'Senior .NET Backend Engineer (Microservices)',
      companyName: 'Techcombank',
      location: 'Hà Nội',
      salaryMin: 35000000,
      salaryMax: 50000000,
      category: 'Tài chính - Ngân hàng',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.senior,
      skills: ['.NET 8', 'C#', 'PostgreSQL', 'YARP Gateway', 'RabbitMQ', 'Clean Architecture'],
      description:
          'Xây dựng các core microservices bảo mật cao cho Digital Banking thế hệ mới của Techcombank.',
      requirements:
          'Thành thạo .NET Core / .NET 8, Entity Framework Core, PostgreSQL, RESTful API, Docker/K8s và các tiêu chuẩn bảo mật ngân hàng.',
      benefits:
          'Thưởng ngân hàng 3-5 tháng lương/năm, gói vay ưu đãi cho nhân viên, bảo hiểm sức khỏe VIP.',
      postedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      viewCount: 1620,
      applicationCount: 32,
    ),
    JobModel(
      id: 'job-6',
      title: 'QA Automation Engineer (Mobile & API)',
      companyName: 'Shopee Vietnam',
      location: 'TP. Hồ Chí Minh',
      salaryMin: 22000000,
      salaryMax: 35000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.middle,
      skills: ['Appium', 'Selenium', 'Postman', 'Java/Python', 'CI/CD Jenkins'],
      description:
          'Thiết kế và duy trì framework kiểm thử tự động cho hệ thống Mobile App Shopee và các API Gateway.',
      requirements:
          '2+ năm kinh nghiệm Automation Test cho Mobile/Web. Thành thạo viết test script với Appium/Selenium và tích hợp CI pipeline.',
      benefits:
          'Bữa trưa & snack miễn phí, bảo hiểm sức khỏe toàn diện, cơ hội phát triển nghề nghiệp tại tập đoàn công nghệ Sea Group.',
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      viewCount: 890,
      applicationCount: 28,
    ),
    JobModel(
      id: 'job-7',
      title: 'UI/UX Mobile Designer',
      companyName: 'One Mount Group',
      location: 'Hà Nội',
      salaryMin: 20000000,
      salaryMax: 32000000,
      category: 'Marketing',
      jobType: JobType.hybrid,
      experienceLevel: ExperienceLevel.middle,
      skills: ['Figma', 'Material Design 3', 'User Research', 'Prototyping', 'Design System'],
      description:
          'Thiết kế trải nghiệm người dùng tinh tế, chuẩn Material 3 và iOS HIG cho hệ sinh thái VinID và OneHousing.',
      requirements:
          '2+ năm kinh nghiệm thiết kế UI/UX trên Mobile Apps. Có portfolio chỉn chu chứng minh năng lực thiết kế trực quan và wireframing.',
      benefits:
          'Lương cạnh tranh, làm việc tại tòa nhà hiện đại Times City, hỗ trợ thiết bị Macbook Pro.',
      postedAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      viewCount: 1100,
      applicationCount: 42,
    ),
    JobModel(
      id: 'job-8',
      title: 'Junior Flutter Developer',
      companyName: 'Tiki Corp',
      location: 'TP. Hồ Chí Minh',
      salaryMin: 15000000,
      salaryMax: 22000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.junior,
      skills: ['Flutter', 'Dart', 'Provider/Riverpod', 'REST API', 'Git'],
      description:
          'Tham gia phát triển các tính năng giỏ hàng, tìm kiếm và chi tiết sản phẩm trên ứng dụng Tiki.',
      requirements:
          '1+ năm kinh nghiệm làm việc thực tế với Flutter. Nắm vững OOP, Widget Lifecycle và kết nối REST API.',
      benefits:
          'Được hướng dẫn bởi các Senior/Tech Lead giàu kinh nghiệm, đào tạo nâng cao kỹ năng liên tục.',
      postedAt: DateTime.now().subtract(const Duration(days: 3)),
      viewCount: 1450,
      applicationCount: 65,
    ),
    JobModel(
      id: 'job-9',
      title: 'Cloud DevOps Engineer (AWS / Kubernetes)',
      location: 'Đà Nẵng',
      companyName: 'VNPT Information Technology Company',
      salaryMin: 28000000,
      salaryMax: 42000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.middle,
      skills: ['AWS', 'Kubernetes', 'Docker', 'Terraform', 'GitLab CI', 'Prometheus'],
      description:
          'Quản trị hạ tầng Cloud, triển khai tự động hóa CI/CD và giám sát hệ thống cho các giải pháp Chính phủ điện tử.',
      requirements:
          '2+ năm kinh nghiệm quản trị Linux, Cloud (AWS/GCP), triển khai Kubernetes cluster và hệ thống monitoring.',
      benefits:
          'Thu nhập ổn định, chế độ đãi ngộ doanh nghiệp nhà nước hàng đầu, thưởng các dịp lễ tết lớn.',
      postedAt: DateTime.now().subtract(const Duration(days: 4)),
      viewCount: 620,
      applicationCount: 15,
    ),
    JobModel(
      id: 'job-10',
      title: 'Fresher Software Engineer (All Tracks)',
      companyName: 'KMS Technology',
      location: 'TP. Hồ Chí Minh',
      salaryMin: 10000000,
      salaryMax: 16000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.fresher,
      skills: ['Java', 'C#', 'JavaScript', 'SQL', 'Data Structures', 'OOP'],
      description:
          'Chương trình tuyển dụng Freshers hàng năm tại KMS với lộ trình đào tạo bài bản 3 tháng chuyên sâu.',
      requirements:
          'Sinh viên mới tốt nghiệp hoặc sắp tốt nghiệp chuyên ngành CNTT/KTPM. GPA từ 7.0/10 hoặc tương đương. Tiếng Anh giao tiếp tốt.',
      benefits:
          'Được nhận full lương trong quá trình đào tạo, trợ cấp ngoại ngữ, văn phòng hiện đại với nhiều câu lạc bộ thể thao.',
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      viewCount: 3200,
      applicationCount: 120,
    ),
    JobModel(
      id: 'job-11',
      title: 'Digital Marketing Lead (SEO / Ads)',
      companyName: 'VNG Media & Games',
      location: 'Hà Nội',
      salaryMin: 25000000,
      salaryMax: 38000000,
      category: 'Marketing',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.senior,
      skills: ['SEO', 'Google Ads', 'Facebook Ads', 'Data Analytics', 'Content Strategy'],
      description:
          'Xây dựng chiến lược tăng trưởng người dùng và tối ưu hóa chuyển đổi cho các sản phẩm game và nội dung số.',
      requirements:
          '3+ năm kinh nghiệm Digital Marketing, quản lý ngân sách quảng cáo quy mô lớn, tư duy phân tích ROI sắc bén.',
      benefits:
          'Môi trường năng động, thưởng theo hiệu quả chiến dịch (performance bonus hấp dẫn).',
      postedAt: DateTime.now().subtract(const Duration(days: 6)),
      viewCount: 880,
      applicationCount: 22,
    ),
    JobModel(
      id: 'job-12',
      title: 'Fullstack Remote Developer (React + Node.js)',
      companyName: 'Hybrid Technologies',
      location: 'Từ xa',
      salaryMin: 30000000,
      salaryMax: 48000000,
      category: 'Công nghệ thông tin',
      jobType: JobType.remote,
      experienceLevel: ExperienceLevel.middle,
      skills: ['React', 'Node.js', 'TypeScript', 'PostgreSQL', 'Next.js', 'AWS'],
      description:
          'Làm việc hoàn toàn từ xa (100% Remote) phát triển các hệ thống SaaS và E-commerce cho khách hàng Nhật Bản và Bắc Mỹ.',
      requirements:
          '3+ năm kinh nghiệm Fullstack phát triển React và Node.js. Kỹ năng tự quản lý công việc và giao tiếp tốt.',
      benefits:
          'Làm việc linh hoạt tại bất cứ đâu, trợ cấp trang thiết bị làm việc tại nhà, thưởng dự án đều đặn.',
      postedAt: DateTime.now().subtract(const Duration(days: 7)),
      viewCount: 1890,
      applicationCount: 52,
    ),
  ];

  @override
  Future<PaginatedJobs> getJobs(JobFilterParams params) async {
    // Simulate realistic network delay (MOB-01-02 SLA check)
    await Future.delayed(const Duration(milliseconds: 350));

    var filteredList = _mockJobs.map((job) {
      final isSaved = _savedJobIds.contains(job.id);
      return job.copyWith(isSaved: isSaved);
    }).toList();

    // 1. Keyword search (title, company, skills, category, description)
    if (params.keyword != null && params.keyword!.trim().isNotEmpty) {
      final q = params.keyword!.trim().toLowerCase();
      filteredList = filteredList.where((job) {
        final matchTitle = job.title.toLowerCase().contains(q);
        final matchCompany = job.companyName.toLowerCase().contains(q);
        final matchCategory = job.category.toLowerCase().contains(q);
        final matchLocation = job.location.toLowerCase().contains(q);
        final matchSkills =
            job.skills.any((s) => s.toLowerCase().contains(q));
        final matchDesc = job.description.toLowerCase().contains(q);
        return matchTitle ||
            matchCompany ||
            matchCategory ||
            matchLocation ||
            matchSkills ||
            matchDesc;
      }).toList();
    }

    // 2. Location filter
    if (params.location != null &&
        params.location!.trim().isNotEmpty &&
        params.location != 'Tất cả') {
      final loc = params.location!.trim().toLowerCase();
      filteredList = filteredList.where((job) {
        if (loc == 'từ xa' || loc == 'remote') {
          return job.jobType == JobType.remote ||
              job.location.toLowerCase().contains('từ xa') ||
              job.location.toLowerCase().contains('remote');
        }
        return job.location.toLowerCase().contains(loc);
      }).toList();
    }

    // 3. Category filter
    if (params.category != null &&
        params.category!.trim().isNotEmpty &&
        params.category != 'Tất cả') {
      filteredList = filteredList.where((job) {
        return job.category.toLowerCase() == params.category!.trim().toLowerCase();
      }).toList();
    }

    // 4. Job Type filter
    if (params.jobType != null) {
      filteredList = filteredList.where((job) {
        return job.jobType == params.jobType;
      }).toList();
    }

    // 5. Experience Level filter
    if (params.experienceLevel != null) {
      filteredList = filteredList.where((job) {
        return job.experienceLevel == params.experienceLevel;
      }).toList();
    }

    // 6. Salary filters
    if (params.salaryMin != null) {
      filteredList = filteredList.where((job) {
        if (job.isSalaryNegotiable) return true;
        final max = job.salaryMax ?? job.salaryMin ?? 0;
        return max >= params.salaryMin!;
      }).toList();
    }
    if (params.salaryMax != null) {
      filteredList = filteredList.where((job) {
        if (job.isSalaryNegotiable) return true;
        final min = job.salaryMin ?? 0;
        return min <= params.salaryMax!;
      }).toList();
    }

    // 7. Only saved bookmark filter
    if (params.onlySaved) {
      filteredList = filteredList.where((job) => job.isSaved).toList();
    }

    // 8. Sorting
    if (params.sortBy == 'salary_desc') {
      filteredList.sort((a, b) =>
          (b.salaryMax ?? b.salaryMin ?? 0).compareTo(a.salaryMax ?? a.salaryMin ?? 0));
    } else {
      // Default: newest first
      filteredList.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    }

    // 9. Pagination slicing
    final total = filteredList.length;
    final totalPages = (total / params.pageSize).ceil();
    final startIndex = params.page * params.pageSize;

    List<JobModel> pagedItems = [];
    if (startIndex < total) {
      final endIndex = (startIndex + params.pageSize > total)
          ? total
          : startIndex + params.pageSize;
      pagedItems = filteredList.sublist(startIndex, endIndex);
    }

    return PaginatedJobs(
      items: pagedItems,
      total: total,
      page: params.page,
      size: params.pageSize,
      totalPages: totalPages == 0 ? 1 : totalPages,
    );
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final job = _mockJobs.firstWhere((j) => j.id == id);
      return job.copyWith(isSaved: _savedJobIds.contains(id));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> toggleSaveJob(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_savedJobIds.contains(id)) {
      _savedJobIds.remove(id);
      return false;
    } else {
      _savedJobIds.add(id);
      return true;
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return const [];
    await Future.delayed(const Duration(milliseconds: 100));

    final cleanQuery = query.toLowerCase().trim();
    final suggestions = <String>{
      'Flutter Developer',
      'Golang Engineer',
      '.NET Developer',
      'React Native',
      'Data Scientist',
      'QA Automation',
      'UI/UX Designer',
      'DevOps Engineer',
      'Product Manager',
    };

    return suggestions
        .where((s) => s.toLowerCase().contains(cleanQuery))
        .take(5)
        .toList();
  }
}
