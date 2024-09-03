-- This scripts analyzes the the landing page tests. 
-- BACKGROUND: After the previous analysis on bounce rates, the management has asked the data anlayst to do a A/B testing of Home page vs Lander 1 page which is recently added by the marketing manager.
	-- Constraints : Perform the analysis only from the date when /Lander-1 was first introduced against the /home page.
    
    -- Step 1: Find the date and time when /lander-1 first appears.
    -- Step 2: Find the first website pageview id.
    -- Step 3: Identify the landing page of each session.
    -- Step 4: Identify the bounce sessions by counting the pageviews of each sessions.
    -- Step 5: Summarize the total.
    
use mavenfuzzyfactory;

select * from website_pageviews;

	-- Find the date and time when /lander-1 was created.

select min(created_at)
from website_pageviews
where pageview_url = "/lander-1";

	-- Find the first website pageview id.

SELECT website_pageview_id, created_at
FROM website_pageviews
WHERE pageview_url = '/lander-1'
  AND created_at = (SELECT MIN(created_at)
                    FROM website_pageviews
                    WHERE pageview_url = '/lander-1');
                    
	-- Find the landing page of each session.

drop table landing_page_analysis;
create temporary table landing_page_analysis
select 
	website_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
inner join website_sessions
	on website_sessions.website_session_id = website_pageviews.website_session_id
    where website_pageviews.created_at>='2012-06-19 00:35:54' and website_pageviews.created_at < '2012-07-28 00:00:00'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
    and website_pageview_id > 23504
group by website_pageviews.website_session_id;

select 
	*
from landing_page_analysis;

			-- Identifying the landing page /home or /lander-1.
drop table nonbrand_test;
create temporary table nonbrand_test
select landing_page_analysis.website_session_id,
	min_pageview_id,
    website_pageviews.pageview_url as landing_page
from landing_page_analysis
left join website_pageviews
on website_pageviews.website_pageview_id = landing_page_analysis.min_pageview_id
where pageview_url in ('/home','/lander-1');

select * from nonbrand_test;

	-- counting the number of boounced sessions by counting the number of pages visited in each session.

create temporary table bounced_session_tbl
select
	nonbrand_test.website_session_id,
    nonbrand_test.landing_page,
    count(website_pageviews.website_pageview_id) as count_of_page
from nonbrand_test
left join website_pageviews
on nonbrand_test.website_session_id = website_pageviews.website_session_id
group by 	
	nonbrand_test.website_session_id,
    nonbrand_test.landing_page
having 
	count(website_pageviews.website_pageview_id) = 1;
    
select * from bounced_session_tbl;

	-- Now summarising the total and analyze the A/B Test.

create temporary table total_sessions
select
    nonbrand_test.landing_page,
    count(distinct website_pageviews.website_session_id) as sessions
from nonbrand_test
left join website_pageviews
on nonbrand_test.website_session_id = website_pageviews.website_session_id
group by 	
    nonbrand_test.landing_page;
    
select * from total_sessions;
    
create temporary table bounced_table    
select 
	landing_page,
    count(website_session_id) as bounce_count
from bounced_session_tbl
group by landing_page;

	--  Bounced Rate calculation.
select
	bounced_table.landing_page as landing_page,
    total_sessions.sessions as total_sessions,
	bounced_table.bounce_count as bounced_sessions,
	(bounced_table.bounce_count /total_sessions.sessions) as bounced_rate
from bounced_table
inner join total_sessions
on bounced_table.landing_page = total_sessions.landing_page; 
