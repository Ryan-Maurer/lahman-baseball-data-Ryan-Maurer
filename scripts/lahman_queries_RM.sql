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
Answer:	Strong correlation between avg strikeouts and homeruns,save the fact that 
		homeruns took a sharp decrease in the last decade.
		Both appear to generally increase in frequency over time*/
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
ORDER BY decade DESC;
/* Q6:Find the player who had the most success stealing bases in 2016, 
	where success is measured as the percentage of stolen base attempts which are successful.
	(A stolen base attempt results either in a stolen base or being caught stealing.) 
	Consider only players who attempted at least 20 stolen bases.
Answer:	Christoper Scott													*/
WITH success_perc AS(
	SELECT playerid,yearid,sb,cs,(sb-cs) AS stolen_success
	FROM batting) 
SELECT sp.playerid,namegiven,(stolen_success::float / sb::float)*100 AS perc_success
FROM success_perc AS sp
LEFT JOIN people AS p
ON p.playerid = sp.playerid
WHERE sb >= 20
and YEARID = 2016
	AND stolen_success IS NOT NULL
ORDER BY (stolen_success::float / sb::float)*100  DESC;
/* Q7:From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion –
determine why this is the case. Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
What percentage of the time?
Answer:
	7A:	114 Wins for the 1998 New York Yankees
	7B: After exclusion of 1981 season due to player strike,
		2006 St.Louis Cardinals won with 83 wins
	7C:	between 1970 and 2016 12 (22.64%)teams who have had the most wins went on to win the world series															*/
WITH ref AS(
	SELECT teamid,name,g,w,l,wswin,yearid
	FROM teams
	WHERE wswin = 'Y'
		AND yearid BETWEEN 1970 AND 2016
	ORDER BY yearid DESC)
SELECT MAX(w) AS wins,name,yearid
FROM ref
GROUP BY name,yearid
ORDER BY wins ;

--Q7 Second Part
SELECT (SUM(is_wswin::float)/COUNT(*))* 100 AS perc
FROM(
	SELECT t.yearid,t.w,t.name,
		CASE WHEN t.wswin = 'Y' THEN 1
		ELSE 0 END AS is_wswin
	FROM (
		SELECT MAX(w) AS max_wins, yearid
		FROM teams
		GROUP BY yearid) AS nestsub
	INNER JOIN teams AS t 
	ON t.yearid = nestsub.yearid AND t.w = nestsub.max_wins
	WHERE t.yearid BETWEEN 1970 AND 2016) AS sub;