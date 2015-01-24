-- Parameters:
--     source_table      -- Fully qualified table name to compute the
--                          statistics for.
--     destination_table -- Fully qualified table name to stopre the
--                          computed statistics in. This table should
--                          have schema described in [1].
--     webrequest_source -- webrequest_source of partition to compute
--                          statistics for.
--     year              -- year of partition to compute statistics
--                          for.
--     month             -- month of partition to compute statistics
--                          for.
--     day               -- day of partition to compute statistics
--                          for.
--     hour              -- hour of partition to compute statistics
--                          for.
--
-- Usage:
--     hive -f refine_webrequest.hql                              \
--         -d source_table=wmf_raw.webrequest                     \
--         -d destination_table=wmf.webrequest                    \
--         -d webrequest_source=text                              \
--         -d year=2014                                           \
--         -d month=12                                            \
--         -d day=30                                              \
--         -d hour=1
--

SET parquet.compression              = SNAPPY;
SET hive.enforce.bucketing           = true;
-- mapreduce.job.reduces should not be necessary to
-- specify since we set hive.enforce.bucketing=true.
-- However, without this set, only one reduce task is
-- launched, so we set it manually.  This needs
-- to be the same as the number of buckets the
-- table is clustered by.
SET mapreduce.job.reduces            = 64;

ADD JAR ${artifacts_directory}/refinery-hive.jar;
CREATE TEMPORARY FUNCTION is_pageview as 'org.wikimedia.analytics.refinery.hive.IsPageviewUDF';

INSERT OVERWRITE TABLE ${destination_table}
    PARTITION(webrequest_source='${webrequest_source}',year=${year},month=${month},day=${day},hour=${hour})
    SELECT DISTINCT
        hostname,
        sequence,
        dt,
        time_firstbyte,
        ip,
        cache_status,
        http_status,
        response_size,
        http_method,
        uri_host,
        uri_path,
        uri_query,
        content_type,
        referer,
        x_forwarded_for,
        user_agent,
        accept_language,
        x_analytics,
        range,
        is_pageview(uri_host, uri_path, uri_query, http_status, content_type, user_agent) as is_pageview
    FROM
        ${source_table}
    WHERE
        webrequest_source='${webrequest_source}' AND
        year=${year} AND month=${month} AND day=${day} AND hour=${hour}
;
