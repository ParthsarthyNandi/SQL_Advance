use mavenfuzzyfactory;

-- Fiind the most viewed website pages, ranked by session volumn.

select * from website_sessions;

select * from website_pageviews;

select pageview_url, count(distinct website_pageview_id) 
from website_pageviews
where created_at < '2012-06-09'
group by pageview_url
order by count(*) desc;

-- Find the top entry pages with the volumns?

-- STEP 1: Find the first pageview for each session
-- STEP 2: Find the url that the cusstomer saw on the first pageview

create temporary table first_pv_per_session
select 
	website_session_id,
    min(website_pageview_id) as first_pv
from website_pageviews
where created_at <'2012-06-12'
group by website_session_id;

select * from first_pv_per_session;

select website_pageviews.pageview_url as landing_page_url,
count(distinct first_pv_per_session.website_session_id) as sessions_hitting_page
from first_pv_per_session
left join website_pageviews
on first_pv_per_session.first_pv = website_pageviews.website_pageview_id
group by website_pageviews.pageview_url;

-- Find the sessions which have more than 1 pageview.

select * from website_pageviews;

select website_session_id, count(website_pageview_id) as num_of_hit
from website_pageviews
group by website_session_id
order by count(website_pageview_id) desc;

-- Business Question -> Find the landing page performance for a given time period.

	-- Step 1:find tthe first website_pageview_id for the relevan sessions.
    
    select * from website_pageviews;
    select website_session_id, min(website_pageview_id) as first_pageview
    from website_pageviews
    group by website_session_id;

	-- Step 2: identify the landing page for each sessions
	
    create temporary table first_website_pageview
    select website_session_id, min(website_pageview_id) as first_pageview
    from website_pageviews
    group by website_session_id;
    
    create temporary table landing_page
    select first_website_pageview.website_session_id, first_pageview, website_pageviews.pageview_url
    from first_website_pageview
    left join website_pageviews
    on first_pageview = website_pageviews.website_pageview_id;
    
    select pageview_url, count(distinct website_session_id) as number_of_hits
    from landing_page
    group by pageview_url
    order by count(distinct website_session_id) desc;
    
    select * from landing_page;
    
    -- Findign the bounce rates
    
    select * from landing_page;
    
    select * from website_pageviews;
    
    create temporary table bounce_page
    SELECT 
    landing_page.website_session_id, 
    landing_page.first_pageview,
    landing_page.pageview_url,
    COUNT(DISTINCT website_pageview_id) AS num_of_page_visited
	FROM landing_page
	LEFT JOIN website_pageviews
		ON landing_page.website_session_id = website_pageviews.website_session_id
	GROUP BY landing_page.website_session_id, 
         landing_page.first_pageview, 
         landing_page.pageview_url;
    
    -- Bounce sessions are those where the user landed on a page but did not do anything further
    
    select * from bounce_page;
    
    select 
		pageview_url,
        count(distinct website_session_id) as count_of_sessions
    from bounce_page
    where num_of_page_visited = 1
    group by pageview_url
    order by count(website_session_id) desc;
    
    create temporary table required_bounce_page
	select 
		pageview_url,
        count(distinct b.website_session_id) as count_of_sessions
    from bounce_page b
    inner join website_sessions w
    on b.website_session_id = w.website_session_id
    where num_of_page_visited = 1
		and w.created_at between '2014-01-01' and '2014-02-01'
    group by pageview_url
    order by count(b.website_session_id) desc; 
    
    -- Calculatiing Bouce Rate will be easy after this as we need to divide the bouce sessions by total sessions
    
    create temporary table total_pageview
    select wp.pageview_url, count(distinct wp.website_pageview_Id) as total_sessions
    from website_pageviews wp
    inner join website_sessions ws
    on wp.website_session_id = ws.website_session_id
    where ws.created_at between '2014-01-01' and '2014-02-01'
    group by wp.pageview_url;

	select rbp.pageview_url,
		(count_of_sessions/total_sessions) as bounce_rate
    from required_bounce_page rbp
    inner join total_pageview tp
    on rbp.pageview_url = tp.pageview_url;