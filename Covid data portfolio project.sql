-- COVID DEATH PERCENTAGE IN CZECH REPUBLIC --
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from coviddeaths
where location like '%czech%'
order by 1;

-- COVID CASE PERCENTAGE AGAINST POPULATION IN CZECH REPUBLIC --
select location, date, POPULATION, total_cases, (total_cases/POPULATION)*100 as CasePercentage
from coviddeaths
where location like '%czech%'
order by 1;

-- INFECTION RATE GROUPED BY COUNTRIES --
select location, POPULATION, MAX(total_cases) AS HighestInfectionCount, max((total_cases/POPULATION)*100) as PercentPopulationInfected
from coviddeaths
group by location, population
order by PercentPopulationInfected desc;

-- PERCENT POPULATION DEATHS GROUPED BY COUNTRIES --
-- WE HAVE TO CAST VARCHAR TYPE AS SOME TYPE OF INT TO GET THE NUMBER--
-- HERE I USED SIGNED INT - https://stackoverflow.com/questions/12126991/cast-from-varchar-to-int-mysql--
select location, POPULATION, MAX(cast(TOTAL_DEATHS as signed)) AS HighestDeathCount, max((TOTAL_DEATHS/POPULATION)*100) as PercentPopulationDeaths
from coviddeaths
group by location, population
order by PercentPopulationDeaths desc;

-- SIMILAR - ORDER BY TOTAL DEATH COUNT --
select location, MAX(cast(TOTAL_DEATHS as signed)) AS HighestDeathCount, max((TOTAL_DEATHS/POPULATION)*100) as PercentPopulationDeaths
from coviddeaths
group by location
order by HighestDeathCount desc;

-- WITHOUT CONTINET AGGREGATIONS --
-- WHERE CONTINENT IS NOT NULL

-- BY CONTINENT --
-- CONTINENT ITSELF DOES HAVE CONTINENT COLUMNT NULL --
select LOCATION, MAX(cast(TOTAL_DEATHS as signed)) AS HighestDeathCount, max((TOTAL_DEATHS/POPULATION)*100) as PercentPopulationDeaths
from coviddeaths
WHERE CONTINENT IS NULL
group by LOCATION
order by HighestDeathCount desc;


-- TOTAL CASES AND DEATHS PER DAY WORLDWIDE --
SELECT DATE_, SUM(NEW_CASES) AS TOTAL_CASES, SUM(CAST(NEW_DEATHS AS UNSIGNED)) AS TOTAL_DEATHS, SUM(CAST(NEW_DEATHS AS UNSIGNED))/SUM(NEW_CASES)*100 AS DEATHPERCENTAGE
FROM coviddeaths
WHERE CONTINENT IS NOT NULL
GROUP BY DATE_
ORDER BY 1, 2;

-- CZECH REP COVID CASES PER DAY --
select dea.continent, dea.location, dea.date_, dea.new_cases, dea.new_deaths, dea.total_cases, dea.total_deaths, vac.new_vaccinations
from coviddeaths as dea
join covidvaccinations as vac
	on (dea.location = vac.location
    and dea.date_ = vac. date_)
    where dea.continent is not null and dea.LOCATION LIKE '%czech%'
order by DATE_;

-- CUMULATIVE COUNT OF NEW VACCINATIONS --
select dea.location, dea.date_, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location ,dea.date_) as CumulativeVaccinations
from coviddeaths as dea
join covidvaccinations as vac
	on (dea.location = vac.location
    and dea.date_ = vac. date_)
    where dea.continent is not null
order by 1, 2;

-- CUMULATIVE VCCINATIONS AND PERCENTAGE OF PEOPLE VACCINATED PER DAY ---
WITH PopvsVac (continent, location, date_, population, new_vaccinations, CumulativeVaccinations) as
(
select dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.date_) as CumulativeVaccinations
from coviddeaths as dea
join covidvaccinations as vac
	on (dea.location = vac.location
    and dea.date_ = vac. date_)
    where dea.continent is not null
)
SELECT *, (CumulativeVaccinations/population)*100 as PercentageVaccinated
FROM popvsvac;


-- CREATING TEMP TABLE, INSERTING SELECT THERE AND SHOWING --
drop table if exists PercentPopulationVaccinated;
create temporary table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date_ datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric
);

insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.date_) as CumulativeVaccinations
from coviddeaths as dea
join covidvaccinations as vac
	on (dea.location = vac.location
    and dea.date_ = vac. date_)
    where dea.continent is not null;
    
select *, (CumulativeVaccinations/Population)*100
from PercentPopulationVaccinated;


-- Creating VIEW to store data for future visualization
Create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.date_) as CumulativeVaccinations
from coviddeaths as dea
join covidvaccinations as vac
	on (dea.location = vac.location
    and dea.date_ = vac. date_)
    where dea.continent is not null;

