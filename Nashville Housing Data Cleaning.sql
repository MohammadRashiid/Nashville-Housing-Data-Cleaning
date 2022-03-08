use DataCleaningProject
/*
Cleaning Data in SQL Queries
*/

select * 
from NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
Alter table NashvilleHousing
alter column saledate date

-- If it doesn't Update properly
--Alter table NashvilleHousing
--add SaleDateUpdated date
--update NashvilleHousing
--set SaleDateUpdated = convert(date,SaleDate)

--Alter table NashvilleHousing
--drop column SaleDateUpdated 


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
select *
from NashvilleHousing  
--where PropertyAddress is null --43076 025 07 0 031.00 410  ROSEHILL CT, GOODLETTSVILLE
where ParcelID = '025 07 0 031.00'
order by ParcelID

select a.ParcelID,b.ParcelID,b.PropertyAddress,b.PropertyAddress,isnull(a.PropertyAddress,b.PropertyAddress)
from NashvilleHousing a join NashvilleHousing b on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
from NashvilleHousing a join NashvilleHousing b on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

--PropertyAddress
select PropertyAddress, 
		Address = substring(PropertyAddress, 1, charindex(',',PropertyAddress)-1),
		City = substring(PropertyAddress, charindex(',',PropertyAddress)+1, len(PropertyAddress))
from NashvilleHousing

Alter table NashvilleHousing
add PropertyCity nvarchar(255)

update NashvilleHousing
set PropertyCity = substring(PropertyAddress, charindex(',',PropertyAddress)+1, len(PropertyAddress))

update NashvilleHousing
set PropertyAddress = substring(PropertyAddress, 1, charindex(',',PropertyAddress)-1)
 
--OwnerAddress
select OwnerAddress,
PARSENAME(replace(OwnerAddress,',','.'),3),
PARSENAME(replace(OwnerAddress,',','.'),2),
PARSENAME(replace(OwnerAddress,',','.'),1)
from NashvilleHousing

Alter table NashvilleHousing
add OwnerCity nvarchar(255), OwnerState nvarchar(255)

update NashvilleHousing
set OwnerCity = PARSENAME(replace(OwnerAddress,',','.'),2), OwnerState = PARSENAME(replace(OwnerAddress,',','.'),1)

update NashvilleHousing
set OwnerAddress = PARSENAME(replace(OwnerAddress,',','.'),3)

-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
end
From NashvilleHousing 

update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
end

-- Remove Duplicates -> not a good practice to remove data from the original table that's why i will use temp table


with rownumcte as
(
select *,
		rownum = row_number() over(partition by ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference order by UniqueID)
from NashvilleHousing
)

select * 
into #removeduplicates
from rownumcte
where rownum = 1

alter table #removeduplicates
drop column rownum

select * from #removeduplicates

-- Drop Unused Columns
select * from NashvilleHousing

alter table NashvilleHousing
drop column TaxDistrict

-- Output in Organized temp table
SELECT [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[PropertyCity]
	  ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[OwnerCity]
      ,[OwnerState]
	  ,[Acreage]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  INTO #CleanedData    
  FROM [DataCleaningProject].[dbo].[NashvilleHousing]

  select * from #CleanedData