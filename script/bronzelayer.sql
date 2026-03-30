create table bronze.crm_cust_info(
cst_id INT,
cst_key VARCHAR(50),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_material_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date DATE
);

create table bronze.crm_prd_info(
prd_id INT,
prd_key VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost NUMERIC(10,2),
prd_line VARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE
);

create table bronze.crm_sales_details(
sls_ord_num INT,
sls_prd_key VARCHAR(50),
sls_cust_id INT,
sls_order_dt DATE,
sls_ship_dt DATE,
sls_due_dt DATE,
sls_sales NUMERIC(10,2),
sls_quantity INT,
sls_price NUMERIC(10,2)
);

create table bronze.erp_CUST_AZ12(
CID VARCHAR(50),
BDATE DATE,
GEN VARCHAR(50)
);

--Data inserted manually in POSRGRESSSQL and I suggest you to create stored-procedure
