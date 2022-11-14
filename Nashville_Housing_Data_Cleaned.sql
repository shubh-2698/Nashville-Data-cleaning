-- This dataset includes the Nashville Housing data which we are about to clean using SQL queries

-- As Initial step created a database named portfolio and used query to use it by default
create database portfolio;
use portfolio;

-- Firstly checking all columns in data
select * from Housing_data;

-- Checking the Structure of Table
exec sp_help housing_data;

-- Counting total entries in table : 56477 rows
select count(*) from Housing_data;

-- Firstly correcting the incorrect format for columns such as saledate which is currently in datetime format
select saledate,saledateconverted, CONVERT(date,SaleDate) from Housing_data;

alter table housing_data
add saledateconverted date;

update housing_data
set saledateconverted =  CONVERT(date,SaleDate);

-- While viewing the data, we found some null values in property address with same parcelid so now removing the nulls 
with cte as (
select distinct(ParcelID) parcel, PropertyAddress
from Housing_data 
where PropertyAddress is not null)

update a
set a.PropertyAddress = cte.propertyaddress
from Housing_data a
join cte 
on cte.parcel = a.ParcelID
where a.PropertyAddress is null;

--  Splitting property address into location and city fo atomicity of data

select PropertyAddress, left(PropertyAddress,CHARINDEX(',',PropertyAddress)-1),
RIGHT(propertyaddress, len(propertyaddress) - CHARINDEX(',',PropertyAddress))
from Housing_data;

alter table housing_data
add propertysplitaddress varchar(255), propertysplitcity varchar(255);

update Housing_data
set propertysplitaddress = left(PropertyAddress,CHARINDEX(',',PropertyAddress)-1);

update Housing_data
set propertysplitcity = RIGHT(propertyaddress, len(propertyaddress) - CHARINDEX(',',PropertyAddress));

-- Similarly updating Owneraddress and splitting it into address, city and state with different functions

select OwnerAddress,
PARSENAME(replace(OwnerAddress,',','.'),3),
PARSENAME(replace(OwnerAddress,',','.'),2),
PARSENAME(replace(OwnerAddress,',','.'),1)
from Housing_data;

alter table housing_data
add ownersplitaddress nvarchar(255), ownersplitcity nvarchar(255), ownersplitstate nvarchar(255);

update Housing_data
set ownersplitaddress = PARSENAME(replace(OwnerAddress,',','.'),3),
ownersplitcity = PARSENAME(replace(OwnerAddress,',','.'),2),
ownersplitstate = PARSENAME(replace(OwnerAddress,',','.'),1);

-- During Exploration of data it was found that soldasvacant field had No as N and Yes as Y in some rows which needs to be updated

select distinct soldasvacant, count(*) from Housing_data
group by soldasvacant
order by 2;

update Housing_data
set SoldAsVacant = case when soldasvacant = 'Y' then 'Yes'
			when soldasvacant = 'N' then 'No'
			else soldasvacant
			end

--  fetching duplicates and found 167 duplicates
with cte as (
select * , ROW_NUMBER() over(partition by  ParcelID, LandUse, PropertyAddress,saledate,saleprice order by uniqueid) rn
from Housing_data)

select * from cte
where rn >1;

-- Now remaining rows after removal of duplicate is 56310
-- Removing duplicate columns

alter table housing_data
drop column propertyaddress, saledate, owneraddress, taxdistrict;

select * from Housing_data;

-- Renaming columns to the original names for convenience
exec sp_rename 'housing_data.propertysplitaddress', 'propertyaddress','column';
exec sp_rename 'housing_data.saledateconverted', 'saledate','column';
exec sp_rename 'housing_data.propertysplitcity', 'propertycity','column';
exec sp_rename 'housing_data.ownersplitaddress', 'owneraddress','column';
exec sp_rename 'housing_data.ownersplitcity', 'ownercity','column';
exec sp_rename 'housing_data.ownersplitstate', 'ownerstate','column';


