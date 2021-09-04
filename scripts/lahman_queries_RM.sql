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
Answer:	David Price ($81,851,296)													*/
WITH cte AS(
	SELECT p.playerid ,CONCAT(namelast,',',' ',namefirst) AS full_name,
	CASE WHEN salary IS NULL THEN 0.00
	ELSE salary END AS salary_corr
	,sch.schoolid,sal.yearid
	FROM people AS p
	LEFT JOIN collegeplaying AS cp
	ON cp.playerid = p.playerid
	LEFT JOIN schools AS sch
	ON sch.schoolid = cp.schoolid
	LEFT JOIN salaries AS sal
	ON sal.playerid = p.playerid
	WHERE sch.schoolid = 'vandy')
SELECT full_name,SUM(DISTINCT salary_corr) AS total_salary
FROM cte
GROUP BY full_name,schoolid
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
	SUM(PO)
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
Answer:	Technically Chris Owings, but Billy Hamilton's percentage is close
and has nearly triple double the attempts			*/
WITH success_perc AS(
	SELECT playerid,yearid,sb,cs,(sb-cs) AS stolen_success
	FROM batting) 
SELECT sp.playerid,namelast,namefirst,
(stolen_success::float / sb::float)*100 AS perc_success,
sb
FROM success_perc AS sp
LEFT JOIN people AS p
ON p.playerid = sp.playerid
WHERE sb >= 20
and yearid = 2016
ORDER BY (stolen_success::float / sb::float)*100  DESC;
/* Q7:From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion –
determine why this is the case. Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
What percentage of the time?
Answer:
	7A:	116 Wins for the 2001 Seattle Mariners
	7B: After exclusion of 1981 season due to player strike,
		2006 St.Louis Cardinals won with 83 wins
	7C:--between 1970 and 2016 12 (22.64%)teams who have had the most wins went on to win the world series															*/
WITH ref AS(					--team that did not win
	SELECT teamid,name,g,w,l,wswin,yearid
	FROM teams
	WHERE wswin = 'N'
		AND yearid BETWEEN 1970 AND 2016
	ORDER BY yearid DESC)
SELECT MAX(w) AS wins,name,yearid
FROM ref
GROUP BY name,yearid
ORDER BY wins DESC;

WITH ref AS(					--team that did  win
	SELECT teamid,name,g,w,l,wswin,yearid
	FROM teams
	WHERE wswin = 'Y'
		AND yearid BETWEEN 1970 AND 2016
	ORDER BY yearid DESC)
SELECT MIN(w) AS wins,name,yearid
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
	WHERE t.yearid BETWEEN 1970 AND 2016
	AND t.yearid <> 1981) AS sub;

/* Q8:Using the attendance figures from the homegames table, 
find the teams and parks which had the top 5 average attendance per game in 2016 
(where average attendance is defined as total attendance divided by number of games).
Only consider parks where there were at least 10 games played. 
Report the park name, team name, and average attendance. 
Repeat for the lowest 5 average attendance.
Answer:	
TOP 5
"LAN"	"Dodger Stadium"	45719
"SLN"	"Busch Stadium III"	42524
"TOR"	"Rogers Centre"		41877
"SFN"	"AT&T Park"			41546
"CHN"	"Wrigley Field"		39906

BOTTOM 5
"TBA"	"Tropicana Field"					15878
"OAK"	"Oakland-Alameda County Coliseum"	18784
"CLE"	"Progressive Field"					19650
"MIA"	"Marlins Park"						21405
"CHA"	"U.S. Cellular Field"				21559	*/
														
SELECT DISTINCT name,park_name,
(hg.attendance/games) AS avg_attendance	   --top stadiums
FROM homegames AS hg
LEFT JOIN parks AS p
ON hg.park = p.park
LEFT JOIN (
	SELECT *
	FROM teams
	WHERE yearid = 2016) AS t
ON hg.team = t.teamid
WHERE year = 2016
	AND games >= 10
ORDER BY hg.attendance/games  DESC
LIMIT 5;

