
-- Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows chance of dying if you contract covid (in the UK)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows percentage of UK population infected with covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location = 'United Kingdom' 
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM CovidPortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectedPercentage desc


-- Showing Countries with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Showing Continents with Highest Death Count per Population

SELECT deaths.continent, SUM(deaths.MaxDeath) AS TotalDeathCount
FROM (SELECT continent, location, MAX(CAST(total_deaths AS int)) AS MaxDeath
		FROM CovidPortfolioProject..CovidDeaths
		WHERE continent is not null
		GROUP BY location, continent
		) AS deaths
GROUP BY deaths.continent
ORDER BY TotalDeathCount desc


-- Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations
--- CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by 
		dea.location, dea.date) as RollingPeopleVaccinated 
FROM CovidPortfolioProject..CovidDeaths as dea
Join CovidPortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVacced
FROM PopVsVac

--- Temp Table

DROP TABLE IF exists #PercentPopVacced
CREATE TABLE #PercentPopVacced
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopVacced
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by 
		dea.location, dea.date) as RollingPeopleVaccinated 
FROM CovidPortfolioProject..CovidDeaths as dea
Join CovidPortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVacced
FROM #PercentPopVacced
ORDER BY 2,3

--- Creating View to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by 
		dea.location, dea.date) as RollingPeopleVaccinated 
FROM CovidPortfolioProject..CovidDeaths as dea
Join CovidPortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null


-- Date of First Vaccinations

SELECT dea.location, MIN(dea.date) AS EarliestVaccination
FROM CovidPortfolioProject..CovidDeaths as dea
Join CovidPortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null AND vac.new_vaccinations is not null
GROUP BY dea.continent, dea.location
ORDER BY 2

