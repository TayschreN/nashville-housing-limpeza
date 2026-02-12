/*
===========================================================
LIMPEZA E TRATAMENTO DE DADOS - NASHVILLE HOUSING
Autor: Gabriel França
Este script realiza a limpeza e padronização dos dados
da tabela NashvilleHousing utilizando SQL Server.
===========================================================
*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;


-- 1. PADRONIZAÇÃO DO FORMATO DE DATA


-- Visualizando a conversão da data
SELECT SaleDate,
       CONVERT(DATE, SaleDate) AS SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing;

-- Criando nova coluna para data padronizada
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted DATE;

-- Atualizando a nova coluna com a data convertida
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate);


-- 2. PREENCHIMENTO DE ENDEREÇOS NULOS (PropertyAddress)

-- Identificando registros com endereço nulo
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

-- Preenchendo PropertyAddress usando registros com o mesmo ParcelID
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


-- 3. SEPARAÇÃO DO ENDEREÇO EM COLUNAS (ENDEREÇO E CIDADE)

-- Criando coluna para o endereço
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

-- Criando coluna para a cidade
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

-- Atualizando as colunas com base no PropertyAddress
UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity    = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


-- 4. SEPARAÇÃO DO ENDEREÇO DO PROPRIETÁRIO (OwnerAddress)

-- Criando colunas separadas
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity    NVARCHAR(255),
    OwnerSplitState   NVARCHAR(255);

-- Atualizando as colunas usando PARSENAME
UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity    = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState   = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- 5. PADRONIZAÇÃO DA COLUNA SoldAsVacant (Y/N → Yes/No)


-- Verificando valores distintos
SELECT DISTINCT SoldAsVacant, COUNT(*) AS Quantidade
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY Quantidade;

-- Atualizando valores
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- 6. REMOÇÃO DE REGISTROS DUPLICADOS

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


-- 7. REMOÇÃO DE COLUNAS NÃO UTILIZADAS

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress,
            TaxDistrict,
            PropertyAddress,
            SaleDate;