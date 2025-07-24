CREATE TABLE customer
(
        c_custkey       UInt32,
        c_name          String,
        c_address       String,
        c_city          LowCardinality(String),
        c_nation        LowCardinality(String),
        c_region        LowCardinality(String),
        c_phone         String,
        c_mktsegment    LowCardinality(String)
)
ENGINE = MergeTree ORDER BY (c_custkey);

CREATE TABLE lineorder
(
    lo_orderkey             UInt32,
    lo_linenumber           UInt8,
    lo_custkey              UInt32,
    lo_partkey              UInt32,
    lo_suppkey              UInt32,
    lo_orderdate            Date,
    lo_orderpriority        LowCardinality(String),
    lo_shippriority         UInt8,
    lo_quantity             UInt8,
    lo_extendedprice        UInt32,
    lo_ordtotalprice        UInt32,
    lo_discount             UInt8,
    lo_revenue              UInt32,
    lo_supplycost           UInt32,
    lo_tax                  UInt8,
    lo_commitdate           Date,
    lo_shipmode             LowCardinality(String)
)
ENGINE = MergeTree PARTITION BY toYear(lo_orderdate) ORDER BY (lo_orderdate, lo_orderkey);

CREATE TABLE part
(
        p_partkey       UInt32,
        p_name          String,
        p_mfgr          LowCardinality(String),
        p_category      LowCardinality(String),
        p_brand         LowCardinality(String),
        p_color         LowCardinality(String),
        p_type          LowCardinality(String),
        p_size          UInt8,
        p_container     LowCardinality(String)
)
ENGINE = MergeTree ORDER BY p_partkey;

CREATE TABLE supplier
(
        s_suppkey       UInt32,
        s_name          String,
        s_address       String,
        s_city          LowCardinality(String),
        s_nation        LowCardinality(String),
        s_region        LowCardinality(String),
        s_phone         String
)
ENGINE = MergeTree ORDER BY s_suppkey;

CREATE TABLE dates
(
        d_datekey            Date,
        d_date               FixedString(18),
        d_dayofweek          LowCardinality(String),
        d_month              LowCardinality(String),
        d_year               UInt16,
        d_yearmonthnum       UInt32,
        d_yearmonth          LowCardinality(FixedString(7)),
        d_daynuminweek       UInt8,
        d_daynuminmonth      UInt8,
        d_daynuminyear       UInt16,
        d_monthnuminyear     UInt8,
        d_weeknuminyear      UInt8,
        d_sellingseason      String,
        d_lastdayinweekfl    UInt8,
        d_lastdayinmonthfl   UInt8,
        d_holidayfl          UInt8,
        d_weekdayfl          UInt8
)
ENGINE = MergeTree ORDER BY d_datekey;