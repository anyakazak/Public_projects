-- Task 1

WITH fb_analitics AS (
SELECT 
	ad_date,
	facebook_campaign.campaign_name,
	facebook_adset.adset_name,
	spend, 
	impressions, 
	reach, 
	clicks, 
	leads, 
	value
FROM facebook_ads_basic_daily
LEFT JOIN facebook_adset 
	ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
LEFT JOIN facebook_campaign 
	ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id),
	common_analytics AS (
SELECT
	ad_date,
	'Google Ads' AS media_source,
	campaign_name,
	adset_name,
	spend, 
	impressions, 
	reach, 
	clicks, 
	leads, 
	value
FROM google_ads_basic_daily
UNION
SELECT
	ad_date,
	'Facebook Ads' AS media_source,
	campaign_name,
	adset_name,
	spend, 
	impressions, 
	reach, 
	clicks, 
	leads, 
	value
FROM fb_analitics)
SELECT 
	ad_date,
	media_source,
	campaign_name,
	adset_name,
	SUM (spend) AS total_spend,
	SUM (impressions) AS total_impressions,
	SUM (clicks) AS total_clicks,
	SUM(value) AS total_value
FROM common_analytics
GROUP BY 
	ad_date,
	media_source,
	campaign_name,
	adset_name
ORDER BY 
	ad_date;


-- Additional task - var.1
WITH analitics AS (
SELECT 
	facebook_campaign.campaign_name,
	facebook_adset.adset_name,
	spend,
	value
FROM facebook_ads_basic_daily
LEFT JOIN facebook_adset 
	ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
LEFT JOIN facebook_campaign 
	ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
UNION
SELECT 
	campaign_name,
	adset_name,
	spend, 
	value
FROM google_ads_basic_daily),
top_campaign AS (
	SELECT
		campaign_name,
		ROUND(100.0 * (SUM (value) - SUM (spend)) / SUM(spend), 2) AS "ROMI"
	FROM analitics
	GROUP BY 
		campaign_name
	HAVING
		SUM (spend) > 500000
	ORDER BY
   		"ROMI" desc
	LIMIT 1)
SELECT
	analitics.campaign_name,
	analitics.adset_name,
	ROUND(100.0 * (SUM (value) - SUM (spend)) / SUM(spend), 2) AS "ROMI"
FROM analitics
JOIN top_campaign ON analitics.campaign_name=top_campaign.campaign_name
GROUP BY 
		analitics.campaign_name,
		analitics.adset_name;
	
	
-- 	Additional task - var.2 (simple) 
WITH analitics AS (
	SELECT 
		facebook_campaign.campaign_name,
		facebook_adset.adset_name,
		spend,
		value
	FROM facebook_ads_basic_daily
	LEFT JOIN facebook_adset 
		ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
	LEFT JOIN facebook_campaign 
		ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
	UNION
	SELECT 
		campaign_name,
		adset_name,
		spend, 
		value
	FROM google_ads_basic_daily)
SELECT
	campaign_name,
	adset_name,
	ROUND(100.0 * (SUM (value) - SUM (spend)) / SUM(spend), 2) AS "ROMI"
FROM analitics
GROUP BY 
	campaign_name,
	adset_name
HAVING
	SUM (spend) > 500000
ORDER BY
   	"ROMI" desc
LIMIT 1;

-- Task 2
WITH analytics AS (
	SELECT 
		ad_date,
		campaign_name,
		adset_name,
		url_parameters,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM facebook_ads_basic_daily
	LEFT JOIN facebook_adset 
		ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
	LEFT JOIN facebook_campaign 
		ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
	UNION
	SELECT 
		ad_date,
		campaign_name,
		adset_name,
		url_parameters,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM google_ads_basic_daily)
SELECT
	ad_date,
	CASE 
        WHEN LOWER(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)')) = 'nan' 
        THEN NULL 
        ELSE LOWER(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)')) 
   END AS utm_campaign,
	SUM(spend) AS total_spend,
	SUM(impressions) AS total_impressions,
	SUM(clicks) AS total_clicks,
	SUM(value) AS total_value,
	CASE WHEN SUM(clicks) > 0 THEN round (1.0 * SUM(spend) / SUM(clicks),2) ELSE 0 END AS "CPC",
	CASE WHEN SUM(impressions) > 0 THEN round (1.0 * SUM(spend) / SUM(impressions) * 1000, 2) ELSE 0 END AS "CPM",
	CASE WHEN SUM(impressions) > 0 THEN round (100.0 * SUM(clicks) / SUM(impressions),2) ELSE 0 END AS "CTR",
	CASE WHEN SUM(spend) > 0 THEN ROUND(100.0 * (SUM(value) - SUM(spend)) / SUM(spend),2) ELSE 0 END AS "ROMI"
