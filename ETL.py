import hashlib
import os
import time
import numpy as np
import pandas as pd

# ----------------------------------------------------
# BẢNG ÁNH XẠ VÙNG MIỀN (63 TỈNH THÀNH CŨ)
# ----------------------------------------------------
REGION_MAP = {
    # Miền Bắc
    "Hà Nội": "Miền Bắc", "TP. Hà Nội": "Miền Bắc", "Hải Phòng": "Miền Bắc", "TP. Hải Phòng": "Miền Bắc",
    "Quảng Ninh": "Miền Bắc", "Hải Dương": "Miền Bắc", "Hưng Yên": "Miền Bắc", "Bắc Ninh": "Miền Bắc",
    "Hà Nam": "Miền Bắc", "Nam Định": "Miền Bắc", "Thái Bình": "Miền Bắc", "Vĩnh Phúc": "Miền Bắc",
    "Lào Cai": "Miền Bắc", "Yên Bái": "Miền Bắc", "Điện Biên": "Miền Bắc", "Hòa Bình": "Miền Bắc",
    "Lai Châu": "Miền Bắc", "Sơn La": "Miền Bắc", "Hà Giang": "Miền Bắc", "Cao Bằng": "Miền Bắc",
    "Bắc Kạn": "Miền Bắc", "Lạng Sơn": "Miền Bắc", "Tuyên Quang": "Miền Bắc", "Thái Nguyên": "Miền Bắc",
    "Phú Thọ": "Miền Bắc", "Bắc Giang": "Miền Bắc", "Ninh Bình": "Miền Bắc",
    # Miền Trung
    "Thanh Hóa": "Miền Trung", "Nghệ An": "Miền Trung", "Hà Tĩnh": "Miền Trung", "Quảng Bình": "Miền Trung",
    "Quảng Trị": "Miền Trung", "Thừa Thiên Huế": "Miền Trung", "Thừa Thiên - Huế": "Miền Trung", "TP. Huế": "Miền Trung",
    "Đà Nẵng": "Miền Trung", "TP. Đà Nẵng": "Miền Trung", "Quảng Nam": "Miền Trung", "Quảng Ngãi": "Miền Trung",
    "Bình Định": "Miền Trung", "Phú Yên": "Miền Trung", "Khánh Hòa": "Miền Trung", "Ninh Thuận": "Miền Trung",
    "Bình Thuận": "Miền Trung", "Kon Tum": "Miền Trung", "Gia Lai": "Miền Trung", "Đắk Lắk": "Miền Trung",
    "Đắk Nông": "Miền Trung", "Lâm Đồng": "Miền Trung",
    # Miền Nam
    "Thành phố Hồ Chí Minh": "Miền Nam", "TP.HCM": "Miền Nam", "TPHCM": "Miền Nam", "TP. Hồ Chí Minh": "Miền Nam",
    "Cần Thơ": "Miền Nam", "TP. Cần Thơ": "Miền Nam", "Bình Dương": "Miền Nam", "Đồng Nai": "Miền Nam",
    "Bà Rịa - Vũng Tàu": "Miền Nam", "Bà Rịa Vũng Tàu": "Miền Nam", "Tây Ninh": "Miền Nam", "Bình Phước": "Miền Nam",
    "Long An": "Miền Nam", "Tiền Giang": "Miền Nam", "Bến Tre": "Miền Nam", "Trà Vinh": "Miền Nam",
    "Vĩnh Long": "Miền Nam", "Đồng Tháp": "Miền Nam", "An Giang": "Miền Nam", "Kiên Giang": "Miền Nam",
    "Hậu Giang": "Miền Nam", "Sóc Trăng": "Miền Nam", "Bạc Liêu": "Miền Nam", "Cà Mau": "Miền Nam"
}

