select * 
from portfolio.dbo.coviddeaths
order by 3, 4 --specifies which cols to order by

--select * 
--from portfolio.dbo.covidvaccs
--order by 3, 4

select location, date, total_cases, new_cases, total_deaths, population
from Portfolio..coviddeaths
order by 1, 2


-- Looking at Total Cases vs total Deaths
-- Likelihood of dying from covid in Nigeria
select location, date, total_cases, total_deaths, (convert (float, total_deaths)/ convert(float, total_cases)) * 100 as DeathPercent
from Portfolio..coviddeaths
where location like '%Nigeria%'
order by 1, 2


-- Looking at Total Cases vs Population
-- Percentage of population infected 
select location, date, population, total_cases, (convert (float, total_cases)/ convert(float, population)) * 100 as PercentpOpInfection
from Portfolio..coviddeaths
where continent is not null and location like '%Nigeria%'
order by PercentpOpInfection desc


-- Countries with highest infection rate per population

select continent, population, MAX(total_cases) as highestInfectionCount, 
Max (cast(total_cases as float)/ cast(population as float)) * 100 
as PercentpOpInfected
from Portfolio..coviddeaths
where continent is not null
group by continent, population
--where location like '%Nigeria%'
order by PercentpOpInfected desc


-- Countries with highest death count per population

select location, MAX(cast(total_deaths as int)) as TotaldeathCount 
from Portfolio..coviddeaths
where continent is not null
group by location, population
--where location like '%Nigeria%'
order by TotaldeathCount desc


-- BREAK DOWN BY CONTINENT


-- Continents with highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotaldeathCount 
from Portfolio..coviddeaths
where continent is not null
--where continent is null
group by continent --also use location for different result
order by TotaldeathCount desc


-- Global Numbers

SET ARITHABORT OFF   -- Default 
SET ANSI_WARNINGS OFF
select sum(new_cases) as totalcases, sum(cast(new_deaths as float)) as totaldeaths, 
sum(cast (new_deaths as float))/ sum(new_cases) * 100 as DeathPercent
from Portfolio..coviddeaths
where continent is not null
-- group by date
order by 1, 2


-- Total population vs vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location 
order by dea.location, dea.date) as RollingVaccTotal
--(RollingVaccTotal/population)*100  -- rolling count. same process for rolling average [this a daily calculation] 
from portfolio..coviddeaths dea
join Portfolio..covidvaccs vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3


-- USE CTE

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


-- TEMP TABLE

Drop table if exists #percentpopvacc
Create Table #PercentPopVacc
(continent nvarchar (255)
, location nvarchar (255)
, date datetime
, population numeric
, new_vaccinations numeric
, RollingVaccTotal numeric)

Insert into #PercentPopVacc
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location 
order by dea.location, dea.date) as RollingVaccTotal 
from portfolio..coviddeaths dea
join Portfolio..covidvaccs vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2, 3

Select *, (RollingVaccTotal/population)*100 as VaccsPop
from #PercentPopVacc


-- View for Viz
-- Drop View if exists percentpopvacc
Create View percentpopvacc as

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location 
order by dea.date ROWS UNBOUNDED PRECEDING) as RollingVaccTotal 
from portfolio..coviddeaths dea
join Portfolio..covidvaccs vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2, 3



select *
from percentpopvacc