SELECT DISTINCT name,park_name,
(hg.attendance/games) AS avg_attendance	   --bottom stadiums
FROM homegames AS hg
LEFT JOIN parks AS p
ON hg.park = p.park
LEFT JOIN (
	SELECT *
	FROM teams
	WHERE yearid = 2016) AS t
ON hg.team = t.teamid
WHERE year = 2016
	AND games >= 10
ORDER BY hg.attendance/games 
LIMIT 5;

/* Q9:Which managers have won the TSN Manager of the Year award in both the National League (NL)
and the American League (AL)? Give their full name and the teams that they were managing 
when they won the award.
Answer:												*/

SELECT CONCAT(ppl.namelast,',',' ',ppl.namefirst) as name_full,
	awdmgrs.yearid,teamid,awdmgrs.lgid
FROM awardsmanagers AS awdmgrs
INNER JOIN (
	SELECT am.playerid,namelast,namefirst
	FROM awardsmanagers AS am
	LEFT JOIN people AS p
	ON am.playerid = p.playerid
	LEFT JOIN managers AS m 
	ON am.playerid = m.playerid AND m.yearid = am.yearid
	WHERE awardid = 'TSN Manager of the Year'
		AND am.lgid = 'AL' 
INTERSECT
SELECT am.playerid,namelast,namefirst
	FROM awardsmanagers AS am
	LEFT JOIN people AS p
	ON am.playerid = p.playerid
	LEFT JOIN managers AS m 
	ON am.playerid = m.playerid AND m.yearid = am.yearid
	WHERE awardid = 'TSN Manager of the Year'
		AND am.lgid = 'NL' ) AS sub
ON sub.playerid = awdmgrs.playerid 
LEFT JOIN managers AS mgr
ON mgr.playerid = awdmgrs.playerid AND mgr.yearid = awdmgrs.yearid
LEFT JOIN people as ppl
ON ppl.playerid = awdmgrs.playerid
GROUP BY awdmgrs.playerid,ppl.namelast,ppl.namefirst,awdmgrs.yearid,teamid,awdmgrs.lgid
;
--open ended questions

/* Q12:In this question, you will explore the connection between number of wins and attendance.
Does there appear to be any correlation between attendance at home games and number of wins?
Do teams that win the world series see a boost in attendance the following year?
What about teams that made the playoffs? 
Making the playoffs means either being a division winner or a wild card winner. */
	SELECT name,ROUND(AVG(attendance),2) AS avg_attendance,SUM(w) AS sum_wins
	FROM teams
	WHERE yearid >= 2000
	GROUP BY name
	ORDER BY AVG(attendance) DESC;	
	--Do teams that win the world series see a boost in attendance the following year?
WITH cte AS (
	SELECT yearid,teamid,atn_after_wsw,attendance,(atn_after_wsw-attendance) AS attendance_diff,
	wswin
FROM (
	SELECT yearid,teamid,
		CASE WHEN wswin = 'N' THEN 0
	ELSE LEAD (attendance,1,0) OVER(PARTITION BY teamid ORDER BY yearid) END AS atn_after_wsw,
		attendance,wswin
	FROM
	teams) AS sub)
SELECT ROUND(AVG(attendance_diff),2) AS atn_after_wswin
FROM cte
WHERE atn_after_wsw > 0
	AND wswin IS NOT NULL
;

WITH cte AS (
	SELECT yearid,teamid,atn_after_playoff,attendance,
			(atn_after_playoff-attendance) AS attendance_diff,divwin,wcwin

FROM (
	SELECT yearid,teamid,
		CASE WHEN divwin = 'Y' OR wcwin = 'Y'THEN LEAD (attendance,1,0) OVER(PARTITION BY teamid ORDER BY yearid)
		ELSE 0 END AS atn_after_playoff,
		attendance,divwin,wcwin
	FROM
	teams) AS sub)
