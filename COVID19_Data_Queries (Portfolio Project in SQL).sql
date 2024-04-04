-- (Whole Data of Covid 19 Deaths)
select * 
from ['owid-covid-dataDeath']


-- Maximum Death Count For Each Country and Death Percentage Of Population
select location, population, max(cast(total_deaths as int)) as total_death, ((max(cast(total_deaths as int)/population)*100)) as death_percent_population
from ['owid-covid-dataDeath']
where continent is not null
group by location, population
order by 1, 2 


-- Country with Highest Death Toll per Continent
select continent, max(cast(total_deaths as int)) as country_highest_death_toll_per_continent
from ['owid-covid-dataDeath']
where continent is not null
group by continent
order by 1, 2


-- Continental Mortality: Total Death Counts by Continent
select continent, sum(convert(int, new_deaths)) as total_death_per_continent
from ['owid-covid-dataDeath']
where continent is not null
group by continent
order by 1, 2


-- Comparing Continent-Specific Death Counts and Death Percentages Across Population and Wealth Demographics
select location, population, max(cast(total_deaths as int)) as total_death, (max(cast(total_deaths as int))) / population*100 as death_percentage
from ['owid-covid-dataDeath']
where continent is null
group by location, population
order by 1, 3


-- Global COVID-19 Stats: Total Cases and Deaths by Date, Descending Order
select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths
from ['owid-covid-dataDeath']
where continent is not null
and total_cases is not null
group by date 
order by 1 desc


-- Global COVID-19 Stats: Total Cases, Total Deaths, and Worldwide Fatality Rate
select convert(varchar, convert(money, sum(new_cases)), 1) as world_total_cases, convert(varchar, convert(money, sum(new_deaths)), 1) as world_total_deaths, (sum(new_deaths)/sum(new_cases))*100 as world_death_percentage
from ['owid-covid-dataDeath']
where continent is not null
-- Comment: nearly 1 percent of all total cases in the world died.


-- Combining COVID-19 Deaths and Vaccination Data: A Comprehensive Analysis 

-- (Whole Data)
select *
from ['owid-covid-dataDeath'] as dth
join ['owid-covid-dataVac'] as vac
on dth.location = vac.location
and dth.date = vac.date
and dth.continent = vac.continent
where dth.continent is not null 
and vac.continent is not null


-- Examining Total Population in Relation to Cumulative New Vaccinations
select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,sum(cast(vac.new_vaccinations as float)) over (partition by dth.location order by dth.location, dth.date) as cumulative_new_vaccinations
from ['owid-covid-dataDeath'] as dth
join ['owid-covid-dataVac'] as vac
on dth.location = vac.location
and dth.date = vac.date
and dth.continent = vac.continent
where dth.continent is not null 
and vac.continent is not null
and new_vaccinations is not null
order by 1


-- Examining Total Population in Relation to Cumulative New Vaccinations and Cumulative New Vaccinations Percentage Using CTEs
with cnv (continent, location, date, population, new_vaccinations, cumulative_new_vaccinations)
as
(select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as float)) over (partition by dth.location order by dth.location, dth.date) as cumulative_new_vaccinations
from ['owid-covid-dataDeath'] as dth
join ['owid-covid-dataVac'] as vac
on dth.location = vac.location
and dth.date = vac.date
and dth.continent = vac.continent
where dth.continent is not null 
and vac.continent is not null
and new_vaccinations is not null
)

select *, cast((cumulative_new_vaccinations/population) as decimal(18, 10))*100 as cumulative_new_vaccinations_percent
from cnv
order by 1
-- cnv short for cumulative new vaccinations


-- Examining Total Population in Relation to Cumulative New Vaccinations and Cumulative New Vaccinations Percentage Using TEMP TABLE
drop table if exists #temp_table1
create table #temp_table1 (
    continent varchar(100), 
	location varchar(100), 
	date datetime, 
	population int,
	new_vaccinations float,
	cumulative_new_vaccinations float
)

insert into #temp_table1 
	select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as float)) over (partition by dth.location order by dth.location, dth.date) as cumulative_new_vaccinations
	from ['owid-covid-dataDeath'] as dth
	join ['owid-covid-dataVac'] as vac
	on dth.location = vac.location
	and dth.date = vac.date
	and dth.continent = vac.continent
	where dth.continent is not null 
	and vac.continent is not null
	and new_vaccinations is not null

select *, cast((cumulative_new_vaccinations/population) as decimal(18, 10))*100 as cumulative_new_vaccinations_percent
from #temp_table1
order by 1


-- Create View For Visualization

-- view to calculate cumulative new vaccinations 
create view cumulative_new_vaccinations_percent as
	select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as float)) over (partition by dth.location order by dth.location, dth.date) as cumulative_new_vaccinations
	from ['owid-covid-dataDeath'] as dth
	join ['owid-covid-dataVac'] as vac
	on 
	dth.location = vac.location
	and dth.date = vac.date
	and dth.continent = vac.continent
	where 
    dth.continent is not null 
    and vac.continent is not null
    and new_vaccinations is not null
    -- order by 1;

select *
from cumulative_new_vaccinations_percent