# ----------------------------------------------------
# BẢNG ÁNH XẠ SÁP NHẬP (34 TỈNH THÀNH THEO NGHỊ QUYẾT)
# ----------------------------------------------------
PROVINCE_NEW_MAP = {
    # 11 tỉnh/thành phố KHÔNG thực hiện sáp nhập (Giữ nguyên)
    "Hà Nội": "Hà Nội", "TP. Hà Nội": "Hà Nội",
    "Thanh Hóa": "Thanh Hóa",
    "Lạng Sơn": "Lạng Sơn",
    "Thừa Thiên Huế": "Thừa Thiên Huế", "Thừa Thiên - Huế": "Thừa Thiên Huế", "TP. Huế": "Thừa Thiên Huế",
    "Nghệ An": "Nghệ An",
    "Hà Tĩnh": "Hà Tĩnh",
    "Lai Châu": "Lai Châu",
    "Điện Biên": "Điện Biên",
    "Cao Bằng": "Cao Bằng",
    "Quảng Ninh": "Quảng Ninh",
    "Sơn La": "Sơn La",

    # 23 tỉnh/thành phố MỚI sau sáp nhập
    "Tuyên Quang": "Tuyên Quang", "Hà Giang": "Tuyên Quang",
    "Lào Cai": "Lào Cai", "Yên Bái": "Lào Cai",
    "Thái Nguyên": "Thái Nguyên", "Bắc Kạn": "Thái Nguyên",
    "Phú Thọ": "Phú Thọ", "Vĩnh Phúc": "Phú Thọ", "Hòa Bình": "Phú Thọ",
    "Bắc Ninh": "Bắc Ninh", "Bắc Giang": "Bắc Ninh",
    "Hưng Yên": "Hưng Yên", "Thái Bình": "Hưng Yên",
    "Hải Phòng": "TP. Hải Phòng", "TP. Hải Phòng": "TP. Hải Phòng", "Hải Dương": "TP. Hải Phòng",
    "Ninh Bình": "Ninh Bình", "Nam Định": "Ninh Bình", "Hà Nam": "Ninh Bình",
    "Quảng Trị": "Quảng Trị", "Quảng Bình": "Quảng Trị",
    "Đà Nẵng": "TP. Đà Nẵng", "TP. Đà Nẵng": "TP. Đà Nẵng", "Quảng Nam": "TP. Đà Nẵng",
    "Quảng Ngãi": "Quảng Ngãi", "Kon Tum": "Quảng Ngãi",
    "Gia Lai": "Gia Lai", "Bình Định": "Gia Lai",
    "Khánh Hòa": "Khánh Hòa", "Ninh Thuận": "Khánh Hòa",
    "Lâm Đồng": "Lâm Đồng", "Bình Thuận": "Lâm Đồng", "Đắk Nông": "Lâm Đồng",
    "Đắk Lắk": "Đắk Lắk", "Phú Yên": "Đắk Lắk",
    "Thành phố Hồ Chí Minh": "TP. Hồ Chí Minh", "TP.HCM": "TP. Hồ Chí Minh", "TPHCM": "TP. Hồ Chí Minh", "TP. Hồ Chí Minh": "TP. Hồ Chí Minh",
    "Bình Dương": "TP. Hồ Chí Minh", "Bà Rịa - Vũng Tàu": "TP. Hồ Chí Minh", "Bà Rịa Vũng Tàu": "TP. Hồ Chí Minh",
    "Đồng Nai": "Đồng Nai", "Bình Phước": "Đồng Nai",
    "Tây Ninh": "Tây Ninh", "Long An": "Tây Ninh",
    "Cần Thơ": "TP. Cần Thơ", "TP. Cần Thơ": "TP. Cần Thơ", "Sóc Trăng": "TP. Cần Thơ", "Hậu Giang": "TP. Cần Thơ",
    "Vĩnh Long": "Vĩnh Long", "Bến Tre": "Vĩnh Long", "Trà Vinh": "Vĩnh Long",
    "Đồng Tháp": "Đồng Tháp", "Tiền Giang": "Đồng Tháp",
    "Cà Mau": "Cà Mau", "Bạc Liêu": "Cà Mau",
    "An Giang": "An Giang", "Kiên Giang": "An Giang"
}

