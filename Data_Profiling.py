
import pandas as pd
import numpy as np

# 1. ĐỌC DỮ LIỆU
df_raw = pd.read_csv(
    r"C:\Users\Khanhlinh\OneDrive\Desktop\Tài liệu UTH\HK5\Kho dữ liệu & hệ thống hỗ trợ ra quyết định\Bài tập\Cuối kỳ\VN-real-estate-Apr-Sept-2025.csv"
)
df_raw.columns = df_raw.columns.str.strip()

# Chuyển các thuộc tính số về dạng số
numeric_cols = ['Price', 'Area', 'Width', 'Length', 'AlleyWidth']
for col in numeric_cols:
    if col in df_raw.columns:
        df_raw[col] = pd.to_numeric(df_raw[col], errors='coerce')

# 2. DATA PROFILING
print("=" * 65)
print("                        DATA PROFILING")
print("=" * 65)

# Tổng số dòng và cột
print(f"\n• Tổng số dòng          : {len(df_raw):,}")
print(f"• Tổng số cột           : {len(df_raw.columns)}")

# Khoảng thời gian thu thập dữ liệu
if 'ScrapedAt' in df_raw.columns:
    dates = pd.to_datetime(df_raw['ScrapedAt'], errors='coerce')
    dates = dates.dropna()

    if len(dates) > 0:
        print(f"• Kỳ dữ liệu             : {dates.min().date()} - {dates.max().date()}")

# Số loại bất động sản
if 'PropertyType' in df_raw.columns:
    types = df_raw['PropertyType'].dropna().unique().tolist()
    print(f"• Số loại bất động sản  : {len(types)} -> {types}")

# 3. GIÁ TRỊ NULL
print("\n• Giá trị NULL:")
null_count = df_raw.isnull().sum()
null_percent = df_raw.isnull().mean() * 100

for col in df_raw.columns:
    if null_count[col] > 0:
        print(
            f"   - {col:<22}: "
            f"{null_count[col]:,} dòng "
            f"({null_percent[col]:.2f}%)"
        )

# 4. DỮ LIỆU TRÙNG LẶP
duplicate_count = df_raw.duplicated().sum()

duplicate_percent = (
    duplicate_count / len(df_raw) * 100
    if len(df_raw) > 0 else 0
)

print(
    f"\n• Dòng trùng lặp hoàn toàn: "
    f"{duplicate_count:,} "
    f"({duplicate_percent:.2f}%)"
)

# Kiểm tra trùng lặp theo ListingID
listing_id_col = next(
    (
        col for col in df_raw.columns
        if col.lower().replace(" ", "").replace("_", "") == "listingid"
    ),
    None
)

if listing_id_col is not None:
    listing_ids = df_raw[listing_id_col]

    # Không tính mã bị thiếu hoặc rỗng
    valid_ids = listing_ids[
        listing_ids.notna()
        & listing_ids.astype(str).str.strip().ne("")
    ]

    duplicate_listing = valid_ids.duplicated().sum()

    duplicate_listing_percent = (
        duplicate_listing / len(df_raw) * 100
        if len(df_raw) > 0 else 0
    )

    print(
        f"• Trùng ListingID          : "
        f"{duplicate_listing:,} "
        f"({duplicate_listing_percent:.2f}%)"
    )
else:
    print("• Trùng ListingID          : Không tìm thấy cột ListingID")

# 5. BẤT THƯỜNG NGHIỆP VỤ
print("\n• Bất thường nghiệp vụ:")

# Giá bán không hợp lệ
if 'Price' in df_raw.columns:
    invalid_price = (df_raw['Price'] <= 0).sum()
    print(f"   - Price <= 0            : {invalid_price:,} dòng")

# Diện tích nhỏ hơn 10 m2
if 'Area' in df_raw.columns:
    invalid_area = (df_raw['Area'] < 10).sum()
    print(f"   - Area < 10             : {invalid_area:,} dòng")

# Thiếu giá hoặc diện tích
if 'Price' in df_raw.columns and 'Area' in df_raw.columns:
    missing_price_area = (
        df_raw['Price'].isnull() |
        df_raw['Area'].isnull()
    ).sum()

    print(
        f"   - Thiếu Price/Area      : "
        f"{missing_price_area:,} dòng"
    )

# Tin đăng không thuộc loại đất
if 'PropertyType' in df_raw.columns:
    non_land = ~df_raw['PropertyType'].astype(str).str.contains(
        'đất', case=False, na=False
    )

    print(
        f"   - Không phải đất        : "
        f"{non_land.sum():,} dòng"
    )

# Tin đăng cho thuê
if 'Title' in df_raw.columns:
    title = df_raw['Title'].fillna('').astype(str)

    rental = (
        title.str.contains('cho thuê', case=False)
        & ~title.str.contains('bán', case=False)
    )

    print(
        f"   - Tin đăng cho thuê     : "
        f"{rental.sum():,} dòng"
    )

print("\n" + "=" * 65)
print("                  KẾT THÚC DATA PROFILING")
print("=" * 65)
