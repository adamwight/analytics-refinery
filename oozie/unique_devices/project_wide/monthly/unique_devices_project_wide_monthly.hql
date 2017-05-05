-- Generates unique devices project-wide monthly based on WMF-Last-Access-global cookie
--
-- Parameters:
--     source_table        -- Table containing source data
--     destination_table   -- Table where to write newly computed data
--     year                -- year of the to-be-generated
--     month               -- month of the to-be-generated
--     refinery_hive_jar   -- The path to refinery-hive jar for UDF
--
-- Usage
--     hive -f unique_devices_project_wide_monthly.hql \
--         -d source_table=wmf.webrequest \
--         -d destination_table=wmf.unique_devices_project_wide_monthly \
--         -d year=2017 \
--         -d month=4  \
--         -d refinery_hive_jar=/wmf/refinery/current/artifacts/refinery-hive.jar

-- Register is_redirect_to_pageview UDF
ADD JAR ${refinery_hive_jar};
CREATE TEMPORARY FUNCTION is_redirect_to_pageview as 'org.wikimedia.analytics.refinery.hive.IsRedirectToPageviewUDF';

-- Set parquet compression codec
SET parquet.compression              = SNAPPY;

-- Allocate resources to almost all maps before starting reducers
SET mapreduce.job.reduce.slowstart.completedmaps=0.99;

WITH last_access_dates AS (
    SELECT
        year,
        month,
        normalized_host.project_class AS project,
        geocoded_data['country'] AS country,
        geocoded_data['country_code'] AS country_code,
        unix_timestamp(x_analytics_map['WMF-Last-Access-Global'], 'dd-MMM-yyyy') AS last_access_global,
        x_analytics_map['nocookies'] AS nocookies,
        ip,
        user_agent,
        accept_language
    FROM ${source_table}
    WHERE x_analytics_map IS NOT NULL
      AND agent_type = 'user'
      AND (is_pageview
        OR is_redirect_to_pageview(uri_host, uri_path, uri_query, http_status, content_type, user_agent, x_analytics))
      AND webrequest_source = 'text'
      AND year = ${year}
      AND month = ${month}
),

-- Only keeping clients having 1 event without cookies
-- (fresh sessions are not counted with last_access method)
fresh_sessions_aggregated AS (
    SELECT
        project,
        country,
        country_code,
        COUNT(1) AS uniques_offset
    FROM (
        SELECT
            hash(ip, user_agent, accept_language, project) AS id,
            project,
            country,
            country_code,
            SUM(CASE WHEN (nocookies IS NOT NULL) THEN 1 ELSE 0 END)
        FROM
            last_access_dates
        GROUP BY
            hash(ip, user_agent, accept_language, project),
            project,
            country,
            country_code
        -- Only keeping clients having done 1 event without cookies
        HAVING SUM(CASE WHEN (nocookies IS NOT NULL) THEN 1 ELSE 0 END) = 1
        ) fresh_sessions
    GROUP BY
        project,
        country,
        country_code
)

INSERT OVERWRITE TABLE ${destination_table}
    PARTITION(year = ${year}, month = ${month})

SELECT
    COALESCE(la.project, fresh.project) as project,
    COALESCE(la.country, fresh.country) as country,
    COALESCE(la.country_code, fresh.country_code) as country_code,
    SUM(CASE
        -- project set, last-access-global not set and client accept cookies --> first visit, count
        WHEN (la.project IS NOT NULL AND la.last_access_global IS NULL AND la.nocookies is NULL) THEN 1
        -- last-access-global set and its date is before today --> First visit today, count
        WHEN ((la.last_access_global IS NOT NULL)
            AND (la.last_access_global < unix_timestamp(CONCAT('${year}-', LPAD('${month}', 2, '0'), '-','01'), 'yyyy-MM-dd'))) THEN 1
        -- Other cases, don't count
        ELSE 0
    END) AS uniques_underestimate,
    COALESCE(fresh.uniques_offset, 0) AS uniques_offset,
    SUM(CASE
        -- project set, last-access-global not set and client accept cookies --> first visit, count
        WHEN (la.project IS NOT NULL AND la.last_access_global IS NULL AND la.nocookies is NULL) THEN 1
        -- last-access-global set and its date is before today --> First visit today, count
        WHEN ((la.last_access_global IS NOT NULL)
            AND (la.last_access_global < unix_timestamp(CONCAT('${year}-', LPAD('${month}', 2, '0'), '-','01'), 'yyyy-MM-dd'))) THEN 1
        -- Other cases, don't count
        ELSE 0
    END) + COALESCE(fresh.uniques_offset, 0) AS uniques_estimate
FROM
    last_access_dates AS la
     -- Outer join to keep every row from both table
    FULL OUTER JOIN fresh_sessions_aggregated AS fresh
        ON (la.project = fresh.project AND la.country_code = fresh.country_code)
GROUP BY
    COALESCE(la.project, fresh.project),
    COALESCE(la.country, fresh.country),
    COALESCE(la.country_code, fresh.country_code),
    COALESCE(fresh.uniques_offset, 0)
-- TODO
-- Add HAVING clause to restrict on long tail (maybe ?)
--
-- Limit enforced by hive strict mapreduce setting.
-- 1000000000 == NO LIMIT !
LIMIT 1000000000;