DIRECTION_MAP = {
    "ĐÔNG": "Đông", "DONG": "Đông", "E": "Đông",
    "TÂY": "Tây", "TAY": "Tây", "W": "Tây",
    "NAM": "Nam", "S": "Nam",
    "BẮC": "Bắc", "BAC": "Bắc", "N": "Bắc",
    "ĐÔNG BẮC": "Đông Bắc", "DONG BAC": "Đông Bắc", "ĐB": "Đông Bắc", "NE": "Đông Bắc",
    "TÂY BẮC": "Tây Bắc", "TAY BAC": "Tây Bắc", "TB": "Tây Bắc", "NW": "Tây Bắc",
    "ĐÔNG NAM": "Đông Nam", "DONG NAM": "Đông Nam", "ĐN": "Đông Nam", "SE": "Đông Nam",
    "TÂY NAM": "Tây Nam", "TAY NAM": "Tây Nam", "TN": "Tây Nam", "SW": "Tây Nam",
}

ROAD_TYPE_MAP = {
    "MAT TIEN": "Mặt tiền", "MẶT TIỀN": "Mặt tiền", "MAT PHO": "Mặt tiền", "MẶT PHỐ": "Mặt tiền", "ĐƯỜNG LỚN": "Mặt tiền",
    "HEM XE HOI": "Hẻm xe hơi", "HẺM XE HƠI": "Hẻm xe hơi", "HEM O TO": "Hẻm xe hơi", "HẺM Ô TÔ": "Hẻm xe hơi",
    "HEM NGOT": "Hẻm ngõ", "HẺM NGÕ": "Hẻm ngõ", "NGÕ": "Hẻm ngõ", "HEM": "Hẻm ngõ", "HẺM": "Hẻm ngõ"
}


def parse_location_right_to_left(location_str):
    if not isinstance(location_str, str) or not location_str.strip():
        return pd.Series({
            "Admin_Version": "Old",
            "Province_Std": "Không xác định",
            "City/District": "Không xác định",
            "Ward/Commune": "Không xác định",
            "Street": "Không xác định"
        })

    is_new = bool(np.where("(mới)" in location_str.lower(), True, False))
    admin_ver = "New" if is_new else "Old"
    
    clean_str = location_str.replace("(Mới)", "").replace("(mới)", "").strip()
    clean_str = " ".join(clean_str.split())

    parts = [p.strip() for p in clean_str.split(",") if p.strip()]

    if not parts:
        return pd.Series({
            "Admin_Version": admin_ver,
            "Province_Std": "Không xác định",
            "City/District": "Không áp dụng (địa chỉ mới)" if is_new else "Không xác định",
            "Ward/Commune": "Không xác định",
            "Street": "Không xác định"
        })

    province = parts[-1]
    remaining = parts[:-1]

    district = None
    ward = None
    street_parts = []

    district_prefixes = ("Quận", "Huyện", "Thành phố", "Thị xã", "TP.", "Tx.", "H.")
    ward_prefixes = ("Phường", "Xã", "Thị trấn", "P.", "X.", "Tt.")

    for p in reversed(remaining):
        if not district and p.startswith(district_prefixes):
            district = p
        elif not ward and p.startswith(ward_prefixes):
            ward = p
        else:
            street_parts.insert(0, p)

    if not district:
        district = "Không áp dụng (địa chỉ mới)" if is_new else "Không xác định"

    if not ward:
        ward = "Không xác định"

    street = ", ".join(street_parts) if street_parts else "Không xác định"

    return pd.Series({
        "Admin_Version": admin_ver,
        "Province_Std": province,
        "City/District": district,
        "Ward/Commune": ward,
        "Street": street
    })


