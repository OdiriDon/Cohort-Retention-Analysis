---Preview your dataset
  select *
  from onlineretail

  ---cleaning your data
--Total Records = 541909
--135080 Records have no customerID
--406829 Records have customerID

select *
from ['Online Retail$']
where CustomerID is null

select *
from ['Online Retail$']
where CustomerID is not null

--397884 Records with quantity and unitprice
with online_retail as
(
     select * 
     from ['Online Retail$']
     where CustomerID is not null
)
, quantity_unit_price as
(
    select * 
    from online_retail
    where Quantity > 0 and UnitPrice > 0
)
, dup_check as
(
---Duplicate check
   select *, ROW_NUMBER() over(partition by InvoiceNO, Stockcode, Quantity order by InvoiceDate) as dup_flag
   from quantity_unit_price
)
--create temp table
--392669 clean data
--5215 duplicate records
   select *
   into #online_retail_main
   from dup_check
   where dup_flag = 1

--Clean Data
--Begin Cohort Analysis
 --Preview everything from the temp table
 select *
 from #online_retail_main

 --Unique Identifier (CustomerID)
 --Initial start data (First Invoice date)
 --Revenue Data 

 select 
       CustomerID,
       min(InvoiceDate) as first_purchase_date,
       DATEFROMPARTS(year(min(Invoicedate)), month(min(InvoiceDate)), 1) as Cohort_Date
 into #cohort
 from #online_retail_main
 Group by CustomerID

 select *
 from #cohort

 --Create cohort index
 select mmm.*,
 cohort_index = year_diff * 12 + month_diff +1
 into #cohort_retention
 from 
 (
    select mm.*,
    year_diff = invoice_year - cohort_year,
    month_diff = invoice_month - cohort_month
    from 
     (
     select 
     m.*, 
     c.Cohort_Date, year(m.InvoiceDate) as invoice_year,
     month(m.invoiceDate) as invoice_month,
     year(c.Cohort_Date) as cohort_year, month(c.cohort_date) as cohort_month
     from #online_retail_main as m
     left join #cohort as c
     on m.CustomerID = c.CustomerID
     ) as mm
	 ) as mmm

--Pivot data to see the cohort table
select distinct
CustomerID, Cohort_Date, cohort_index
from #cohort_retention

select *
into #cohort_pivot
from
(
    select distinct
    CustomerID, Cohort_Date, cohort_index
    from #cohort_retention
)tbl
pivot(
      count(customerid)
	  for cohort_index in
	  ([1], [2], [3], [4], [5], [6], [7], [8], [9],
	  [10], [11], [12], [13])
	  ) as pivot_table
	  order by 1

--Percentage that returned
select cohort_date,
1.0 * [1]/[1] * 100 as [1],
1.0 * [2]/[1] * 100 as [2],
1.0 * [3]/[1] * 100 as [3],
1.0 * [4]/[1] * 100 as [4],
1.0 * [5]/[1] * 100 as [5],
1.0 * [6]/[1] * 100 as [6],
1.0 * [7]/[1] * 100 as [7],
1.0 * [8]/[1] * 100 as [8],
1.0 * [9]/[1] * 100 as [9],
1.0 * [10]/[1] * 100 as [10],
1.0 * [11]/[1] * 100 as [11],
1.0 * [12]/[1] * 100 as [12],
1.0 * [13]/[1] * 100 as [13]
from #cohort_pivot 
order by Cohort_Date