FROM analytics
GROUP BY 
	ad_date,
	utm_campaign
ORDER BY 
    ad_date;


CREATE OR REPLACE FUNCTION url_decode(encoded text)
RETURNS text AS $$
DECLARE
    decoded text;
BEGIN
    decoded := replace(encoded, '+', ' ');
    decoded := replace(decoded, '%20', ' ');
    decoded := replace(decoded, '%21', '!');
    decoded := replace(decoded, '%22', '"');
    decoded := replace(decoded, '%23', '#');
    decoded := replace(decoded, '%24', '$');
    decoded := replace(decoded, '%25', '%');
    decoded := replace(decoded, '%26', '&');
    decoded := replace(decoded, '%27', '''');
    decoded := replace(decoded, '%28', '(');
    decoded := replace(decoded, '%29', ')');
    decoded := replace(decoded, '%2A', '*');
    decoded := replace(decoded, '%2B', '+');
    decoded := replace(decoded, '%2C', ',');
    decoded := replace(decoded, '%2D', '-');
    decoded := replace(decoded, '%2E', '.');
    decoded := replace(decoded, '%2F', '/');
    decoded := replace(decoded, '%3A', ':');
    decoded := replace(decoded, '%3B', ';');
    decoded := replace(decoded, '%3C', '<');
    decoded := replace(decoded, '%3D', '=');
    decoded := replace(decoded, '%3E', '>');
    decoded := replace(decoded, '%3F', '?');
    decoded := replace(decoded, '%40', '@');
    decoded := replace(decoded, '%5B', '[');
    decoded := replace(decoded, '%5C', '\');
    decoded := replace(decoded, '%5D', ']');
    decoded := replace(decoded, '%5E', '^');
    decoded := replace(decoded, '%5F', '_');
    decoded := replace(decoded, '%60', '`');
    decoded := replace(decoded, '%7B', '{');
    decoded := replace(decoded, '%7C', '|');
    decoded := replace(decoded, '%7D', '}');
    decoded := replace(decoded, '%7E', '~');
    decoded := replace(decoded, '%C2%A0', ' ');
    RETURN decoded;
END;
$$ LANGUAGE plpgsql;

WITH analytics AS (
	SELECT 
		ad_date,
		campaign_name,
		adset_name,
		url_parameters,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM facebook_ads_basic_daily
	LEFT JOIN facebook_adset 
		ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
	LEFT JOIN facebook_campaign 
		ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
	UNION
	SELECT 
		ad_date,
		campaign_name,
		adset_name,
		url_parameters,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM google_ads_basic_daily)
SELECT
	ad_date,
	CASE 
        WHEN LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) = 'nan' 
        THEN NULL 
        ELSE LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) 
    END AS utm_campaign,
	SUM(spend) AS total_spend,
	SUM(impressions) AS total_impressions,
	SUM(clicks) AS total_clicks,
	SUM(value) AS total_value,
	CASE WHEN SUM(clicks) > 0 THEN round (1.0 * SUM(spend) / SUM(clicks),2) ELSE 0 END AS "CPC",
	CASE WHEN SUM(impressions) > 0 THEN round (1.0 * SUM(spend) / SUM(impressions) * 1000, 2) ELSE 0 END AS "CPM",
	CASE WHEN SUM(impressions) > 0 THEN round (100.0 * SUM(clicks) / SUM(impressions),2) ELSE 0 END AS "CTR",
	CASE WHEN SUM(spend) > 0 THEN ROUND(100.0 * (SUM(value) - SUM(spend)) / SUM(spend),2) ELSE 0 END AS "ROMI"
FROM analytics
GROUP BY 
	ad_date,
	utm_campaign
ORDER BY 
    ad_date;


-- Task 3
-- var.1: Three separate fields: "CPM difference" - Δ_CPM, "CTR difference" - Δ_CTR, and "ROMI difference" - Δ_ROMI
-- I like it more visually
WITH daily_analytics AS (
	SELECT 
		ad_date,
		CASE 
        	WHEN LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) = 'nan'
        	THEN NULL 
        	ELSE LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) 
   		END AS utm_campaign,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM facebook_ads_basic_daily
	LEFT JOIN facebook_adset 
		ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
	LEFT JOIN facebook_campaign 
		ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
	UNION
	SELECT 
		ad_date,
		CASE 
        	WHEN LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) = 'nan' 
        	THEN NULL 
        	ELSE LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) 
   		END AS utm_campaign,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM google_ads_basic_daily),
monthly_analytics AS (
	SELECT
		DATE_TRUNC('month', ad_date)::date AS ad_month,
		utm_campaign,
		SUM(spend) AS total_spend,
		SUM(impressions) AS total_impressions,
		SUM(clicks) AS total_clicks,
		SUM(value) AS total_value,
		CASE WHEN SUM(clicks) > 0 THEN ROUND (1.0 * SUM(spend) / SUM(clicks),2) ELSE 0 END AS CPC,
		CASE WHEN SUM(impressions) > 0 THEN ROUND (1.0 * SUM(spend) / SUM(impressions) * 1000, 2) ELSE 0 END AS CPM,
		CASE WHEN SUM(impressions) > 0 THEN ROUND (100.0 * SUM(clicks) / SUM(impressions),2) ELSE 0 END AS CTR,
		CASE WHEN SUM(spend) > 0 THEN ROUND(100.0 * (SUM(value) - SUM(spend)) / SUM(spend),2) ELSE 0 END AS ROMI
	FROM daily_analytics
	GROUP BY 
        ad_month,
        utm_campaign)
SELECT 
	ad_month,
	utm_campaign,
	total_spend,
	total_impressions,
	total_clicks,
	total_value,
	CPC,
	CPM,
	ROUND(
		(CPM/(LAG(CPM) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) -1) * 100
		, 2) AS Δ_CPM,
	CTR,
	ROUND(
		(CTR/(LAG(CTR) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) -1) * 100
		, 2) AS Δ_CTR,
	ROMI,
	ROUND(
		(ROMI/(LAG(ROMI) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) -1 ) * 100
		, 2) AS Δ_ROMI
FROM monthly_analytics
ORDER BY
	utm_campaign;

        
-- var.2: One field "Difference of CPM, CTR, and ROMI in percentages" (as specified in the task) - "Δ_CPM,CTR,ROMI,%",
-- where the Δ (difference) values are separated by ' / '.
WITH daily_analytics AS (
	SELECT 
		ad_date,
		CASE 
        	WHEN LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) = 'nan'
        	THEN NULL 
        	ELSE LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) 
   		END AS utm_campaign,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM facebook_ads_basic_daily
	LEFT JOIN facebook_adset 
		ON facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
	LEFT JOIN facebook_campaign 
		ON facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
	UNION
	SELECT 
		ad_date,
		CASE 
        	WHEN LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) = 'nan' 
        	THEN NULL 
        	ELSE LOWER(url_decode(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]+)'))) 
   		END AS utm_campaign,
		COALESCE(spend, 0) AS spend, 
        COALESCE(impressions, 0) AS impressions, 
        COALESCE(reach, 0) AS reach, 
        COALESCE(clicks, 0) AS clicks, 
        COALESCE(leads, 0) AS leads,
        COALESCE(value, 0) AS value
	FROM google_ads_basic_daily),
monthly_analytics AS (
	SELECT
		DATE_TRUNC('month', ad_date)::date AS ad_month,
		utm_campaign,
		SUM(spend) AS total_spend,
		SUM(impressions) AS total_impressions,
		SUM(clicks) AS total_clicks,
		SUM(value) AS total_value,
		CASE WHEN SUM(clicks) > 0 THEN ROUND (1.0 * SUM(spend) / SUM(clicks),2) ELSE 0 END AS CPC,
		CASE WHEN SUM(impressions) > 0 THEN ROUND (1.0 * SUM(spend) / SUM(impressions) * 1000, 2) ELSE 0 END AS CPM,
		CASE WHEN SUM(impressions) > 0 THEN ROUND (100.0 * SUM(clicks) / SUM(impressions),2) ELSE 0 END AS CTR,
		CASE WHEN SUM(spend) > 0 THEN ROUND(100.0 * (SUM(value) - SUM(spend)) / SUM(spend),2) ELSE 0 END AS ROMI
	FROM daily_analytics
	GROUP BY 
        ad_month,
        utm_campaign)
SELECT 
	ad_month,
	utm_campaign,
	total_spend,
	total_impressions,
	total_clicks,
	total_value,
	CPC,
	CPM,
	CTR,
	ROMI,
	CONCAT_WS(
		' / ',
		NULLIF(
			ROUND(
				(CPM/(LAG(CPM) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) -1) * 100, 2)
			, 0),
		NULLIF(
			ROUND(
				(CTR/(LAG(CTR) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) -1) * 100, 2)
			, 0),
		NULLIF(
			ROUND(
				(ROMI/(LAG(ROMI) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) -1) * 100, 2)
			, 0)
	) AS "Δ_CPM_CTR_ROMI,%"
	FROM monthly_analytics
ORDER BY 
	utm_campaign;