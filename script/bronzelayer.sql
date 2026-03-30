drop table if exists bronze.crm_cust_info;
create table bronze.crm_cust_info(
cst_id INT,
cst_key VARCHAR(50),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_material_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date DATE
);

drop table if exists bronze.crm_prd_info;
create table bronze.crm_prd_info(
prd_id INT,
prd_key VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost int,
prd_line VARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE
);

drop table if exists bronze.crm_sales_details;
create table bronze.crm_sales_details(
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

drop table if exists bronze.erp_CUST_AZ12;
create table bronze.erp_CUST_AZ12(
CID VARCHAR(50),
BDATE DATE,
GEN VARCHAR(50)
);

drop table if exists bronze.erp_LOC_A101;
create table bronze.erp_LOC_A101(
CID VARCHAR(50),
CNTRY VARCHAR(50)
);

drop table if exists bronze.erp_PX_CAT_G1V2;
create table bronze.erp_PX_CAT_G1V2(
ID VARCHAR(50),
CAT VARCHAR(50),
SUBCAT VARCHAR(50),
MAINTENANCE VARCHAR(50)
);
