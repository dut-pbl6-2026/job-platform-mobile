#!/usr/bin/env bash
set -euo pipefail

BASE_BRANCH="${1:-main}"
SRS_DIR="${2:-job-platform-docs/docs/srs/vi}"  # Trỏ đúng vào thư mục SRS trong repos
OUTPUT_REPORT="${3:-PR_REVIEW_REPORT.md}"
MODEL_NAME="${GEMINI_MODEL:-gemini-1.5-pro}"

# 1. Lấy Git Diff chỉ trong thư mục lib/ (tránh rác build/android/ios)
git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null || true
TARGET_REF="origin/$BASE_BRANCH"
if ! git rev-parse --verify "$TARGET_REF" >/dev/null 2>&1; then
    TARGET_REF="$BASE_BRANCH"
fi

GIT_DIFF=$(git diff "$TARGET_REF"...HEAD -- lib/ ':(exclude)*.g.dart' ':(exclude)*.freezed.dart')

if [[ -z "$GIT_DIFF" ]]; then
    echo "Không tìm thấy thay đổi mã nguồn trong thư mục lib/. Bỏ qua review."
    exit 0
fi

# 2. Đọc toàn bộ file Markdown SRS trong thư mục docs
SRS_PAYLOAD=""
if [[ -d "$SRS_DIR" ]]; then
    for file in "$SRS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            SRS_PAYLOAD+=$'\n\n'
            SRS_PAYLOAD+="=== SRS DOCUMENT: $(basename "$file") ==="$'\n'
            SRS_PAYLOAD+=$(cat "$file")
        fi
    done
elif [[ -f "$SRS_DIR" ]]; then
    SRS_PAYLOAD=$(cat "$SRS_DIR")
fi

if [[ -z "$SRS_PAYLOAD" ]]; then
    echo "Lỗi: Không tìm thấy tài liệu SRS tại $SRS_DIR"
    exit 1
fi

# 3. Định hình System Prompt chuyên cho Flutter / Mobile Architecture
PROMPT_TMP=$(mktemp)
cat << 'EOF' > "$PROMPT_TMP"
Bạn là Mobile Lead kiêm Senior QA Reviewer (chuyên sâu Flutter / Dart / Clean Architecture).
Nhiệm vụ: Đối chiếu Git Diff của Pull Request (thuộc thư mục lib/) với tài liệu đặc tả SRS hệ thống.

TIÊU CHÍ ĐÁNH GIÁ:
1. Business Logic & Scope:
   - Các use cases và tính năng (Auth, Jobs, Home, Splash, v.v.) trong diff đã thỏa mãn đúng yêu cầu trong SRS chưa?
   - Có thiếu luồng nghiệp vụ (Main flow / Alternative flow) hoặc validate sai rule không?
2. Clean Architecture & Code Quality:
   - Tuân thủ cấu trúc phân lớp (Data / Domain / Presentation) và Core services (Network, Session, Error handling).
   - Quản lý state, exception handling và async/await chuẩn xác.
3. Security & Best Practices:
   - Token/Session storage, bảo mật kết nối API, tránh memory leak khi dispose widget/controller.
4. Feedback & Actionable Fixes:
   - Chỉ rõ file/dòng code cần cải thiện và viết code mẫu Dart trực quan.

KẾT QUẢ TRẢ VỀ (Markdown):
- Đánh giá tổng quan (Status: PASS / NEEDS CHANGES / BLOCKED)
- Chức năng đã đáp ứng (Covered Features)
- Vi phạm hoặc thiếu sót so với SRS (Gaps & Logic Issues)
- Đề xuất sửa đổi code (Refactoring & Code Snippets)
EOF

# 4. Gửi payload sang Gemini CLI
PAYLOAD_TMP=$(mktemp)
{
    cat "$PROMPT_TMP"
    echo -e "\n=== SPECIFICATION (SRS DOCUMENTS) ==="
    echo "$SRS_PAYLOAD"
    echo -e "\n=== FLUTTER PULL REQUEST GIT DIFF (lib/) ==="
    echo "$GIT_DIFF"
} > "$PAYLOAD_TMP"

gemini -m "$MODEL_NAME" < "$PAYLOAD_TMP" > "$OUTPUT_REPORT"
rm -f "$PROMPT_TMP" "$PAYLOAD_TMP"