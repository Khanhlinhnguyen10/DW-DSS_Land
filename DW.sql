/*==============================================================
  ĐỒ ÁN: KHO DỮ LIỆU HỖ TRỢ RA QUYẾT ĐỊNH ĐỊNH GIÁ
         VÀ TƯ VẤN ĐẦU TƯ ĐẤT CÁ NHÂN

  CẤU TRÚC:
  1. Tạo Database
  2. Tạo Staging
  3. Tạo CleanListing và Reject_Log
  4. Tạo các bảng Dimension
  5. Tạo bảng Fact
  6. Tạo Index
  7. Nạp dữ liệu Dimension
  8. Kiểm tra cấu trúc Data Warehouse
  9. Kiểm tra dữ liệu sau ETL

==============================================================*/


/*==============================================================
  PHẦN 1: KIỂM TRA KẾT NỐI VÀ TẠO DATABASE
==============================================================*/

-- 1.1. Kiểm tra kết nối SQL Server
SELECT
    @@SERVERNAME AS ServerName,
    DB_NAME() AS CurrentDatabase,
    GETDATE() AS CheckTime;
GO


-- 1.2. Tạo Database Staging
IF DB_ID('Land_Staging') IS NULL
BEGIN
    CREATE DATABASE Land_Staging;
    PRINT N'Đã tạo Database Land_Staging thành công';
END
ELSE
    PRINT N'Database Land_Staging đã tồn tại';
GO


-- 1.3. Tạo Database Data Warehouse
IF DB_ID('DW_Land') IS NULL
BEGIN
    CREATE DATABASE DW_Land;
    PRINT N'Đã tạo Database DW_Land thành công';
END
ELSE
    PRINT N'Database DW_Land đã tồn tại';
GO


-- 1.4. Kiểm tra trạng thái hai Database
SELECT
    name AS DatabaseName,
    state_desc AS DatabaseStatus
FROM sys.databases
WHERE name IN ('Land_Staging', 'DW_Land')
ORDER BY name;
GO



/*==============================================================
  PHẦN 2: TẠO BẢNG STAGING
  Database: Land_Staging
  Mục đích: Tiếp nhận dữ liệu thô từ file CSV
==============================================================*/

USE Land_Staging;
GO


