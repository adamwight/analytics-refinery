-- Create CirrusSearchRequestSet table
--
-- Search requests from CirrusSearch
--
-- NOTE: the schema is embedded in the CREATE statement.
-- This is not ideal because:
--  * We'll have to re-create the table when we change the schema
--  * If schema grows a bit it might go over the length hive has allotted to
--    this field and thus table creation will fail.
--
-- See https://phabricator.wikimedia.org/T118155 for more details
--
-- TODO: review this script and use avro.schema.url once we have
--       an official repo in hdfs for schemas.
--
-- Parameters:
--     None
-- Usage:
--     hive -f create_CirrusSearchRequestSet_table.hql --database wmf_raw
--

CREATE EXTERNAL TABLE CirrusSearchRequestSet
PARTITIONED BY (
  `year` string,
  `month` string,
  `day` string,
  `hour` string)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION
  'hdfs://analytics-hadoop/wmf/data/raw/mediawiki/mediawiki_CirrusSearchRequestSet/hourly'
TBLPROPERTIES (
   'avro.schema.literal'='{"type":"record","name":"CirrusSearchRequestSet","namespace":"org.wikimedia.analytics.schemas","fields":[{"name":"ts","type":"int","default":0},{"name":"wikiId","type":"string","default":""},{"name":"source","type":"string","default":""},{"name":"identity","type":"string","default":""},{"name":"ip","type":"string","default":""},{"name":"userAgent","type":"string","default":""},{"name":"backendUserTests","type":{"type":"array","items":"string"},"default":[]},{"name":"payload","type":{"type":"map","values":"string"},"default":{}},{"name":"requests","default":[],"type":{"type":"array","items":{"name":"CirrusSearchRequest","namespace":"org.wikimedia.analytics.schemas","type":"record","fields":[{"name":"query","type":"string","default":""},{"name":"queryType","type":"string","default":""},{"name":"indices","type":{"type":"array","items":"string"},"default":[]},{"name":"tookMs","type":"int","default":-1},{"name":"elasticTookMs","type":"int","default":-1},{"name":"limit","type":"int","default":-1},{"name":"hitsTotal","type":"int","default":-1},{"name":"hitsReturned","type":"int","default":-1},{"name":"hitsOffset","type":"int","default":-1},{"name":"namespaces","type":{"type":"array","items":"int"},"default":[]},{"name":"suggestion","type":"string","default":""},{"name":"suggestionRequested","type":"boolean","default":false},{"name":"payload","type":{"type":"map","values":"string"},"default":{}}]}}}]}'
)
;