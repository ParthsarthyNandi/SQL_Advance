-- Pull the volumn of paid search nonbrand traffic landing on /lander-1 and /home, trended weekly since June 1st.
-- Also the overall paid search bounce rate trended weekly.

	-- Step 1: Find the first website_pageview_id for relevant sessions.
    -- Step 2: indentify the landing page
    -- Step 3: Counting Pageviews for ech sessions to identfy the bounces.
    -- Step 4: Summarizing by week (bounce rate, sessions to each lander).
    
use mavenfuzzyfactory;

select  * from website_sessions;
select * from website_pageviews;

-- Step 1: Find the first website_pageview_id for relevant sessions.
	
    create temporary table first_pageview_tbl
	select
		website_sessions.website_session_id,
        min(website_pageviews.website_pageview_id) as first_pageview,
        count(website_pageviews.website_pageview_id) as pages_visited
    from website_sessions
    left join website_pageviews 
    on website_sessions.website_session_id=website_pageviews.website_session_id
    where 
		website_sessions.created_at > '2012-06-01' and website_sessions.created_at < '2012-08-31'
        and website_sessions.utm_source = 'gsearch'
        and website_sessions.utm_campaign = 'nonbrand'
	
    group by website_sessions.website_session_id;
    
-- Step 2: indentify the landing page.
	
    create temporary table landing_page_tbl
	select
	 website_pageviews.website_session_id,
     first_pageview_tbl.first_pageview,
     first_pageview_tbl.pages_visited,
     website_pageviews.pageview_url as landing_page,
     website_pageviews.created_at as session_created_at
    from first_pageview_tbl
    left join website_pageviews
    on first_pageview_tbl.first_pageview = website_pageviews.website_pageview_id;
    
-- Step 3: Calcullate the bounce sessions. Based on Yearweek, week start date total sessions, bounced session, bounced rate, home sessions, lander sessions.
-- Step 4: Summarize.

	select * from landing_page_tbl;
    
    select
		yearweek(session_created_at) as year_of_the_week,
        min(date(session_created_at)) as week_start_date,
        count(distinct website_session_id) as total_sessions,
        count(distinct case when pages_visited = 1 then website_session_id else null end) as bounced_sessions,
        (count(distinct case when pages_visited = 1 then website_session_id else null end)/count(distinct website_session_id)) as bounced_rate,
        count(distinct case when landing_page = '/home' then website_session_id else null end) as home_sessions,
        count(distinct case when landing_page = '/lander-1' then website_session_id else null end) as lander_sessions
	from landing_page_tbl
    group by yearweek(session_created_at);
    
-- Lander has more session and less bounce rate.