def normalize_province_for_compare(val):
    if pd.isna(val) or not isinstance(val, str):
        return ""
    s = val.strip().lower()
    for prefix in ["thành phố ", "tp. ", "tp ", "tỉnh "]:
        if s.startswith(prefix):
            s = s[len(prefix):].strip()
    return s.replace("-", " ").replace(".", "").strip()


def normalize_direction(val):
    if pd.isna(val) or val is None:
        return "Không xác định"
    s = str(val).strip().upper()
    if s in ["NAN", "NONE", "", "NULL", "KHÔNG XÁC ĐỊNH"]:
        return "Không xác định"
    return DIRECTION_MAP.get(s, str(val).strip().title())


def normalize_road_type(val):
    if pd.isna(val) or val is None:
        return "Không xác định"
    s = str(val).strip().upper()
    if s in ["NAN", "NONE", "", "NULL", "KHÔNG XÁC ĐỊNH"]:
        return "Không xác định"
    return ROAD_TYPE_MAP.get(s, str(val).strip().title())


def generate_row_hash(row):
    """Tính Row_Hash = MD5(Price, Area, Last Updated Date, Location) theo Bảng 2"""
    raw_str = f"{row.get('Price', '')}|{row.get('Area', '')}|{row.get('Last Updated Date', '')}|{row.get('Location', '')}"
    return hashlib.md5(raw_str.encode("utf-8")).hexdigest()


