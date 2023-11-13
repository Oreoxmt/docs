---
title: TiDB 7.2.0 Release Notes
summary: Learn about the new features, compatibility changes, improvements, and bug fixes in TiDB 7.2.0.
---

# TiDB 7.2.0 Release Notes

Release date: June 29, 2023

TiDB version: 7.2.0

Quick access: [Quick start](https://docs.pingcap.com/tidb/v7.2/quick-start-with-tidb) | [Installation packages](https://www.pingcap.com/download/?version=v7.2.0#version-list)

7.2.0 introduces the following key features and improvements:

<table>
<thead>
  <tr>
    <th>Category</th>
    <th>Feature</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="2">Scalability and Performance</td>
    <td>Resource groups support <a href="https://docs.pingcap.com/tidb/v7.2/tidb-resource-control#manage-queries-that-consume-more-resources-than-expected-runaway-queries"> managing runaway queries</a> (experimental)</td>
    <td>You can now manage query timeout with more granularity, allowing for different behaviors based on query classifications. Queries meeting your specified threshold can be deprioritized or terminated.
    </td>
  </tr>
  <tr>
    <td>TiFlash supports the <a href="https://docs.pingcap.com/tidb/v7.2/tiflash-pipeline-model">pipeline execution model</a> (experimental)</td>
    <td>TiFlash supports a pipeline execution model to optimize thread resource control.</td>
  </tr>
  <tr>
    <td rowspan="1">SQL</td>
    <td>Support a new SQL statement, <a href="https://docs.pingcap.com/tidb/v7.2/sql-statement-import-into">IMPORT INTO</a>, for data import (experimental)</td>
   <td>To simplify the deployment and maintenance of TiDB Lightning, TiDB introduces a new SQL statement <code>IMPORT INTO</code>, which integrates physical import mode of TiDB Lightning, including remote import from Amazon S3 or Google Cloud Storage (GCS) directly into TiDB.</td>
  </tr>
  <tr>
    <td rowspan="2">DB Operations and Observability</td>
    <td>DDL supports <a href="https://docs.pingcap.com/tidb/v7.2/ddl-introduction#ddl-related-commands">pause and resume operations</a> (experimental)</td>
    <td>This new capability lets you temporarily suspend resource-intensive DDL operations, such as index creation, to conserve resources and minimize the impact on online traffic. You can seamlessly resume these operations when ready, without the need to cancel and restart. This feature enhances resource utilization, improves user experience, and streamlines schema changes.</td>
  </tr>
</tbody>
</table>

## Feature details

### Performance

* Support pushing down the following two [window functions](/tiflash/tiflash-supported-pushdown-calculations.md) to TiFlash [#7427](https://github.com/pingcap/tiflash/issues/7427) @[xzhangxian1008](https://github.com/xzhangxian1008)

    * `FIRST_VALUE`
    * `LAST_VALUE`

* TiFlash supports the pipeline execution model (experimental) [#6518](https://github.com/pingcap/tiflash/issues/6518) @[SeaRise](https://github.com/SeaRise)

    Prior to v7.2.0, each task in the TiFlash engine must individually request thread resources during execution. TiFlash controls the number of tasks to limit thread resource usage and prevent overuse, but this issue could not be completely eliminated. To address this problem, starting from v7.2.0, TiFlash introduces a pipeline execution model. This model centrally manages all thread resources and schedules task execution uniformly, maximizing the utilization of thread resources while avoiding resource overuse. To enable or disable the pipeline execution model, modify the [`tidb_enable_tiflash_pipeline_model`](https://docs.pingcap.com/tidb/v7.2/system-variables#tidb_enable_tiflash_pipeline_model-new-in-v720) system variable.

    For more information, see [documentation](/tiflash/tiflash-pipeline-model.md).

* TiFlash reduces the latency of schema replication [#7630](https://github.com/pingcap/tiflash/issues/7630) @[hongyunyan](https://github.com/hongyunyan)

    When the schema of a table changes, TiFlash needs to replicate the latest schema from TiKV in a timely manner. Before v7.2.0, when TiFlash accesses table data and detects a table schema change within a database, TiFlash needs to replicate the schemas of all tables in this database again, including those tables without TiFlash replicas. As a result, in a database with a large number of tables, even if you only need to read data from a single table using TiFlash, you might experience significant latency to wait for TiFlash to complete the schema replication of all tables.

    In v7.2.0, TiFlash optimizes the schema replication mechanism and supports only replicating schemas of tables with TiFlash replicas. When a schema change is detected for a table with TiFlash replicas, TiFlash only replicates the schema of that table, which reduces the latency of schema replication of TiFlash and minimizes the impact of DDL operations on TiFlash data replication. This optimization is automatically applied and does not require any manual configuration.

* Improve the performance of statistics collection [#44725](https://github.com/pingcap/tidb/issues/44725) @[xuyifangreeneyes](https://github.com/xuyifangreeneyes)

    TiDB v7.2.0 optimizes the statistics collection strategy, skipping some of the duplicate information and information that is of little value to the optimizer. The overall speed of statistics collection has been improved by 30%. This improvement allows TiDB to update the statistics of the database in a more timely manner, making the generated execution plans more accurate, thus improving the overall database performance.

    By default, statistics collection skips the columns of the `JSON`, `BLOB`, `MEDIUMBLOB`, and `LONGBLOB` types. You can modify the default behavior by setting the [`tidb_analyze_skip_column_types`](/system-variables.md#tidb_analyze_skip_column_types-new-in-v720) system variable. TiDB supports skipping the `JSON`, `BLOB`, and `TEXT` types and their subtypes.

    For more information, see [documentation](/system-variables.md#tidb_analyze_skip_column_types-new-in-v720).

* Improve the performance of checking data and index consistency [#43693](https://github.com/pingcap/tidb/issues/43693) @[wjhuang2016](https://github.com/wjhuang2016)

    The [`ADMIN CHECK [TABLE|INDEX]`](/sql-statements/sql-statement-admin-check-table-index.md) statement is used to check the consistency between data in a table and its corresponding indexes. In v7.2.0, TiDB optimizes the method for checking data consistency and improves the execution efficiency of [`ADMIN CHECK [TABLE|INDEX]`](/sql-statements/sql-statement-admin-check-table-index.md) greatly. In scenarios with large amounts of data, this optimization can provide a performance boost of hundreds of times.

    The optimization is enabled by default ([`tidb_enable_fast_table_check`](/system-variables.md#tidb_enable_fast_table_check-new-in-v720) is `ON` by default) to greatly reduce the time required for data consistency checks in large-scale tables and enhance operational efficiency.

    For more information, see [documentation](/system-variables.md#tidb_enable_fast_table_check-new-in-v720).

### Reliability

* Automatically manage queries that consume more resources than expected (experimental) [#43691](https://github.com/pingcap/tidb/issues/43691) @[Connor1996](https://github.com/Connor1996) @[CabinfeverB](https://github.com/CabinfeverB) @[glorv](https://github.com/glorv) @[HuSharp](https://github.com/HuSharp) @[nolouch](https://github.com/nolouch)

    The most common challenge to database stability is the degradation of overall database performance caused by abrupt SQL performance problems. There are many causes for SQL performance issues, such as new SQL statements that have not been fully tested, drastic changes in data volume, and abrupt changes in execution plans. These issues are difficult to completely avoid at the root. TiDB v7.2.0 provides the ability to manage queries that consume more resources than expected. This feature can quickly reduce the scope of impact when a performance issue occurs.

    To manage these queries, you can set the maximum execution time of queries for a resource group. When the execution time of a query exceeds this limit, the query is automatically deprioritized or cancelled. You can also set a period of time to immediately match identified queries by text or execution plan. This helps prevent high concurrency of the problematic queries during the identification phase that could consume more resources than expected.

    Automatic management of queries that consume more resources than expected provides you with an effective means to quickly respond to unexpected query performance problems. This feature can reduce the impact of the problem on overall database performance, thereby improving database stability.

    For more information, see [documentation](/tidb-resource-control.md#manage-queries-that-consume-more-resources-than-expected-runaway-queries).

* Enhance the capability of creating a binding according to a historical execution plan [#39199](https://github.com/pingcap/tidb/issues/39199) @[qw4990](https://github.com/qw4990)

    TiDB v7.2.0 enhances the capability of [creating a binding according to a historical execution plan](/sql-plan-management.md#create-a-binding-according-to-a-historical-execution-plan). This feature improves the parsing and binding process for complex statements, making the bindings more stable, and supports the following new hints:

    - [`AGG_TO_COP()`](/optimizer-hints.md#agg_to_cop)
    - [`LIMIT_TO_COP()`](/optimizer-hints.md#limit_to_cop)
    - [`ORDER_INDEX`](/optimizer-hints.md#order_indext1_name-idx1_name--idx2_name-)
    - [`NO_ORDER_INDEX()`](/optimizer-hints.md#no_order_indext1_name-idx1_name--idx2_name-)

  For more information, see [documentation](/sql-plan-management.md).

* Introduce the Optimizer Fix Controls mechanism to provide fine-grained control over optimizer behaviors [#43169](https://github.com/pingcap/tidb/issues/43169) @[time-and-fate](https://github.com/time-and-fate)

    To generate more reasonable execution plans, the behavior of the TiDB optimizer evolves over product iterations. However, in some particular scenarios, the changes might lead to performance regression. TiDB v7.2.0 introduces Optimizer Fix Controls to let you control some of the fine-grained behaviors of the optimizer. This enables you to roll back or control some new changes.

    Each controllable behavior is described by a GitHub issue corresponding to the fix number. All controllable behaviors are listed in [Optimizer Fix Controls](/optimizer-fix-controls.md). You can set a target value for one or more behaviors by setting the [`tidb_opt_fix_control`](/system-variables.md#tidb_opt_fix_control-new-in-v710) system variable to achieve behavior control.

    The Optimizer Fix Controls mechanism helps you control the TiDB optimizer at a granular level. It provides a new means of fixing performance issues caused by the upgrade process and improves the stability of TiDB.

    For more information, see [documentation](/optimizer-fix-controls.md).

* Lightweight statistics initialization becomes generally available (GA) [#42160](https://github.com/pingcap/tidb/issues/42160) @[xuyifangreeneyes](https://github.com/xuyifangreeneyes)

    Starting from v7.2.0, the lightweight statistics initialization feature becomes GA. Lightweight statistics initialization can significantly reduce the number of statistics that must be loaded during startup, thus improving the speed of loading statistics. This feature increases the stability of TiDB in complex runtime environments and reduces the impact on the overall service when TiDB nodes restart.

    For newly created clusters of v7.2.0 or later versions, TiDB loads lightweight statistics by default during TiDB startup and will wait for the loading to finish before providing services. For clusters upgraded from earlier versions, you can set the TiDB configuration items [`lite-init-stats`](/tidb-configuration-file.md#lite-init-stats-new-in-v710) and [`force-init-stats`](/tidb-configuration-file.md#force-init-stats-new-in-v710) to `true` to enable this feature.

    For more information, see [documentation](/statistics.md#load-statistics).

### SQL

* Support the `CHECK` constraints [#41711](https://github.com/pingcap/tidb/issues/41711) @[fzzf678](https://github.com/fzzf678)

    Starting from v7.2.0, you can use `CHECK` constraints to restrict the values of one or more columns in a table to meet your specified conditions. When a `CHECK` constraint is added to a table, TiDB checks whether the constraint is satisfied before inserting or updating data in the table. Only the data that satisfies the constraint can be written.

     This feature is disabled by default. You can set the [`tidb_enable_check_constraint`](/system-variables.md#tidb_enable_check_constraint-new-in-v720) system variable to `ON` to enable it.

    For more information, see [documentation](/constraints.md#check).

### DB operations

* DDL jobs support pause and resume operations (experimental) [#18015](https://github.com/pingcap/tidb/issues/18015) @[godouxm](https://github.com/godouxm)

    Before TiDB v7.2.0, when a DDL job encounters a business peak during execution, you can only manually cancel the DDL job to reduce its impact on the business. In v7.2.0, TiDB introduces pause and resume operations for DDL jobs. These operations let you pause DDL jobs during a peak and resume them after the peak ends, thus avoiding impact on your application workloads.

    For example, you can pause and resume multiple DDL jobs using `ADMIN PAUSE DDL JOBS` or `ADMIN RESUME DDL JOBS`:

    ```sql
    ADMIN PAUSE DDL JOBS 1,2;
    ADMIN RESUME DDL JOBS 1,2;
    ```

    For more information, see [documentation](/ddl-introduction.md#ddl-related-commands).

### Data migration

* Introduce a new SQL statement `IMPORT INTO` to improve data import efficiency greatly (experimental) [#42930](https://github.com/pingcap/tidb/issues/42930) @[D3Hunter](https://github.com/D3Hunter)

    The `IMPORT INTO` statement integrates the [Physical Import Mode](/tidb-lightning/tidb-lightning-physical-import-mode.md) capability of TiDB Lightning. With this statement, you can quickly import data in formats such as CSV, SQL, and PARQUET into an empty table in TiDB. This import method eliminates the need for a separate deployment and management of TiDB Lightning, thereby reducing the complexity of data import and greatly improving import efficiency.

    For data files stored in Amazon S3 or GCS, when the [Backend task distributed execution framework](/tidb-distributed-execution-framework.md) is enabled, `IMPORT INTO` also supports splitting a data import job into multiple sub-jobs and scheduling them to multiple TiDB nodes for parallel import, which further enhances import performance.

    For more information, see [documentation](/sql-statements/sql-statement-import-into.md).

* TiDB Lightning supports importing source files with the Latin-1 character set into TiDB [#44434](https://github.com/pingcap/tidb/issues/44434) @[lance6716](https://github.com/lance6716)

    With this feature, you can directly import source files with the Latin-1 character set into TiDB using TiDB Lightning. Before v7.2.0, importing such files requires your additional preprocessing or conversion. Starting from v7.2.0, you only need to specify `character-set = "latin1"` when configuring the TiDB Lightning import task. Then, TiDB Lightning automatically handles the character set conversion during the import process to ensure data integrity and accuracy.

    For more information, see [documentation](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-task).

## Compatibility changes

> **Note:**
>
> This section provides compatibility changes you need to know when you upgrade from v7.1.0 to the current version (v7.2.0). If you are upgrading from v7.0.0 or earlier versions to the current version, you might also need to check the compatibility changes introduced in intermediate versions.

### System variables

| Variable name | Change type | Description |
|--------|------------------------------|------|
| [`last_insert_id`](/system-variables.md#last_insert_id) | Modified | Changes the maximum value from `9223372036854775807` to `18446744073709551615` to be consistent with that of MySQL. |
| [`tidb_enable_non_prepared_plan_cache`](/system-variables.md#tidb_enable_non_prepared_plan_cache) | Modified | Changes the default value from `OFF` to `ON` after further tests, meaning that non-prepared execution plan cache is enabled. |
| [`tidb_remove_orderby_in_subquery`](/system-variables.md#tidb_remove_orderby_in_subquery-new-in-v610) | Modified | Changes the default value from `OFF` to `ON` after further tests, meaning that the optimizer removes the `ORDER BY` clause in a subquery. |
| [`tidb_analyze_skip_column_types`](/system-variables.md#tidb_analyze_skip_column_types-new-in-v720) | Newly added | Controls which types of columns are skipped for statistics collection when executing the `ANALYZE` command to collect statistics. The variable is only applicable for [`tidb_analyze_version = 2`](/system-variables.md#tidb_analyze_version-new-in-v510). When using the syntax of `ANALYZE TABLE t COLUMNS c1, ..., cn`, if the type of a specified column is included in `tidb_analyze_skip_column_types`, the statistics of this column will not be collected. |
| [`tidb_enable_check_constraint`](/system-variables.md#tidb_enable_check_constraint-new-in-v720) | Newly added | Controls whether to enable `CHECK` constraints. The default value is `OFF`, which means this feature is disabled. |
| [`tidb_enable_fast_table_check`](/system-variables.md#tidb_enable_fast_table_check-new-in-v720) | Newly added | Controls whether to use a checksum-based approach to quickly check the consistency of data and indexes in a table. The default value is `ON`, which means this feature is enabled. |
| [`tidb_enable_tiflash_pipeline_model`](https://docs.pingcap.com/tidb/v7.2/system-variables#tidb_enable_tiflash_pipeline_model-new-in-v720) | Newly added | Controls whether to enable the new execution model of TiFlash, the [pipeline model](/tiflash/tiflash-pipeline-model.md). The default value is `OFF`, which means the pipeline model is disabled. |
| [`tidb_expensive_txn_time_threshold`](/system-variables.md#tidb_expensive_txn_time_threshold-new-in-v720) | Newly added | Controls the threshold for logging expensive transactions, which is 600 seconds by default. When the duration of a transaction exceeds the threshold, and the transaction is neither committed nor rolled back, it is considered an expensive transaction and will be logged. |

### Configuration file parameters

| Configuration file | Configuration parameter | Change type | Description |
| -------- | -------- | -------- | -------- |
| TiDB | [`lite-init-stats`](/tidb-configuration-file.md#lite-init-stats-new-in-v710) | Modified | Changes the default value from `false` to `true` after further tests, meaning that TiDB uses lightweight statistics initialization by default during TiDB startup to improve the initialization efficiency. |
| TiDB | [`force-init-stats`](/tidb-configuration-file.md#force-init-stats-new-in-v710) | Modified | Changes the default value from `false` to `true` to align with [`lite-init-stats`](/tidb-configuration-file.md#lite-init-stats-new-in-v710), meaning that TiDB waits for statistics initialization to finish before providing services during TiDB startup. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].compaction-guard-min-output-file-size</code>](/tikv-configuration-file.md#compaction-guard-min-output-file-size) | Modified | Changes the default value from `"8MB"` to `"1MB"` to reduce the data volume of compaction tasks in RocksDB. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].optimize-filters-for-memory</code>](/tikv-configuration-file.md#optimize-filters-for-memory-new-in-v720) | Newly added | Controls whether to generate Bloom/Ribbon filters that minimize memory internal fragmentation. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].periodic-compaction-seconds</code>](/tikv-configuration-file.md#periodic-compaction-seconds-new-in-v720) | Newly added | Controls the time interval for periodic compaction. SST files with updates older than this value will be selected for compaction and rewritten to the same level where these SST files originally reside. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].ribbon-filter-above-level</code>](/tikv-configuration-file.md#ribbon-filter-above-level-new-in-v720) | Newly added | Controls whether to use Ribbon filters for levels greater than or equal to this value and use non-block-based bloom filters for levels less than this value. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].ttl</code>](/tikv-configuration-file.md#ttl-new-in-v720) | Newly added | SST files with updates older than the TTL will be automatically selected for compaction. |
| TiDB Lightning | `send-kv-pairs` | Deprecated | Starting from v7.2.0, the parameter `send-kv-pairs` is deprecated. You can use [`send-kv-size`](/tidb-lightning/tidb-lightning-configuration.md) to control the maximum size of one request when sending data to TiKV in physical import mode. |
| TiDB Lightning | [`character-set`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-task) | Modified | Introduces a new value option `latin1` for the supported character sets of data import. You can use this option to import source files with the Latin-1 character set. |
| TiDB Lightning | [`send-kv-size`](/tidb-lightning/tidb-lightning-configuration.md) | Newly added | Specify the maximum size of one request when sending data to TiKV in physical import mode. When the size of key-value pairs reaches the specified threshold, TiDB Lightning will immediately send them to TiKV. This avoids the OOM problems caused by TiDB Lightning nodes accumulating too many key-value pairs in memory when importing large wide tables. By adjusting this parameter, you can find a balance between memory usage and import speed, improving the stability and efficiency of the import process. |
| Data Migration | [`strict-optimistic-shard-mode`](/dm/feature-shard-merge-optimistic.md) | Newly added | This configuration item is used to be compatible with the DDL shard merge behavior in TiDB Data Migration v2.0. You can enable this configuration item in optimistic mode. After this is enabled, the replication task will be interrupted when it encounters a Type 2 DDL statement. In scenarios where there are dependencies between DDL changes in multiple tables, a timely interruption can be made. You need to manually process the DDL statements of each table before resuming the replication task to ensure data consistency between the upstream and the downstream. |
| TiCDC | [`sink.protocol`](/ticdc/ticdc-changefeed-config.md) | Modified | Introduces a new value option `"open-protocol"` when the downstream is Kafka. Specifies the protocol format used for encoding messages. |
| TiCDC | [`sink.delete-only-output-handle-key-columns`](/ticdc/ticdc-changefeed-config.md) | Newly added | Specifies the output of DELETE events. This parameter is valid only for `"canal-json"` and `"open-protocol"` protocols. The default value is `false`, which means outputting all columns. When you set it to `true`, only primary key columns or unique index columns are output. |

## Improvements

+ TiDB

    - Optimize the logic of constructing index scan range so that it supports converting complex conditions into index scan range [#41572](https://github.com/pingcap/tidb/issues/41572) [#44389](https://github.com/pingcap/tidb/issues/44389) @[xuyifangreeneyes](https://github.com/xuyifangreeneyes)
    - Add new monitoring metrics `Stale Read OPS` and `Stale Read Traffic` [#43325](https://github.com/pingcap/tidb/issues/43325) @[you06](https://github.com/you06)
    - When the retry leader of stale read encounters a lock, TiDB forcibly retries with the leader after resolving the lock, which avoids unnecessary overhead [#43659](https://github.com/pingcap/tidb/issues/43659) @[you06](https://github.com/you06)
    - Use estimated time to calculate stale read ts and reduce the overhead of stale read [#44215](https://github.com/pingcap/tidb/issues/44215) @[you06](https://github.com/you06)
    - Add logs and system variables for long-running transactions [#41471](https://github.com/pingcap/tidb/issues/41471) @[crazycs520](https://github.com/crazycs520)
    - Support connecting to TiDB through the compressed MySQL protocol, which improves the performance of data-intensive queries under low bandwidth networks and saves bandwidth costs. This supports both `zlib` and `zstd` based compression. [#22605](https://github.com/pingcap/tidb/issues/22605) @[dveeden](https://github.com/dveeden)
    - Recognize both `utf8` and `utf8bm3` as the legacy three-byte UTF-8 character set encodings, which facilitates the migration of tables with legacy UTF-8 encodings from MySQL 8.0 to TiDB [#26226](https://github.com/pingcap/tidb/issues/26226) @[dveeden](https://github.com/dveeden)
    - Support using `:=` for assignment in `UPDATE` statements [#44751](https://github.com/pingcap/tidb/issues/44751) @[CbcWestwolf](https://github.com/CbcWestwolf)

+ TiKV

    - Support configuring the retry interval of PD connections in scenarios such as connection request failures using `pd.retry-interval` [#14964](https://github.com/tikv/tikv/issues/14964) @[rleungx](https://github.com/rleungx)
    - Optimize the resource control scheduling algorithm by incorporating the global resource usage [#14604](https://github.com/tikv/tikv/issues/14604) @[Connor1996](https://github.com/Connor1996)
    - Use gzip compression for `check_leader` requests to reduce traffic [#14553](https://github.com/tikv/tikv/issues/14553) @[you06](https://github.com/you06)
    - Add related metrics for `check_leader` requests [#14658](https://github.com/tikv/tikv/issues/14658) @[you06](https://github.com/you06)
    - Provide detailed time information during TiKV handling write commands [#12362](https://github.com/tikv/tikv/issues/12362) @[cfzjywxk](https://github.com/cfzjywxk)

+ PD

    - Use a separate gRPC connection for PD leader election to prevent the impact of other requests [#6403](https://github.com/tikv/pd/issues/6403) @[rleungx](https://github.com/rleungx)
    - Enable the bucket splitting by default to mitigate hotspot issues in multi-Region scenarios [#6433](https://github.com/tikv/pd/issues/6433) @[bufferflies](https://github.com/bufferflies)

+ Tools

    + Backup & Restore (BR)

        - Support access to Azure Blob Storage by shared access signature (SAS) [#44199](https://github.com/pingcap/tidb/issues/44199) @[Leavrth](https://github.com/Leavrth)

    + TiCDC

        - Optimize the structure of the directory where data files are stored when a DDL operation occurs in the scenario of replication to an object storage service [#8891](https://github.com/pingcap/tiflow/issues/8891) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - Support the OAUTHBEARER authentication in the scenario of replication to Kafka [#8865](https://github.com/pingcap/tiflow/issues/8865) @[hi-rustin](https://github.com/hi-rustin)
        - Add the option of outputting only the handle keys for the `DELETE` operation in the scenario of replication to Kafka [#9143](https://github.com/pingcap/tiflow/issues/9143) @[3AceShowHand](https://github.com/3AceShowHand)

    + TiDB Data Migration (DM)

        - Support reading compressed binlogs in MySQL 8.0 as a data source for incremental replication [#6381](https://github.com/pingcap/tiflow/issues/6381) @[dveeden](https://github.com/dveeden)

    + TiDB Lightning

        - Optimize the retry mechanism during import to avoid errors caused by leader switching [#44478](https://github.com/pingcap/tidb/pull/44478) @[lance6716](https://github.com/lance6716)
        - Verify checksum through SQL after the import to improve stability of verification [#41941](https://github.com/pingcap/tidb/issues/41941) @[GMHDBJD](https://github.com/GMHDBJD)
        - Optimize TiDB Lightning OOM issues when importing wide tables [#43853](https://github.com/pingcap/tidb/issues/43853) @[D3Hunter](https://github.com/D3Hunter)

## Bug fixes

+ TiDB

    - Fix the issue that the query with CTE causes TiDB to hang [#43749](https://github.com/pingcap/tidb/issues/43749) [#36896](https://github.com/pingcap/tidb/issues/36896) @[guo-shaoge](https://github.com/guo-shaoge)
    - Fix the issue that the `min, max` query result is incorrect [#43805](https://github.com/pingcap/tidb/issues/43805) @[wshwsh12](https://github.com/wshwsh12)
    - Fix the issue that the `SHOW PROCESSLIST` statement cannot display the TxnStart of the transaction of the statement with a long subquery time [#40851](https://github.com/pingcap/tidb/issues/40851) @[crazycs520](https://github.com/crazycs520)
    - Fix the issue that the stale read global optimization does not take effect due to the lack of `TxnScope` in Coprocessor tasks [#43365](https://github.com/pingcap/tidb/issues/43365) @[you06](https://github.com/you06)
    - Fix the issue that follower read does not handle flashback errors before retrying, which causes query errors [#43673](https://github.com/pingcap/tidb/issues/43673) @[you06](https://github.com/you06)
    - Fix the issue that data and indexes are inconsistent when the `ON UPDATE` statement does not correctly update the primary key [#44565](https://github.com/pingcap/tidb/issues/44565) @[zyguan](https://github.com/zyguan)
    - Modify the upper limit of the `UNIX_TIMESTAMP()` function to `3001-01-19 03:14:07.999999 UTC` to be consistent with that of MySQL 8.0.28 or later versions [#43987](https://github.com/pingcap/tidb/issues/43987) @[YangKeao](https://github.com/YangKeao)
    - Fix the issue that adding an index fails in the ingest mode [#44137](https://github.com/pingcap/tidb/issues/44137) @[tangenta](https://github.com/tangenta)
    - Fix the issue that canceling a DDL task in the rollback state causes errors in related metadata [#44143](https://github.com/pingcap/tidb/issues/44143) @[wjhuang2016](https://github.com/wjhuang2016)
    - Fix the issue that using `memTracker` with cursor fetch causes memory leaks [#44254](https://github.com/pingcap/tidb/issues/44254) @[YangKeao](https://github.com/YangKeao)
    - Fix the issue that dropping a database causes slow GC progress [#33069](https://github.com/pingcap/tidb/issues/33069) @[tiancaiamao](https://github.com/tiancaiamao)
    - Fix the issue that TiDB returns an error when the corresponding rows in partitioned tables cannot be found in the probe phase of index join [#43686](https://github.com/pingcap/tidb/issues/43686) @[AilinKid](https://github.com/AilinKid) @[mjonss](https://github.com/mjonss)
    - Fix the issue that there is no warning when using `SUBPARTITION` to create partitioned tables [#41198](https://github.com/pingcap/tidb/issues/41198) [#41200](https://github.com/pingcap/tidb/issues/41200) @[mjonss](https://github.com/mjonss)
    - Fix the issue that when a query is killed because it exceeds `MAX_EXECUTION_TIME`, the returned error message is inconsistent with that of MySQL [#43031](https://github.com/pingcap/tidb/issues/43031) @[dveeden](https://github.com/dveeden)
    - Fix the issue that the `LEADING` hint does not support querying block aliases [#44645](https://github.com/pingcap/tidb/issues/44645) @[qw4990](https://github.com/qw4990)
    - Modify the return type of the `LAST_INSERT_ID()` function from VARCHAR to LONGLONG to be consistent with that of MySQL [#44574](https://github.com/pingcap/tidb/issues/44574) @[Defined2014](https://github.com/Defined2014)
    - Fix the issue that incorrect results might be returned when using a common table expression (CTE) in statements with non-correlated subqueries [#44051](https://github.com/pingcap/tidb/issues/44051) @[winoros](https://github.com/winoros)
    - Fix the issue that Join Reorder might cause incorrect outer join results [#44314](https://github.com/pingcap/tidb/issues/44314) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue that `PREPARE stmt FROM "ANALYZE TABLE xxx"` might be killed by `tidb_mem_quota_query` [#44320](https://github.com/pingcap/tidb/issues/44320) @[chrysan](https://github.com/chrysan)

+ TiKV

    - Fix the issue that the transaction returns an incorrect value when TiKV handles stale pessimistic lock conflicts [#13298](https://github.com/tikv/tikv/issues/13298) @[cfzjywxk](https://github.com/cfzjywxk)
    - Fix the issue that in-memory pessimistic lock might cause flashback failures and data inconsistency [#13303](https://github.com/tikv/tikv/issues/13303) @[JmPotato](https://github.com/JmPotato)
    - Fix the issue that the fair lock might be incorrect when TiKV handles stale requests [#13298](https://github.com/tikv/tikv/issues/13298) @[cfzjywxk](https://github.com/cfzjywxk)
    - Fix the issue that `autocommit` and `point get replica read` might break linearizability [#14715](https://github.com/tikv/tikv/issues/14715) @[cfzjywxk](https://github.com/cfzjywxk)

+ PD

    - Fix the issue that redundant replicas cannot be automatically repaired in some corner cases [#6573](https://github.com/tikv/pd/issues/6573) @[nolouch](https://github.com/nolouch)

+ TiFlash

    - Fix the issue that queries might consume more memory than needed when the data on the Join build side is very large and contains many small string type columns [#7416](https://github.com/pingcap/tiflash/issues/7416) @[yibin87](https://github.com/yibin87)

+ Tools

    + Backup & Restore (BR)

        - Fix the issue that `checksum mismatch` is falsely reported in some cases [#44472](https://github.com/pingcap/tidb/issues/44472) @[Leavrth](https://github.com/Leavrth)
        - Fix the issue that `resolved lock timeout` is falsely reported in some cases [#43236](https://github.com/pingcap/tidb/issues/43236) @[YuJuncen](https://github.com/YuJuncen)
        - Fix the issue that TiDB might panic when restoring statistics information [#44490](https://github.com/pingcap/tidb/issues/44490) @[tangenta](https://github.com/tangenta)

    + TiCDC

        - Fix the issue that Resolved TS does not advance properly in some cases [#8963](https://github.com/pingcap/tiflow/issues/8963) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - Fix the issue that the `UPDATE` operation cannot output old values when the Avro or CSV protocol is used [#9086](https://github.com/pingcap/tiflow/issues/9086) @[3AceShowHand](https://github.com/3AceShowHand)
        - Fix the issue of excessive downstream pressure caused by reading downstream metadata too frequently when replicating data to Kafka [#8959](https://github.com/pingcap/tiflow/issues/8959) @[hi-rustin](https://github.com/hi-rustin)
        - Fix the issue of too many downstream logs caused by frequently setting the downstream bidirectional replication-related variables when replicating data to TiDB or MySQL [#9180](https://github.com/pingcap/tiflow/issues/9180) @[asddongmen](https://github.com/asddongmen)
        - Fix the issue that the PD node crashing causes the TiCDC node to restart [#8868](https://github.com/pingcap/tiflow/issues/8868) @[asddongmen](https://github.com/asddongmen)
        - Fix the issue that TiCDC cannot create a changefeed with a downstream Kafka-on-Pulsar [#8892](https://github.com/pingcap/tiflow/issues/8892) @[hi-rustin](https://github.com/hi-rustin)

    + TiDB Lightning

        - Fix the TiDB Lightning panic issue when `experimental.allow-expression-index` is enabled and the default value is UUID [#44497](https://github.com/pingcap/tidb/issues/44497) @[lichunzhu](https://github.com/lichunzhu)
        - Fix the TiDB Lightning panic issue when a task exits while dividing a data file [#43195](https://github.com/pingcap/tidb/issues/43195) @[lance6716](https://github.com/lance6716)

## Contributors

We would like to thank the following contributors from the TiDB community:

- [asjdf](https://github.com/asjdf)
- [blacktear23](https://github.com/blacktear23)
- [Cavan-xu](https://github.com/Cavan-xu)
- [darraes](https://github.com/darraes)
- [demoManito](https://github.com/demoManito)
- [dhysum](https://github.com/dhysum)
- [HappyUncle](https://github.com/HappyUncle)
- [jiyfhust](https://github.com/jiyfhust)
- [L-maple](https://github.com/L-maple)
- [nyurik](https://github.com/nyurik)
- [SeigeC](https://github.com/SeigeC)
- [tangjingyu97](https://github.com/tangjingyu97)

---
title: TiDB 7.3.0 Release Notes
summary: Learn about the new features, compatibility changes, improvements, and bug fixes in TiDB 7.3.0.
---

# TiDB 7.3.0 Release Notes

Release date: August 14, 2023

TiDB version: 7.3.0

Quick access: [Quick start](https://docs.pingcap.com/tidb/v7.3/quick-start-with-tidb) | [Installation packages](https://www.pingcap.com/download/?version=v7.3.0#version-list)

7.3.0 introduces the following major features. In addition to that, 7.3.0 also includes a series of enhancements (described in the [Feature details](#feature-details) section) to query stability in TiDB server and TiFlash. These enhancements are more miscellaneous in nature and not user-facing so they are not included in the following table.

<table>
<thead>
  <tr>
    <th>Category</th>
    <th>Feature</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Scalability and Performance</td>
    <td>TiDB Lightning supports <a href="https://docs.pingcap.com/tidb/v7.3/partitioned-raft-kv">Partitioned Raft KV</a> (experimental)</td>
    <td>TiDB Lightning now supports the new Partitioned Raft KV architecture, as part of the near-term GA of the architecture.
    </td>
  </tr>
  <tr>
    <td rowspan="2">Reliability and Availability</td>
    <td><a href="https://docs.pingcap.com/tidb/v7.3/tidb-lightning-physical-import-mode-usage#conflict-detection">Add automatic conflict detection and resolution on data imports</a></td>
    <td>The TiDB Lightning Physical Import Mode supports a new version of conflict detection, which implements the semantics of replacing (<code>replace</code>) or ignoring (<code>ignore</code>) conflict data when encountering conflicts. It automatically handles conflict data for you while improving the performance of conflict resolution.</td>
  </tr>
  <tr>
    <td><a href="https://docs.pingcap.com/tidb/v7.3/tidb-resource-control#query-watch-parameters">Manual management of runaway queries </a>(experimental)</td>
    <td>Queries might take longer than you expect. With the new watch list of resource groups, you can now manage queries more effectively and either deprioritize or kill them. Allowing operators to mark target queries by exact SQL text, SQL digest, or plan digest and deal with the queries at a resource group level, this feature gives you much more control over the potential impact of unexpected large queries on a cluster.</td>
  </tr>
  <tr>
    <td>SQL</td>
    <td><a href="https://docs.pingcap.com/tidb/v7.3/optimizer-hints">Enhance operator control over query stability by adding more optimizer hints to the query planner</a></td>
    <td>Added hints: <code>NO_INDEX_JOIN()</code>, <code>NO_MERGE_JOIN()</code>, <code>NO_INDEX_MERGE_JOIN()</code>, <code>NO_HASH_JOIN()</code>, <code>NO_INDEX_HASH_JOIN()</code>
    </td>
  </tr>
  <tr>
    <td>DB Operations and Observability</td>
    <td><a href="https://docs.pingcap.com/tidb/v7.3/sql-statement-show-analyze-status">Show the progress of statistics collection tasks</a></td>
    <td>Support viewing the progress of <code>ANALYZE</code> tasks using the <code>SHOW ANALYZE STATUS</code> statement or through the <code>mysql.analyze_jobs</code> system table.</td>
  </tr>
</tbody>
</table>

## Feature details

### Performance

* TiFlash supports the replica selection strategy [#44106](https://github.com/pingcap/tidb/issues/44106) @[XuHuaiyu](https://github.com/XuHuaiyu)

    Before v7.3.0, TiFlash uses replicas from all its nodes for data scanning and MPP calculations to maximize performance. Starting from v7.3.0, TiFlash introduces the replica selection strategy and lets you configure it using the [`tiflash_replica_read`](/system-variables.md#tiflash_replica_read-new-in-v730) system variable. This strategy supports selecting specific replicas based on the [zone attributes](/schedule-replicas-by-topology-labels.md#optional-configure-labels-for-tidb) of nodes and scheduling specific nodes for data scanning and MPP calculations.

    For a cluster that is deployed in multiple data centers and each data center has complete TiFlash data replicas, you can configure this strategy to only select TiFlash replicas from the current data center. This means data scanning and MPP calculations are performed only on TiFlash nodes in the current data center, which avoids excessive network data transmission across data centers.

    For more information, see [documentation](/system-variables.md#tiflash_replica_read-new-in-v730).

* TiFlash supports Runtime Filter within nodes [#40220](https://github.com/pingcap/tidb/issues/40220) @[elsa0520](https://github.com/elsa0520)

    Runtime Filter is a **dynamic predicate** generated during the query planning phase. In the process of table joining, these dynamic predicates can effectively filter out rows that do not meet the join conditions, reducing scan time and network overhead, and improving the efficiency of table joining. Starting from v7.3.0, TiFlash supports Runtime Filter within nodes, improving the overall performance of analytical queries. In some TPC-DS workloads, the performance can be improved by 10% to 50%.

    This feature is disabled by default in v7.3.0. To enable this feature, set the system variable [`tidb_runtime_filter_mode`](/system-variables.md#tidb_runtime_filter_mode-new-in-v720) to `LOCAL`.

    For more information, see [documentation](/runtime-filter.md).

* TiFlash supports executing common table expressions (CTEs) (experimental) [#43333](https://github.com/pingcap/tidb/issues/43333) @[winoros](https://github.com/winoros)

    Before v7.3.0, the MPP engine of TiFlash cannot execute queries that contain CTEs by default. To achieve the best execution performance within the MPP framework, you need to use the system variable [`tidb_opt_force_inline_cte`](/system-variables.md#tidb_opt_force_inline_cte-new-in-v630) to enforce inlining CTE.

    Starting from v7.3.0, TiFlash's MPP engine supports executing queries with CTEs without inlining them, allowing for optimal query execution within the MPP framework. In TPC-DS benchmark tests, compared with inlining CTEs, this feature has shown a 20% improvement in overall query execution speed for queries containing CTE.

    This feature is experimental and is disabled by default. It is controlled by the system variable [`tidb_opt_enable_mpp_shared_cte_execution`](/system-variables.md#tidb_opt_enable_mpp_shared_cte_execution-new-in-v720).

### Reliability

* Add new optimizer hints [#45520](https://github.com/pingcap/tidb/issues/45520) @[qw4990](https://github.com/qw4990)

    In v7.3.0, TiDB introduces several new optimizer hints to control the join methods between tables, including:

    - [`NO_MERGE_JOIN()`](/optimizer-hints.md#no_merge_joint1_name--tl_name-) selects join methods other than merge join.
    - [`NO_INDEX_JOIN()`](/optimizer-hints.md#no_index_joint1_name--tl_name-) selects join methods other than index nested loop join.
    - [`NO_INDEX_MERGE_JOIN()`](/optimizer-hints.md#no_index_merge_joint1_name--tl_name-) selects join methods other than index nested loop merge join.
    - [`NO_HASH_JOIN()`](/optimizer-hints.md#no_hash_joint1_name--tl_name-) selects join methods other than hash join.
    - [`NO_INDEX_HASH_JOIN()`](/optimizer-hints.md#no_index_hash_joint1_name--tl_name-) selects join methods other than [index nested loop hash join](/optimizer-hints.md#inl_hash_join).

  For more information, see [documentation](/optimizer-hints.md).

* Manually mark queries that use resources more than expected (experimental) [#43691](https://github.com/pingcap/tidb/issues/43691) @[Connor1996](https://github.com/Connor1996) @[CabinfeverB](https://github.com/CabinfeverB)

    In v7.2.0, TiDB automatically manages queries that use resources more than expected (Runaway Query) by automatically downgrading or canceling runaway queries. In actual practice, rules alone cannot cover all cases. Therefore, TiDB v7.3.0 introduces the ability to manually mark runaway queries. With the new command [`QUERY WATCH`](/sql-statements/sql-statement-query-watch.md), you can mark runaway queries based on SQL text, SQL Digest, or execution plan, and the marked runaway queries can be downgraded or cancelled.

    This feature provides an effective intervention method for sudden performance issues in the database. For performance issues caused by queries, before identifying the root cause, this feature can quickly alleviate its impact on overall performance, thereby improving system service quality.

    For more information, see [documentation](/tidb-resource-control.md#query-watch-parameters).

### SQL

* List and List COLUMNS partitioned tables support default partitions [#20679](https://github.com/pingcap/tidb/issues/20679) @[mjonss](https://github.com/mjonss) @[bb7133](https://github.com/bb7133)

    Before v7.3.0, when you use the `INSERT` statement to insert data into a List or List COLUMNS partitioned table, the data needs to meet the specified partitioning conditions of the table. If the data to be inserted does not meet any of these conditions, either the execution of the statement will fail or the non-compliant data will be ignored.

   Starting from v7.3.0, List and List COLUMNS partitioned tables support default partitions. After a default partition is created, if the data to be inserted does not meet any partitioning condition, it will be written to the default partition. This feature improves the usability of List and List COLUMNS partitioning, avoiding the execution failure of the `INSERT` statement or data being ignored due to data that does not meet partitioning conditions.

    Note that this feature is a TiDB extension to MySQL syntax. For a partitioned table with a default partition, the data in the table cannot be directly replicated to MySQL.

    For more information, see [documentation](/partitioned-table.md#list-partitioning).

### Observability

* Show the progress of collecting statistics [#44033](https://github.com/pingcap/tidb/issues/44033) @[hawkingrei](https://github.com/hawkingrei)

    Collecting statistics for large tables often takes a long time. In previous versions, you cannot see the progress of collecting statistics, and therefore cannot predict the completion time. TiDB v7.3.0 introduces a feature to show the progress of collecting statistics. You can view the overall workload, current progress, and estimated completion time for each subtask using the system table `mysql.analyze_jobs` or `SHOW ANALYZE STATUS`. In scenarios such as large-scale data import and SQL performance optimization, this feature helps you understand the overall task progress and improves the user experience.

    For more information, see [documentation](/sql-statements/sql-statement-show-analyze-status.md).

* Plan Replayer supports exporting historical statistics [#45038](https://github.com/pingcap/tidb/issues/45038) @[time-and-fate](https://github.com/time-and-fate)

    Starting from v7.3.0, with the newly added [`dump with stats as of timestamp`](/sql-plan-replayer.md) clause, you can use Plan Replayer to export the statistics of specified SQL-related objects at a specific point in time. During the diagnosis of execution plan issues, accurately capturing historical statistics can help analyze more precisely how the execution plan was generated at the time when the issue occurred. This helps identify the root cause of the issue and greatly improves efficiency in diagnosing execution plan issues.

    For more information, see [documentation](/sql-plan-replayer.md).

### Data migration

* TiDB Lightning introduces a new version of conflict data detection and handling strategy [#41629](https://github.com/pingcap/tidb/issues/41629) @[lance6716](https://github.com/lance6716)

    In previous versions, TiDB Lightning uses different conflict detection and handling methods for Logical Import Mode and Physical Import Mode, which are complex to configure and not easy for users to understand. In addition, Physical Import Mode cannot handle conflicts using the `replace` or `ignore` strategy. Starting from v7.3.0, TiDB Lightning introduces a unified conflict detection and handling strategy for both Logical Import Mode and Physical Import Mode. You can choose to report an error (`error`), replace (`replace`) or ignore (`ignore`) conflicting data when encountering conflicts. You can limit the number of conflict records, such as the task is interrupted and terminated after processing a specified number of conflict records. Furthermore, the system can record conflicting data for troubleshooting.

    For import data with many conflicts, it is recommended to use the new version of the conflict detection and handling strategy for better performance. In the lab environment, the new version strategy can improve the performance of conflict detection and handling up to three times faster than the old version. This performance value is for reference only. The actual performance might vary depending on your configuration, table structure, and the percentage of conflicting data. Note that the new version and the old version of the conflict strategy cannot be used at the same time. The old conflict detection and handling strategy will be deprecated in the future.

    For more information, see [documentation](/tidb-lightning/tidb-lightning-physical-import-mode-usage.md#conflict-detection).

* TiDB Lightning supports Partitioned Raft KV (experimental) [#14916](https://github.com/tikv/tikv/issues/14916) @[GMHDBJD](https://github.com/GMHDBJD)

    TiDB Lightning now supports Partitioned Raft KV. This feature helps improve the data import performance of TiDB Lightning.

* TiDB Lightning introduces a new parameter `enable-diagnose-log` to enhance troubleshooting by printing more diagnostic logs [#45497](https://github.com/pingcap/tidb/issues/45497) @[D3Hunter](https://github.com/D3Hunter)

    By default, this feature is disabled and TiDB Lightning only prints logs containing `lightning/main`. When enabled, TiDB Lightning prints logs for all packages (including `client-go` and `tidb`) to help diagnose issues related to `client-go` and `tidb`.

    For more information, see [documentation](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-global).

## Compatibility changes

> **Note:**
>
> This section provides compatibility changes you need to know when you upgrade from v7.2.0 to the current version (v7.3.0). If you are upgrading from v7.1.0 or earlier versions to the current version, you might also need to check the compatibility changes introduced in intermediate versions.

### Behavior changes

* Backup & Restore (BR)

    - BR adds an empty cluster check before performing a full data restoration. By default, restoring data to a non-empty cluster is not allowed. If you want to force the restoration, you can use the `--filter` option to specify the corresponding table name to restore data to.

* TiDB Lightning

    - `tikv-importer.on-duplicate` is deprecated and replaced by [`conflict.strategy`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-task).
    - The `max-error` parameter, which controls the maximum number of non-fatal errors that TiDB Lightning can tolerate before stopping the migration task, no longer limits import data conflicts. The [`conflict.threshold`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-task) parameter now controls the maximum number of conflicting records that can be tolerated.

* TiCDC

    - When Kafka sink uses Avro protocol, if the `force-replicate` parameter is set to `true`, TiCDC reports an error when creating a changefeed.
    - Due to incompatibility between `delete-only-output-handle-key-columns` and `force-replicate` parameters, when both parameters are enabled, TiCDC reports an error when creating a changefeed.
    - When the output protocol is Open Protocol, the `UPDATE` events only output the changed columns.

### System variables

| Variable name | Change type | Description |
|--------|------------------------------|------|
| [`tidb_opt_enable_mpp_shared_cte_execution`](/system-variables.md#tidb_opt_enable_mpp_shared_cte_execution-new-in-v720) | Modified | This system variable takes effect starting from v7.3.0. It controls whether non-recursive Common Table Expressions (CTEs) can be executed in TiFlash MPP. |
| [`tidb_lock_unchanged_keys`](/system-variables.md#tidb_lock_unchanged_keys-new-in-v711-and-v730) | Newly added | This variable is used to control in certain scenarios whether to lock the keys that are involved but not modified in a transaction. |
| [`tidb_opt_enable_non_eval_scalar_subquery`](/system-variables.md#tidb_opt_enable_non_eval_scalar_subquery-new-in-v730) | Newly added | Controls whether the `EXPLAIN` statement disables the execution of constant subqueries that can be expanded at the optimization stage.  |
| [`tidb_skip_missing_partition_stats`](/system-variables.md#tidb_skip_missing_partition_stats-new-in-v730) | Newly added | This variable controls the generation of GlobalStats when partition statistics are missing. |
| [`tiflash_replica_read`](/system-variables.md#tiflash_replica_read-new-in-v730) | Newly added | Controls the strategy for selecting TiFlash replicas when a query requires the TiFlash engine. |

### Configuration file parameters

| Configuration file | Configuration parameter | Change type | Description |
| -------- | -------- | -------- | -------- |
| TiDB | [`enable-32bits-connection-id`](/tidb-configuration-file.md#enable-32bits-connection-id-new-in-v730) | Newly added | Controls whether to enable the 32-bit connection ID feature. |
| TiDB | [`in-mem-slow-query-recent-num`](/tidb-configuration-file.md#in-mem-slow-query-recent-num-new-in-v730) | Newly added | Controls the number of recently used slow queries that are cached in memory. |
| TiDB | [`in-mem-slow-query-topn-num`](/tidb-configuration-file.md#in-mem-slow-query-topn-num-new-in-v730) | Newly added | Controls the number of slowest queries that are cached in memory. |
| TiKV | [`coprocessor.region-bucket-size`](/tikv-configuration-file.md#region-bucket-size-new-in-v610) | Modified | Changes the default value from `96MiB` to `50MiB`. |
| TiKV | [`raft-engine.format-version`](/tikv-configuration-file.md#format-version-new-in-v630) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), Ribbon filter is used. Therefore, TiKV changes the default value from `2` to `5`. |
| TiKV | [`raftdb.max-total-wal-size`](/tikv-configuration-file.md#max-total-wal-size-1) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), TiKV skips writing WAL. Therefore, TiKV changes the default value from `"4GB"` to `1`, meaning that WAL is disabled. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].compaction-guard-min-output-file-size</code>](/tikv-configuration-file.md#compaction-guard-min-output-file-size) | Modified | Changes the default value from `"1MB"` to `"8MB"` to resolve the issue that compaction speed cannot keep up with the write speed during large data writes. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].format-version</code>](/tikv-configuration-file.md#format-version-new-in-v620) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), Ribbon filter is used. Therefore, TiKV changes the default value from `2` to `5`. |
| TiKV | [`rocksdb.lockcf.write-buffer-size`](/tikv-configuration-file.md#write-buffer-size) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), to speed up compaction on lockcf, TiKV changes the default value from `"32MB"` to `"4MB"`. |
| TiKV | [`rocksdb.max-total-wal-size`](/tikv-configuration-file.md#max-total-wal-size) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), TiKV skips writing WAL. Therefore, TiKV changes the default value from `"4GB"` to `1`, meaning that WAL is disabled. |
| TiKV | [`rocksdb.stats-dump-period`](/tikv-configuration-file.md#stats-dump-period) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), to disable redundant log printing, changes the default value from `"10m"` to `"0"`. |
| TiKV | [`rocksdb.write-buffer-limit`](/tikv-configuration-file.md#write-buffer-limit-new-in-v660) | Modified | To reduce the memory overhead of memtables, when `storage.engine="raft-kv"`, TiKV changes the default value from 25% of the memory of the machine to `0`, which means no limit. When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), TiKV changes the default value from 25% to 20% of the memory of the machine. |
| TiKV | [`storage.block-cache.capacity`](/tikv-configuration-file.md#capacity) | Modified | When using Partitioned Raft KV (`storage.engine="partitioned-raft-kv"`), to compensate for the memory overhead of memtables, TiKV changes the default value from 45% to 30% of the size of total system memory. |
| TiFlash | [`storage.format_version`](/tiflash/tiflash-configuration.md) | Modified | Introduces a new DTFile format `format_version = 5` to reduce the number of physical files by merging smaller files. Note that this format is experimental and not enabled by default. |
| TiDB Lightning  | `tikv-importer.incremental-import` | Deleted | TiDB Lightning parallel import parameter. Because it could easily be mistaken as an incremental import parameter, this parameter is now renamed to `tikv-importer.parallel-import`. If a user passes in the old parameter name, it will be automatically converted to the new one. |
| TiDB Lightning  | `tikv-importer.on-duplicate` | Deprecated | Controls action to do when trying to insert a conflicting record in the logical import mode. Starting from v7.3.0, this parameter is replaced by [`conflict.strategy`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-task). |
| TiDB Lightning | [`conflict.max-record-rows`](/tidb-lightning/tidb-lightning-configuration.md) | Newly added | The new version of strategy to handle conflicting data. It controls the maximum number of rows in the `conflict_records` table. The default value is 100. |
| TiDB Lightning  | [`conflict.strategy`](/tidb-lightning/tidb-lightning-configuration.md) | Newly added | The new version of strategy to handle conflicting data. It includes the following options: "" (TiDB Lightning does not detect and process conflicting data), `error` (terminate the import and report an error if a primary or unique key conflict is detected in the imported data), `replace` (when encountering data with conflicting primary or unique keys, the new data is retained and the old data is overwritten.), `ignore` (when encountering data with conflicting primary or unique keys, the old data is retained and the new data is ignored.). The default value is "", that is, TiDB Lightning does not detect and process conflicting data. |
| TiDB Lightning  | [`conflict.threshold`](/tidb-lightning/tidb-lightning-configuration.md) | Newly added | Controls the upper limit of the conflicting data. When `conflict.strategy="error"`, the default value is `0`. When `conflict.strategy="replace"` or `conflict.strategy="ignore"`, you can set it as a maxint. |
| TiDB Lightning  | [`enable-diagnose-logs`](/tidb-lightning/tidb-lightning-configuration.md) | Newly added | Controls whether to enable the diagnostic logs. The default value is `false`, that is, only the logs related to the import are output, and the logs of other dependent components are not output. When you set it to `true`, logs from both the import process and other dependent components are output, and GRPC debugging is enabled, which can be used for diagnosis. |
|TiDB Lightning  | [`tikv-importer.parallel-import`](/tidb-lightning/tidb-lightning-configuration.md) | Newly added | TiDB Lightning parallel import parameter. It replaces the existing `tikv-importer.incremental-import` parameter, which could be mistaken as an incremental import parameter and misused. |
|BR  | `azblob.encryption-scope` | Newly added | BR provides encryption scope support for Azure Blob Storage. |
|BR  | `azblob.encryption-key` | Newly added | BR provides encryption key support for Azure Blob Storage. |
| TiCDC | [`large-message-handle-option`](/ticdc/ticdc-sink-to-kafka.md#handle-messages-that-exceed-the-kafka-topic-limit) | Newly added | Empty by default, which means that when the message size exceeds the limit of Kafka topic, the changefeed fails. When this configuration is set to `"handle-key-only"`, if the message exceeds the size limit, only the handle key will be sent to reduce the message size; if the reduced message still exceeds the limit, then the changefeed fails. |
| TiCDC | [`sink.csv.binary-encoding-method`](/ticdc/ticdc-changefeed-config.md#changefeed-configuration-parameters) | Newly added | The encoding method of binary data, which can be `'base64'` or `'hex'`. The default value is `'base64'`. |

### System tables

- Add a new system table `mysql.tidb_timers` to store the metadata of internal timers.

## Deprecated features

* TiDB

    - The [`Fast Analyze`](/system-variables.md#tidb_enable_fast_analyze) feature (experimental) for statistics will be deprecated in v7.5.0.
    - The [incremental collection](https://docs.pingcap.com/tidb/v7.3/statistics#incremental-collection) feature for statistics will be deprecated in v7.5.0.

## Improvements

+ TiDB

    - Introduce a new system variable [`tidb_opt_enable_non_eval_scalar_subquery`](/system-variables.md#tidb_opt_enable_non_eval_scalar_subquery-new-in-v730) to control whether the `EXPLAIN` statement executes subqueries in advance during the optimization phase [#22076](https://github.com/pingcap/tidb/issues/22076) @[winoros](https://github.com/winoros)
    - When [Global Kill](/tidb-configuration-file.md#enable-global-kill-new-in-v610) is enabled, you can terminate the current session by pressing <kbd>Control+C</kbd> [#8854](https://github.com/pingcap/tidb/issues/8854) @[pingyu](https://github.com/pingyu)
    - Support the `IS_FREE_LOCK()` and `IS_USED_LOCK()` locking functions [#44493](https://github.com/pingcap/tidb/issues/44493) @[dveeden](https://github.com/dveeden)
    - Optimize the performance of reading the dumped chunks from disk [#45125](https://github.com/pingcap/tidb/issues/45125) @[YangKeao](https://github.com/YangKeao)
    - Optimize the overestimation issue of the inner table of Index Join by using Optimizer Fix Controls [#44855](https://github.com/pingcap/tidb/issues/44855) @[time-and-fate](https://github.com/time-and-fate)

+ TiKV

    - Add the `Max gap of safe-ts` and `Min safe ts region` metrics and introduce the `tikv-ctl get-region-read-progress` command to better observe and diagnose the status of resolved-ts and safe-ts [#15082](https://github.com/tikv/tikv/issues/15082) @[ekexium](https://github.com/ekexium)

+ PD

    - Support blocking the Swagger API by default when the Swagger server is not enabled [#6786](https://github.com/tikv/pd/issues/6786) @[bufferflies](https://github.com/bufferflies)
    - Improve the high availability of etcd [#6554](https://github.com/tikv/pd/issues/6554) [#6442](https://github.com/tikv/pd/issues/6442) @[lhy1024](https://github.com/lhy1024)
    - Reduce the memory consumption of `GetRegions` requests [#6835](https://github.com/tikv/pd/issues/6835) @[lhy1024](https://github.com/lhy1024)

+ TiFlash

    - Support a new DTFile format version [`storage.format_version = 5`](/tiflash/tiflash-configuration.md) to reduce the number of physical files (experimental) [#7595](https://github.com/pingcap/tiflash/issues/7595) @[hongyunyan](https://github.com/hongyunyan)

+ Tools

    + Backup & Restore (BR)

        - When backing up data to Azure Blob Storage using BR, you can specify either an encryption scope or an encryption key for server-side encryption [#45025](https://github.com/pingcap/tidb/issues/45025) @[Leavrth](https://github.com/Leavrth)

    + TiCDC

        - Optimize the message size of the Open Protocol output to make it include only the updated column values when sending `UPDATE` events [#9336](https://github.com/pingcap/tiflow/issues/9336) @[3AceShowHand](https://github.com/3AceShowHand)
        - Storage Sink now supports hexadecimal encoding for HEX formatted data, making it compatible with AWS DMS format specifications [#9373](https://github.com/pingcap/tiflow/issues/9373) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - Kafka Sink supports [sending only handle key data](/ticdc/ticdc-sink-to-kafka.md#handle-messages-that-exceed-the-kafka-topic-limit) when the message is too large, reducing the size of the message [#9382](https://github.com/pingcap/tiflow/issues/9382) @[3AceShowHand](https://github.com/3AceShowHand)

## Bug fixes

+ TiDB

    - Fix the issue that when the MySQL Cursor Fetch protocol is used, the memory consumption of result sets might exceed the `tidb_mem_quota_query` limit and causes TiDB OOM. After the fix, TiDB will automatically write result sets to the disk to release memory [#43233](https://github.com/pingcap/tidb/issues/43233) @[YangKeao](https://github.com/YangKeao)
    - Fix the TiDB panic issue caused by data race [#45561](https://github.com/pingcap/tidb/issues/45561) @[genliqi](https://github.com/gengliqi)
    - Fix the hang-up issue that occurs when queries with `indexMerge` are killed [#45279](https://github.com/pingcap/tidb/issues/45279) @[xzhangxian1008](https://github.com/xzhangxian1008)
    - Fix the issue that query results in MPP mode are incorrect when `tidb_enable_parallel_apply` is enabled [#45299](https://github.com/pingcap/tidb/issues/45299) @[windtalker](https://github.com/windtalker)
    - Fix the issue that `resolve lock` might hang when there is a sudden change in PD time [#44822](https://github.com/pingcap/tidb/issues/44822) @[zyguan](https://github.com/zyguan)
    - Fix the issue that the GC Resolve Locks step might miss some pessimistic locks [#45134](https://github.com/pingcap/tidb/issues/45134) @[MyonKeminta](https://github.com/MyonKeminta)
    - Fix the issue that the query with `ORDER BY` returns incorrect results in dynamic pruning mode [#45007](https://github.com/pingcap/tidb/issues/45007) @[Defined2014](https://github.com/Defined2014)
    - Fix the issue that `AUTO_INCREMENT` can be specified on the same column with the `DEFAULT` column value [#45136](https://github.com/pingcap/tidb/issues/45136) @[Defined2014](https://github.com/Defined2014)
    - Fix the issue that querying the system table `INFORMATION_SCHEMA.TIKV_REGION_STATUS` returns incorrect results in some cases [#45531](https://github.com/pingcap/tidb/issues/45531) @[Defined2014](https://github.com/Defined2014)
    - Fix the issue of incorrect partition table pruning in some cases [#42273](https://github.com/pingcap/tidb/issues/42273) @[jiyfhust](https://github.com/jiyfhust)
    - Fix the issue that global indexes are not cleared when truncating partition of a partitioned table [#42435](https://github.com/pingcap/tidb/issues/42435) @[L-maple](https://github.com/L-maple)
    - Fix the issue that other TiDB nodes do not take over TTL tasks after failures in one TiDB node [#45022](https://github.com/pingcap/tidb/issues/45022) @[lcwangchao](https://github.com/lcwangchao)
    - Fix the memory leak issue when TTL is running [#45510](https://github.com/pingcap/tidb/issues/45510) @[lcwangchao](https://github.com/lcwangchao)
    - Fix the issue of inaccurate error messages when inserting data into partitioned tables [#44966](https://github.com/pingcap/tidb/issues/44966) @[lilinghai](https://github.com/lilinghai)
    - Fix the read permission issue on the `INFORMATION_SCHEMA.TIFLASH_REPLICA` table [#7795](https://github.com/pingcap/tiflash/issues/7795) @[Lloyd-Pottiger](https://github.com/Lloyd-Pottiger)
    - Fix the issue that an error occurs when using a wrong partition table name [#44967](https://github.com/pingcap/tidb/issues/44967) @[River2000i](https://github.com/River2000i)
    - Fix the issue that creating indexes gets stuck when `tidb_enable_dist_task` is enabled in some cases [#44440](https://github.com/pingcap/tidb/issues/44440) @[tangenta](https://github.com/tangenta)
    - Fix the `duplicate entry` error that occurs when restoring a table with `AUTO_ID_CACHE=1` using BR [#44716](https://github.com/pingcap/tidb/issues/44716) @[tiancaiamao](https://github.com/tiancaiamao)
    - Fix the issue that the time consumed for executing `TRUNCATE TABLE` is inconsistent with the task execution time shown in `ADMIN SHOW DDL JOBS` [#44785](https://github.com/pingcap/tidb/issues/44785) @[tangenta](https://github.com/tangenta)
    - Fix the issue that upgrading TiDB gets stuck when reading metadata takes longer than one DDL lease [#45176](https://github.com/pingcap/tidb/issues/45176) @[zimulala](https://github.com/zimulala)
    - Fix the issue that the query result of the `SELECT CAST(n AS CHAR)` statement is incorrect when `n` in the statement is a negative number [#44786](https://github.com/pingcap/tidb/issues/44786) @[xhebox](https://github.com/xhebox)
    - Fix the issue that queries might return incorrect results when `tidb_opt_agg_push_down` is enabled [#44795](https://github.com/pingcap/tidb/issues/44795) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue of wrong results that occurs when a query with `current_date()` uses plan cache [#45086](https://github.com/pingcap/tidb/issues/45086) @[qw4990](https://github.com/qw4990)

+ TiKV

    - Fix the issue that reading data during GC might cause TiKV panic in some rare cases [#15109](https://github.com/tikv/tikv/issues/15109) @[MyonKeminta](https://github.com/MyonKeminta)

+ PD

    - Fix the issue that restarting PD might cause the `default` resource group to be reinitialized [#6787](https://github.com/tikv/pd/issues/6787) @[glorv](https://github.com/glorv)
    - Fix the issue that when etcd is already started but the client has not yet connected to it, calling the client might cause PD to panic [#6860](https://github.com/tikv/pd/issues/6860) @[HuSharp](https://github.com/HuSharp)
    - Fix the issue that the `health-check` output of a Region is inconsistent with the Region information returned by querying the Region ID [#6560](https://github.com/tikv/pd/issues/6560) @[JmPotato](https://github.com/JmPotato)
    - Fix the issue that failed learner peers in `unsafe recovery` are ignored in `auto-detect` mode [#6690](https://github.com/tikv/pd/issues/6690) @[v01dstar](https://github.com/v01dstar)
    - Fix the issue that Placement Rules select TiFlash learners that do not meet the rules [#6662](https://github.com/tikv/pd/issues/6662) @[rleungx](https://github.com/rleungx)
    - Fix the issue that unhealthy peers cannot be removed when rule checker selects peers [#6559](https://github.com/tikv/pd/issues/6559) @[nolouch](https://github.com/nolouch)

+ TiFlash

    - Fix the issue that TiFlash cannot replicate partitioned tables successfully due to deadlocks [#7758](https://github.com/pingcap/tiflash/issues/7758) @[hongyunyan](https://github.com/hongyunyan)
    - Fix the issue that the `INFORMATION_SCHEMA.TIFLASH_REPLICA` system table contains tables that users do not have privileges to access [#7795](https://github.com/pingcap/tiflash/issues/7795) @[Lloyd-Pottiger](https://github.com/Lloyd-Pottiger)
    - Fix the issue that when there are multiple HashAgg operators within the same MPP task, the compilation of the MPP task might take an excessively long time, severely affecting query performance [#7810](https://github.com/pingcap/tiflash/issues/7810) @[SeaRise](https://github.com/SeaRise)

+ Tools

    + TiCDC

        - Fix the issue that changefeeds would fail due to the temporary unavailability of PD [#9294](https://github.com/pingcap/tiflow/issues/9294) @[asddongmen](https://github.com/asddongmen)
        - Fix the data inconsistency issue that might occur when some TiCDC nodes are isolated from the network [#9344](https://github.com/pingcap/tiflow/issues/9344) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - Fix the issue that when Kafka Sink encounters errors it might indefinitely block changefeed progress [#9309](https://github.com/pingcap/tiflow/issues/9309) @[hicqu](https://github.com/hicqu)
        - Fix the panic issue that might occur when the TiCDC node status changes [#9354](https://github.com/pingcap/tiflow/issues/9354) @[sdojjy](https://github.com/sdojjy)
        - Fix the encoding error for the default `ENUM` values [#9259](https://github.com/pingcap/tiflow/issues/9259) @[3AceShowHand](https://github.com/3AceShowHand)

    + TiDB Lightning

        - Fix the issue that executing checksum after TiDB Lightning completes import might get SSL errors [#45462](https://github.com/pingcap/tidb/issues/45462) @[D3Hunter](https://github.com/D3Hunter)
        - Fix the issue that in Logical Import Mode, deleting tables downstream during import might cause TiDB Lightning metadata not to be updated in time [#44614](https://github.com/pingcap/tidb/issues/44614) @[dsdashun](https://github.com/dsdashun)

## Contributors

We would like to thank the following contributors from the TiDB community:

- [charleszheng44](https://github.com/charleszheng44)
- [dhysum](https://github.com/dhysum)
- [haiyux](https://github.com/haiyux)
- [Jiang-Hua](https://github.com/Jiang-Hua)
- [Jille](https://github.com/Jille)
- [jiyfhust](https://github.com/jiyfhust)
- [krishnaduttPanchagnula](https://github.com/krishnaduttPanchagnula)
- [L-maple](https://github.com/L-maple)
- [pingandb](https://github.com/pingandb)
- [testwill](https://github.com/testwill)
- [tisonkun](https://github.com/tisonkun)
- [xuyifangreeneyes](https://github.com/xuyifangreeneyes)
- [yumchina](https://github.com/yumchina)

---
title: TiDB 7.4.0 Release Notes
summary: Learn about the new features, compatibility changes, improvements, and bug fixes in TiDB 7.4.0.
---

# TiDB 7.4.0 Release Notes

Release date: October 12, 2023

TiDB version: 7.4.0

Quick access: [Quick start](https://docs.pingcap.com/tidb/v7.4/quick-start-with-tidb) | [Installation packages](https://www.pingcap.com/download/?version=v7.4.0#version-list)

7.4.0 introduces the following key features and improvements:

<table>
<thead>
  <tr>
    <th>Category</th>
    <th>Feature</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="3">Reliability and Availability</td>
    <td>Improve the performance and stability of <code>IMPORT INTO</code> and <code>ADD INDEX</code> operations via <a href="https://docs.pingcap.com/tidb/v7.4/tidb-global-sort" target="_blank">global sort</a> (experimental)</td>
    <td>Before v7.4.0, tasks such as <code>ADD INDEX</code> or <code>IMPORT INTO</code> using the <a href="https://docs.pingcap.com/tidb/v7.4/tidb-distributed-execution-framework" target="_blank">distributed execution framework</a> meant localized and partial sorting, which ultimately led to TiKV doing a lot of extra work to make up for the partial sorting. These jobs also required TiDB nodes to allocate local disk space for sorting, before loading to TiKV.<br/>With the introduction of the Global Sorting feature in v7.4.0, data is temporarily stored in external shared storage (S3 in this version) for global sorting before being loaded into TiKV. This eliminates the need for TiKV to consume extra resources and significantly improves the performance and stability of operations like <code>ADD INDEX</code> and <code>IMPORT INTO</code>.</td>
  </tr>
  <tr>
    <td><a href="https://docs.pingcap.com/tidb/v7.4/tidb-resource-control#manage-background-tasks" target="_blank">Resource control</a> for background tasks (experimental)</td>
    <td>In v7.1.0, the <a href="https://docs.pingcap.com/tidb/v7.4/tidb-resource-control#use-resource-control-to-achieve-resource-isolation" target="_blank">Resource Control</a> feature was introduced to mitigate resource and storage access interference between workloads. TiDB v7.4.0 applies this control to background tasks as well. In v7.4.0, Resource Control now identifies and manages the resources produced by background tasks, such as auto-analyze, Backup & Restore, bulk load with TiDB Lightning, and online DDL. This will eventually apply to all background tasks.</td>
  </tr>
  <tr>
    <td>TiFlash supports <a href="https://docs.pingcap.com/tidb/v7.4/tiflash-disaggregated-and-s3" target="_blank">storage-computing separation and S3</a> (GA) </td>
    <td>TiFlash disaggregated storage and compute architecture and S3 shared storage become generally available:
      <ul>
        <li>Disaggregates TiFlash's compute and storage, which is a milestone for elastic HTAP resource utilization.</li>
        <li>Supports using S3-based storage engine, which can provide shared storage at a lower cost.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td rowspan="2">SQL</td>
    <td>TiDB supports <a href="https://docs.pingcap.com/tidb/v7.4/partitioned-table#convert-a-partitioned-table-to-a-non-partitioned-table" target="_blank">partition type management</a> </td>
    <td>Before v7.4.0, Range/List partitioned tables support partition management operations such as <code>TRUNCATE</code>, <code>EXCHANGE</code>, <code>ADD</code>, <code>DROP</code>, and <code>REORGANIZE</code>, and Hash/Key partitioned tables support partition management operations such as <code>ADD</code> and <code>COALESCE</code>.
    <p>Now TiDB also supports the following partition type management operations:</p>
      <ul>
        <li>Convert partitioned tables to non-partitioned tables</li>
        <li>Partition existing non-partitioned tables</li>
        <li>Modify partition types for existing tables</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td>MySQL 8.0 compatibility: support<a href="https://docs.pingcap.com/tidb/v7.4/character-set-and-collation#character-sets-and-collations-supported-by-tidb" target="_blank"> collation <code>utf8mb4_0900_ai_ci</code></a></td>
    <td>One notable change in MySQL 8.0 is that the default character set is utf8mb4, and the default collation of utf8mb4 is <code>utf8mb4_0900_ai_ci</code>. TiDB v7.4.0 adding support for this enhances compatibility with MySQL 8.0 so that migrations and replications from MySQL 8.0 databases with the default collation are now much smoother.</td>
  </tr>
  <tr>
    <td>DB Operations and Observability</td>
    <td>Specify<a href="https://docs.pingcap.com/tidb/v7.4/system-variables#tidb_service_scope-new-in-v740" target="_blank"> the respective TiDB nodes</a> to execute the <code>IMPORT INTO</code> and <code>ADD INDEX</code> SQL statements (experimental)</td>
    <td>You have the flexibility to specify whether to execute <code>IMPORT INTO</code> or <code>ADD INDEX</code> SQL statements on some of the existing TiDB nodes or newly added TiDB nodes. This approach enables resource isolation from the rest of the TiDB nodes, preventing any impact on business operations while ensuring optimal performance for executing the preceding SQL statements.</td>
  </tr>
</tbody>
</table>

## Feature details

### Scalability

* Support selecting the TiDB nodes to parallelly execute the backend `ADD INDEX` or `IMPORT INTO` tasks of the distributed execution framework (experimental) [#46453](https://github.com/pingcap/tidb/pull/46453) @[ywqzzy](https://github.com/ywqzzy)

    Executing `ADD INDEX` or `IMPORT INTO` tasks in parallel in a resource-intensive cluster can consume a large amount of TiDB node resources, which can lead to cluster performance degradation. Starting from v7.4.0, you can use the system variable [`tidb_service_scope`](/system-variables.md#tidb_service_scope-new-in-v740) to control the service scope of each TiDB node under the [TiDB Backend Task Distributed Execution Framework](/tidb-distributed-execution-framework.md). You can select several existing TiDB nodes or set the TiDB service scope for new TiDB nodes, and all parallel `ADD INDEX` and `IMPORT INTO` tasks only run on these nodes. This mechanism can avoid performance impact on existing services.

    For more information, see [documentation](/system-variables.md#tidb_service_scope-new-in-v740).

* Enhance the Partitioned Raft KV storage engine (experimental) [#11515](https://github.com/tikv/tikv/issues/11515) [#12842](https://github.com/tikv/tikv/issues/12842) @[busyjay](https://github.com/busyjay) @[tonyxuqqi](https://github.com/tonyxuqqi) @[tabokie](https://github.com/tabokie) @[bufferflies](https://github.com/bufferflies) @[5kbpers](https://github.com/5kbpers) @[SpadeA-Tang](https://github.com/SpadeA-Tang) @[nolouch](https://github.com/nolouch)

    TiDB v6.6.0 introduces the Partitioned Raft KV storage engine as an experimental feature, which uses multiple RocksDB instances to store TiKV Region data, and the data of each Region is independently stored in a separate RocksDB instance.

    In v7.4.0, TiDB further improves the compatibility and stability of the Partitioned Raft KV storage engine. Through large-scale data testing, the compatibility with TiDB ecosystem tools and features such as DM, Dumpling, TiDB Lightning, TiCDC, BR, and PITR is ensured. Additionally, the Partitioned Raft KV storage engine provides more stable performance under mixed read and write workloads, making it especially suitable for write-heavy scenarios. Furthermore, each TiKV node now supports 8 core CPUs and can be configured with 8 TB data storage, and 64 GB memory.

    For more information, see [documentation](/partitioned-raft-kv.md).

* TiFlash supports the disaggregated storage and compute architecture (GA) [#6882](https://github.com/pingcap/tiflash/issues/6882) @[JaySon-Huang](https://github.com/JaySon-Huang) @[JinheLin](https://github.com/JinheLin) @[breezewish](https://github.com/breezewish) @[lidezhu](https://github.com/lidezhu) @[CalvinNeo](https://github.com/CalvinNeo) @[Lloyd-Pottiger](https://github.com/Lloyd-Pottiger)

    In v7.0.0, TiFlash introduces the disaggregated storage and compute architecture as an experimental feature. With a series of improvements, the disaggregated storage and compute architecture for TiFlash becomes GA starting from v7.4.0.

    In this architecture, TiFlash nodes are divided into two types (Compute Nodes and Write Nodes) and support object storage that is compatible with S3 API. Both types of nodes can be independently scaled for computing or storage capacities. In the disaggregated storage and compute architecture, you can use TiFlash in the same way as the coupled storage and compute architecture, such as creating TiFlash replicas, querying data, and specifying optimizer hints.

    Note that the TiFlash **disaggregated storage and compute architecture** and **coupled storage and compute architecture** cannot be used in the same cluster or converted to each other. You can configure which architecture to use when you deploy TiFlash.

    For more information, see [documentation](/tiflash/tiflash-disaggregated-and-s3.md).

### Performance

* Support pushing down the JSON operator `MEMBER OF` to TiKV [#46307](https://github.com/pingcap/tidb/issues/46307) @[wshwsh12](https://github.com/wshwsh12)

    * `value MEMBER OF(json_array)`

  For more information, see [documentation](/functions-and-operators/expressions-pushed-down.md).

* Support pushing down window functions with any frame definition type to TiFlash [#7376](https://github.com/pingcap/tiflash/issues/7376) @[xzhangxian1008](https://github.com/xzhangxian1008)

    Before v7.4.0, TiFlash does not support window functions containing `PRECEDING` or `FOLLOWING`, and all window functions containing such frame definitions cannot be pushed down to TiFlash. Starting from v7.4.0, TiFlash supports frame definitions of all window functions. This feature is enabled automatically, and window functions containing frame definitions will be automatically pushed down to TiFlash for execution when the related requirements are met.

* Introduce cloud storage-based global sort capability to improve the performance and stability of `ADD INDEX` and `IMPORT INTO` tasks in parallel execution (experimental) [#45719](https://github.com/pingcap/tidb/issues/45719) @[wjhuang2016](https://github.com/wjhuang2016)

    Before v7.4.0, when executing tasks like `ADD INDEX` or `IMPORT INTO` in the distributed parallel execution framework, each TiDB node needs to allocate a significant amount of local disk space for sorting encoded index KV pairs and table data KV pairs. However, due to the lack of global sorting capability, there might be overlapping data between different TiDB nodes and within each individual node during the process. As a result, TiKV has to constantly perform compaction operations while importing these KV pairs into its storage engine, which impacts the performance and stability of `ADD INDEX` and `IMPORT INTO`.

    In v7.4.0, TiDB introduces the [Global Sort](/tidb-global-sort.md) feature. Instead of writing the encoded data locally and sorting it there, the data is now written to cloud storage for global sorting. Once sorted, both the indexed data and table data are imported into TiKV in parallel, thereby improving performance and stability.

    For more information, see [documentation](/tidb-global-sort.md).

* Support caching execution plans for non-prepared statements (GA) [#36598](https://github.com/pingcap/tidb/issues/36598) @[qw4990](https://github.com/qw4990)

    TiDB v7.0.0 introduces non-prepared plan cache as an experimental feature to improve the load capacity of concurrent OLTP. In v7.4.0, this feature becomes GA. The execution plan cache will be applied to more scenarios, thereby improving the concurrent processing capacity of TiDB.

    Enabling the non-prepared plan cache might incur additional memory and CPU overhead and might not be suitable for all situations. Starting from v7.4.0, this feature is disabled by default. You can enable it using [`tidb_enable_non_prepared_plan_cache`](/system-variables.md#tidb_enable_non_prepared_plan_cache) and control the cache size using [`tidb_session_plan_cache_size`](/system-variables.md#tidb_session_plan_cache_size-new-in-v710).

    Additionally, this feature does not support DML statements by default and has certain restrictions on SQL statements. For more details, see [Restrictions](/sql-non-prepared-plan-cache.md#restrictions).

    For more information, see [documentation](/sql-non-prepared-plan-cache.md).

### Reliability

* TiFlash supports query-level data spilling [#7738](https://github.com/pingcap/tiflash/issues/7738) @[windtalker](https://github.com/windtalker)

    Starting from v7.0.0, TiFlash supports controlling data spilling for three operators: `GROUP BY`, `ORDER BY`, and `JOIN`. This feature prevents issues such as query termination or system crashes when the data size exceeds the available memory. However, managing spilling for each operator individually can be cumbersome and ineffective for overall resource control.

    In v7.4.0, TiFlash introduces the query-level data spilling. By setting the memory limit for a query on a TiFlash node using [`tiflash_mem_quota_query_per_node`](/system-variables.md#tiflash_mem_quota_query_per_node-new-in-v740) and the memory ratio that triggers data spilling using [`tiflash_query_spill_ratio`](/system-variables.md#tiflash_query_spill_ratio-new-in-v740), you can conveniently manage the memory usage of a query and have better control over TiFlash memory resources.

    For more information, see [documentation](/tiflash/tiflash-spill-disk.md).

* Support user-defined TiKV read timeout [#45380](https://github.com/pingcap/tidb/issues/45380) @[crazycs520](https://github.com/crazycs520)

    Normally, TiKV processes requests very quickly, in a matter of milliseconds. However, when a TiKV node encounters disk I/O jitter or network latency, the request processing time can increase significantly. In versions earlier than v7.4.0, the timeout limit for TiKV requests is fixed and unadjustable. Hence, TiDB has to wait for a fixed-duration timeout response when a TiKV node encounters issues, which results in a noticeable impact on application query performance during jitter.

    TiDB v7.4.0 introduces a new system variable [`tikv_client_read_timeout`](/system-variables.md#tikv_client_read_timeout-new-in-v740), which lets you customize the timeout for RPC read requests that TiDB sends to TiKV in a query. It means that when the request sent to a TiKV node is delayed due to disk or network issues, TiDB can time out faster and resend the request to other TiKV nodes, thus reducing query latency. If timeouts occur for all TiKV nodes, TiDB will retry using the default timeout. Additionally, you can also use the optimizer hint `/*+ SET_VAR(TIKV_CLIENT_READ_TIMEOUT=N) */` in a query to set the timeout for TiDB to send a TiKV RPC read request. This enhancement gives TiDB the flexibility to adapt to unstable network or storage environments, improving query performance and enhancing the user experience.

    For more information, see [documentation](/system-variables.md#tikv_client_read_timeout-new-in-v740).

* Support temporarily modifying some system variable values using an optimizer hint [#45892](https://github.com/pingcap/tidb/issues/45892) @[winoros](https://github.com/winoros)

    TiDB v7.4.0 introduces the optimizer hint `SET_VAR()`, which is similar to that of MySQL 8.0. By including the hint `SET_VAR()` in SQL statements, you can temporarily modify the value of system variables during statement execution. This helps you set the environment for different statements. For example, you can actively increase the parallelism of resource-intensive SQL statements or change the optimizer behavior through variables.

    You can find the system variables that can be modified using the hint `SET_VAR()` in [system variables](/system-variables.md). It is strongly recommended not to modify variables that are not explicitly supported, as this might cause unpredictable behavior.

    For more information, see [documentation](/optimizer-hints.md).

* TiFlash supports resource control [#7660](https://github.com/pingcap/tiflash/issues/7660) @[guo-shaoge](https://github.com/guo-shaoge)

    In TiDB v7.1.0, the resource control feature becomes generally available and provides resource management capabilities for TiDB and TiKV. In v7.4.0, TiFlash supports the resource control feature, improving the overall resource management capabilities of TiDB. The resource control of TiFlash is fully compatible with the existing TiDB resource control feature, and the existing resource groups will manage the resources of TiDB, TiKV, and TiFlash at the same time.

    To control whether to enable the TiFlash resource control feature, you can configure the TiFlash parameter `enable_resource_control`. After enabling this feature, TiFlash performs resource scheduling and management based on the resource group configuration of TiDB, ensuring the reasonable allocation and use of overall resources.

    For more information, see [documentation](/tidb-resource-control.md).

* TiFlash supports the pipeline execution model (GA) [#6518](https://github.com/pingcap/tiflash/issues/6518) @[SeaRise](https://github.com/SeaRise)

    Starting from v7.2.0, TiFlash introduces a pipeline execution model. This model centrally manages all thread resources and schedules task execution uniformly, maximizing the utilization of thread resources while avoiding resource overuse. In v7.4.0, TiFlash improves the statistics of thread resource usage, and the pipeline execution model becomes a GA feature and is enabled by default. Since this feature is mutually dependent with the TiFlash resource control feature, TiDB v7.4.0 removes the variable `tidb_enable_tiflash_pipeline_model` used to control whether to enable the pipeline execution model in previous versions. Instead, you can enable or disable the pipeline execution model and the TiFlash resource control feature by configuring the TiFlash parameter `tidb_enable_resource_control`.

    For more information, see [documentation](/tiflash/tiflash-pipeline-model.md).

* Add the option of optimizer mode [#46080](https://github.com/pingcap/tidb/issues/46080) @[time-and-fate](https://github.com/time-and-fate)

    In v7.4.0, TiDB introduces a new system variable [`tidb_opt_objective`](/system-variables.md#tidb_opt_objective-new-in-v740), which controls the estimation method used by the optimizer. The default value `moderate` maintains the previous behavior of the optimizer, where it uses runtime statistics to adjust estimations based on data changes. If this variable is set to `determinate`, the optimizer generates execution plans solely based on statistics without considering runtime corrections.

    For long-term stable OLTP applications or situations where you are confident in the existing execution plans, it is recommended to switch to `determinate` mode after testing. This reduces potential plan changes.

    For more information, see [documentation](/system-variables.md#tidb_opt_objective-new-in-v740).

* TiDB resource control supports managing background tasks (experimental) [#44517](https://github.com/pingcap/tidb/issues/44517) @[glorv](https://github.com/glorv)

    Background tasks, such as data backup and automatic statistics collection, are low-priority but consume many resources. These tasks are usually triggered periodically or irregularly. During execution, they consume a lot of resources, thus affecting the performance of online high-priority tasks. Starting from v7.4.0, the TiDB resource control feature supports managing background tasks. This feature reduces the performance impact of low-priority tasks on online applications, enabling rational resource allocation, and greatly improving cluster stability.

    TiDB supports the following types of background tasks:

    - `lightning`: perform import tasks using [TiDB Lightning](/tidb-lightning/tidb-lightning-overview.md) or [`IMPORT INTO`](/sql-statements/sql-statement-import-into.md).
    - `br`: perform backup and restore tasks using [BR](/br/backup-and-restore-overview.md). PITR is not supported.
    - `ddl`: control the resource usage during the batch data write back phase of Reorg DDLs.
    - `stats`: the [collect statistics](/statistics.md#collect-statistics) tasks that are manually executed or automatically triggered by TiDB.

  By default, the task types that are marked as background tasks are empty, and the management of background tasks is disabled. This default behavior is the same as that of versions prior to TiDB v7.4.0. To manage background tasks, you need to manually modify the background task types of the `default` resource group.

    For more information, see [documentation](/tidb-resource-control.md#manage-background-tasks).

* Enhance the ability to lock statistics [#46351](https://github.com/pingcap/tidb/issues/46351) @[hi-rustin](https://github.com/hi-rustin)

    In v7.4.0, TiDB has enhanced the ability to [lock statistics](/statistics.md#lock-statistics). Now, to ensure operational security, locking and unlocking statistics require the same privileges as collecting statistics. In addition, TiDB supports locking and unlocking statistics for specific partitions, providing greater flexibility. If you are confident in queries and execution plans in the database and want to prevent any changes from occurring, you can lock statistics to enhance stability.

    For more information, see [documentation](/statistics.md#lock-statistics).

* Introduce a system variable to control whether to select hash joins for tables [#46695](https://github.com/pingcap/tidb/issues/46695) @[coderplay](https://github.com/coderplay)

     MySQL 8.0 introduces hash joins for tables as a new feature. This feature is primarily used to join two relatively large tables and result sets. However, for transactional workloads, or some applications running on MySQL 5.7, hash joins for tables might pose a performance risk. MySQL provides the [`optimizer_switch`](https://dev.mysql.com/doc/refman/8.0/en/switchable-optimizations.html#optflag_block-nested-loop) to control whether to select hash joins at the global or session level.

    Starting from v7.4.0, TiDB introduces the system variable [`tidb_opt_enable_hash_join`](/system-variables.md#tidb_opt_enable_hash_join-new-in-v740) to have control over hash joins for tables. It is enabled by default (`ON`). If you are sure that you do not need to select hash joins between tables in your execution plan, you can modify the variable to `OFF` to reduce the possibility of execution plan rollbacks and improve system stability.

    For more information, see [documentation](/system-variables.md#tidb_opt_enable_hash_join-new-in-v740).

### SQL

* TiDB supports partition type management [#42728](https://github.com/pingcap/tidb/issues/42728) @[mjonss](https://github.com/mjonss)

    Before v7.4.0, partition types of partitioned tables in TiDB cannot be modified. Starting from v7.4.0, TiDB supports modifying partitioned tables to non-partitioned tables or non-partitioned tables to partitioned tables, and supports changing partition types. Hence, now you can flexibly adjust the partition type and number for a partitioned table. For example, you can use the `ALTER TABLE t PARTITION BY ...` statement to modify the partition type.

    For more information, see [documentation](/partitioned-table.md#convert-a-partitioned-table-to-a-non-partitioned-table).

* TiDB supports using the `ROLLUP` modifier and the `GROUPING` function [#44487](https://github.com/pingcap/tidb/issues/44487) @[AilinKid](https://github.com/AilinKid)

    The `WITH ROLLUP` modifier and `GROUPING` function are commonly used in data analysis for multi-dimensional data summarization. Starting from v7.4.0, you can use the `WITH ROLLUP` modifier and `GROUPING` function in the `GROUP BY` clause. For example, you can use the `WITH ROLLUP` modifier in the `SELECT ... FROM ... GROUP BY ... WITH ROLLUP` syntax.

   For more information, see [documentation](/functions-and-operators/group-by-modifier.md).

### DB operations

* Support collation `utf8mb4_0900_ai_ci` and `utf8mb4_0900_bin` [#37566](https://github.com/pingcap/tidb/issues/37566) @[YangKeao](https://github.com/YangKeao) @[zimulala](https://github.com/zimulala) @[bb7133](https://github.com/bb7133)

    TiDB v7.4.0 enhances the support for migrating data from MySQL 8.0 and adds two collations: `utf8mb4_0900_ai_ci` and `utf8mb4_0900_bin`. `utf8mb4_0900_ai_ci` is the default collation in MySQL 8.0.

    TiDB v7.4.0 also introduces the system variable `default_collation_for_utf8mb4` which is compatible with MySQL 8.0. This enables you to specify the default collation for the utf8mb4 character set and provides compatibility with migration or data replication from MySQL 5.7 or earlier versions.

    For more information, see [documentation](/character-set-and-collation.md#character-sets-and-collations-supported-by-tidb).

### Observability

* Support adding session connection IDs and session aliases to logs [#46071](https://github.com/pingcap/tidb/issues/46071) @[lcwangchao](https://github.com/lcwangchao)

     When you troubleshoot a SQL execution problem, it is often necessary to correlate the contents of TiDB component logs to pinpoint the root cause. Starting from v7.4.0, TiDB can write session connection IDs (`CONNECTION_ID`) to session-related logs, including TiDB logs, slow query logs, and slow logs from the coprocessor on TiKV. You can correlate the contents of several types of logs based on session connection IDs to improve troubleshooting and diagnostic efficiency.

     In addition, by setting the session-level system variable [`tidb_session_alias`](/system-variables.md#tidb_session_alias-new-in-v740), you can add custom identifiers to the logs mentioned above. With this ability to inject your application identification information into the logs, you can correlate the contents of the logs with the application, build the link from the application to the logs, and reduce the difficulty of diagnosis.

* TiDB Dashboard supports displaying execution plans in a table view [#1589](https://github.com/pingcap/tidb-dashboard/issues/1589) @[baurine](https://github.com/baurine)

    In v7.4.0, TiDB Dashboard supports displaying execution plans on the **Slow Query** and **SQL Statement** pages in a table view to improve the diagnosis experience.

    For more information, see [documentation](/dashboard/dashboard-statement-details.md).

### Data migration

* Enhance the `IMPORT INTO` feature [#46704](https://github.com/pingcap/tidb/issues/46704) @[D3Hunter](https://github.com/D3Hunter)

    Starting from v7.4.0, you can add the `CLOUD_STORAGE_URI` option in the `IMPORT INTO` statement to enable the [global sorting](/tidb-global-sort.md) feature (experimental), which helps boost import performance and stability. In the `CLOUD_STORAGE_URI` option, you can specify a cloud storage address for the encoded data.

    In addition, in v7.4.0, the `IMPORT INTO` feature introduces the following functionalities:

    - Support configuring the `Split_File` option, which allows you to split a large CSV file into multiple 256 MiB small CSV files for parallel processing, improving import performance.
    - Support importing compressed CSV and SQL files. The supported compression formats include `.gzip`, `.gz`, `.zstd`, `.zst`, and `.snappy`.

  For more information, see [documentation](/sql-statements/sql-statement-import-into.md).

* Dumpling supports the user-defined terminator when exporting data to CSV files [#46982](https://github.com/pingcap/tidb/issues/46982) @[GMHDBJD](https://github.com/GMHDBJD)

    Before v7.4.0, Dumpling uses `"\r\n"` as the line terminator when exporting data to a CSV file. As a result, certain downstream systems that only recognize `"\n"` as the terminator cannot parse the exported CSV file, or have to use a third-party tool for conversion before parsing the file.

    Starting from v7.4.0, Dumpling introduces a new parameter `--csv-line-terminator`. This parameter allows you to specify a desired terminator when you export data to a CSV file. This parameter supports `"\r\n"` and `"\n"`. The default terminator is `"\r\n"` to keep consistent with earlier versions.

    For more information, see [documentation](/dumpling-overview.md#option-list-of-dumpling).

* TiCDC supports replicating data to Pulsar [#9413](https://github.com/pingcap/tiflow/issues/9413) @[yumchina](https://github.com/yumchina) @[asddongmen](https://github.com/asddongmen)

    Pulsar is a cloud-native and distributed message streaming platform that significantly enhances your real-time data streaming experience. Starting from v7.4.0, TiCDC supports replicating change data to Pulsar in `canal-json` format to achieve seamless integration with Pulsar. With this feature, TiCDC provides you with the ability to easily capture and replicate TiDB changes to Pulsar, offering new possibilities for data processing and analytics capabilities. You can develop your own consumer applications that read and process newly generated change data from Pulsar to meet specific business needs.

    For more information, see [documentation](/ticdc/ticdc-sink-to-pulsar.md).

- TiCDC improves large message handling with claim-check pattern [#9153](https://github.com/pingcap/tiflow/issues/9153) @[3AceShowHand](https://github.com/3AceShowHand)

    Before v7.4.0, TiCDC is unable to send large messages exceeding the maximum message size (`max.message.bytes`) of Kafka to downstream. Starting from v7.4.0, when configuring a changefeed with Kafka as the downstream, you can specify an external storage location for storing the large message, and send a reference message containing the address of the large message in the external storage to Kafka. When consumers receive this reference message, they can retrieve the message content from the external storage address.

    For more information, see [documentation](/ticdc/ticdc-sink-to-kafka.md#send-large-messages-to-external-storage).

## Compatibility changes

> **Note:**
>
> This section provides compatibility changes you need to know when you upgrade from v7.3.0 to the current version (v7.4.0). If you are upgrading from v7.2.0 or earlier versions to the current version, you might also need to check the compatibility changes introduced in intermediate versions.

### Behavior changes

- Starting with v7.4.0, TiDB is compatible with essential features of MySQL 8.0, and `version()` returns the version prefixed with `8.0.11`.

- After TiFlash is upgraded to v7.4.0 from an earlier version, in-place downgrading to the original version is not supported. This is because, starting from v7.4, TiFlash optimizes the data compaction logic of PageStorage V3 to reduce the read and write amplification generated during data compaction, which leads to changes to some of the underlying storage file names.

- A [`TIDB_PARSE_TSO_LOGICAL()`](/functions-and-operators/tidb-functions.md#tidb-specific-functions) function is added to allow the extraction of the logical part of the TSO timestamp.

- The [`information_schema.CHECK_CONSTRAINTS`](/information-schema/information-schema-check-constraints.md) table is added for improved compatibility with MySQL 8.0.

### System variables

| Variable name | Change type | Description |
|--------|------------------------------|------|
| `tidb_enable_tiflash_pipeline_model` | Deleted | This variable was used to control whether to enable the TiFlash pipeline execution model. Starting from v7.4.0, the TiFlash pipeline execution model is automatically enabled when the TiFlash resource control feature is enabled. |
| [`tidb_enable_non_prepared_plan_cache`](/system-variables.md#tidb_enable_non_prepared_plan_cache) | Modified |  Changes the default value from `ON` to `OFF` after further tests, meaning that non-prepared execution plan cache is disabled. |
| [`default_collation_for_utf8mb4`](/system-variables.md#default_collation_for_utf8mb4-new-in-v740) | Newly added | Controls the default collation for the `utf8mb4` character set. The default value is `utf8mb4_bin`. |
| [`tidb_cloud_storage_uri`](/system-variables.md#tidb_cloud_storage_uri-new-in-v740) | Newly added | Specifies the cloud storage URI to enable [Global Sort](/tidb-global-sort.md). |
| [`tidb_opt_enable_hash_join`](/system-variables.md#tidb_opt_enable_hash_join-new-in-v740) | Newly added | Controls whether the optimizer will select hash joins for tables. The value is `ON` by default. If set to `OFF`, the optimizer avoids selecting a hash join of a table unless there is no other execution plan available. |
| [`tidb_opt_objective`](/system-variables.md#tidb_opt_objective-new-in-v740) | Newly added | This variable controls the objective of the optimizer. `moderate` maintains the default behavior in versions prior to TiDB v7.4.0, where the optimizer tries to use more information to generate better execution plans. `determinate` mode tends to be more conservative and makes the execution plan more stable. |
| [`tidb_schema_version_cache_limit`](/system-variables.md#tidb_schema_version_cache_limit-new-in-v740) | Newly added | This variable limits how many historical schema versions can be cached in a TiDB instance. The default value is `16`, which means that TiDB caches 16 historical schema versions by default. |
| [`tidb_service_scope`](/system-variables.md#tidb_service_scope-new-in-v740) | Newly added | This variable is an instance-level system variable. You can use it to control the service scope of TiDB nodes under the [TiDB distributed execution framework](/tidb-distributed-execution-framework.md). When you set `tidb_service_scope` of a TiDB node to `background`, the TiDB distributed execution framework schedules that TiDB node to execute background tasks, such as [`ADD INDEX`](/sql-statements/sql-statement-add-index.md) and [`IMPORT INTO`](/sql-statements/sql-statement-import-into.md). |
| [`tidb_session_alias`](/system-variables.md#tidb_session_alias-new-in-v740) |  Newly added | Controls the value of the `session_alias` column in the logs related to the current session. |
| [`tiflash_mem_quota_query_per_node`](/system-variables.md#tiflash_mem_quota_query_per_node-new-in-v740) | Newly added | Limits the maximum memory usage for a query on a TiFlash node. When the memory usage of a query exceeds this limit, TiFlash returns an error and terminates the query. The default value is `0`, which means no limit.|
| [`tiflash_query_spill_ratio`](/system-variables.md#tiflash_query_spill_ratio-new-in-v740) | Newly added | Controls the threshold for TiFlash [query-level spilling](/tiflash/tiflash-spill-disk.md#query-level-spilling). The default value is `0.7`. |
| [`tikv_client_read_timeout`](/system-variables.md#tikv_client_read_timeout-new-in-v740) | Newly added | Controls the timeout for TiDB to send a TiKV RPC read request in a query. The default value `0` indicates that the default timeout (usually 40 seconds) is used. |

### Configuration file parameters

| Configuration file | Configuration parameter | Change type | Description |
| -------- | -------- | -------- | -------- |
| TiDB | [`enable-stats-cache-mem-quota`](/tidb-configuration-file.md#enable-stats-cache-mem-quota-new-in-v610) | Modified | The default value is changed from `false` to `true`, which means the memory limit for caching TiDB statistics is enabled by default. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].periodic-compaction-seconds</code>](/tikv-configuration-file.md#periodic-compaction-seconds-new-in-v720) | Modified | The default value is changed from `"30d"` to `"0s"` to disable periodic compaction of RocksDB by default. This change avoids a significant number of compactions being triggered after the TiDB upgrade, which affects the read and write performance of the frontend. |
| TiKV | [<code>rocksdb.\[defaultcf\|writecf\|lockcf\].ttl</code>](/tikv-configuration-file.md#ttl-new-in-v720) | Modified | The default value is changed from `"30d"` to `"0s"` so that SST files do not trigger compactions by default due to TTL, which avoids affecting the read and write performance of the frontend. |
| TiFlash | [`flash.compact_log_min_gap`](/tiflash/tiflash-configuration.md) | Newly added | When the gap between the `applied_index` advanced by the current Raft state machine and the `applied_index` at the last disk spilling exceeds `compact_log_min_gap`, TiFlash executes the `CompactLog` command from TiKV and spills data to disk. |
| TiFlash | [`profiles.default.enable_resource_control`](/tiflash/tiflash-configuration.md) | Newly added | Controls whether to enable the TiFlash resource control feature. |
| TiFlash | [`storage.format_version`](/tiflash/tiflash-configuration.md) | Modified | Change the default value from `4` to `5`. The new format can reduce the number of physical files by merging smaller files. |
| Dumpling  | [`--csv-line-terminator`](/dumpling-overview.md#option-list-of-dumpling) | Newly added | Specifies the desired terminator of CSV files . This option supports `"\r\n"` and `"\n"`. The default value is `"\r\n"`, which is consistent with the earlier versions. |
| TiCDC | [`claim-check-storage-uri`](/ticdc/ticdc-sink-to-kafka.md#send-large-messages-to-external-storage) | Newly added | When `large-message-handle-option` is set to `claim-check`, `claim-check-storage-uri` must be set to a valid external storage address. Otherwise, creating a changefeed results in an error. |
| TiCDC | [`large-message-handle-compression`](/ticdc/ticdc-sink-to-kafka.md#ticdc-data-compression) | Newly added | Controls whether to enable compression during encoding. The default value is empty, which means not enabled. |
| TiCDC | [`large-message-handle-option`](/ticdc/ticdc-sink-to-kafka.md#send-large-messages-to-external-storage) | Modified | This configuration item adds a new value `claim-check`. When it is set to `claim-check`, TiCDC Kafka sink supports sending the message to external storage when the message size exceeds the limit and sends a message to Kafka containing the address of this large message in external storage. |

## Deprecated features

+ [Mydumper](https://docs.pingcap.com/tidb/v4.0/mydumper-overview) will be deprecated in v7.5.0 and most of its features have been replaced by [Dumpling](/dumpling-overview.md). It is strongly recommended that you use Dumpling instead of mydumper.
+ TiKV-importer will be deprecated in v7.5.0. It is strongly recommended that you use the [Physical Import Mode of TiDB Lightning](/tidb-lightning/tidb-lightning-physical-import-mode.md) as an alternative.

## Improvements

+ TiDB

    - Optimize memory usage and performance for `ANALYZE` operations on partitioned tables [#47071](https://github.com/pingcap/tidb/issues/47071) [#47104](https://github.com/pingcap/tidb/issues/47104) [#46804](https://github.com/pingcap/tidb/issues/46804) @[hawkingrei](https://github.com/hawkingrei)
    - Optimize memory usage and performance for statistics garbage collection [#31778](https://github.com/pingcap/tidb/issues/31778) @[winoros](https://github.com/winoros)
    - Optimize the pushdown of `limit` for index merge intersections to improve query performance [#46863](https://github.com/pingcap/tidb/issues/46863) @[AilinKid](https://github.com/AilinKid)
    - Improve the cost model to minimize the chances of mistakenly choosing a full table scan when `IndexLookup` involves many table retrieval tasks [#45132](https://github.com/pingcap/tidb/issues/45132) @[qw4990](https://github.com/qw4990)
    - Optimize the join elimination rule to improve the query performance of `join on unique keys` [#46248](https://github.com/pingcap/tidb/issues/46248) @[fixdb](https://github.com/fixdb)
    - Change the collation of multi-valued index columns to `binary` to avoid execution failure [#46717](https://github.com/pingcap/tidb/issues/46717) @[YangKeao](https://github.com/YangKeao)

+ TiKV

    - Optimize memory usage of Resolver to prevent OOM [#15458](https://github.com/tikv/tikv/issues/15458) @[overvenus](https://github.com/overvenus)
    - Eliminate LRUCache in Router objects to reduce memory usage and prevent OOM [#15430](https://github.com/tikv/tikv/issues/15430) @[Connor1996](https://github.com/Connor1996)
    - Reduce memory usage of TiCDC Resolver [#15412](https://github.com/tikv/tikv/issues/15412) @[overvenus](https://github.com/overvenus)
    - Reduce memory fluctuations caused by RocksDB compaction [#15324](https://github.com/tikv/tikv/issues/15324) @[overvenus](https://github.com/overvenus)
    - Reduce memory consumption in the flow control module of Partitioned Raft KV [#15269](https://github.com/tikv/tikv/issues/15269) @[overvenus](https://github.com/overvenus)
    - Add the backoff mechanism for the PD client in the process of connection retries, which gradually increases retry intervals during error retries to reduce PD pressure [#15428](https://github.com/tikv/tikv/issues/15428) @[nolouch](https://github.com/nolouch)
    - Support dynamically adjusting `background_compaction` of RocksDB [#15424](https://github.com/tikv/tikv/issues/15424) @[glorv](https://github.com/glorv)

+ PD

    - Optimize TSO tracing information for easier investigation of TSO-related issues [#6856](https://github.com/tikv/pd/pull/6856) @[tiancaiamao](https://github.com/tiancaiamao)
    - Support reusing HTTP Client connections to reduce memory usage [#6913](https://github.com/tikv/pd/issues/6913) @[nolouch](https://github.com/nolouch)
    - Improve the speed of PD automatically updating cluster status when the backup cluster is disconnected [#6883](https://github.com/tikv/pd/issues/6883) @[disksing](https://github.com/disksing)
    - Enhance the configuration retrieval method of the resource control client to dynamically fetch the latest configurations [#7043](https://github.com/tikv/pd/issues/7043) @[nolouch](https://github.com/nolouch)

+ TiFlash

    - Improve write performance during random write workloads by optimizing the spilling policy of the TiFlash write process [#7564](https://github.com/pingcap/tiflash/issues/7564) @[CalvinNeo](https://github.com/CalvinNeo)
    - Add more metrics about the Raft replication process for TiFlash [#8068](https://github.com/pingcap/tiflash/issues/8068) @[CalvinNeo](https://github.com/CalvinNeo)
    - Reduce the number of small files to avoid potential exhaustion of file system inodes [#7595](https://github.com/pingcap/tiflash/issues/7595) @[hongyunyan](https://github.com/hongyunyan)

+ Tools

    + Backup & Restore (BR)

        - Alleviate the issue that the latency of the PITR log backup progress increases when Region leadership migration occurs [#13638](https://github.com/tikv/tikv/issues/13638) @[YuJuncen](https://github.com/YuJuncen)
        - Enhance support for connection reuse of log backup and PITR restore tasks by setting `MaxIdleConns` and `MaxIdleConnsPerHost` parameters in the HTTP client [#46011](https://github.com/pingcap/tidb/issues/46011) @[Leavrth](https://github.com/Leavrth)
        - Improve fault tolerance of BR when it fails to connect to PD or external S3 storage [#42909](https://github.com/pingcap/tidb/issues/42909) @[Leavrth](https://github.com/Leavrth)
        - Add a new restore parameter `WaitTiflashReady`. When this parameter is enabled, the restore operation will be completed after TiFlash replicas are successfully replicated [#43828](https://github.com/pingcap/tidb/issues/43828) [#46302](https://github.com/pingcap/tidb/issues/46302) @[3pointer](https://github.com/3pointer)
        - Reduce the CPU overhead of log backup `resolve lock` [#40759](https://github.com/pingcap/tidb/issues/40759) @[3pointer](https://github.com/3pointer)

    + TiCDC

        - Optimize the execution logic of replicating the `ADD INDEX` DDL operations to avoid blocking subsequent DML statements [#9644](https://github.com/pingcap/tiflow/issues/9644) @[sdojjy](https://github.com/sdojjy)

    + TiDB Lightning

        - Optimize the retry logic of TiDB Lightning during the Region scatter phase [#46203](https://github.com/pingcap/tidb/issues/46203) @[mittalrishabh](https://github.com/mittalrishabh)
        - Optimize the retry logic of TiDB Lightning for the `no leader` error during the data import phase [#46253](https://github.com/pingcap/tidb/issues/46253) @[lance6716](https://github.com/lance6716)

## Bug fixes

+ TiDB

    - Fix the issue that the `BatchPointGet` operator returns incorrect results for tables that are not hash partitioned [#45889](https://github.com/pingcap/tidb/issues/45889) @[Defined2014](https://github.com/Defined2014)
    - Fix the issue that the `BatchPointGet` operator returns incorrect results for hash partitioned tables [#46779](https://github.com/pingcap/tidb/issues/46779) @[jiyfhust](https://github.com/jiyfhust)
    - Fix the issue that the TiDB parser remains in a state and causes parsing failure [#45898](https://github.com/pingcap/tidb/issues/45898) @[qw4990](https://github.com/qw4990)
    - Fix the issue that `EXCHANGE PARTITION` does not check constraints [#45922](https://github.com/pingcap/tidb/issues/45922) @[mjonss](https://github.com/mjonss)
    - Fix the issue that the `tidb_enforce_mpp` system variable cannot be correctly restored [#46214](https://github.com/pingcap/tidb/issues/46214) @[djshow832](https://github.com/djshow832)
    - Fix the issue that the `_` in the `LIKE` clause is incorrectly handled [#46287](https://github.com/pingcap/tidb/issues/46287) [#46618](https://github.com/pingcap/tidb/issues/46618) @[Defined2014](https://github.com/Defined2014)
    - Fix the issue that the `schemaTs` is set to 0 when TiDB fails to obtain the schema [#46325](https://github.com/pingcap/tidb/issues/46325) @[hihihuhu](https://github.com/hihihuhu)
    - Fix the issue that `Duplicate entry` might occur when `AUTO_ID_CACHE=1` is set [#46444](https://github.com/pingcap/tidb/issues/46444) @[tiancaiamao](https://github.com/tiancaiamao)
    - Fix the issue that TiDB recovers slowly after a panic when `AUTO_ID_CACHE=1` is set [#46454](https://github.com/pingcap/tidb/issues/46454) @[tiancaiamao](https://github.com/tiancaiamao)
    - Fix the issue that the `next_row_id` in `SHOW CREATE TABLE` is incorrect when `AUTO_ID_CACHE=1` is set [#46545](https://github.com/pingcap/tidb/issues/46545) @[tiancaiamao](https://github.com/tiancaiamao)
    - Fix the panic issue that occurs during parsing when using CTE in subqueries [#45838](https://github.com/pingcap/tidb/issues/45838) @[djshow832](https://github.com/djshow832)
    - Fix the issue that restrictions on partitioned tables remain on the original table when `EXCHANGE PARTITION` fails or is canceled [#45920](https://github.com/pingcap/tidb/issues/45920) [#45791](https://github.com/pingcap/tidb/issues/45791) @[mjonss](https://github.com/mjonss)
    - Fix the issue that the definition of List partitions does not support using both `NULL` and empty strings [#45694](https://github.com/pingcap/tidb/issues/45694) @[mjonss](https://github.com/mjonss)
    - Fix the issue of not being able to detect data that does not comply with partition definitions during partition exchange [#46492](https://github.com/pingcap/tidb/issues/46492) @[mjonss](https://github.com/mjonss)
    - Fix the issue that the `tmp-storage-quota` configuration does not take effect [#45161](https://github.com/pingcap/tidb/issues/45161) [#26806](https://github.com/pingcap/tidb/issues/26806) @[wshwsh12](https://github.com/wshwsh12)
    - Fix the issue that the `WEIGHT_STRING()` function does not match the collation [#45725](https://github.com/pingcap/tidb/issues/45725) @[dveeden](https://github.com/dveeden)
    - Fix the issue that an error in Index Join might cause the query to get stuck [#45716](https://github.com/pingcap/tidb/issues/45716) @[wshwsh12](https://github.com/wshwsh12)
    - Fix the issue that the behavior is inconsistent with MySQL when comparing a `DATETIME` or `TIMESTAMP` column with a number constant [#38361](https://github.com/pingcap/tidb/issues/38361) @[yibin87](https://github.com/yibin87)
    - Fix the incorrect result that occurs when comparing unsigned types with `Duration` type constants [#45410](https://github.com/pingcap/tidb/issues/45410) @[wshwsh12](https://github.com/wshwsh12)
    - Fix the issue that access path pruning logic ignores the `READ_FROM_STORAGE(TIFLASH[...])` hint, which causes the `Can't find a proper physical plan` error [#40146](https://github.com/pingcap/tidb/issues/40146) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue that `GROUP_CONCAT` cannot parse the `ORDER BY` column [#41986](https://github.com/pingcap/tidb/issues/41986) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue that HashCode is repeatedly calculated for deeply nested expressions, which causes high memory usage and OOM [#42788](https://github.com/pingcap/tidb/issues/42788) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue that the `cast(col)=range` condition causes FullScan when CAST has no precision loss [#45199](https://github.com/pingcap/tidb/issues/45199) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue that when Aggregation is pushed down through Union in MPP execution plans, the results are incorrect [#45850](https://github.com/pingcap/tidb/issues/45850) @[AilinKid](https://github.com/AilinKid)
    - Fix the issue that bindings with `in (?)` cannot match `in (?, ... ?)` [#44298](https://github.com/pingcap/tidb/issues/44298) @[qw4990](https://github.com/qw4990)
    - Fix the error caused by not considering the connection collation when `non-prep plan cache` reuses the execution plan [#47008](https://github.com/pingcap/tidb/issues/47008) @[qw4990](https://github.com/qw4990)
    - Fix the issue that no warning is reported when an executed plan does not hit the plan cache [#46159](https://github.com/pingcap/tidb/issues/46159) @[qw4990](https://github.com/qw4990)
    - Fix the issue that `plan replayer dump explain` reports an error [#46197](https://github.com/pingcap/tidb/issues/46197) @[time-and-fate](https://github.com/time-and-fate)
    - Fix the issue that executing DML statements with CTE can cause panic [#46083](https://github.com/pingcap/tidb/issues/46083) @[winoros](https://github.com/winoros)
    - Fix the issue that the `TIDB_INLJ` hint does not take effect when joining two sub-queries [#46160](https://github.com/pingcap/tidb/issues/46160) @[qw4990](https://github.com/qw4990)
    - Fix the issue that the results of `MERGE_JOIN` are incorrect [#46580](https://github.com/pingcap/tidb/issues/46580) @[qw4990](https://github.com/qw4990)

+ TiKV

    - Fix the issue that TiKV fails to start when Titan is enabled and the `Blob file deleted twice` error occurs [#15454](https://github.com/tikv/tikv/issues/15454) @[Connor1996](https://github.com/Connor1996)
    - Fix the issue of no data in the Thread Voluntary and Thread Nonvoluntary monitoring panels [#15413](https://github.com/tikv/tikv/issues/15413) @[SpadeA-Tang](https://github.com/SpadeA-Tang)
    - Fix the data error of continuously increasing raftstore-applys [#15371](https://github.com/tikv/tikv/issues/15371) @[Connor1996](https://github.com/Connor1996)
    - Fix the TiKV panic issue caused by incorrect metadata of Region [#13311](https://github.com/tikv/tikv/issues/13311) @[zyguan](https://github.com/zyguan)
    - Fix the issue of QPS dropping to 0 after switching from `sync_recovery` to `sync` [#15366](https://github.com/tikv/tikv/issues/15366) @[nolouch](https://github.com/nolouch)
    - Fix the issue that Online Unsafe Recovery does not abort on timeout [#15346](https://github.com/tikv/tikv/issues/15346) @[Connor1996](https://github.com/Connor1996)
    - Fix the potential memory leak issue caused by CpuRecord [#15304](https://github.com/tikv/tikv/issues/15304) @[overvenus](https://github.com/overvenus)
    - Fix the issue that `"Error 9002: TiKV server timeout"` occurs when the backup cluster is down and the primary cluster is queried [#12914](https://github.com/tikv/tikv/issues/12914) @[Connor1996](https://github.com/Connor1996)
    - Fix the issue that the backup TiKV gets stuck when TiKV restarts after the primary cluster recovers [#12320](https://github.com/tikv/tikv/issues/12320) @[disksing](https://github.com/disksing)

+ PD

    - Fix the issue that the Region information is not updated and saved during Flashback [#6912](https://github.com/tikv/pd/issues/6912) @[overvenus](https://github.com/overvenus)
    - Fix the issue of slow switching of PD Leaders due to slow synchronization of store config [#6918](https://github.com/tikv/pd/issues/6918) @[bufferflies](https://github.com/bufferflies)
    - Fix the issue that the groups are not considered in Scatter Peers [#6962](https://github.com/tikv/pd/issues/6962) @[bufferflies](https://github.com/bufferflies)
    - Fix the issue that RU consumption less than 0 causes PD to crash [#6973](https://github.com/tikv/pd/issues/6973) @[CabinfeverB](https://github.com/CabinfeverB)
    - Fix the issue that modified isolation levels are not synchronized to the default placement rules [#7121](https://github.com/tikv/pd/issues/7121) @[rleungx](https://github.com/rleungx)
    - Fix the issue that the client-go regularly updating `min-resolved-ts` might cause PD OOM when the cluster is large [#46664](https://github.com/pingcap/tidb/issues/46664) @[HuSharp](https://github.com/HuSharp)

+ TiFlash

    - Fix the issue that the `max_snapshot_lifetime` metric is displayed incorrectly on Grafana [#7713](https://github.com/pingcap/tiflash/issues/7713) @[JaySon-Huang](https://github.com/JaySon-Huang)
    - Fix the issue that some metrics about the maximum duration are not correct [#8076](https://github.com/pingcap/tiflash/issues/8076) @[CalvinNeo](https://github.com/CalvinNeo)
    - Fix the issue that TiDB incorrectly reports that an MPP task has failed [#7177](https://github.com/pingcap/tiflash/issues/7177) @[yibin87](https://github.com/yibin87)

+ Tools

    + Backup & Restore (BR)

        - Fix an issue that the misleading error message `resolve lock timeout` covers up the actual error when backup fails [#43236](https://github.com/pingcap/tidb/issues/43236) @[YuJuncen](https://github.com/YuJuncen)
        - Fix the issue that recovering implicit primary keys using PITR might cause conflicts [#46520](https://github.com/pingcap/tidb/issues/46520) @[3pointer](https://github.com/3pointer)
        - Fix the issue that recovering meta-kv using PITR might cause errors [#46578](https://github.com/pingcap/tidb/issues/46578) @[Leavrth](https://github.com/Leavrth)
        - Fix the errors in BR integration test cases [#45561](https://github.com/pingcap/tidb/issues/46561) @[purelind](https://github.com/purelind)

    + TiCDC

        - Fix the issue that TiCDC accesses the invalid old address during PD scaling up and down [#9584](https://github.com/pingcap/tiflow/issues/9584) @[fubinzh](https://github.com/fubinzh) @[asddongmen](https://github.com/asddongmen)
        - Fix the issue that changefeed fails in some scenarios [#9309](https://github.com/pingcap/tiflow/issues/9309) [#9450](https://github.com/pingcap/tiflow/issues/9450) [#9542](https://github.com/pingcap/tiflow/issues/9542) [#9685](https://github.com/pingcap/tiflow/issues/9685) @[hicqu](https://github.com/hicqu) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - Fix the issue that replication write conflicts might occur when the unique keys for multiple rows are modified in one transaction on the upstream [#9430](https://github.com/pingcap/tiflow/issues/9430) @[sdojjy](https://github.com/sdojjy)
        - Fix the issue that a replication error occurs when multiple tables are renamed in the same DDL statement on the upstream [#9476](https://github.com/pingcap/tiflow/issues/9476) [#9488](https://github.com/pingcap/tiflow/issues/9488) @[CharlesCheung96](https://github.com/CharlesCheung96) @[asddongmen](https://github.com/asddongmen)
        - Fix the issue that Chinese characters are not validated in CSV files [#9609](https://github.com/pingcap/tiflow/issues/9609) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - Fix the issue that upstream TiDB GC is blocked after all changefeeds are removed [#9633](https://github.com/pingcap/tiflow/issues/9633) @[sdojjy](https://github.com/sdojjy)
        - Fix the issue of uneven distribution of write keys among nodes when `scale-out` is enabled [#9665](https://github.com/pingcap/tiflow/issues/9665) @[sdojjy](https://github.com/sdojjy)
        - Fix the issue that sensitive user information is recorded in the logs [#9690](https://github.com/pingcap/tiflow/issues/9690) @[sdojjy](https://github.com/sdojjy)

    + TiDB Data Migration (DM)

        - Fix the issue that DM cannot handle conflicts correctly with case-insensitive collations [#9489](https://github.com/pingcap/tiflow/issues/9489) @[hihihuhu](https://github.com/hihihuhu)
        - Fix the DM validator deadlock issue and enhance retries [#9257](https://github.com/pingcap/tiflow/issues/9257) @[D3Hunter](https://github.com/D3Hunter)
        - Fix the issue that replication lag returned by DM keeps growing when a failed DDL is skipped and no subsequent DDLs are executed [#9605](https://github.com/pingcap/tiflow/issues/9605) @[D3Hunter](https://github.com/D3Hunter)
        - Fix the issue that DM cannot properly track upstream table schemas when skipping online DDLs [#9587](https://github.com/pingcap/tiflow/issues/9587) @[GMHDBJD](https://github.com/GMHDBJD)
        - Fix the issue that DM skips all DMLs when resuming a task in optimistic mode [#9588](https://github.com/pingcap/tiflow/issues/9588) @[GMHDBJD](https://github.com/GMHDBJD)
        - Fix the issue that DM skips partition DDLs in optimistic mode [#9788](https://github.com/pingcap/tiflow/issues/9788) @[GMHDBJD](https://github.com/GMHDBJD)

    + TiDB Lightning

        - Fix the issue that inserting data returns an error after TiDB Lightning imports the `NONCLUSTERED auto_increment` and `AUTO_ID_CACHE=1` tables [#46100](https://github.com/pingcap/tidb/issues/46100) @[tiancaiamao](https://github.com/tiancaiamao)
        - Fix the issue that checksum still reports errors when `checksum = "optional"` [#45382](https://github.com/pingcap/tidb/issues/45382) @[lyzx2001](https://github.com/lyzx2001)
        - Fix the issue that data import fails when the PD cluster address changes [#43436](https://github.com/pingcap/tidb/issues/43436) @[lichunzhu](https://github.com/lichunzhu)

## Contributors

We would like to thank the following contributors from the TiDB community:

- [aidendou](https://github.com/aidendou)
- [coderplay](https://github.com/coderplay)
- [fatelei](https://github.com/fatelei)
- [highpon](https://github.com/highpon)
- [hihihuhu](https://github.com/hihihuhu) (First-time contributor)
- [isabella0428](https://github.com/isabella0428)
- [jiyfhust](https://github.com/jiyfhust)
- [JK1Zhang](https://github.com/JK1Zhang)
- [joker53-1](https://github.com/joker53-1) (First-time contributor)
- [L-maple](https://github.com/L-maple)
- [mittalrishabh](https://github.com/mittalrishabh)
- [paveyry](https://github.com/paveyry)
- [shawn0915](https://github.com/shawn0915)
- [tedyu](https://github.com/tedyu)
- [yumchina](https://github.com/yumchina)
- [ZhuohaoHe](https://github.com/ZhuohaoHe)
