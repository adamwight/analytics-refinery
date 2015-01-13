-- Creates table statement for refined webrequest table.
--
-- NOTE:  When choosing partition field types,
-- one should take into consideration Hive's
-- insistence on storing partition values
-- as strings.  See:
-- https://wikitech.wikimedia.org/wiki/File:Hive_partition_formats.png
-- and
-- http://bots.wmflabs.org/~wm-bot/logs/%23wikimedia-analytics/20140721.txt
--
-- Parameters:
--     <none>
--
-- Usage
--     hive -f create_webrequest_table.hql --database wmf
--
-- NOTE: This table uses the parquet.hive.DeprecatedParquet*Formats to read
-- and write Parquet data.  Once we upgrade to hive 0.13, we will be able to
-- use the simpler and more up to date 'STORED AS PARQUET' to store data in
-- Parquet format.
--  https://issues.apache.org/jira/browse/HIVE-5783
--  http://blog.cloudera.com/blog/2014/02/native-parquet-support-comes-to-apache-hive/

CREATE EXTERNAL TABLE IF NOT EXISTS `webrequest`(
    `hostname`          string  COMMENT 'Source node hostname',
    `sequence`          bigint  COMMENT 'Per host sequence number',
    `dt`                string  COMMENT 'Timestame at cache in ISO 8601',
    `time_firstbyte`    double  COMMENT 'Time to first byte',
    `ip`                string  COMMENT 'IP of packet at cache',
    `cache_status`      string  COMMENT 'Cache status',
    `http_status`       string  COMMENT 'HTTP status of response',
    `response_size`     bigint  COMMENT 'Response size',
    `http_method`       string  COMMENT 'HTTP method of request',
    `uri_host`          string  COMMENT 'Host of request',
    `uri_path`          string  COMMENT 'Path of request',
    `uri_query`         string  COMMENT 'Query of request',
    `content_type`      string  COMMENT 'Content-Type header of response',
    `referer`           string  COMMENT 'Referer header of request',
    `x_forwarded_for`   string  COMMENT 'X-Forwarded-For header of request',
    `user_agent`        string  COMMENT 'User-Agent header of request',
    `accept_language`   string  COMMENT 'Accept-Language header of request',
    `x_analytics`       string  COMMENT 'X-Analytics header of response',
    `range`             string  COMMENT 'Range header of response',
    `is_pageview`       boolean COMMENT 'Indicates if this record was marked as a pageview during refinement'
)
PARTITIONED BY (
    `webrequest_source` string  COMMENT 'Source cluster',
    `year`              int     COMMENT 'Unpadded year of request',
    `month`             int     COMMENT 'Unpadded month of request',
    `day`               int     COMMENT 'Unpadded day of request',
    `hour`              int     COMMENT 'Unpadded hour of request'
)
CLUSTERED BY(hostname, sequence) INTO 64 BUCKETS
ROW FORMAT SERDE
    'parquet.hive.serde.ParquetHiveSerDe'
STORED AS
    INPUTFORMAT
        'parquet.hive.DeprecatedParquetInputFormat'
    OUTPUTFORMAT
        'parquet.hive.DeprecatedParquetOutputFormat'
LOCATION '/wmf/data/wmf/webrequest'
;
