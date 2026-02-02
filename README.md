# QTran Plus

**QTran Plus** là một công cụ dịch thuật Trung - Việt mã nguồn mở được viết bằng ngôn ngữ [Crystal](https://crystal-lang.org/). Khác với các công cụ dịch thông thường, QTran Plus tập trung vào việc xử lý các cấu trúc ngữ pháp phức tạp và ngữ cảnh của từ ngữ để đưa ra bản dịch tự nhiên và chính xác nhất.

## 🚀 Tính năng nổi bật

- **Phân tích ngữ pháp sâu**: Sử dụng kết quả phân tích từ LTP (Linguistic Tool of Peking University) để hiểu cấu trúc câu.
- **Xử lý cấu trúc đặc biệt**: Đã triển khai các quy tắc xử lý cho:
  - Câu chữ 把 (Disposal construction).
  - Câu so sánh (Comparison).
  - Câu tồn tại (Existential sentences).
  - Câu hỏi chính phản (A-not-A questions).
- **Nhận diện từ loại thông minh**: Hệ thống nhận diện dựa trên hậu tố (suffix-based) để phân loại chính xác:
  - Địa danh (nhà, thành phố, quốc gia...).
  - Nhân vật & Quan hệ gia đình (bố, mẹ, thầy giáo...).
  - Tổ chức & Cơ quan (cục, bộ, hội...).
  - Thời gian (năm, tháng, tuần...).
- **Xử lý đa nghĩa theo ngữ cảnh**: Tự động chọn nghĩa phù hợp cho các từ như "会" (biết/sẽ), "想" (muốn/nhớ/tưởng) dựa trên các từ xung quanh.

## 🛠 Yêu cầu hệ thống

- **Crystal**: 1.0.0 trở lên.
- **SQLite3**: Được sử dụng để lưu trữ từ điển.
- **LTP Server**: Cần có một LTP server đang chạy để phân tích cú pháp (mặc định cấu hình trong `src/client/ltp.cr`).

## 📦 Cài đặt

1. Clone dự án:
   ```bash
   git clone https://github.com/chi-vi/qtran-plus.git
   cd qtran-plus
   ```

2. Cài đặt các thư viện phụ thuộc:
   ```bash
   shards install
   ```

## 📖 Hướng dẫn sử dụng

Bạn có thể chạy công cụ trực tiếp bằng lệnh:

```bash
crystal run src/qtran.cr -- "我想到 ngươi"
```

Công cụ sẽ thực hiện các bước:
1. Gửi văn bản đến LTP Server để tách từ và dán nhãn từ loại.
2. Áp dụng các quy tắc biến đổi ngữ pháp (Grammar Rules).
3. Tra cứu từ điển và xuất kết quả dịch tiếng Việt.

## 🧪 Kiểm thử (Testing)

Dự án có bộ test case toàn diện bao phủ nhiều cấu trúc ngữ pháp:

```bash
crystal spec
```

Hiện tại có hơn 170 test case kiểm tra tính đúng đắn của các quy tắc ngữ pháp Trung - Việt.

## 📂 Cấu trúc dự án

- `src/mt/rules/`: Chứa các quy tắc biến đổi ngữ pháp (Động từ, Định ngữ, Trạng ngữ...).
- `src/mt/word_classifier.cr`: Logic phân loại từ dựa trên hậu tố và nhãn từ loại.
- `etc/suffixes/`: Danh sách các hậu tố dùng để nhận diện từ loại (Địa danh, Nhân vật, Thời gian...).
- `spec/fixtures/grammar/`: Các file YAML chứa dữ liệu kiểm thử ngữ pháp.

---
Phát triển bởi Antigravity :^)
