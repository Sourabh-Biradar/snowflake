-------------------------
-- Basics of SnowFlake --
-------------------------


-- create DATABASE
create or replace database sf1DB;

-- create WAREHOUSE
-- X-small warehouse
create warehouse sf1_wh;           // WAREHOUSE has all resources

-- use DB
use sf1DB;

-- create SCHEMA
create schema sf1_schema;

-- create SCHEMA with specifics
-- create schema DBname.SCHEMAname

-- use SCHEMA
use schema sf1_schema;

---------------------
-- TYPES OF TABLES --
---------------------

-- create table by default PERMANENT TABLE
-- can set data retention upto 90 days*
create or replace table users
(
 ID int autoincrement primary key,
 Name varchar(10) not null
)
DATA_RETENTION_TIME_IN_DAYS = 1;           // upto 90 days valid + 7 days (fix) FAIL SAFE

-- tables list n info.
show tables;

-- create TRANSIENT table
create or replace TRANSIENT table transTable
(
 calculations text
);

-- alter DATA RETENTION TIME
alter table transTable 
set DATA_RETENTION_TIME_IN_DAYS = 1;         // only 0 & 1 valid


-- create TEMPORARY table
create or replace TEMPORARY table tempTable
(
 calculations text
)
DATA_RETENTION_TIME_IN_DAYS = 1;              // only 0 & 1 valid

show tables;


-- insert values to USERS
insert into users (name) values
('Bolu'),                         // strings in 'single quote'
('Dolu'),
('Golu'),
('Molu');


select * from users;

--------------------
-- TYPES OF VIEWS --
--------------------

-- create STANDARD VIEW
create or replace VIEW user_3 as
select name
from users
where ID = 3;

-- run view
select * from user_3;

-- create MATERIALIZED VIEW
// Results are stored in CACHE
// NO joins or window fn() allowed
// ALIAS is must for agg() column
// GROUP BY is must
create or replace MATERIALIZED VIEW count_view as
select
    Name,
    count(Name) as name_count          
from users
GROUP BY Name;                         
 
-- run view
select * from count_view;


---------------------
-- TYPES OF STAGES --
---------------------
// STAGE : Temp cloud storage 

create or replace table employees(
    emp_ID int,
    name varchar(10),
    dept varchar(5),
    salary float
);

-- create NAMED STAGE
create or replace STAGE emp_stage;


// LIST : lists files sitting inside STAGES(cloud)
-- % : looks at TABLE STAGE
list @%employees;

-- ~ : looks at USER STAGE
list @~;

-- list of files in NAMED STAGE
list @emp_stage;

-- TRUNCATE employees table so METADATA is deleted
truncate table employees;

-- load data from STAGE to TABLE
COPY INTO employees
FROM @emp_stage
file_format = (TYPE = 'CSV' , SKIP_HEADER = 1);


-- check data
select * from employees;

-----------------------
-- FILE FORMAT (CSV) --
-----------------------

create FILE FORMAT demo_csv_ff
TYPE = 'CVS'
FIELD_DELIMTER = ','
RECORD_DELIMTER = '\n'
SKIP_HEADER = 1;

-- use case
COPY INTO employees
FROM @emp_stage
file_format = demo_csv_ff;

-----------------------------
-- TIME TRAVEL & FAIL SAFE --
-----------------------------

-- 1. using TIMESTAMP
select * 
from employees
AT (TIMESTAMP => '2026-06-19 03:39:57.694 -0700'::timestamp_tz);

// get TIMESTAMP from TABLE INFO
show tables;

-- 2. using OFFSET
-- -600 = before 10 mins 
select *
from employees
AT (OFFSET => -600);

-- 3. using STATEMENT
select * 
from employees 
BEFORE (STATEMENT => '01b315ca-0001-2e63-0003-7b3e0002b12a');

// get STATEMENT (QUERY ID) from Monitoring > Query History


---------------
-- RESTORING --
---------------

-- get data from DROPPED table into NEW TABLE
create table new_emp_table as
select * 
from employees 
BEFORE (STATEMENT => '01b315ca-0001-2e63-0003-7b3e0002b12a');

-------------
-- CLONING --
-------------
// ZERO-COPY clone
create table emp_backup
CLONE employees;

// can CLONE TABLE,ENTIRE SCHEMA OR EVEN DB

----------------
-- CLUSTERING --
----------------
// rearranges and resorts table using specific columns for fast queries
-- Defining a cluster key on creation
create table web_logs (
    log_id INT,
    log_date DATE,
    user_id INT,
    event VARCHAR(50)
)
CLUSTER BY (log_date, user_id);

-- altering table
alter table web_logs
CLUSTER BY (log_date);

// it turns on a background service called AUTOMATIC CLUSTERING