def clean_and_normalize_data(input_file, output_excel_file, output_csv_file):
    start_time = time.time()
    print("Bắt đầu đọc file dữ liệu thô")
    print("Thư mục file nhập", input_file)

    df = pd.read_excel(input_file)
    print("Đã đọc xong dữ liệu thô với tổng số bản ghi ban đầu là", len(df))

    # 1/15: Lọc loại hình Đất
    if "Property Type" in df.columns:
        print("Bước 1/15: Đang lọc dữ liệu theo Property Type chỉ giữ loại Đất")
        df = df[df["Property Type"].astype(str).str.contains("Đất", case=False, na=False)].copy()

    # 2/15: Khử trùng Listing ID
    if "Scraped At" in df.columns or "Listing ID" in df.columns:
        print("Bước 2/15: Chuẩn hóa Scraped At tạo Batch_ID và khử trùng Listing ID")
        if "Scraped At" in df.columns:
            df["Scraped At"] = pd.to_datetime(df["Scraped At"], errors="coerce")
            df = df.sort_values(by="Scraped At", ascending=False)
            df["Batch_ID"] = df["Scraped At"].dt.strftime("%Y%m%d").fillna("BATCH_UNKNOWN")

        if "Listing ID" in df.columns:
            df = df[df["Listing ID"].notna()].copy()
            df["Listing ID"] = pd.to_numeric(df["Listing ID"], errors="coerce").dropna().astype("int64")
            df = df.drop_duplicates(subset=["Listing ID"], keep="first")

    df = df.reset_index(drop=True)

    # 3/15: Dim_Time
    if "Last Updated Date" in df.columns:
        print("Bước 3/15: Parse Last Updated Date theo định dạng ngày giờ và tạo thuộc tính Dim_Time")
        parsed_dt = pd.to_datetime(df["Last Updated Date"], format="%d/%m/%Y %H:%M", errors="coerce")
        valid_mask = parsed_dt.notna()
        
        df["Time_Key"] = np.where(valid_mask, parsed_dt.dt.strftime("%Y%m").astype(object), "-1")
        df["Year_Month"] = np.where(valid_mask, parsed_dt.dt.strftime("%Y-%m"), "Unknown")
        df["Year"] = np.where(valid_mask, parsed_dt.dt.year.astype(str), "Unknown")
        df["Month"] = np.where(valid_mask, parsed_dt.dt.month.astype(str), "Unknown")
        df["Quarter"] = np.where(valid_mask, "Q" + parsed_dt.dt.quarter.astype(str), "Unknown")

    # 4/15: Lọc tin cho thuê
    if "Title" in df.columns:
        print("Bước 4/15: Đang kiểm tra tiêu đề Title để loại bỏ tin cho thuê")
        has_rental = df["Title"].astype(str).str.contains("cho thuê|cho thue|cho thuê đất", case=False, na=False)
        has_sale = df["Title"].astype(str).str.contains("bán|ban|cần bán", case=False, na=False)
        rental_mask = has_rental & ~has_sale
        df = df[~rental_mask].copy()
        df = df.reset_index(drop=True)

    # 5/15: Dup_Flag
    dup_cols = ["Title", "Price", "Area", "Location"]
    existing_dup_cols = [c for c in dup_cols if c in df.columns]
    if len(existing_dup_cols) == 4:
        print("Bước 5/15: Đang kiểm tra trùng lặp nội dung để gắn Dup_Flag")
        dup_content_mask = df.duplicated(subset=existing_dup_cols, keep=False)
        df["Dup_Flag"] = np.where(dup_content_mask, 1, 0)

    # 6/15: Land_Use_Class
    print("Bước 6/15: Đang quét Description và Title để phân loại Land_Use_Class")
    text_source = (df["Title"].fillna("").astype(str) + " " + df["Description"].fillna("").astype(str)).str.lower()
    
    res_kw = "|".join(["thổ cư", "tho cu", "đất ở", "dat o", "sổ đỏ", "so do", "sổ hồng", "so hong", "dân cư"])
    other_kw = "|".join(["nông nghiệp", "nong nghiep", "trồng cây", "trong cay", "lúa", "vườn", "vuon", "rừng", "rung", "thương mại", "thuong mai", "dịch vụ", "kcn", "kho xưởng", "tmdv"])

    has_res = text_source.str.contains(res_kw, regex=True)
    has_other = text_source.str.contains(other_kw, regex=True)

    cond_land = [has_res & ~has_other, has_other & ~has_res, has_res & has_other]
    choic_land = ["Dấu hiệu đất ở", "Dấu hiệu đất khác", "Mâu thuẫn"]
    df["Land_Use_Class"] = np.select(cond_land, choic_land, default="Chưa xác định")

    # 7/15: Price, Area, Price_per_m2, Price_Billion, Area_Group, Price_Segment
    print("Bước 7/15: Làm sạch Price, Area, tính Price_per_m2, Price_Billion, Area_Group và Price_Segment theo Bảng 2")
    if "Price" in df.columns:
        df["Price"] = pd.to_numeric(df["Price"], errors="coerce")
        df = df[df["Price"].notna() & (df["Price"] > 0) & (df["Price"] < 1000000)].copy()

    if "Area" in df.columns:
        df["Area"] = pd.to_numeric(df["Area"], errors="coerce")
        df = df[df["Area"].notna() & (df["Area"] >= 10) & (df["Area"] <= 1000000)].copy()

        # Area_Group (Dim_Size_Group) theo mốc: 50, 100, 200, 500, 1000 m2 trong Bảng 2
        area_cond = [
            df["Area"] < 50,
            (df["Area"] >= 50) & (df["Area"] < 100),
            (df["Area"] >= 100) & (df["Area"] < 200),
            (df["Area"] >= 200) & (df["Area"] < 500),
            (df["Area"] >= 500) & (df["Area"] < 1000),
            df["Area"] >= 1000,
        ]
        area_choic = ["Dưới 50 m2", "50 - 100 m2", "100 - 200 m2", "200 - 500 m2", "500 - 1000 m2", "Trên 1000 m2"]
        df["Area_Group"] = np.select(area_cond, area_choic, default="Không xác định")

    df["Price_Billion"] = (df["Price"] / 1000.0).round(4)
    df["Price_per_m2"] = (df["Price"] / df["Area"]).round(4)

    # Price_Segment (Dim_Price_Segment) theo mốc: 1, 3, 5, 10 tỷ đồng trong Bảng 2
    seg_cond = [
        df["Price_Billion"] < 1.0,
        (df["Price_Billion"] >= 1.0) & (df["Price_Billion"] < 3.0),
        (df["Price_Billion"] >= 3.0) & (df["Price_Billion"] < 5.0),
        (df["Price_Billion"] >= 5.0) & (df["Price_Billion"] < 10.0),
        df["Price_Billion"] >= 10.0,
    ]
    seg_choic = ["Dưới 1 tỷ", "1 - 3 tỷ", "3 - 5 tỷ", "5 - 10 tỷ", "Trên 10 tỷ"]
    df["Price_Segment"] = np.select(seg_cond, seg_choic, default="Không xác định")

    df = df.reset_index(drop=True)

    # 8/15: Width & Length
    print("Bước 8/15: Đang xử lý Width và Length")
    if "Width" in df.columns:
        df["Width"] = pd.to_numeric(df["Width"], errors="coerce")
        df.loc[(df["Width"] <= 0) | (df["Width"] > 1000), "Width"] = np.nan

    if "Length" in df.columns:
        df["Length"] = pd.to_numeric(df["Length"], errors="coerce")
        df.loc[(df["Length"] <= 0) | (df["Length"] > 10000), "Length"] = np.nan

    df["Length_Derived"] = 0

    if "Area" in df.columns and "Width" in df.columns:
        mask_l_missing = df["Length"].isna() & df["Width"].notna() & (df["Width"] > 0)
        df.loc[mask_l_missing, "Length"] = df.loc[mask_l_missing, "Area"] / df.loc[mask_l_missing, "Width"]
        df.loc[mask_l_missing, "Length_Derived"] = 1

        invalid_derived = df["Length"] > 10000
        df.loc[invalid_derived, "Length"] = np.nan
        df.loc[invalid_derived, "Length_Derived"] = 0

    if "Area" in df.columns and "Width" in df.columns and "Length" in df.columns:
        calculated_area = df["Width"] * df["Length"]
        valid_calc_mask = calculated_area.notna() & df["Area"].notna() & (df["Area"] > 0)

        df["WxL_Check"] = np.nan
        diff_ratio = (calculated_area - df["Area"]).abs() / df["Area"]
        df.loc[valid_calc_mask & (diff_ratio <= 0.20), "WxL_Check"] = 1
        df.loc[valid_calc_mask & (diff_ratio > 0.20), "WxL_Check"] = 0

    # 9/15: Alley Width
    if "Alley Width" in df.columns:
        print("Bước 9/15: Đang chuẩn hóa Alley Width")
        df["Alley Width"] = pd.to_numeric(df["Alley Width"], errors="coerce")
        df.loc[(df["Alley Width"] <= 0) | (df["Alley Width"] > 100), "Alley Width"] = np.nan

    # 10/15: Geo_Status
    print("Bước 10/15: Đang kiểm tra Latitude và Longitude theo cặp và bổ sung cờ Geo_Status")
    if "Latitude" in df.columns and "Longitude" in df.columns:
        df["Latitude"] = pd.to_numeric(df["Latitude"], errors="coerce")
        df["Longitude"] = pd.to_numeric(df["Longitude"], errors="coerce")

        valid_lat_mask = (df["Latitude"] >= 8.0) & (df["Latitude"] <= 23.5)
        valid_lon_mask = (df["Longitude"] >= 102.0) & (df["Longitude"] <= 110.0)

        has_both_coords = df["Latitude"].notna() & df["Longitude"].notna()
        is_in_vn_bounds = valid_lat_mask & valid_lon_mask

        geo_conditions = [
            ~has_both_coords,
            has_both_coords & is_in_vn_bounds,
            has_both_coords & ~is_in_vn_bounds
        ]
        geo_choices = ["Missing", "Valid", "Invalid"]
        df["Geo_Status"] = np.select(geo_conditions, geo_choices, default="Missing")

        invalid_or_missing_mask = df["Geo_Status"] != "Valid"
        df.loc[invalid_or_missing_mask, ["Latitude", "Longitude"]] = np.nan

    # 11/15: Location & Province_Std
    if "Location" in df.columns:
        print("Bước 11/15: Đang tách Location theo bảng 34 Tỉnh mới và đối chiếu Province_Match_Flag")
        parsed_df = df["Location"].apply(parse_location_right_to_left)
        df[["Admin_Version", "Province_Std", "City/District", "Ward/Commune", "Street"]] = parsed_df

        if "Province" in df.columns:
            prov_raw_norm = df["Province"].apply(normalize_province_for_compare)
            prov_std_norm = df["Province_Std"].apply(normalize_province_for_compare)
            df["Province_Match_Flag"] = np.where(prov_raw_norm == prov_std_norm, 1, 0)
        else:
            df["Province_Match_Flag"] = 1

        df["Region"] = df["Province_Std"].map(REGION_MAP).fillna("Không xác định")
        df["Province_New"] = df["Province_Std"].map(PROVINCE_NEW_MAP).fillna(df["Province_Std"])

        df["Effective_Date"] = pd.to_datetime("2025-01-01")
        df["Expiration_Date"] = pd.NaT
        df["Is_Current"] = 1

    # 12/15: Outlier_Flag
    print("Bước 12/15: Đang tính Outlier_Flag theo Phân vị P1-P99 giá/m2 từng tỉnh, Area > 20.000, Width > 100")
    national_p1 = df["Price_per_m2"].quantile(0.01)
    national_p99 = df["Price_per_m2"].quantile(0.99)

    def is_price_outlier(group):
        if len(group) >= 50:
            p1 = group["Price_per_m2"].quantile(0.01)
            p99 = group["Price_per_m2"].quantile(0.99)
        else:
            p1, p99 = national_p1, national_p99
        return (group["Price_per_m2"] < p1) | (group["Price_per_m2"] > p99)

    price_outlier_mask = df.groupby("Province_Std", group_keys=False).apply(is_price_outlier).astype(bool)
    outlier_area = df["Area"] > 20000 if "Area" in df.columns else False
    outlier_width = df["Width"] > 100 if "Width" in df.columns else False

    df["Outlier_Flag"] = np.where(price_outlier_mask | outlier_area | outlier_width, 1, 0)

    # Tạo Row_Hash theo Bảng 2
    print("Đang khởi tạo cột Row_Hash (MD5)")
    df["Row_Hash"] = df.apply(generate_row_hash, axis=1)

    # 13/15: Categorical attributes
    print("Bước 13/15: Chuẩn hóa Direction, Road Type, Position, Seller_Type")
    if "Direction" in df.columns:
        df["Direction"] = df["Direction"].apply(normalize_direction)

    if "Road Type" in df.columns:
        df["Road Type"] = df["Road Type"].apply(normalize_road_type)

    if "Position" in df.columns:
        df["Position"] = df["Position"].astype(str).str.strip()
        df["Position"] = df["Position"].replace(["nan", "None", "", "NULL"], "Không xác định").fillna("Không xác định")

    if "Agent Role" in df.columns:
        df["Seller_Type"] = df["Agent Role"].astype(str).str.strip()
        df["Seller_Type"] = df["Seller_Type"].replace(["nan", "None", "", "NULL"], "Không xác định").fillna("Không xác định")

    # 14/15: Drop unused columns
    print("Bước 14/15: Loại bỏ các cột dư thừa / PII")
    cols_to_drop = [
        "Property Type Slug", "Province", "VIP Account", "Avatar", "Agent Name",
        "Agent Listing Count", "Bedrooms", "Bathrooms", "Floors", "Description",
        "Agent Role", "Last Updated", "Property Type", "Title"
    ]
    existing_cols_to_drop = [col for col in cols_to_drop if col in df.columns]
    df_cleaned = df.drop(columns=existing_cols_to_drop)

    # 15/15: Khóa chính Fact_Key / Listing_SK và thứ tự cột
    print("Bước 15/15: Tạo Fact_Key / Listing_SK và xuất kết quả Excel & CSV")
    df_cleaned = df_cleaned.reset_index(drop=True)
    df_cleaned["Fact_Key"] = df_cleaned.index + 1
    df_cleaned["Listing_SK"] = df_cleaned["Fact_Key"]

    priority_cols = [
        "Fact_Key", "Listing_SK", "Listing ID", "Batch_ID", "Row_Hash", "Scraped At", "Last Updated Date", "Time_Key", 
        "Year_Month", "Year", "Quarter", "Month", "Price_Segment", "Area_Group",
        "Dup_Flag", "Outlier_Flag", "Geo_Status", "Province_Match_Flag", "Length_Derived", "WxL_Check", "Land_Use_Class", 
        "Seller_Type", "Direction", "Road Type", "Admin_Version",
        "Province_Std", "Province_New", "Region", "City/District", "Ward/Commune",
        "Street", "Effective_Date", "Expiration_Date", "Is_Current",
        "Price", "Price_Billion", "Area", "Width", "Length", "Alley Width", "Latitude", "Longitude", "Price_per_m2"
    ]
    existing_priority = [c for c in priority_cols if c in df_cleaned.columns]
    other_cols = [c for c in df_cleaned.columns if c not in existing_priority]

    df_cleaned = df_cleaned[existing_priority + other_cols]

    # --- GHI FILE EXCEL ---
    print("Đang ghi kết quả ra file Excel!")
    try:
        df_cleaned.to_excel(output_excel_file, index=False, engine="openpyxl")
        print("File Excel kết quả đã lưu thành công tại:", output_excel_file)
    except PermissionError:
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        backup_excel_file = output_excel_file.replace(".xlsx", f"_{timestamp}.xlsx")
        print(f"CẢNH BÁO: File '{output_excel_file}' đang mở! Tự động lưu sang: '{backup_excel_file}'")
        df_cleaned.to_excel(backup_excel_file, index=False, engine="openpyxl")

    # --- GHI FILE CSV ---
    print("Đang ghi kết quả ra file CSV!")
    try:
        df_cleaned.to_csv(output_csv_file, index=False, encoding="utf-8-sig")
        print("File CSV kết quả đã lưu thành công tại:", output_csv_file)
    except PermissionError:
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        backup_csv_file = output_csv_file.replace(".csv", f"_{timestamp}.csv")
        print(f"CẢNH BÁO: File '{output_csv_file}' đang mở! Tự động lưu sang: '{backup_csv_file}'")
        df_cleaned.to_csv(backup_csv_file, index=False, encoding="utf-8-sig")

    elapsed_time = time.time() - start_time
    print("\nXử lý thành công hoàn toàn!")
    print("Tổng số dòng sạch là:", len(df_cleaned))
    print("Thời gian thực thi:", round(elapsed_time, 2), "giây")


if __name__ == "__main__":
    folder_path = r"C:\Users\Khanhlinh\OneDrive\Desktop\Tài liệu UTH\HK5\Kho dữ liệu & hệ thống hỗ trợ ra quyết định\Bài tập\Cuối kỳ"

    input_excel_path = os.path.join(folder_path, "VN-real-estate-Apr-Sept-2025.xlsx")
    output_excel_path = os.path.join(folder_path, "VN-real-estate-Apr-Sept-2025-cleaned.xlsx")
    output_csv_path = os.path.join(folder_path, "VN-real-estate-Apr-Sept-2025-cleaned.csv")

    clean_and_normalize_data(input_excel_path, output_excel_path, output_csv_path)