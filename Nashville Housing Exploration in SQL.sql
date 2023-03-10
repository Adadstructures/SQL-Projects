--CLEANING THE DATA
--1. Quick overview
SELECT *
FROM Nashville

--2. Standardizing the Date Formate
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM Nashville

UPDATE Nashville
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE Nashville
ADD SaleDateConverted Date;

UPDATE Nashville
SET SaleDateConverted = CONVERT(Date, SaleDate)

--3. Cleaning the Property Address
SELECT Old.ParcelID, Old.PropertyAddress, New.ParcelID, New.PropertyAddress,
ISNULL (Old.PropertyAddress, New.PropertyAddress)
FROM Nashville Old
JOIN Nashville New
	ON Old.ParcelID = New.ParcelID
	AND Old.[UniqueID ] <> New.[UniqueID ]
WHERE Old.PropertyAddress IS NULL

--This checks for properties with the same parcelID, though different uniqueIDs.  It then assign the same address to 
--them where either of them is null
--To Update  the property column

UPDATE Old
SET PropertyAddress = ISNULL (Old.PropertyAddress, New.PropertyAddress)
FROM Nashville Old
JOIN Nashville New
	ON Old.ParcelID = New.ParcelID
	AND Old.[UniqueID ] <> New.[UniqueID ]
WHERE Old.PropertyAddress IS NULL


--4. Extracting the Address (Address, and City) - Using SUBSTRING

SELECT 
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1,LEN(PropertyAddress)) AS Address_2
FROM Nashville

--Creating 2 Columns for Address and City
--For Address
ALTER TABLE Nashville
ADD PropertySplitAddress nvarchar(255);

UPDATE Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1)

--For City
ALTER TABLE Nashville
ADD PropertySplitCity nvarchar(255);

UPDATE Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1,LEN(PropertyAddress)) 



--5. Extracting the OwnersAddress (Address, City and State) - Using PARSENAME
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Nashville

--Creating the Columns for the Split Owners Address
--For Address
ALTER TABLE Nashville
ADD OwnerSplitAddress nvarchar(255);

UPDATE Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

--For City
ALTER TABLE Nashville
ADD OwnerSplitCity nvarchar(255);

UPDATE Nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

--For State
ALTER TABLE Nashville
ADD OwnerSplitState nvarchar(255);

UPDATE Nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--6. Cleaning SoldAsVacant

SELECT DISTINCT (SoldAsVacant), COUNT (SoldAsVacant)
FROM Nashville
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END
FROM Nashville

--Updating the Table
UPDATE Nashville
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END

--7. Removing Duplicates
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
				UniqueID
				) Row_Num	
FROM Nashville
				)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1

--8. Deleting Unused Columns

ALTER TABLE Nashville
DROP COLUMN 
		PropertyAddress,
		OwnerAddress,
		TaxDistrict,
		SaleDate

--ANALYSIS OF THE DATA
--9. Classification of the LandUse
WITH LandClassCTE AS (
SELECT 
CASE
	WHEN (LandUse LIKE 'Residential%' OR LandUse LIKE 'Apartment%' OR LandUse LIKE '%Family'OR LandUse LIKE '%plex'OR LandUse LIKE '%Condo%'OR LandUse LIKE '%home%' OR LandUse LIKE '%line%' OR LandUse LIKE '%res%') THEN 'Residential Allocations'
	ELSE 'Non-Residential Allocations'
END AS LandClass
FROM Nashville
)
SELECT DISTINCT (LandClass), COUNT(LandClass) AS LandClassCount
FROM LandClassCTE
GROUP BY LandClass
ORDER BY 2 DESC

--10. Total Number of Properties
SELECT COUNT(LandUse) AS 'Total Property Count'
FROM Nashville

--11. SalePrice Range
WITH SalesGroupCTE AS (
SELECT 
CASE 
	WHEN SalePrice BETWEEN 0 AND 99999 THEN '0 - 99999'
	WHEN SalePrice BETWEEN 100000 AND 499999 THEN '100000 - 499999'
	WHEN SalePrice BETWEEN 500000 AND 999999 THEN '500000 - 999999'
	ELSE 'Above 1M'
END AS SalesGroup
FROM Nashville
)
SELECT DISTINCT (SalesGroup), COUNT(SalesGroup) AS	SalesCount
FROM SalesGroupCTE
GROUP BY SalesGroup
ORDER BY 1

--12. Properties Count by Cities
SELECT DISTINCT (PropertySplitCity) AS 'City', COUNT(PropertySplitCity) AS 'Property Count'
FROM Nashville
GROUP BY PropertySplitCity

--13. Vacancy of Sales Classification

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant) AS SoldVacantStatus
FROM Nashville
GROUP BY SoldAsVacant

--14. Year Built Classification (Time-Series)
--Sale Price by Year
SELECT DISTINCT (YearBuilt), TotalValue, YEAR(SaleDateConverted) AS YearSold, SalePrice
FROM Nashville
WHERE YearBuilt IS NOT NULL
ORDER BY YearBuilt

--15. Acreage Classification
--Creating the LandClass Column
ALTER TABLE Nashville
ADD LandClass nvarchar(255);

UPDATE Nashville
SET LandClass =
CASE
	WHEN (LandUse LIKE '%Residential%' OR LandUse LIKE '%Apartment%' OR LandUse LIKE '%Family'OR LandUse LIKE '%plex'OR LandUse LIKE '%Condo%'OR LandUse LIKE '%home%' OR LandUse LIKE '%line%' OR LandUse LIKE '%res%') THEN 'Residential'
	ELSE 'Non-Residential'
END

--Classifying Based on Acreage
SELECT DISTINCT (LandClass), COUNT(LandClass) AS PropertyCount, SUM(Acreage) AS Acreage
FROM Nashville
GROUP BY LandClass