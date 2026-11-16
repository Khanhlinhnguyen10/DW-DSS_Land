# 🎓 DỰ ÁN: KHO DỮ LIỆU HỖ TRỢ RA QUYẾT ĐỊNH ĐỊNH GIÁ & ĐẦU TƯ BẤT ĐỘNG SẢN CÁ NHÂN
> **Môn học:** Kho dữ liệu và hệ thống hỗ trợ ra quyết định  
> **Công nghệ sử dụng:** Python, SQL Sever, SSIS, SSAS, Power BI  
> **Công cụ hỗ trợ:** SSMS, Visual Studio, Power BI Desktop

---
## 📌 TỔNG QUAN DỰ ÁN
**KHO DỮ LIỆU HỖ TRỢ RA QUYẾT ĐỊNH ĐỊNH GIÁ & ĐẦU TƯ BẤT ĐỘNG SẢN CÁ NHÂN** là hệ thống Kinh doanh thông minh (BI) và Hỗ trợ ra quyết định (DSS) được xây dựng nhằm hỗ trợ định giá đất và tư vấn đầu tư bất động sản cá nhân tại Việt Nam. Ứng dụng phương pháp luận Bottom-up của Ralph Kimball cùng kiến trúc Lược đồ hình sao, hệ thống xử lý hơn 236.226 tin đăng thô trên 63 tỉnh/thành phố, cung cấp bộ chỉ số tham chiếu mặt bằng giá, so sánh khu vực và sàng lọc danh mục đầu tư trực quan

---
## ✨ CÁC TÍNH NĂNG & KIẾN TRÚC XỬ LÝ CHÍNH
### 🧹 1. Đánh giá chất lượng & Tiền xử lý dữ liệu 15 bước bằng Python
* **Khảo sát chất lượng dữ liệu:** Sử dụng thư viện ydata-profiling để phát hiện giá trị thiếu, tin trùng lặp ListingID (8,26%), tin cho thuê và các bất thường nghiệp vụ
* **Lọc phạm vi & Khử trùng lặp:** Chỉ giữ lại loại hình bất động sản là Đất, loại bỏ tin chỉ cho thuê và xử lý trùng lặp ListingID bằng cách ưu tiên bản ghi có thời gian thu thập mới nhất.
* **Chuẩn hóa & Bổ sung dữ liệu:** Tính bổ sung chiều dài thiếu từ Area/Width, kiểm tra tính hợp lệ tọa độ địa lý tại Việt Nam, chuẩn hóa hướng/loại đường và bóc tách địa chỉ phân cấp hành chính
* **Tạo thuộc tính dẫn xuất & Gắn cờ chất lượng:** Xây dựng 31 trường phái sinh

### 🗄️ 2. Thiết kế mô hình Kho dữ liệu đa chiều
* **Kiến trúc Lược đồ hình sao:** Bảng sự kiện trung tâm Fact_Listing liên kết qua khóa thay thế với 5 bảng chiều và hỗ trợ bản ghi dự phòng khóa -1 cho dữ liệu khuyết thiếu
* **Hệ thống 5 bảng Dimension:** Dim_Time, Dim_Location, Dim_Size_Group, Dim_Price_Segment, Dim_Land_Profile

### ⚙️ 3. Quy trình ETL tự động & Kiểm soát toàn vẹn dữ liệu
* **Kiến trúc vùng đệm phân tầng** Tách biệt môi trường tiếp nhận thô và ghi nhận lỗi khỏi kho dữ liệu phân tích chính thức
* **Luồng điều khiển SSIS 4 tầng** Tự động hóa quy trình từ dọn dẹp vùng đệm và khởi tạo khóa -1, nạp dữ liệu vào Staging, chạy song song 5 luồng nạp Dimension, đến bước đối chiếu khóa ngoại và nạp nhanh vào Fact_Listing
* **Kiểm thử toàn vẹn & Ràng buộc vật lý:** Đảm bảo không phát sinh khóa ngoại mồ côi trên toàn bộ 108.909 bản ghi, đồng thời thiết lập các ràng buộc CHECK để chặn dữ liệu sai lệch ngay tại tầng cơ sở dữ liệu

### 📊 4. Khối phân tích OLAP & Báo cáo trực quan
* **Mô hình Cube & Chỉ số DAX:** Triển khai khối đa chiều Cube_Land trên SSAS và xây dựng các hàm tính toán DAX trong Power BI
* **Dashboard tổng hợp đa chiều:** Thiết kế giao diện báo cáo tích hợp thẻ chỉ số KPI tổng quan, biểu đồ cột so sánh giá trung bình theo tỉnh/thành, biểu đồ Donut cơ cấu phân khúc giá, biểu đồ thanh nhóm diện tích và biểu đồ đường xu hướng tin đăng theo tháng
* **Bộ lọc tương tác hỗ trợ ra quyết định:** Cho phép người dùng lọc động theo Tỉnh/Thành phố và Phân khúc giá để tra cứu đơn giá trung vị, nhận diện nguồn cung phổ biến nhằm lựa chọn bất động sản phù hợp ngân sách
