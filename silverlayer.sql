SELECT * FROM bronze.crm_cust_info
LIMIT 1000

SELECT * FROM bronze.crm_prd_info
LIMIT 1000

SELECT * FROM bronze.crm_sales_details
LIMIT 1000

SELECT * FROM bronze.erp_cust_az12
LIMIT 1000

SELECT * FROM bronze.erp_loc_a101
LIMIT 1000


SELECT * FROM bronze.erp_px_cat_g1v2
LIMIT 1000


drop table if exists silver.crm_cust_info;
create table silver.crm_cust_info(
cst_id INT,
cst_key VARCHAR(50),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_material_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date DATE, 
dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

drop table if exists silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
    prd_id       INT,
    cat_id       VARCHAR(50), -- Moved this up to match your SELECT order
    prd_key      VARCHAR(50),
    prd_nm       VARCHAR(50),
    prd_cost     INT,
    prd_line     VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt   DATE
);

drop table if exists silver.crm_sales_details;
create table silver.crm_sales_details(
sls_ord_num varchar(50),
sls_prd_key VARCHAR(50),
sls_cust_id INT,
sls_order_dt int,
sls_ship_dt int,
sls_due_dt int,
sls_sales int,
sls_quantity INT,
sls_price int
);

drop table if exists silver.erp_CUST_AZ12;
create table silver.erp_CUST_AZ12(
CID VARCHAR(50),
BDATE DATE,
GEN VARCHAR(50)
);

drop table if exists silver.erp_LOC_A101;
create table silver.erp_LOC_A101(
CID VARCHAR(50),
CNTRY VARCHAR(50)
);

drop table if exists silver.erp_PX_CAT_G1V2;
create table silver.erp_PX_CAT_G1V2(
ID VARCHAR(50),
CAT VARCHAR(50),
SUBCAT VARCHAR(50),
MAINTENANCE VARCHAR(50)
);

-- CHECKING QUALITY OF DATA
SELECT * FROM bronze.crm_cust_info
-- check for null and duplicates in primary key
select
cst_id,
count(*)
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null
--transform--
select * from bronze.crm_cust_info
where cst_id = 29466
order by cst_create_date desc
limit 1;
--another approach
SELECT 
*
FROM(
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
)t where flag_last = 1 and cst_id = 29466


--in string values we have to check whether there is unwanted space or not
select cst_firstname
from bronze.crm_cust_info
where cst_firstname != trim(cst_firstname)

select cst_lastname
from bronze.crm_cust_info
where cst_lastname != trim(cst_lastname)

select cst_gndr
from bronze.crm_cust_info
where cst_gndr != trim(cst_gndr)


---to trim the columns which contains extra space--
SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname, -- Added the missing comma here
    cst_material_status AS cst_marital_status, -- Mapping the typo to the correct name
    cst_gndr,
    cst_create_date
FROM bronze.crm_cust_info;


--data standardization and consistency
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,         -- Added missing column
    cst_material_status,
    cst_gndr,             -- Matches the column name in your Silver table
    cst_create_date
)
SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname),
    TRIM(cst_lastname),
    CASE 
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        ELSE 'n/a'
    END,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END,
    cst_create_date
FROM (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t 
WHERE flag_last = 1;

--filtration----
select * from bronze.crm_prd_info

select 
prd_id,
count(*)
from bronze.crm_prd_info
group by prd_id
having count(*) > 1 and prd_id is NULL;

select 
prd_key,
count(*)
from bronze.crm_prd_info
group by prd_key
having count(*) > 1 and prd_key is NULL;


select distinct prd_line
from bronze.crm_prd_info

---check for invalid date orders
select *
from silver.crm_prd_info
where prd_end_dt < prd_start_dt


--transformation--
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Calculated Cat ID
    SUBSTRING(prd_key, 7) AS prd_key_clean,               -- Cleaned Key
    prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    prd_start_dt,
    -- PostgreSQL Date Math: Subtracting 1 from a date works, 
    -- but usually we cast the LEAD result to DATE
    (LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day')::DATE AS prd_end_dt
FROM bronze.crm_prd_info;

ALTER TABLE silver.crm_sales_details 
    ALTER COLUMN sls_order_dt TYPE DATE USING NULL,
    ALTER COLUMN sls_ship_dt TYPE DATE USING NULL,
    ALTER COLUMN sls_due_dt TYPE DATE USING NULL;

---check data quality---
insert into silver.crm_sales_details(
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    -- Date Logic
    CASE 
        WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
        ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
    END AS sls_order_dt,
    CASE 
        WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
        ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
    END AS sls_ship_dt,
    CASE 
        WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
        ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
    END AS sls_due_dt,
    -- Sales Logic: Derive if missing or invalid
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <= 0 THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity, -- Ensure comma is here
    -- Price Logic: Fix negatives and derive if missing
    CASE 
        WHEN sls_price IS NULL OR sls_price = 0 THEN 
            CASE WHEN sls_quantity != 0 THEN sls_sales / sls_quantity ELSE 0 END
        WHEN sls_price < 0 THEN ABS(sls_price)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details);

--filtration--
select * from bronze.crm_sales_details
where sls_ord_num != trim(sls_ord_num)  


select
nullif(sls_order_dt,0) sls_order_dt
from bronze.crm_sales_details
where sls_order_dt <=0 or  LENGTH(sls_order_dt::TEXT) != 8;

SELECT * FROM bronze.crm_sales_details 


--here in sls_sale = sls_quantity*sls_price and also sales,price and quantity can be negative, null or zero

select distinct
sls_sales,
sls_quantity,
sls_price
from bronze.crm_sales_details
where sls_Sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <=0 or sls_quantity <=0 or sls_price <=0 \

--- erp----

---filtration--
select * from bronze.erp_cust_az12

select 
cid,
count(*) from bronze.erp_cust_az12
group by cid
having count(*) > 1 or cid is null


select * from bronze.erp_cust_az12
where bdate is null 

SELECT * FROM silver.erp_cust_az12
WHERE gen  IN ('M', 'F',null);

insert into silver.erp_cust_az12(
SELECT
    -- Fix 1: Use LENGTH() and fixed substring logic
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
        ELSE cid
    END AS cid,
    -- Fix 2: Use CURRENT_DATE instead of GETDATE()
    CASE 
        WHEN bdate > CURRENT_DATE THEN NULL
        ELSE bdate
    END AS bdate,
    -- Fix 3: Standardize Gender
    CASE 
        WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
        ELSE gen
    END AS gen
FROM bronze.erp_cust_az12);


select * from bronze.erp_loc_a101;
select distinct cntry from bronze.erp_loc_a101;

insert into silver.erp_loc_a101(
SELECT
    REPLACE(cid, '-', '') AS cid,
    CASE 
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'Unknown'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101);
select * from silver.crm_prd_info

select * from bronze.erp_px_cat_g1v2
select distinct maintenance from bronze.erp_px_cat_g1v2
select distinct subcat from bronze.erp_px_cat_g1v2
select distinct cat from bronze.erp_px_cat_g1v2

select 
id,
count(*)
from bronze.erp_px_cat_g1v2
group by id
having count(*) > 1 or id is null

insert into silver.erp_px_cat_g1v2(
select
id,
trim(cat) as cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2);