SELECT ROUND(AVG(attendance_diff),2) AS atn_after_playoff
FROM cte
WHERE atn_after_playoff> 0
;
/* Q13:It is thought that since left-handed pitchers are more rare,
causing batters to face them less often, that they are more effective. 
Investigate this claim and present evidence to either support or dispute this claim.
First, determine just how rare left-handed pitchers are compared with right-handed pitchers.
Are left-handed pitchers more likely to win the Cy Young Award?
Are they more likely to make it into the hall of fame?

Answer:	Approximately 20% of all pitchers are left handed.  Since approximately 33% of a Cy Young
Winners are left handed (13% more than the avg number of left handed pitchers)
they have a greater relative chance of winning the Cy Young Award.
With a makeup of approximately 28% of the pitchers in the hall of fame*/

WITH cte AS(			--creates table excluding nulls for reference
	SELECT playerid,throws
		FROM people
		WHERE throws IS NOT NULL)
SELECT (SUM(is_left::float) / COUNT(*))*100 AS perc_left	
FROM(
SELECT cte.playerid, 			--quantifies 'throws' field so calculations can be made on it
	CASE WHEN cte.throws = 'R' THEN 0
	WHEN  cte.throws = 'L' THEN 1
	ELSE 0 END AS is_left		--creates 'is_left' to specify number of left handed pitchers		
FROM cte
INNER JOIN people AS ppl
ON cte.playerid = ppl.playerid) AS sub
;
--how likely are left handed pitchers to win cy young award
WITH people_clean AS(			--creates table excluding nulls for reference
	SELECT playerid,throws
		FROM people
		WHERE throws IS NOT NULL)
SELECT (SUM(is_left::float) / COUNT(*))*100 AS perc_left_awd,
		(SUM(is_right::float) / COUNT(*))*100 AS perc_right_awd
FROM awardsplayers AS ap
INNER JOIN (			--inner joining pitching table to get list of pitchers
	SELECT pitch.playerid,
	CASE WHEN throws = 'L' THEN 1	--adding column 'is_left' onto pitching table
	ELSE 0 END AS is_left
	FROM pitching AS pitch
	LEFT JOIN people_clean AS cte
	ON pitch.playerid = cte.playerid
	GROUP BY pitch.playerid,cte.throws) AS leftpitchers
ON ap.playerid = leftpitchers.playerid
LEFT JOIN(		--left joining 'is_right' column on to pitching table
	SELECT pitch.playerid,
	CASE WHEN throws = 'R' THEN 1
	ELSE 0 END AS is_right
	FROM pitching AS pitch
	LEFT JOIN people_clean AS cte
	ON pitch.playerid = cte.playerid
	GROUP BY pitch.playerid,cte.throws) AS rightpitchers
ON ap.playerid = rightpitchers.playerid
WHERE awardid = 'Cy Young Award';		--specifying award type

--how likely are left handed pitchers to make it into the hall of fame
--presuming that this is out of all pitchers in hof and not players 
WITH cte AS(			
	SELECT playerid,throws
		FROM people
		WHERE throws IS NOT NULL)
SELECT (SUM(is_left::float) / COUNT(*))*100 AS perc_left_hof,
		(SUM(is_right::float) / COUNT(*))*100 AS perc_right_hof
FROM halloffame AS hof
INNER JOIN (			--inner joining list of 9,302 pitchers (excluding nulls) onto people (cte)
	SELECT pitch.playerid,
	CASE WHEN throws = 'L' THEN 1	--only including left handed pitchers for this join
	ELSE 0 END AS is_left
	FROM pitching AS pitch
	LEFT JOIN cte
	ON pitch.playerid = cte.playerid
	GROUP BY pitch.playerid,cte.throws) AS leftpitchers
ON hof.playerid = leftpitchers.playerid
LEFT JOIN(				--add is_right handed on to pitchers table
	SELECT pitch.playerid,
	CASE WHEN throws = 'R' THEN 1
	ELSE 0 END AS is_right
	FROM pitching AS pitch
	LEFT JOIN cte
	ON pitch.playerid = cte.playerid
	GROUP BY pitch.playerid,cte.throws) AS rightpitchers
ON hof.playerid = rightpitchers.playerid
;

