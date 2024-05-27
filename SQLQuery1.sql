-- COVID SQL Data Exploration Project
-- The goal of this project is to use SQL and publicly available data 
-- to find better understand the COVID pandemic's global effects

USE covidproject;

SELECT location, date, new_cases, total_deaths
		FROM covidproject..Coviddeaths
		WHERE continent IS NOT NULL;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in different countries (currently looking at Canada)
SELECT location, date, total_cases, population, total_deaths,
			CONCAT((total_deaths / total_cases) * 100, '%') AS "DeathPercentage"
				FROM Coviddeaths
				WHERE location LIKE '%Canada%' 
					AND continent IS NOT NULL;

-- Looking at Total Cases vs Population
-- Shows what percentage of population has gotten COVID, by day
SELECT location, date, population, total_cases,
			CONCAT((total_cases / population) * 100, '%') AS "PercentPopulationInfected"
				FROM Coviddeaths
				WHERE continent IS NOT NULL
				ORDER BY 1,2;

-- Looking at Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as "InfectionCount",
			CONCAT(MAX((total_cases / population)) * 100, '%') AS "PercentPopulationInfected"
				FROM Coviddeaths
				WHERE continent IS NOT NULL
				GROUP BY location, population
				ORDER BY PercentPopulationInfected DESC;

-- Showing Continents and their Death Counts
SELECT continent, MAX(Total_deaths) as TotalDeathCount
				FROM Coviddeaths
				WHERE continent IS NOT NULL
				GROUP BY continent
				ORDER BY TotalDeathCount DESC;

-- Showing Global Numbers for death percentage, all time (Till end of dataset on 30 April 2021)
-- First query for data for Tableau Dashboard
SELECT SUM(new_cases) AS 'Global Cases', 
				SUM(new_deaths) AS 'Global Deaths',
				CONCAT(CAST(SUM(new_deaths) AS FLOAT)/
				CAST(SUM(new_cases) AS FLOAT)* 100, ' %') AS 'Death_Percentage'
					FROM Coviddeaths
					WHERE continent IS NOT NULL;

-- Showing Global numbers for death Percentages daily
-- Second query for data for Tableau Dashboard
SELECT date, SUM(new_cases) AS 'Global_New_Cases', 
				SUM(new_deaths) AS 'Global_New_Deaths',
				CONCAT(CAST(SUM(new_deaths) AS FLOAT)/
				CAST(SUM(new_cases) AS FLOAT)* 100, ' %') AS 'Death_Percentage'
					FROM Coviddeaths
					WHERE continent IS NOT NULL
					GROUP BY date
					ORDER BY 1;

-- Looking at Total Population vs Vaccinations
SELECT cd.continent, cd.location, 
			cd.date, cd.population, 
			cv.new_vaccinations
				FROM Coviddeaths AS cd 
					JOIN Covidvaccinations AS cv
						ON cd.location = cv.location 
						AND cd.date = cv.date
					WHERE cd.continent IS NOT NULL
					ORDER BY 2,3;	

-- Rolling count of Vaccinations and total populations of countries
SELECT cd.continent, cd.location, 
			cd.date, cd.population, 
			cv.new_vaccinations,
			SUM(CONVERT(int, cv.new_vaccinations)) 
				OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
				AS 'Rolling_Vaccination_Count'
					FROM Coviddeaths AS cd 
						JOIN Covidvaccinations AS cv
							ON cd.location = cv.location 
							AND cd.date = cv.date
						WHERE cd.continent IS NOT NULL
						ORDER BY 2,3;	

-- Using Common Table Expression (CTE) to find number of vaccination in each country
WITH population_vaccination 
			(continent, location, date, population, new_vaccinations, rolling_vaccination_count)
			AS 
			(SELECT cd.continent, cd.location, 
			cd.date, cd.population, 
			cv.new_vaccinations,
			SUM(CONVERT(int, cv.new_vaccinations)) 
				OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
				AS 'Rolling_Vaccination_Count'
					FROM Coviddeaths AS cd 
						JOIN Covidvaccinations AS cv
							ON cd.location = cv.location 
							AND cd.date = cv.date
						WHERE cd.continent IS NOT NULL)
		
SELECT continent, location, MAX(rolling_vaccination_count) FROM population_vaccination
			GROUP BY continent, location
			ORDER BY 1, 2;

-- Using Temp Table to find max vaccination percents by country
DROP TABLE IF EXISTS #Percent_population_vaccinated;
CREATE TABLE #Percent_population_vaccinated 
			(
			continent NVARCHAR(255),
			location NVARCHAR(255),
			date DATETIME,
			population BIGINT,
			new_vaccinations INT,
			rolling_vaccination_count INT,
			);

INSERT INTO #Percent_population_vaccinated 
			SELECT cd.continent, cd.location, 
			cd.date, cd.population, 
			cv.new_vaccinations,
			SUM(CONVERT(int, cv.new_vaccinations)) 
				OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
				AS 'Rolling_Vaccination_Count'
					FROM Coviddeaths AS cd 
						JOIN Covidvaccinations AS cv
							ON cd.location = cv.location 
							AND cd.date = cv.date
						WHERE cd.continent IS NOT NULL

SELECT continent, location, population, 
		MAX(rolling_vaccination_count) "vaccinated_individuals",
		CONCAT(CONVERT(FLOAT, MAX(rolling_vaccination_count)) / 
			CONVERT(FLOAT, population)*100, ' %') AS vaccination_percent
				FROM #Percent_population_vaccinated
				GROUP BY continent, location, population
				ORDER BY vaccination_percent DESC;

-- Global infection percentage of each country 
-- Third query for data for Tableau Dashboard
SELECT location, SUM(CONVERT(int, new_cases)) AS "infection", 
		AVG(population) AS "population",
			SUM(CONVERT(FLOAT, new_cases)) / CONVERT(FLOAT, AVG(population))*100 AS "infection_percent"
				FROM coviddeaths
					WHERE continent IS NOT NULL
					GROUP BY location
					ORDER BY 1;

-- Vaccination affect on infection vs deaths
-- Fourth query for data for Tableau Dashboard
SELECT cd.continent, SUM(CONVERT(INT, cd.new_deaths)) AS "death_count"
						FROM Coviddeaths AS cd
							JOIN
							Covidvaccinations AS cv 
							ON cd.date = cv.date AND cd.location = cv.location
						WHERE cd.continent IS NOT NULL
						GROUP BY cd.continent
						ORDER BY 1;