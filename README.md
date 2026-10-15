# Website lớp học – hướng dẫn từ con số 0 (Android)

Giải pháp: **GitHub Pages** (đưa giao diện lên mạng) + **Supabase** (đăng nhập, lưu dữ liệu, lưu ảnh). Cả hai có gói miễn phí, không cần tên miền.
Lưu ý gói miễn phí Supabase: dự án **tự tạm dừng nếu 7 ngày không có hoạt động**. Chỉ cần mở trang chủ ít nhất 1 lần/tuần là tránh được. Nếu bị dừng: vào supabase.com > dự án > nhấn **Restore**.

## Bước 1. Giải nén
Tải file ZIP về điện thoại, mở bằng ứng dụng **Files by Google** > chạm vào ZIP > **Giải nén**. Bạn sẽ có 7 file (index.html, admin.html, app.js, style.css, config.js, schema.sql, README.md).

## Bước 2. Tạo Supabase
1. Mở **supabase.com** > **Start your project** > đăng ký (dùng GitHub hoặc email).
2. **New project**: đặt tên `lop-hoc`, đặt **Database password** (lưu lại), chọn Region gần nhất (Singapore), nhấn **Create**. Đợi 1–2 phút.

## Bước 3. Tạo bảng và quyền
1. Menu trái > **SQL Editor** > **New query**.
2. Mở file `schema.sql` (bằng Chrome hoặc trình soạn thảo văn bản), **sao chép toàn bộ**, dán vào, nhấn **Run**. Đúng: hiện "Success".
3. **Tắt đăng ký tự do** (rất quan trọng): **Authentication** > **Sign In / Providers** > hãy **tắt** mục **Allow new users to sign up** > **Save**.
4. Tạo tài khoản admin: **Authentication** > **Users** > **Add user** > **Create new user**: nhập email, mật khẩu mạnh, **bật Auto Confirm User** > **Create**.

## Bước 4. Lấy khóa công khai
**Project Settings** (bánh răng) > **API Keys**: chép **Project URL** (dạng `https://xxxx.supabase.co`) và khóa **anon** (dài, bắt đầu bằng `eyJ`; nằm ở tab *Legacy API Keys* nếu giao diện mới ẩn nó). **Không** dùng khóa `service_role` hay `secret`.
Sau khi lên GitHub (Bước 5), mở file `config.js` > biểu tượng bút chì > thay 2 giá trị > **Commit changes**.

## Bước 5. Đưa code lên GitHub
1. **github.com** > đăng ký > **New repository**: tên `lop-hoc`, chọn **Public**, nhấn **Create repository**.
2. Nhấn **uploading an existing file** > chọn **đồng thời cả 7 file** (không chọn thư mục) > **Commit changes**.
3. Mở `config.js` > bút chì > dán URL và khóa anon > **Commit changes**.

## Bước 6. Xuất bản
Repo > **Settings** > **Pages** > Source: **Deploy from a branch** > Branch: **main**, thư mục **/(root)** > **Save**. Sau 1–3 phút, trang hiện link `https://TÊN-GITHUB.github.io/lop-hoc/`. Mở link này trên điện thoại: đúng là thấy đồng hồ, dữ liệu minh họa, banner vàng.

## Bước 7. Dùng trang quản trị
Mở `.../lop-hoc/admin.html` > đăng nhập bằng email/mật khẩu ở Bước 3. Sửa tên lớp, ngày bắt đầu, quy tắc, danh sách học sinh (mỗi dòng 1 tên), các cặp, phòng học > **Lưu thông tin**. Chọn ảnh thời khóa biểu > xem trước > **Tải ảnh lên và lưu**. Mở lại trang chủ để kiểm tra. Dữ liệu có chữ "minh họa" sẽ hết banner vàng khi bạn xóa chúng.

## Cập nhật sau này
Mọi dữ liệu đổi trong trang quản trị, không cần sửa code. Khi nghỉ lễ/học bù làm lịch lệch: đổi **ngày bắt đầu** hoặc thứ tự cặp rồi xem dòng "Hôm nay trực" để kiểm tra.

## Lỗi thường gặp
- *"Chưa cấu hình config.js"*: chưa dán URL/khóa, hoặc dán thiếu. Kiểm tra lại Bước 4.
- *"Sai email hoặc mật khẩu"*: kiểm tra Bước 3.4 (đã bật Auto Confirm?).
- *"Không có quyền ghi"*: đăng xuất, đăng nhập lại; kiểm tra đã chạy đủ `schema.sql`.
- *Trang trắng/cũ sau khi sửa*: đợi 1–2 phút, tải lại trang.
- *Không tải được dữ liệu*: dự án có thể đã tạm dừng (Restore) hoặc mất mạng.

## Checklist kiểm tra
[ ] Đồng hồ chạy mỗi giây, đúng thứ/ngày/tháng/năm  [ ] Hiện 2 bạn trực  [ ] Đổi cặp, lưu, trang chủ cập nhật
[ ] Sửa phòng học  [ ] Tải ảnh, xem trước, thay ảnh  [ ] Chạm ảnh để phóng to  [ ] Đăng xuất rồi truy cập admin: không sửa được
