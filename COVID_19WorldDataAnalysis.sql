SELECT *
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1

SELECT *
FROM [Portfolio Project]..CovidVaccinations
ORDER BY 3,4

-- Select Data that I will use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 

--Looking at Total Cases vs Total Deaths
--Showing the likelinhood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 


--Looking at the Total Cases vs Population
--Shows what percentage of population got covid
SELECT Location, date, population, total_cases,(total_cases/population)*100 AS PercentagePopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 

--Looking at coutries with highest infection rate
SELECT location, population, MAX(total_cases) AS HigestInfectionCases, 
MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentagePopulationInfected DESC

-- BREAKING THINGS DOWN
---Showing countries with the higest death count per population

SELECT continent, MAX(CAST(total_deaths AS int)) AS HigestDeathCounts
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HigestDeathCounts DESC 

--GLOBAL NUMBERS

SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS int)) AS Total_Deaths, 
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL			
ORDER BY 1,2	

--Looking at Total Population Vs Total Vaccinated

SELECT TOP 50000 CD.continent, CD.location, CD.date,
				CD.population, CD.total_deaths, CV.new_vaccinations, 
				CV.total_vaccinations,
				SUM(CV.new_vaccinations) 
				OVER (PARTITION BY CD.location
				ORDER BY CD.location, CD.date) AS CummulativeVaccination
FROM [Portfolio Project]..CovidVaccinations CV
JOIN [Portfolio Project]..CovidDeaths CD
	ON CV.iso_code = CD.iso_code
WHERE CD.continent IS NOT NULL AND CV.new_vaccinations IS NOT NULL
--ORDER BY 2

--USING CTE

WITH PopVsVac (Continent, Location, date, population, total_deaths, new_vaccinations, total_vaccinations, CummulativeVaccination)
AS
(
SELECT TOP 100 CD.continent, CD.location, CD.date,
				CD.population, CD.total_deaths, CV.new_vaccinations, 
				CV.total_vaccinations,
				SUM(CV.new_vaccinations) 
				OVER (PARTITION BY CD.location
				ORDER BY CD.location, CD.date) AS CummulativeVaccination
FROM [Portfolio Project]..CovidVaccinations CV
JOIN [Portfolio Project]..CovidDeaths CD
	ON CV.iso_code = CD.iso_code
WHERE CD.continent IS NOT NULL AND CV.new_vaccinations IS NOT NULL
)
SELECT *, (CummulativeVaccination/population)*100 AS PercCumVacPop
FROM PopVsVac


--TEMP TABLE
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
population numeric,
new_vaccinations numeric,
CummulativeVaccination numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT TOP 100 CD.continent, CD.location, CD.date,
				CD.population, CD.total_deaths, CV.new_vaccinations, 
				CV.total_vaccinations,
				SUM(CV.new_vaccinations) 
				OVER (PARTITION BY CD.location
				ORDER BY CD.location, CD.date) AS CummulativeVaccination
FROM [Portfolio Project]..CovidVaccinations CV
JOIN [Portfolio Project]..CovidDeaths CD
	ON CV.iso_code = CD.iso_code
--WHERE CD.continent IS NOT NULL AND CV.new_vaccinations IS NOT NULL

SELECT *, (CummulativeVaccination/population)*100
FROM #PercentagePopulationVaccinated


--CREATE VIEWS FOR VISUALIZATION
CREATE VIEW PercentagePopulationVaccinated AS
SELECT TOP 100 CD.continent, CD.location, CD.date,
				CD.population, CD.total_deaths, CV.new_vaccinations, 
				CV.total_vaccinations,
				SUM(CV.new_vaccinations) 
				OVER (PARTITION BY CD.location
				ORDER BY CD.location, CD.date) AS CummulativeVaccination
FROM [Portfolio Project]..CovidVaccinations CV
JOIN [Portfolio Project]..CovidDeaths CD
	ON CV.iso_code = CD.iso_code
WHERE CD.continent IS NOT NULL

SELECT *
FROM PercentagePopulationVaccinated