--Q1: What range of years for baseball games played does the provided database cover?
--Answer: Between 1871 and 2016
SELECT MIN(yearid),
		MAX(yearid)
FROM appearances;
/*Q2:Find the name and height of the shortest player in the database. 
	How many games did he play in? What is the name of the team for which he played?*/
--Answer: Edward Carl Gaedel.  Played 1 game for SLA in 1951
WITH ref AS(
	SELECT p.playerid,namegiven,namelast,height,teamid,g_all,yearid,
	ROW_NUMBER() OVER(ORDER BY height) AS height_rank
	FROM people AS p
	LEFT JOIN appearances AS a
	ON p.playerid = a.playerid) 
SELECT *
FROM ref 
WHERE height_rank = 1;
/* Q3: Find all players in the database who played at Vanderbilt University.
Create a list showing each player’s first and last names as well as the 
total salary they earned in the major leagues.
Sort this list in descending order by the total salary earned.
Which Vanderbilt player earned the most money in the majors?
Answer:	David Taylor ($245,553,888)													*/
WITH ref AS(
	SELECT p.playerid AS playerid_1,namelast,namefirst,salary,namegiven,sch.schoolid
	FROM people AS p
	LEFT JOIN collegeplaying AS cp
	ON cp.playerid = p.playerid
	LEFT JOIN schools AS sch
	ON sch.schoolid = cp.schoolid
	LEFT JOIN salaries AS sal
	ON sal.playerid = p.playerid
	WHERE sch.schoolid = 'vandy'
		AND salary IS NOT NULL)
SELECT namegiven,SUM(salary) AS total_salary,schoolid
FROM ref
GROUP BY namegiven,schoolid
ORDER BY total_salary DESC;
/* Q4:Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield",
those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". 
Determine the number of putouts made by each of these three groups in 2016. 
Answer:		
			"Infield"	519,676
			"Outfield"	389,757	
			"Battery"	259,838
																	*/
SELECT 
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = 'SS' OR
		 pos = '1B' OR
		 pos = '2B' OR
		 pos = '3B'		THEN 'Infield'
	WHEN pos = 'P'	OR
		 pos = 'C'		THEN 'Battery'
	ELSE 'NA' END AS position,
	SUM(innouts)
FROM fielding
WHERE yearid = 2016
GROUP BY position;
/* Q5:Find the average number of strikeouts per game by decade since 1920. 
Round the numbers you report to 2 decimal places. 
Do the same for home runs per game. Do you see any trends?
Answer:		*/
WITH cte AS(
SELECT CASE WHEN yearid BETWEEN 1920 AND 1929 THEN 1920
	WHEN yearid BETWEEN 1930 AND 1939 THEN 1930
	WHEN yearid BETWEEN 1940 AND 1949 THEN 1940
	WHEN yearid BETWEEN 1950 AND 1959 THEN 1950
	WHEN yearid BETWEEN 1960 AND 1969 THEN 1960
	WHEN yearid BETWEEN 1970 AND 1979 THEN 1970
	WHEN yearid BETWEEN 1980 AND 1989 THEN 1980
	WHEN yearid BETWEEN 1990 AND 1999 THEN 1990
	WHEN yearid BETWEEN 2000 AND 2009 THEN 2000
	WHEN yearid BETWEEN 2010 AND 2019 THEN 2010
	ELSE 0 END AS decade,
	SUM(so) AS total_strikeouts,
	SUM(ghome) AS total_games,
	SUM(hr) AS total_hr,
	yearid
	FROM teams AS t
	WHERE yearid >=1920
	GROUP BY yearid)
SELECT decade,
ROUND(AVG(total_strikeouts/total_games),2) AS avg_strikeouts_per_game,
ROUND(AVG(total_hr/total_games),2) AS avg_hr_per_game
FROM cte
GROUP BY decade
ORDER BY decade DESC


