-- =============================================== --
-- Data Cleaning 
-- =============================================== --
-- ----------------------------------------------- -- 
SELECT * 
FROM layoffs;
-- Before Data Cleaning:

-- Creating a raw dataset
-- =============================================== --
CREATE TABLE layoffs_raw
LIKE layoffs;
-- LIKE will copy the data inside the layoffs directly inside layoffs_raw

SELECT * FROM layoffs_raw;

INSERT layoffs_raw 
SELECT *
FROM layoffs;

-- Removing duplicates
-- =============================================== --
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs;

WITH duplicate_row AS (
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs
)
SELECT * 
FROM duplicate_row
WHERE row_num > 1; 

SELECT * 
FROM layoffs
WHERE company = 'Casper'; 

-- Creating alternate table(layoffs_staging) for actual data cleaning and layoffs for keeping original data
CREATE TABLE `layoffs_staging` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging
WHERE row_num > 1;

INSERT INTO layoffs_staging
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs;

-- to disable safe update
SET SQL_SAFE_UPDATES = 0;

-- Deleting duplicate rows: using row_num
-- ----------------------------------------------- -- 
DELETE FROM layoffs_staging
WHERE row_num > 1;

-- Standardizing data : finding issue with the data and fixing it
-- ----------------------------------------------- -- 
SELECT DISTINCT(company) 
FROM layoffs_staging;

UPDATE layoffs_staging
SET company = TRIM(company);

-- Removing duplicates in industry
-- ----------------------------------------------- -- 
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

SELECT DISTINCT *
FROM layoffs_staging
WHERE industry LIKE 'Product';

-- Removing same companies in two or more industries
-- ----------------------------------------------- -- 
SELECT company
FROM layoffs_staging
WHERE industry IN ('Real Estate', 'Construction')
GROUP BY company
HAVING COUNT(DISTINCT industry)=2;

UPDATE layoffs_staging
SET industry = 'Crypto' 
WHERE industry LIKE 'Crypto%';

-- Removing duplicates in location -- No duplicates found
-- ----------------------------------------------- -- 
SELECT DISTINCT location 
FROM layoffs_staging
ORDER BY 1;

-- Removing duplicates in country 
-- ----------------------------------------------- -- 
SELECT DISTINCT country 
FROM layoffs_staging
ORDER BY 1;

SELECT * 
FROM layoffs_staging
WHERE country LIKE 'United States'
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) -- it can show countries without '.' at the end
FROM layoffs_staging
ORDER BY 1;

UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Changing date from text to date format 
-- =============================================== --
SELECT `date`
FROM layoffs_staging;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging;

UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

SELECT date
FROM layoffs_staging;

-- Working with the null and blank values 
-- =============================================== --

-- Removing null values from total_laid_off: nothing found
-- ----------------------------------------------- -- 
SELECT * 
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Removing null values from industry
-- ----------------------------------------------- -- 
SELECT DISTINCT industry -- it has some missing value
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging
WHERE industry IS NULL
OR industry = '';

-- Pouplating Airbnb
SELECT * 
FROM layoffs_staging
WHERE company = 'Airbnb';

UPDATE layoffs_staging
SET industry = 'Travel'
WHERE company LIKE 'Airbnb';

-- a better way to populate all of them at once
SELECT t1.industry, t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging
SET industry = NULL 
WHERE industry = '';

UPDATE layoffs_staging t1 -- this will be ineffective you have to first convert the industry to null where they are empty 
JOIN layoffs_staging t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Pouplating Bally's Interactive
SELECT * 
FROM layoffs_staging
WHERE company = "Bally's Interactive";

UPDATE layoffs_staging
SET industry = 'Gaming'
WHERE company LIKE "Bally's Interactive";

-- Removing of columns and rows having null values
-- in both total_laid_off and perecentage_laid_off
-- =============================================== --
SELECT * 
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Column row_num deletion
-- =============================================== --
SELECT * 
FROM layoffs_staging;

ALTER TABLE layoffs_staging
DROP COLUMN row_num;


