/*
DATA EXPLORATION For COVID-19

Skills used: 
	Joins, 
    CTE's, 
    Temp Tables, 
    Windows Functions, 
    Aggregate Functions, 
    Creating Views, 
    Converting Data Types
*/
-- USE
USE covid;

-- We first check all the datas
select * 
from coviddeaths
order by 3, 4 ;

select * 
from covidvaccinations
where continent != ''
order by 3, 4 ;

-- Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from covid.coviddeaths
where continent != ''
order by 1,2;

-- looking at total cases vs total deaths
	-- Showing likelihood of dying if you contract covid in locations you wanna look at
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from covid.coviddeaths
where location LIKE '%Canada%' and continent != ''  -- The location where we want to look at
order by total_deaths desc, DeathPercentage desc;

-- looking at Total Cases vs Population
	-- Showing what percentage of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
from covid.coviddeaths
where location LIKE '%Canada%' and continent != ''  -- The location where we want to look at
order by CovidPercentage desc, 2;

-- Looking at Countries with Highest Infection Rate compare to population
select location, max(total_cases) as Highest_infection_count, population, 
	max((total_cases/population))*100 as population_infect_percentage
from covid.coviddeaths
where continent != ''
group by location, population
order by population_infect_percentage desc;


-- Showing Countries with Highest Death Rate
select location, max(total_deaths) as Highest_total_death_count
from covid.coviddeaths
where continent != ''
group by location
order by Highest_total_death_count desc;

	-- Beaking down locations with empty continent infomation
select location, max(total_deaths) as Highest_total_death_count
from covid.coviddeaths
where continent = ''
group by location
order by Highest_total_death_count desc;

-- Checking the global numbers per day
select date, sum(new_cases) AS cases_per_day, sum(new_deaths) AS death_per_day, 
	sum(new_deaths)/sum(new_cases)*100 As death_percentage
from covid.coviddeaths
where continent != ''
group by date  -- you can delect this line to see the total data
order by 1;


Select de.continent, de.location, de.date, de.population,va.new_vaccinations,
	sum(va.new_vaccinations) 
		OVER (partition by de.location order by de.location,de.date) 
		AS rolling_people_vaccinated
From covid.coviddeaths de
Join covid.covidvaccinations va
	On de.location = va.location
    and de.date = va.date
where de.continent != ''
order by 2,3;

-- USE CTE
With PopvsVac (continent, location, data, population, new_vaccinations, Rolling_people_vaccinated)
as
( 
Select de.continent, de.location, de.date, de.population,va.new_vaccinations,
	sum(va.new_vaccinations) 
		OVER (partition by de.location order by de.location,de.date) 
		AS Rolling_people_vaccinated
From covid.coviddeaths de
Join covid.covidvaccinations va
	On de.location = va.location
    and de.date = va.date
where de.continent != ''
order by 2,3
)
SELECT *
FROM PopvsVac;

-- Temp Table
Drop table if exists PercentPopulationVaccinated;

Create table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations nvarchar(255),
Rolling_people_vaccinated numeric
);

insert into PercentPopulationVaccinated
Select de.continent, de.location, de.date, de.population,va.new_vaccinations,
	sum(va.new_vaccinations) 
		OVER (partition by de.location order by de.location,de.date) 
		AS rolling_people_vaccinated
From covid.coviddeaths de
Join covid.covidvaccinations va
	On de.location = va.location
    and de.date = va.date
where de.continent != ''
order by 2,3;

Select *, (rolling_people_vaccinated/Population)*100 As vaccination_rate
From PercentPopulationVaccinated;

-- Creating view to store data for later visulization
Create View PercentPopulationVaccinated as
Select de.continent, de.location, de.date, de.population,va.new_vaccinations,
	sum(va.new_vaccinations) 
		OVER (partition by de.location order by de.location,de.date) 
		AS rolling_people_vaccinated
From covid.coviddeaths de
Join covid.covidvaccinations va
	On de.location = va.location
    and de.date = va.date
where de.continent != ''
order by 2,3;

