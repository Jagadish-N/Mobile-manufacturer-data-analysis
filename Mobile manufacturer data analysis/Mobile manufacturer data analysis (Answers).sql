--SQL Advance Case Study


--Q1--BEGIN 
select l.State,t.IDCustomer,c.Customer_Name,year(t.Date)[Year]
from DIM_LOCATION[l]
inner join FACT_TRANSACTIONS[t] on l.IDLocation=t.IDLocation
inner join DIM_CUSTOMER[c] on t.IDCustomer=c.IDCustomer
where year(t.Date)>=2005
order by [Year]
--Q1--END

--Q2--BEGIN
select top 1 l.State,l.Country,mf.Manufacturer_Name,count(t.Quantity)[Total Quantity]
from DIM_LOCATION[l]
inner join FACT_TRANSACTIONS[t] on l.IDLocation=t.IDLocation
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where l.Country='US' and mf.Manufacturer_Name='Samsung'
group by l.State,l.Country,mf.Manufacturer_Name
order by [Total Quantity] desc
--Q2--END

--Q3--BEGIN      
select mf.Manufacturer_Name,m.Model_Name,l.ZipCode,l.State,COUNT(t.IDModel)[No of Transaction]
from DIM_LOCATION[l]
inner join FACT_TRANSACTIONS[t] on l.IDLocation=t.IDLocation
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
group by mf.Manufacturer_Name,m.Model_Name,l.ZipCode,l.State
--Q3--END

--Q4--BEGIN
select top 1 mf.Manufacturer_Name,m.Model_Name,m.Unit_price
from DIM_MODEL[m]
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
group by mf.Manufacturer_Name,m.Model_Name,m.Unit_price
order by m.Unit_price
--Q4--END

--Q5--BEGIN
select mf.Manufacturer_Name,m.Model_Name,sum(t.Quantity)[Sales Quantity],avg(t.TotalPrice)[Avg Price]
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where mf.Manufacturer_Name in
(select top 5 mf.Manufacturer_Name
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
group by mf.Manufacturer_Name
order by sum(t.Quantity) desc,avg(t.TotalPrice) desc)
group by mf.Manufacturer_Name,m.Model_Name
order by mf.Manufacturer_Name,[Avg Price] desc

/*--------------------Top 5 manufacturer in terms of sales quantity and order by avg price---------------------------
select mf.Manufacturer_Name,sum(t.Quantity)[Sales Quantity],avg(t.TotalPrice)[Avg Price]
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
group by mf.Manufacturer_Name
order by [Sales Quantity] desc,[Avg Price] desc
--------------------------------------------------------------------------------------------------------------------*/
--Q5--END

--Q6--BEGIN
select c.IDCustomer,c.Customer_Name,AVG(t.TotalPrice)[Avg amount]
from DIM_CUSTOMER[c]
inner join FACT_TRANSACTIONS[t] on c.IDCustomer=t.IDCustomer
where YEAR(t.Date)=2009
group by c.IDCustomer,c.Customer_Name
having AVG(t.TotalPrice)>500
--Q6--END
	
--Q7--BEGIN  
with phone_model as
(select RANK()over(partition by year(t.date) order by sum(t.Quantity) desc)[Rank],m.Model_Name,mf.Manufacturer_Name,year(t.date)[year],sum(t.Quantity)[Qty]
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where year(t.Date) in ('2008','2009','2010')
group by m.Model_Name,year(t.Date),mf.Manufacturer_Name)

select Model_Name,Manufacturer_Name
from phone_model
where [Rank]<6
group by Model_Name,Manufacturer_Name
having count(Model_Name)=3
--Q7--END

--Q8--BEGIN
select * from
(select mf.Manufacturer_Name,sum(t.TotalPrice)[Sales Value]
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where year(t.Date)=2009
group by mf.Manufacturer_Name
order by [Sales Value] desc
offset 1 rows
fetch next 1 rows only
union all
select mf.Manufacturer_Name,sum(t.TotalPrice)[Sales Value]
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where year(t.Date)=2010
group by mf.Manufacturer_Name
order by [Sales Value] desc
offset 1 rows
fetch next 1 rows only) [2nd Top Sales]

--using with function
with [2nd_top_sales] as
(select RANK()over(partition by year(t.Date) order by sum(t.TotalPrice) desc)[Rank],mf.Manufacturer_Name,sum(t.TotalPrice)[Sales Value],year(t.Date)[Year]
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where year(t.Date) in ('2009','2010')
group by mf.Manufacturer_Name,year(t.Date))

select Manufacturer_Name,[Sales Value],[Year]
from [2nd_top_sales]
where [Rank]=2
--Q8--END

--Q9--BEGIN
select distinct mf.Manufacturer_Name
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where year(t.Date)=2010 and mf.Manufacturer_Name not in(select mf.Manufacturer_Name
from FACT_TRANSACTIONS[t]
inner join DIM_MODEL[m] on t.IDModel=m.IDModel
inner join DIM_MANUFACTURER[mf] on m.IDManufacturer=mf.IDManufacturer
where year(t.Date)=2009
group by mf.Manufacturer_Name)
--Q9--END

--Q10--BEGIN
select c.Customer_Name,avg(t.TotalPrice)[Avg_Spend],avg(t.Quantity)[Avg_Qty],YEAR(t.Date)[Year],ROW_NUMBER()over(partition by YEAR(t.Date) order by avg(t.TotalPrice) desc)[rn]
into #all_customers
from DIM_CUSTOMER[c]
inner join FACT_TRANSACTIONS[t] on c.IDCustomer=t.IDCustomer
group by c.Customer_Name,YEAR(t.Date)



select *
into #top_customers
from #all_customers
where rn<=5

select
    L.Customer_Name,
    L.Year,
    L.Avg_Spend,
    L.rn,
    R.Year as [Year_next],
    R.Avg_Spend as Average_Spend_next,
    R.rn as rn_next,
    1.0 * R.Avg_Spend / L.Avg_Spend - 1.0 as diff
from #top_customers as L
left join #all_customers as R
    on L.Customer_Name = R.Customer_Name
    and R.[YEAR] = L.[YEAR] + 1 ;

select * from #all_customers
select * from #top_customers
--Q10--END
	