-- 2.1. Tạo bảng tiếp nhận dữ liệu thô
IF OBJECT_ID('dbo.stgRawListing', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.stgRawListing
    (
        ListingID NVARCHAR(255),
        Title NVARCHAR(MAX),
        Price NVARCHAR(255),
        Area NVARCHAR(255),
        Location NVARCHAR(MAX),
        LastUpdated NVARCHAR(255),
        PropertyType NVARCHAR(255),
        PropertyTypeSlug NVARCHAR(255),
        Width NVARCHAR(255),
        Length NVARCHAR(255),
        Bedrooms NVARCHAR(255),
        Bathrooms NVARCHAR(255),
        Floors NVARCHAR(255),
        Position NVARCHAR(255),
        Direction NVARCHAR(255),
        AlleyWidth NVARCHAR(255),
        RoadType NVARCHAR(255),
        Description NVARCHAR(MAX),
        Latitude NVARCHAR(255),
        Longitude NVARCHAR(255),
        VIPAccount NVARCHAR(255),
        Avatar NVARCHAR(255),
        AgentRole NVARCHAR(255),
        AgentName NVARCHAR(255),
        AgentListingCount NVARCHAR(255),
        Province NVARCHAR(255),
        ScrapedAt NVARCHAR(255),
        LastUpdatedDate NVARCHAR(255),

        -- Hai cột bổ sung phục vụ quá trình ETL
        StagingLoadedAt DATETIME DEFAULT GETDATE(),
        SourceFileName NVARCHAR(255)
    );

    PRINT N'Đã tạo bảng stgRawListing thành công';
END
ELSE
    PRINT N'Bảng stgRawListing đã tồn tại';
GO


-- 2.2. Kiểm tra sự tồn tại của bảng
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'stgRawListing';
GO


-- 2.3. Kiểm tra tổng số cột
SELECT
    COUNT(*) AS TotalColumns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'stgRawListing';
GO


-- 2.4. Kiểm tra tên cột và kiểu dữ liệu
SELECT
    ORDINAL_POSITION AS ColumnNo,
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'stgRawListing'
ORDER BY ORDINAL_POSITION;
GO


-- 2.5. Kiểm tra hai cột bổ sung
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'stgRawListing'
  AND COLUMN_NAME IN ('StagingLoadedAt', 'SourceFileName');
GO


-- 2.6. Hiển thị năm dòng dữ liệu đầu tiên
SELECT TOP 5 *
FROM dbo.stgRawListing;
GO


-- 2.7. Kiểm tra tổng số dòng dữ liệu đã nạp
SELECT
    COUNT_BIG(*) AS TotalRawRows
FROM dbo.stgRawListing;
GO



/*==============================================================
  PHẦN 3: TẠO BẢNG CLEANLISTING
  Mục đích: Lưu dữ liệu sau khi làm sạch và chuẩn hóa
==============================================================*/

IF OBJECT_ID('dbo.CleanListing', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CleanListing
    (
        -- Khóa chính tự tăng
        CleanListingKey INT IDENTITY(1,1) PRIMARY KEY,

        -- Thông tin tin đăng
        ListingID NVARCHAR(255) NOT NULL,

        -- Thông tin giá và diện tích
        Price DECIMAL(22,2) NOT NULL,
        Area DECIMAL(18,2) NOT NULL,
        PricePerM2 DECIMAL(22,6) NOT NULL,
        Price_Billion DECIMAL(18,6) NOT NULL,

        -- Kích thước lô đất
        Width DECIMAL(18,2) NULL,
        Length DECIMAL(18,2) NULL,
        Length_Derived BIT NOT NULL DEFAULT 0,
        AlleyWidth DECIMAL(18,2) NULL,

        -- Thông tin thời gian
        LastUpdatedDate DATETIME2 NULL,
        Time_Key INT NULL,
        ScrapedAt DATETIME2 NULL,

        -- Thông tin địa điểm
        LocationRaw NVARCHAR(MAX) NULL,
        Province_Std NVARCHAR(255) NULL,
        District NVARCHAR(255) NULL,
        Ward NVARCHAR(255) NULL,
        Street NVARCHAR(255) NULL,
        Admin_Version NVARCHAR(50) NULL,
        Region NVARCHAR(100) NULL,

        -- Đặc điểm lô đất
        Position NVARCHAR(255) NULL,
        Direction NVARCHAR(255) NULL,
        RoadType NVARCHAR(255) NULL,
        Seller_Type NVARCHAR(100) NULL,
        Land_Use_Class NVARCHAR(100) NULL,

        -- Thông tin tọa độ
        Latitude DECIMAL(10,7) NULL,
        Longitude DECIMAL(10,7) NULL,
        Geo_Status NVARCHAR(50) NULL,

        -- Thời điểm làm sạch dữ liệu
        CleanedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );

    PRINT N'Đã tạo bảng CleanListing thành công';
END
ELSE
    PRINT N'Bảng CleanListing đã tồn tại';
GO


-- 3.1. Kiểm tra cấu trúc bảng CleanListing
EXEC sp_help 'dbo.CleanListing';
GO


-- 3.2. Kiểm tra số dòng dữ liệu
SELECT
    COUNT_BIG(*) AS TotalCleanRows
FROM dbo.CleanListing;
GO



/*==============================================================
  PHẦN 4: TẠO BẢNG REJECT_LOG
  Mục đích: Lưu thông tin các bản ghi không đạt yêu cầu
==============================================================*/

IF OBJECT_ID('dbo.Reject_Log', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Reject_Log
    (
        RejectID BIGINT IDENTITY(1,1) PRIMARY KEY,
        ListingID NVARCHAR(255) NULL,
        ColumnName NVARCHAR(100) NOT NULL,
        ErrorCode INT NULL,
        ErrorColumn INT NULL,
        ErrorDescription NVARCHAR(2000) NULL,
        RejectedAt DATETIME2 DEFAULT GETDATE()
    );

    PRINT N'Đã tạo bảng Reject_Log thành công';
END
ELSE
    PRINT N'Bảng Reject_Log đã tồn tại';
GO


-- 4.1. Kiểm tra các bảng trong Land_Staging
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN
(
    'stgRawListing',
    'CleanListing',
    'Reject_Log'
)
ORDER BY TABLE_NAME;
GO



/*==============================================================
  PHẦN 5: TẠO CÁC BẢNG DIMENSION
  Database: DW_Land
  Mô hình: Star Schema
==============================================================*/

USE DW_Land;
GO


-- 5.1. Tạo bảng Dim_Time
-- Mỗi dòng đại diện cho một tháng
-- TimeKey có định dạng YYYYMM
-- Giá trị -1 đại diện cho thời gian không xác định

IF OBJECT_ID('dbo.Dim_Time', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Time
    (
        TimeKey INT NOT NULL,
        [Year] SMALLINT NOT NULL,
        [Quarter] TINYINT NOT NULL,
        [Month] TINYINT NOT NULL,
        YearMonth CHAR(7) NOT NULL,
        MonthName NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_Dim_Time
            PRIMARY KEY CLUSTERED (TimeKey),

        CONSTRAINT CK_Dim_Time_Quarter
            CHECK ([Quarter] BETWEEN 0 AND 4),

        CONSTRAINT CK_Dim_Time_Month
            CHECK ([Month] BETWEEN 0 AND 12)
    );
END;
GO


-- 5.2. Tạo bảng Dim_Location
-- Lưu thông tin địa điểm và lịch sử thay đổi địa giới
-- Áp dụng thiết kế SCD Type 2

IF OBJECT_ID('dbo.Dim_Location', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Location
    (
        -- Khóa thay thế tự tăng
        LocationKey INT IDENTITY(1,1) NOT NULL,

        -- Tên tỉnh theo dữ liệu gốc
        Province NVARCHAR(100) NOT NULL,

        -- Tên tỉnh sau sáp nhập
        ProvinceNew NVARCHAR(100) NOT NULL
            DEFAULT N'Không xác định',

        -- Nhóm vùng địa lý
        RegionGroup NVARCHAR(50) NOT NULL
            DEFAULT N'Không xác định',

        -- Thông tin địa giới
        District NVARCHAR(100) NOT NULL
            DEFAULT N'Không xác định',

        Ward NVARCHAR(100) NOT NULL
            DEFAULT N'Không xác định',

        Street NVARCHAR(300) NOT NULL
            DEFAULT N'Không xác định',

        -- Phiên bản địa giới hành chính
        AdminVersion NVARCHAR(10) NOT NULL
            DEFAULT N'Unknown',

        -- Đường dẫn địa điểm được tính tự động
        LocationPath AS
            (Province + N' > ' + District + N' > ' + Ward) PERSISTED,

        -- Thời gian hiệu lực
        EffectiveFrom DATE NOT NULL
            DEFAULT CAST(GETDATE() AS DATE),

        EffectiveTo DATE NULL,

        -- Đánh dấu bản ghi hiện tại
        IsCurrent BIT NOT NULL DEFAULT 1,

        CONSTRAINT PK_Dim_Location
            PRIMARY KEY CLUSTERED (LocationKey),

        CONSTRAINT CK_Dim_Location_Admin
            CHECK (AdminVersion IN (N'Old', N'New', N'Unknown'))
    );
END;
GO


-- Tạo chỉ mục duy nhất cho địa điểm hiện tại
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_Dim_Location_Current'
      AND object_id = OBJECT_ID('dbo.Dim_Location')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_Dim_Location_Current
    ON dbo.Dim_Location
    (
        Province,
        District,
        Ward,
        Street,
        AdminVersion
    )
    WHERE IsCurrent = 1;
END;
GO


-- 5.3. Tạo bảng Dim_Size_Group
-- Phân chia diện tích đất thành sáu nhóm
-- Khoảng giá trị áp dụng quy tắc [MinArea, MaxArea)
IF OBJECT_ID('dbo.Dim_Size_Group', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Size_Group
    (
        SizeKey INT NOT NULL,
        AreaGroup NVARCHAR(40) NOT NULL,
        MinArea DECIMAL(19,2) NOT NULL,
        MaxArea DECIMAL(19,2) NULL,
        SortOrder TINYINT NOT NULL,

        CONSTRAINT PK_Dim_Size_Group
            PRIMARY KEY CLUSTERED (SizeKey),

        CONSTRAINT UQ_Dim_Size_Group_Name
            UNIQUE (AreaGroup),

        CONSTRAINT CK_Dim_Size_Group_Range
            CHECK (MaxArea IS NULL OR MaxArea > MinArea)
    );
END;
GO


-- 5.4. Tạo bảng Dim_Price_Segment
-- Phân chia giá đất thành năm nhóm
-- Đơn vị giá: tỷ đồng
IF OBJECT_ID('dbo.Dim_Price_Segment', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Price_Segment
    (
        SegmentKey INT NOT NULL,
        PriceSegment NVARCHAR(40) NOT NULL,
        MinBillion DECIMAL(19,4) NOT NULL,
        MaxBillion DECIMAL(19,4) NULL,
        SortOrder TINYINT NOT NULL,

        CONSTRAINT PK_Dim_Price_Segment
            PRIMARY KEY CLUSTERED (SegmentKey),

        CONSTRAINT UQ_Dim_Price_Segment_Name
            UNIQUE (PriceSegment),

        CONSTRAINT CK_Dim_Price_Segment_Range
            CHECK (MaxBillion IS NULL OR MaxBillion > MinBillion)
    );
END;
GO


-- 5.5. Tạo bảng Dim_Land_Profile
-- Lưu các thuộc tính phân loại đặc điểm lô đất

IF OBJECT_ID('dbo.Dim_Land_Profile', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Land_Profile
    (
        ProfileKey INT IDENTITY(1,1) NOT NULL,

        Position NVARCHAR(100) NOT NULL
            DEFAULT N'Không xác định',

        Direction NVARCHAR(50) NOT NULL
            DEFAULT N'Không xác định',

        RoadType NVARCHAR(100) NOT NULL
            DEFAULT N'Không xác định',

        LandUseClass NVARCHAR(50) NOT NULL
            DEFAULT N'Chưa xác định',

        SellerType NVARCHAR(50) NOT NULL
            DEFAULT N'Không xác định',

        CONSTRAINT PK_Dim_Land_Profile
            PRIMARY KEY CLUSTERED (ProfileKey),

        CONSTRAINT UQ_Dim_Land_Profile
            UNIQUE
            (
                Position,
                Direction,
                RoadType,
                LandUseClass,
                SellerType
            )
    );
END;
GO



/*==============================================================
  PHẦN 6: TẠO BẢNG FACT_LISTING
  Mỗi dòng đại diện cho một tin đăng bán đất
==============================================================*/

IF OBJECT_ID('dbo.Fact_Listing', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Listing
    (
        -- Khóa chính tự tăng
        ListingKey BIGINT IDENTITY(1,1) NOT NULL,

        -- Mã tin đăng gốc
        ListingID BIGINT NOT NULL,

        -- Năm khóa ngoại liên kết Dimension
        TimeKey INT NOT NULL,
        LocationKey INT NOT NULL,
        SizeKey INT NOT NULL,
        SegmentKey INT NOT NULL,
        ProfileKey INT NOT NULL,

        -- Thông tin giá và diện tích
        Price DECIMAL(19,2) NOT NULL,
        PriceBillion DECIMAL(19,6) NULL,
        Area DECIMAL(19,2) NOT NULL,
        PricePerM2 DECIMAL(19,4) NOT NULL,

        -- Kích thước lô đất
        Width DECIMAL(10,2) NULL,
        Length DECIMAL(10,2) NULL,
        AlleyWidth DECIMAL(8,2) NULL,

        -- Tọa độ địa lý
        Latitude DECIMAL(9,6) NULL,
        Longitude DECIMAL(9,6) NULL,

        -- Các cờ kiểm tra chất lượng dữ liệu
        LengthDerived BIT NOT NULL DEFAULT 0,
        WxLCheck BIT NULL,

        GeoStatus NVARCHAR(10) NOT NULL DEFAULT N'Missing',
        OutlierFlag BIT NOT NULL DEFAULT 0,
        DupFlag BIT NOT NULL DEFAULT 0,

        -- Thông tin hỗ trợ ETL
        RowHash CHAR(32) NULL,
        BatchID INT NULL,

        -- Thời gian
        ScrapedAt DATETIME2(0) NULL,
        LastUpdatedAt DATETIME2(0) NULL,

        LoadDate DATETIME2(0) NOT NULL
            DEFAULT SYSDATETIME(),

        -- Khóa chính
        CONSTRAINT PK_Fact_Listing
            PRIMARY KEY CLUSTERED (ListingKey),

        -- Mỗi mã tin đăng chỉ xuất hiện một lần
        CONSTRAINT UQ_Fact_Listing_ListingID
            UNIQUE (ListingID),

        -- Các khóa ngoại
        CONSTRAINT FK_Fact_Listing_Time
            FOREIGN KEY (TimeKey)
            REFERENCES dbo.Dim_Time(TimeKey),

        CONSTRAINT FK_Fact_Listing_Location
            FOREIGN KEY (LocationKey)
            REFERENCES dbo.Dim_Location(LocationKey),

        CONSTRAINT FK_Fact_Listing_Size
            FOREIGN KEY (SizeKey)
            REFERENCES dbo.Dim_Size_Group(SizeKey),

        CONSTRAINT FK_Fact_Listing_Segment
            FOREIGN KEY (SegmentKey)
            REFERENCES dbo.Dim_Price_Segment(SegmentKey),

        CONSTRAINT FK_Fact_Listing_Profile
            FOREIGN KEY (ProfileKey)
            REFERENCES dbo.Dim_Land_Profile(ProfileKey),

        -- Kiểm tra giá hợp lệ
        CONSTRAINT CK_Fact_Price
            CHECK (Price > 0 AND Price < 1000000),

        -- Kiểm tra diện tích hợp lệ
        CONSTRAINT CK_Fact_Area
            CHECK (Area >= 10 AND Area <= 1000000),

        -- Kiểm tra giá trên mét vuông
        CONSTRAINT CK_Fact_PricePerM2
            CHECK (PricePerM2 > 0),

        -- Kiểm tra trạng thái tọa độ
        CONSTRAINT CK_Fact_GeoStatus
            CHECK (GeoStatus IN (N'Valid', N'Missing', N'Invalid'))
    );
END;
GO



/*==============================================================
  PHẦN 7: TẠO INDEX CHO FACT_LISTING
  Mục đích: Hỗ trợ truy vấn và liên kết dữ liệu
==============================================================*/

-- 7.1. Index cho TimeKey
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Fact_Listing_TimeKey'
      AND object_id = OBJECT_ID('dbo.Fact_Listing')
)
CREATE NONCLUSTERED INDEX IX_Fact_Listing_TimeKey
ON dbo.Fact_Listing(TimeKey);
GO


-- 7.2. Index cho LocationKey
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Fact_Listing_LocationKey'
      AND object_id = OBJECT_ID('dbo.Fact_Listing')
)
CREATE NONCLUSTERED INDEX IX_Fact_Listing_LocationKey
ON dbo.Fact_Listing(LocationKey);
GO


-- 7.3. Index cho SizeKey
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Fact_Listing_SizeKey'
      AND object_id = OBJECT_ID('dbo.Fact_Listing')
)
CREATE NONCLUSTERED INDEX IX_Fact_Listing_SizeKey
ON dbo.Fact_Listing(SizeKey);
GO


-- 7.4. Index cho SegmentKey
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Fact_Listing_SegmentKey'
      AND object_id = OBJECT_ID('dbo.Fact_Listing')
)
CREATE NONCLUSTERED INDEX IX_Fact_Listing_SegmentKey
ON dbo.Fact_Listing(SegmentKey);
GO


-- 7.5. Index cho ProfileKey
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Fact_Listing_ProfileKey'
      AND object_id = OBJECT_ID('dbo.Fact_Listing')
)
CREATE NONCLUSTERED INDEX IX_Fact_Listing_ProfileKey
ON dbo.Fact_Listing(ProfileKey);
GO



/*==============================================================
  PHẦN 8: NẠP DỮ LIỆU MẶC ĐỊNH VÀO DIMENSION
  Giá trị khóa -1 đại diện cho dữ liệu không xác định
==============================================================*/


-- 8.1. Nạp dòng không xác định vào Dim_Time
IF NOT EXISTS (
    SELECT 1 FROM dbo.Dim_Time WHERE TimeKey = -1
)
BEGIN
    INSERT INTO dbo.Dim_Time
    (
        TimeKey,
        [Year],
        [Quarter],
        [Month],
        YearMonth,
        MonthName
    )
    VALUES
    (
        -1,
        0,
        0,
        0,
        '0000-00',
        N'Không xác định'
    );
END;
GO


-- 8.2. Nạp dòng không xác định vào Dim_Location
IF NOT EXISTS (
    SELECT 1 FROM dbo.Dim_Location WHERE LocationKey = -1
)
BEGIN
    SET IDENTITY_INSERT dbo.Dim_Location ON;

    INSERT INTO dbo.Dim_Location
    (
        LocationKey,
        Province,
        District,
        Ward,
        Street
    )
    VALUES
    (
        -1,
        N'Không xác định',
        N'Không xác định',
        N'Không xác định',
        N'Không xác định'
    );

    SET IDENTITY_INSERT dbo.Dim_Location OFF;
END;
GO


-- 8.3. Nạp dòng không xác định vào Dim_Land_Profile
IF NOT EXISTS (
    SELECT 1 FROM dbo.Dim_Land_Profile WHERE ProfileKey = -1
)
BEGIN
    SET IDENTITY_INSERT dbo.Dim_Land_Profile ON;

    INSERT INTO dbo.Dim_Land_Profile
    (
        ProfileKey,
        Position,
        Direction,
        RoadType,
        LandUseClass,
        SellerType
    )
    VALUES
    (
        -1,
        N'Không xác định',
        N'Không xác định',
        N'Không xác định',
        N'Chưa xác định',
        N'Không xác định'
    );

    SET IDENTITY_INSERT dbo.Dim_Land_Profile OFF;
END;
GO



/*==============================================================
  PHẦN 9: NẠP DỮ LIỆU DIMENSION
==============================================================*/


-- 9.1. Nạp dữ liệu thời gian năm 2025
-- Từ tháng 03 đến tháng 12

INSERT INTO dbo.Dim_Time
(
    TimeKey,
    [Year],
    [Quarter],
    [Month],
    YearMonth,
    MonthName
)
SELECT
    YEAR(V.D) * 100 + MONTH(V.D),
    YEAR(V.D),
    DATEPART(QUARTER, V.D),
    MONTH(V.D),
    CONVERT(CHAR(7), V.D, 126),
    N'Tháng ' + CAST(MONTH(V.D) AS NVARCHAR(2))
FROM
(
    VALUES
        (CAST('2025-03-01' AS DATE)),
        (CAST('2025-04-01' AS DATE)),
        (CAST('2025-05-01' AS DATE)),
        (CAST('2025-06-01' AS DATE)),
        (CAST('2025-07-01' AS DATE)),
        (CAST('2025-08-01' AS DATE)),
        (CAST('2025-09-01' AS DATE)),
        (CAST('2025-10-01' AS DATE)),
        (CAST('2025-11-01' AS DATE)),
        (CAST('2025-12-01' AS DATE))
) V(D)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Dim_Time T
    WHERE T.TimeKey = YEAR(V.D) * 100 + MONTH(V.D)
);
GO


-- 9.2. Nạp sáu nhóm diện tích
INSERT INTO dbo.Dim_Size_Group
(
    SizeKey,
    AreaGroup,
    MinArea,
    MaxArea,
    SortOrder
)
SELECT
    V.SizeKey,
    V.AreaGroup,
    V.MinArea,
    V.MaxArea,
    V.SortOrder
FROM
(
    VALUES
        (1, N'Dưới 50 m²', 0, 50, 1),
        (2, N'50–100 m²', 50, 100, 2),
        (3, N'100–200 m²', 100, 200, 3),
        (4, N'200–500 m²', 200, 500, 4),
        (5, N'500–1.000 m²', 500, 1000, 5),
        (6, N'Từ 1.000 m² trở lên', 1000, NULL, 6)
) V(SizeKey, AreaGroup, MinArea, MaxArea, SortOrder)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Dim_Size_Group T
    WHERE T.SizeKey = V.SizeKey
);
GO


-- 9.3. Nạp năm phân khúc giá
-- Đơn vị: tỷ đồng

INSERT INTO dbo.Dim_Price_Segment
(
    SegmentKey,
    PriceSegment,
    MinBillion,
    MaxBillion,
    SortOrder
)
SELECT
    V.SegmentKey,
    V.PriceSegment,
    V.MinBillion,
    V.MaxBillion,
    V.SortOrder
FROM
(
    VALUES
        (1, N'Dưới 1 tỷ', 0, 1, 1),
        (2, N'1–3 tỷ', 1, 3, 2),
        (3, N'3–5 tỷ', 3, 5, 3),
        (4, N'5–10 tỷ', 5, 10, 4),
        (5, N'Từ 10 tỷ trở lên', 10, NULL, 5)
) V(SegmentKey, PriceSegment, MinBillion, MaxBillion, SortOrder)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Dim_Price_Segment T
    WHERE T.SegmentKey = V.SegmentKey
);
GO



/*==============================================================
  PHẦN 10: KIỂM TRA CẤU TRÚC DATA WAREHOUSE
==============================================================*/


-- 10.1. Kiểm tra danh sách sáu bảng
SELECT
    S.name AS SchemaName,
    T.name AS TableName
FROM sys.tables T
JOIN sys.schemas S
    ON T.schema_id = S.schema_id
WHERE S.name = N'dbo'
  AND T.name IN
  (
      N'Dim_Time',
      N'Dim_Location',
      N'Dim_Size_Group',
      N'Dim_Price_Segment',
      N'Dim_Land_Profile',
      N'Fact_Listing'
  )
ORDER BY T.name;
GO


-- 10.2. Kiểm tra số lượng cột của từng bảng
SELECT
    T.name AS TableName,
    COUNT(C.column_id) AS ColumnCount
FROM sys.tables T
JOIN sys.columns C
    ON T.object_id = C.object_id
WHERE T.name IN
(
    N'Dim_Time',
    N'Dim_Location',
    N'Dim_Size_Group',
    N'Dim_Price_Segment',
    N'Dim_Land_Profile',
    N'Fact_Listing'
)
GROUP BY T.name
ORDER BY T.name;
GO


-- 10.3. Kiểm tra năm khóa ngoại của Fact_Listing
SELECT
    FK.name AS ForeignKeyName,
    OBJECT_NAME(FK.parent_object_id) AS TableName,
    COL_NAME(FKC.parent_object_id, FKC.parent_column_id)
        AS ForeignKeyColumn,
    OBJECT_NAME(FKC.referenced_object_id) AS ReferencedTable,
    COL_NAME(FKC.referenced_object_id, FKC.referenced_column_id)
        AS ReferencedColumn
FROM sys.foreign_keys FK
JOIN sys.foreign_key_columns FKC
    ON FK.object_id = FKC.constraint_object_id
WHERE FK.parent_object_id = OBJECT_ID(N'dbo.Fact_Listing')
ORDER BY FK.name;
GO


-- 10.4. Kiểm tra các Index của Fact_Listing
SELECT
    T.name AS TableName,
    I.name AS IndexName,
    I.type_desc AS IndexType
FROM sys.indexes I
JOIN sys.tables T
    ON I.object_id = T.object_id
WHERE T.name = N'Fact_Listing'
  AND I.name LIKE N'IX_Fact_Listing_%'
ORDER BY I.name;
GO


-- 10.5. Đếm tổng số Index đã tạo
SELECT
    COUNT(*) AS TotalIndexes
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.Fact_Listing')
  AND name LIKE N'IX_Fact_Listing_%';
GO



/*==============================================================
  PHẦN 11: KIỂM TRA DỮ LIỆU DIMENSION
==============================================================*/


-- 11.1. Kiểm tra Dim_Time
SELECT *
FROM dbo.Dim_Time
ORDER BY TimeKey;
GO


-- 11.2. Kiểm tra Dim_Location
SELECT *
FROM dbo.Dim_Location
ORDER BY LocationKey;
GO


-- 11.3. Kiểm tra Dim_Size_Group
SELECT *
FROM dbo.Dim_Size_Group
ORDER BY SortOrder;
GO


-- 11.4. Kiểm tra Dim_Price_Segment
SELECT *
FROM dbo.Dim_Price_Segment
ORDER BY SortOrder;
GO


-- 11.5. Kiểm tra Dim_Land_Profile
SELECT *
FROM dbo.Dim_Land_Profile
ORDER BY ProfileKey;
GO


-- 11.6. Đếm số dòng của sáu bảng
SELECT N'Dim_Time' AS TableName, COUNT_BIG(*) AS TotalRows
FROM dbo.Dim_Time

UNION ALL

SELECT N'Dim_Location', COUNT_BIG(*)
FROM dbo.Dim_Location

UNION ALL

SELECT N'Dim_Size_Group', COUNT_BIG(*)
FROM dbo.Dim_Size_Group

UNION ALL

SELECT N'Dim_Price_Segment', COUNT_BIG(*)
FROM dbo.Dim_Price_Segment

UNION ALL

SELECT N'Dim_Land_Profile', COUNT_BIG(*)
FROM dbo.Dim_Land_Profile

UNION ALL

SELECT N'Fact_Listing', COUNT_BIG(*)
FROM dbo.Fact_Listing;
GO



/*==============================================================
  PHẦN 12: KIỂM TRA RÀNG BUỘC CHECK_Fact_Price
  Thử thêm một bản ghi có giá âm
  Kết quả mong đợi: SQL Server từ chối bản ghi
==============================================================*/

BEGIN TRY
    INSERT INTO dbo.Fact_Listing
    (
        ListingID,
        TimeKey,
        LocationKey,
        SizeKey,
        SegmentKey,
        ProfileKey,
        Price,
        Area,
        PricePerM2
    )
    VALUES
    (
        -999,
        -1,
        -1,
        1,
        1,
        -1,
        -5,
        100,
        1
    );

    PRINT N'Cần kiểm tra: Bản ghi sai đã được thêm';

END TRY
BEGIN CATCH

    SELECT
        N'ĐẠT: SQL Server đã chặn bản ghi dữ liệu sai'
            AS TestResult,
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO



/*==============================================================
  PHẦN 13: KIỂM TRA DỮ LIỆU SAU ETL
  Chỉ thực hiện sau khi SSIS đã nạp dữ liệu
==============================================================*/


-- 13.1. Kiểm tra số dòng dữ liệu thô
USE Land_Staging;
GO

SELECT
    COUNT_BIG(*) AS TotalRawRows
FROM dbo.stgRawListing;
GO


-- 13.2. Kiểm tra số dòng dữ liệu sạch
SELECT
    COUNT_BIG(*) AS TotalCleanRows
FROM dbo.CleanListing;
GO


-- 13.3. Kiểm tra số dòng dữ liệu bị từ chối
SELECT
    COUNT_BIG(*) AS TotalRejectedRows
FROM dbo.Reject_Log;
GO


-- 13.4. So sánh số dòng Staging, CleanListing và Fact
USE DW_Land;
GO

SELECT
    (SELECT COUNT_BIG(*)
     FROM Land_Staging.dbo.stgRawListing) AS TotalRawRows,

    (SELECT COUNT_BIG(*)
     FROM Land_Staging.dbo.CleanListing) AS TotalCleanRows,

    (SELECT COUNT_BIG(*)
     FROM dbo.Fact_Listing) AS TotalFactRows;
GO



/*==============================================================
  PHẦN 14: KIỂM TRA LIÊN KẾT NĂM KHÓA NGOẠI
  Kết quả mong đợi: Các cột Missing đều bằng 0
==============================================================*/

SELECT
    SUM(CASE WHEN T.TimeKey IS NULL THEN 1 ELSE 0 END)
        AS Missing_TimeKey,

    SUM(CASE WHEN L.LocationKey IS NULL THEN 1 ELSE 0 END)
        AS Missing_LocationKey,

    SUM(CASE WHEN S.SizeKey IS NULL THEN 1 ELSE 0 END)
        AS Missing_SizeKey,

    SUM(CASE WHEN P.SegmentKey IS NULL THEN 1 ELSE 0 END)
        AS Missing_SegmentKey,

    SUM(CASE WHEN Pr.ProfileKey IS NULL THEN 1 ELSE 0 END)
        AS Missing_ProfileKey

FROM dbo.Fact_Listing F

LEFT JOIN dbo.Dim_Time T
    ON F.TimeKey = T.TimeKey

LEFT JOIN dbo.Dim_Location L
    ON F.LocationKey = L.LocationKey

LEFT JOIN dbo.Dim_Size_Group S
    ON F.SizeKey = S.SizeKey

LEFT JOIN dbo.Dim_Price_Segment P
    ON F.SegmentKey = P.SegmentKey

LEFT JOIN dbo.Dim_Land_Profile Pr
    ON F.ProfileKey = Pr.ProfileKey;
GO



/*==============================================================
  PHẦN 15: TRUY VẤN 10 DÒNG DỮ LIỆU HOÀN CHỈNH
  Kết hợp Fact và năm bảng Dimension
==============================================================*/

SELECT TOP 10
    F.ListingID,
    T.YearMonth,
    L.Province,
    L.District,
    S.AreaGroup,
    P.PriceSegment,
    Pr.Position,
    Pr.SellerType,
    F.Price,
    F.Area,
    F.PricePerM2

FROM dbo.Fact_Listing F

INNER JOIN dbo.Dim_Time T
    ON F.TimeKey = T.TimeKey

INNER JOIN dbo.Dim_Location L
    ON F.LocationKey = L.LocationKey

INNER JOIN dbo.Dim_Size_Group S
    ON F.SizeKey = S.SizeKey

INNER JOIN dbo.Dim_Price_Segment P
    ON F.SegmentKey = P.SegmentKey

INNER JOIN dbo.Dim_Land_Profile Pr
    ON F.ProfileKey = Pr.ProfileKey;
GO


/*==============================================================
  KẾT THÚC SCRIPT
==============================================================*/
