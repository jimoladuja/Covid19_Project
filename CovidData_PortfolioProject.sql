/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
Select * 
From portfolio..coviddeaths
Order by 3, 4

-- Select Data that we are going to be starting with

Select location, date, total_cases, new_cases, total_deaths, population
From Portfolio..coviddeaths
Order by 1, 2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, (convert (float, total_deaths) / convert(float, total_cases)) * 100 as DeathPercent
From Portfolio..coviddeaths
Where location like '%Nigeria%'
Order by 1, 2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select location, date, population, total_cases, (convert (float, total_cases)/ convert(float, population)) * 100 as PercentPopInfection
From Portfolio..coviddeaths
-- where continent is not null and location like '%Nigeria%'
Order by PercentPopInfection desc


-- Countries with Highest Infection Rate compared to Population

Select continent, population, MAX(total_cases) as highestInfectionCount, 
Max (cast(total_cases as float)/ cast(population as float)) * 100 as PercentpOpInfected
From Portfolio..coviddeaths
-- where continent is not null and location like '%Nigeria%'
Group by continent, population
Order by PercentpOpInfected desc


-- Countries with Highest Death Count per Population

Select location, MAX(cast(total_deaths as int)) as TotaldeathCount 
From Portfolio..coviddeaths
Where continent is not null
Group by location, population
Order by TotaldeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%Nigeria%'
Where continent is not null 
Group by continent
Order by TotalDeathCount desc


-- Global Numbers

SET ARITHABORT OFF   -- Default 
SET ANSI_WARNINGS OFF
	
Select sum(new_cases) as totalcases, sum(cast(new_deaths as float)) as totaldeaths, 
sum(cast (new_deaths as float))/ sum(new_cases) * 100 as DeathPercent
From Portfolio..coviddeaths
Where continent is not null
-- Group by date
Order by 1, 2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location 
Order by dea.location, dea.date) as RollingVaccTotal
--(RollingVaccTotal/population)*100  
From portfolio..coviddeaths dea
Join Portfolio..covidvaccs vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2, 3


-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVacc (continent, location, date, population, new_vaccinations, RollingVaccTotal)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location 
order by dea.location, dea.date) as RollingVaccTotal 
from portfolio..coviddeaths dea
join Portfolio..covidvaccs vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2, 3
)
Select *, (RollingVaccTotal/population)*100 as VaccsPop
from PopvsVacc


-- Using Temp Table to perform Calculation on Partition By in previous query

Drop table if exists #percentpopvacc
Create Table #PercentPopVacc
(continent nvarchar (255)
, location nvarchar (255)
, date datetime
, population numeric
, new_vaccinations numeric
, RollingVaccTotal numeric)

Insert into #PercentPopVacc
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location Order by dea.location, dea.date) as RollingVaccTotal 
From portfolio..coviddeaths dea
Join Portfolio..covidvaccs vac
	on dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
-- order by 2, 3
	
Select *, (RollingVaccTotal/population)*100 as VaccsPop
From #PercentPopVacc


-- Creating View to store data for later visualizations
	
-- Drop View if exists percentpopvacc
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select *
from percentpopvacc
