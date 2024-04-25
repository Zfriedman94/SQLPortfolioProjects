/*
Covid-19 Data Exploration

This SQL Code shows the ability for me to use:
SELECT, FROM, WHERE, CAST, Calculated Columns, GROUP BY, ORDER BY, TEMP TABLE, CREATE VIEW, and more.

All data came from: https://ourworldindata.org/covid-deaths
*/



-- DATA SELECTION - 
-- Select the data that we will use for the project and organizing it properly.

select Location, Date, total_cases, new_cases, total_deaths, population
from CovidDeathsCSV
WHERE continent IS NOT NULL
order by 1,2



-- UNITED STATES DATA
-- Looking at the Total Cases vs. Total Deaths and formatting Data Types properly

SELECT Location, Date, total_cases, total_deaths, (CAST(total_deaths AS decimal(12,2)) / CAST(total_cases AS decimal(12,2)))*100 AS DeathPercentage
FROM CovidDeathsCSV
WHERE location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2



-- Looking at the Total Cases vs. The Population
-- Shows the rolling % of people who got Covid compared to Total Population

SELECT Location, Date, population, total_cases, (CAST(total_cases AS decimal(12,2)) / CAST(population AS decimal(12,2)))*100 AS DeathPercentage
FROM CovidDeathsCSV
WHERE Location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2




-- COUNTRY DATA
-- Looking at countries with Highest Infection Rate compared to population with their Max Infection Count values

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, 
(CAST(MAX(total_cases) AS decimal(12,2)) / CAST(population AS decimal(12,2)))*100 AS InfectionPercent
FROM CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY InfectionPercent DESC



-- Showing Countries with the highest Death % per Population

SELECT Location, population, MAX(CAST(total_deaths AS BigInt)) AS HighestDeathCount, 
(CAST(MAX(total_deaths) AS decimal(12,2)) / CAST(population AS decimal(12,2)))*100 AS DeathPercent
FROM CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY DeathPercent DESC



-- Showing Countries with the highest Death Count by Country

SELECT location, MAX(CAST(total_deaths AS BigInt)) AS TotalDeathCount
FROM CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC




-- CONTINENT DATA
-- Same as above table, but by Continent instead. Continent = NULL in continent column - makes Continent value in Location column.

SELECT location, MAX(CAST(total_deaths AS BigInt)) AS TotalDeathCount
FROM CovidDeathsCSV
WHERE continent IS NULL AND location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC




-- GLOBAL DATA
-- Cumulative Death Percentage

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
(CAST(SUM(new_deaths) AS Float) / NULLIF(SUM(new_cases), 0))*100 AS DeathPercentage
FROM CovidDeathsCSV
WHERE continent IS NOT NULL




-- TABLE JOINS
-- Looking at Total Population vs. Vaccination

SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations
FROM CovidDeathsCSV Death
JOIN CovidVaccinationsCSV Vac
	ON Death.location = Vac.location
	AND Death.Date = Vac.Date
WHERE Death.continent IS NOT NULL
ORDER BY 2, 3



--Looking at Total Population vs. Vaccination where Vaccine count is a Rolling Add
--USING CTE's

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingTotalVaccination)
AS

(
SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations,
SUM(CAST(Vac.new_vaccinations AS BigInt)) OVER (Partition by Death.Location ORDER BY Death.Location, Death.Date) AS RollingTotalVaccination
FROM CovidDeathsCSV Death
JOIN CovidVaccinationsCSV Vac
	ON Death.location = Vac.location
	AND Death.Date = Vac.Date
WHERE Death.continent IS NOT NULL
)

SELECT *, (RollingTotalVaccination/CAST(Population AS Float))*100
FROM PopvsVac




-- USING A TEMP TABLE for Partition By

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent varchar(50),
Location varchar(50),
Date datetime,
Population Float,
New_vaccinations Float,
RollingTotalVaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations,
SUM(CAST(Vac.new_vaccinations AS BigInt)) OVER (Partition by Death.Location ORDER BY Death.Location, Death.Date) AS RollingTotalVaccination
FROM CovidDeathsCSV Death
JOIN CovidVaccinationsCSV Vac
	ON Death.location = Vac.location
	AND Death.Date = Vac.Date
WHERE Death.continent IS NOT NULL

SELECT *, (RollingTotalVaccination/CAST(Population AS Float))*100 AS VaccinePercentage
FROM #PercentPopulationVaccinated
ORDER BY 2,3




-- CREATING VIEWS to store Data for Visuals

CREATE VIEW DeathCountbyCountry AS

SELECT location, MAX(CAST(total_deaths AS BigInt)) AS TotalDeathCount
FROM CovidDeathsCSV
WHERE continent IS NULL AND location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location

-- Querying the new VIEW

SELECT *
FROM DeathCountbyCountry
ORDER BY 2 DESC
