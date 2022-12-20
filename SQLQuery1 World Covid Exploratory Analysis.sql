select * from PortfolioProject..CovidDeaths$
order by 3,4

select * from PortfolioProject..CovidVaccination$
order by 3,4

-- select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
order by 1, 2


-- looking at the total cases vs total deaths and calculating the percentage
-- the outcome of the exploratory analysis shows the likelihood of people dying after contacting covid

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1, 2


-- Looking at the total cases vs population
-- Looking at what percentage of population has gotten covid

select location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
from PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1, 2

-- Now looking at the cases for the whole data

select location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
from PortfolioProject..CovidDeaths$
--Where location like '%states%'
order by 1, 2


-- country with the highest infection rate vs population
-- we need to do the group by since we have the aggregate function


select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPercentage
from PortfolioProject..CovidDeaths$
--Where location like '%states%'
Group by location, population
order by InfectedPercentage desc


-- Comparing the total infections vs the total deaths

select location, population, MAX(total_deaths) as Death_total, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPercentage,
MAX((total_deaths/total_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
--Where location like '%states%'
Group by location, population
order by Death_total desc


select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
Where continent is null
Group by location
Order by TotalDeathCount desc

-- BREAKING IT DOWN BY CONTINENT

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
Where continent is not null
Group by continent
Order by TotalDeathCount desc


-- The data type of some of the attribute will need be canged, so we have to CAST the attribute to change the data type
-- Looking at the GLOBAL NUMBERS

select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
-- Where location like '%states%'
where continent is not null
Group by date
order by 1, 2

-- BRING IN THE OTHER TABLE, WE WILL THEN JOIN THE TWO TABLES
-- We are going to look at the total population vs vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- To know the vaccination by each location

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
-- We can use UM(CONVERT(int, vac.new_vaccinations))
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- We could see that there an error at the RollingPeopleVaccinated cause we are just creating it, to get rid of this, we will use CTE

-- USE CTE

With PopvsVac (Continent, location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac
-- NOTE, we have to run it all together



-- TEMP TABLE

DROP table if exists #PercentPopulationVaccinated
-- This could be used in case we make an error and we try to makes changes to the new table
-- We drop the table, then create another table below
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

-- We can now query of this, this is not a Temp Table. we can now work with this

Select * from 
PercentPopulationVaccinated