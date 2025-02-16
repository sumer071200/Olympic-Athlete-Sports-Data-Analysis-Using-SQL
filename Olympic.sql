-- Create and use the Olympic database
CREATE DATABASE olympic;
USE olympic;

-- Create table for Olympic history
CREATE TABLE olympics_history (
    ID INT,
    Name VARCHAR(50),
    Sex VARCHAR(1),
    Age VARCHAR(3),
    Height VARCHAR(3),
    Weight VARCHAR(3),
    Team VARCHAR(30),
    NOC VARCHAR(10),
    Games VARCHAR(20),
    Year INT,
    Season VARCHAR(15),
    City VARCHAR(30),
    Sport VARCHAR(50),
    Event VARCHAR(100),
    Medal VARCHAR(10)
);

-- Preview Olympic history data
SELECT * FROM olympics_history;

-- Create table for NOC regions
CREATE TABLE noc_regions (
    NOC VARCHAR(5),
    Region VARCHAR(30),
    Notes VARCHAR(50)
);

-- Preview NOC regions data
SELECT * FROM noc_regions;

-- Query 1: Count total Olympic Games held
SELECT COUNT(DISTINCT games) AS total_olympics_games 
FROM olympics_history;

-- Query 2: List all Olympic Games held
SELECT DISTINCT Year, Season, City
FROM olympics_history
ORDER BY Year;

-- Query 3: Total number of nations participating in each Olympic Game
SELECT games, COUNT(DISTINCT noc) AS total_countries
FROM olympics_history
GROUP BY games
ORDER BY games;

-- Query 4: Year with the highest and lowest number of participating countries
WITH temp AS (
    SELECT oh.games, nh.region
    FROM olympics_history oh
    JOIN noc_regions nh ON oh.noc = nh.noc
    GROUP BY games, nh.region
),
temp1 AS (
    SELECT games, COUNT(1) AS total_countries
    FROM temp
    GROUP BY games
)
SELECT DISTINCT 
    CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries), ' - ', 
           FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) AS lowest_countries,
    CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries DESC), ' - ', 
           FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS highest_countries
FROM temp1;

-- Query 5: Nations that participated in all Olympic Games
WITH total_games AS (
    SELECT COUNT(DISTINCT games) AS total_olympics_games 
    FROM olympics_history
),
total_countries AS (
    SELECT nh.region AS country, games
    FROM olympics_history oh
    JOIN noc_regions nh ON oh.noc = nh.noc
    GROUP BY games, nh.region
),
tot_participate AS (
    SELECT country, COUNT(games) AS total_participate
    FROM total_countries
    GROUP BY country
)
SELECT tp.* FROM tot_participate tp
JOIN total_games tg ON tp.total_participate = tg.total_olympics_games;

-- Query 6: Sport played in all Summer Olympics
WITH t1 AS (
    SELECT COUNT(DISTINCT games) AS total_summer_games
    FROM olympics_history
    WHERE season = 'Summer'
),
t2 AS (
    SELECT DISTINCT sport, games
    FROM olympics_history
    WHERE season = 'Summer'
    ORDER BY games
),
t3 AS (
    SELECT sport, COUNT(games) AS no_of_games
    FROM t2
    GROUP BY sport
)
SELECT * FROM t3
JOIN t1 ON t1.total_summer_games = t3.no_of_games;

-- Query 7: Sports played only once in Olympics
WITH temp AS (
    SELECT DISTINCT games, sport FROM olympics_history
),
temp1 AS (
    SELECT sport, COUNT(games) AS ng FROM temp
    GROUP BY sport
)
SELECT temp.sport, temp.games, temp1.ng
FROM temp
JOIN temp1 ON temp.sport = temp1.sport
WHERE temp1.ng = 1
ORDER BY sport;

-- Query 10: Ratio of male to female athletes in all Olympics
WITH t1 AS (
    SELECT sex, COUNT(*) AS cnt FROM olympics_history GROUP BY sex
),
t2 AS (
    SELECT *, ROW_NUMBER() OVER(ORDER BY cnt) AS rn FROM t1
),
min_cnt AS (
    SELECT cnt FROM t2 WHERE rn = 1
),
max_cnt AS (
    SELECT cnt FROM t2 WHERE rn = 2
)
SELECT CONCAT('1 : ', ROUND(CAST(max_cnt.cnt AS DECIMAL) / CAST(min_cnt.cnt AS DECIMAL), 2)) AS ratio
FROM min_cnt, max_cnt;

-- Query 11: Top 5 athletes with the most gold medals
WITH t1 AS (
    SELECT name, COUNT(1) AS total_medals
    FROM olympics_history
    WHERE medal = 'gold'
    GROUP BY name
),
t2 AS (
    SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk FROM t1
)
SELECT * FROM t2 WHERE rnk <= 5;

-- Query 12: Top 5 athletes with the most overall medals
WITH t1 AS (
    SELECT name, team, COUNT(1) AS total_medals
    FROM olympics_history
    WHERE medal IN ('gold', 'silver', 'bronze')
    GROUP BY name, team
),
t2 AS (
    SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk FROM t1
)
SELECT * FROM t2 WHERE rnk <= 5;

-- Query 19: Sport where India won the most medals
WITH t1 AS (
    SELECT sport, nr.region AS country, COUNT(1) AS total_medals
    FROM olympics_history oh
    JOIN noc_regions nr ON oh.noc = nr.noc
    WHERE medal <> 'NA' AND nr.region = 'India'
    GROUP BY sport, nr.region
),
t2 AS (
    SELECT *, RANK() OVER (ORDER BY total_medals DESC) AS rnk FROM t1
)
SELECT sport, total_medals FROM t2 WHERE rnk = 1;

-- Query 20: Breakdown of medals won by India in Hockey
SELECT sport, nr.region AS country, games, COUNT(1) AS total_medals
FROM olympics_history oh
JOIN noc_regions nr ON oh.noc = nr.noc
WHERE medal <> 'NA' AND nr.region = 'India' AND sport = 'Hockey'
GROUP BY games, sport, nr.region
ORDER BY total_medals DESC;
