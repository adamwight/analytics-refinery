-- Creates table statement for raw mediawiki_logging table.
--
-- Parameters:
--     <none>
--
-- Usage
--     hive -f create_mediawiki_logging_table.hql \
--         --database wmf_raw
--

CREATE EXTERNAL TABLE `mediawiki_logging`(
  `log_id`          bigint      COMMENT 'Primary key for the table along with wiki. rc_logid is a foreign key linking to this column.',
  `log_type`        string      COMMENT 'The type of the log action, or the "log type". You can filter by this type on Special:Log. Typical values are: block, delete, import, makebot, move, newusers, protect, renameuser, rights, upload ("uploaded" in example) Comparable to rc_log_type.',
  `log_action`      string      COMMENT 'The action performed. There may be multiple actions possible for a given type: for example, an entry with the type delete may have the action delete or restore, etc. Comparable to rc_log_action. See also API:Logevents#Parameters. See Manual:Log actions.',
  `log_timestamp`   string      COMMENT 'The time the action was performed, in the timestamp format MediaWiki uses everywhere in the database: yyyymmddhhmmss ("14:18, 25 June 2008" in example). Comparable to rc_timestamp and rev_timestamp. If the log event is a file upload, this field is not necessarily the same as the image.img_timestamp generated by LocalFile::recordUpload2().',
  `log_user`        bigint      COMMENT 'The id of the user who performed the action. This is a reference into the user table (the user id of "Jacksprat" in example). Comparable to rc_user and rev_user.',
  `log_namespace`   bigint      COMMENT 'The namespace of the affected page. Together with log_title, this is a reference into the page table ("Image:Climb.jpg" in example). Comparable to rc_namespace.  Note: logging table may contain rows with log_namespace < 0',
  `log_title`       string      COMMENT 'The title of the affected page. Together with log_namespace, this is a reference into the page table. Comparable to rc_title.',
  `log_comment`     string      COMMENT 'The comment given for the action\; that is the upload comment for uploads, the deletion comment for deletions, etc. Comparable to rc_comment and rev_comment.',
  `log_params`      string      COMMENT 'Additional parameters, usually empty. Mirrored in rc_params. log_params is usually serialized, but not always\; sometimes, for historical reasons, fields for log_params are separated by a newline. Anyone creating a new log type should use the PHP serialization.',
  `log_deleted`     int         COMMENT 'Used with the revision delete system to delete log entries. This field is comparable to rc_deleted and rev_deleted. It is a bit field. Take the sum of the following to determine what it represents: 1 Action deleted 2 Comment deleted 4 User deleted 8 If the deleted information is restricted. If this field is not set, then only deletedhistory right is needed, otherwise you need suppressrevision right. (On Wikimedia wikis, this corresponds to if admins can view the entry, or if only oversighters can). For example, if the value is 6 (4+2), then the action would be visible, but the comment and user would not be unless you had deletedhistory rights.',
  `log_user_text`   string      COMMENT 'user_name of the user who performed the action, intended primarily for anonymous users, fillable by maintenance/populateLogUsertext.php. Comparable to rc_user_text and rev_user_text.',
  `log_page`        bigint      COMMENT 'The page_id that this log action is about. Comparable to rc_cur_id and rev_page. In the case of a page move, this is set to the page_id of the moved page (since Gerrit change 157872). Formerly, it was the page_id of the redirect, or 0 if the page was moved without creating a redirect.'
)
COMMENT
  'See most up to date documentation at https://www.mediawiki.org/wiki/Manual:Logging_table'
PARTITIONED BY (
  `snapshot` string COMMENT 'Versioning information to keep multiple datasets (YYYY-MM for regular labs imports)',
  `wiki_db` string COMMENT 'The wiki_db project')
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION
  'hdfs://analytics-hadoop/wmf/data/raw/mediawiki/tables/logging'
;
