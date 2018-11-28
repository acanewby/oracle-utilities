-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


DEFINE lgObjSz=512

set linesize 255
set pagesize 30
set echo on
set serveroutput on

spool db-health-check.out

column tablespace_name format a30
column segment_type format a15
column segment_name format a30
column owner format a15
column file_name format a60
column name format a40
column value format a50
column description format a70
column DIRECTORY_NAME format a25
column DIRECTORY_PATH format a64
column MB format a30


-- DB name
select name
from v$database;

-- Data collection date
select sysdate 
from dual;

-- Tablespace summary
select f.tablespace_name, t.block_size, t.initial_extent, t.next_extent, t.SEGMENT_SPACE_MANAGEMENT, t.extent_management, t.allocation_type, sum(f.bytes/(1024*1024)) mb  
from dba_data_files f, dba_tablespaces t 
where t.tablespace_name = f.tablespace_name 
group by f.tablespace_name, t.block_size, t.initial_extent, t.next_extent, t.SEGMENT_SPACE_MANAGEMENT, t.extent_management, t.allocation_type
order by f.tablespace_name;


-- Identify data files
select tablespace_name, file_name, bytes/(1024*1024) MB, autoextensible, increment_by
from dba_data_files
union all
select tablespace_name, file_name, bytes/(1024*1024) MB, autoextensible, increment_by
from dba_temp_files
order by tablespace_name, file_name;

-- Summary segment space usage - by owner, by tablespace
select owner, tablespace_name, segment_type, to_char(sum(bytes/(1024*1024)),'999,999,999') MB
        from dba_segments
        where owner IN (select owner from dba_tables where table_name = 'AVM_INFO_MAIN' )
        group by owner, tablespace_name, segment_type
        order by owner, tablespace_name, segment_type;

-- Summary segment space usage - by owner, by segment_type
select owner, segment_type, tablespace_name, to_char(sum(bytes/(1024*1024)),'999,999,999') MB
        from dba_segments
        where owner IN (select owner from dba_tables where table_name = 'AVM_INFO_MAIN' )
        group by owner, segment_type, tablespace_name
        order by owner, segment_type, tablespace_name;

-- Directories
select DIRECTORY_NAME, DIRECTORY_PATH
	from dba_directories
	order by DIRECTORY_NAME;


-- Assess object segments
select owner, segment_type, 
	tablespace_name,  to_char(sum (bytes/(1024*1024)),'9,999,999')  MB
from dba_segments
group by owner, segment_type, tablespace_name
order by owner, segment_type, tablespace_name;

-- File I/O
select df.file_name, fs.*,
	to_char(((SINGLEBLKRDS)/(PHYRDS))*100,'999.999') || '%' pc_sng_rds,
	to_char(((PHYBLKRD-SINGLEBLKRDS)/(PHYRDS-SINGLEBLKRDS)),'999,999.999')  blks_per_mb_rd
from dba_data_files df, v$filestat fs
where df.file_id=fs.file#
order by file_name;


-- Large objects
select owner, segment_type, segment_name,  extents, to_char(bytes/(1024*1024),'9,999,999')  MB
from dba_segments
where bytes > (&lgObjSz.*1024*1024)
order by owner, bytes desc;

-- Key table locations
select tablespace_name, owner, table_name
from dba_tables
where table_name in ('AVM_INFO_MAIN','AVM_SALEHISTORY')
order by tablespace_name, owner, table_name;

-- Key table sizes
select owner, segment_type, segment_name,  extents, to_char(bytes/(1024*1024),'9,999,999')  MB
from dba_segments
where segment_name in ('AVM_INFO_MAIN','AVM_SALEHISTORY')
and segment_type IN ('TABLE', 'TABLE PARTITION')
order by owner, segment_name, bytes desc;

-- Key table row volumes
declare
	rowCount	NUMBER;	 
begin
	for tbl in (select owner, table_name 
		from dba_tables 
		where table_name IN ('AVM_INFO_MAIN','AVM_SALEHISTORY')
		order by owner, table_name)
	loop
		execute immediate 'SELECT COUNT(OBJECTID) FROM ' || tbl.owner || '.' || tbl.table_name
			into rowCount;
		dbms_output.put_line(RPAD(tbl.owner,12) || RPAD(tbl.table_name,30) || ' [' || to_char(rowCount,'999,999,999') || ']');
		
	end loop;

end;
/




-- Aggregate size, count and locations for index of key tables
select ind.table_owner, ind.table_name, ind.tablespace_name, count(*) num_indexes, to_char(sum(bytes/(1024*1024)),'999,999') index_MB
from dba_indexes ind, dba_segments seg
where ind.owner=seg.owner
	and ind.index_name=seg.segment_name
	and seg.segment_type='INDEX'
	and ind.table_name in ('AVM_INFO_MAIN','AVM_SALEHISTORY')
group by ind.table_owner, ind.table_name, ind.tablespace_name
order by ind.table_owner, ind.table_name, ind.tablespace_name;


-- Trigger check (summary)
select status, count(*)
	from dba_triggers
	where owner in ( select owner from dba_tables where table_name='AVM_INFO_MAIN')
	group by status;

-- Trigger check (detail)
select owner, trigger_name, trigger_type, status
	from dba_triggers
	where owner in ( select owner from dba_tables where table_name='AVM_INFO_MAIN');


-- Library Cache hits
SELECT namespace, pins, pinhits, reloads, invalidations  
FROM V$LIBRARYCACHE 
ORDER BY namespace;


-- SGA target advice
select *
from v$SGA_TARGET_ADVICE
order by SGA_SIZE_FACTOR;

-- Shared pool advice
select *
from V$SHARED_POOL_ADVICE 
order by SHARED_POOL_SIZE_FACTOR;

-- SGA summary
SELECT pool, to_char(sum(bytes/(1024*1024)),'9,999,999.999') mb 
FROM V$SGASTAT 
GROUP by pool
ORDER by pool;



-- Buffer cache hit ratio
SELECT NAME, PHYSICAL_READS, 
	DB_BLOCK_GETS, CONSISTENT_GETS, 
	to_char(100*(1 - (PHYSICAL_READS / (DB_BLOCK_GETS + CONSISTENT_GETS))),'99.999') || '%' Hit_Ratio 
FROM V$BUFFER_POOL_STATISTICS;

-- DB Cache advice
SELECT SIZE_FOR_ESTIMATE, SIZE_FACTOR, BUFFERS_FOR_ESTIMATE, ESTD_PHYSICAL_READ_FACTOR,
		ESTD_PHYSICAL_READS, ESTD_PHYSICAL_READ_TIME, ESTD_PCT_OF_DB_TIME_FOR_READS, ESTD_CLUSTER_READS
FROM V$DB_CACHE_ADVICE 
WHERE name = 'DEFAULT' 
	AND block_size = (
		SELECT value FROM V$PARAMETER 
		WHERE name = 'db_block_size') 
	AND advice_status = 'ON';

	
-- PGA advice
SELECT *
from v$pga_target_advice
order by PGA_TARGET_FACTOR;

	
-- Current session info
SELECT sid,username,machine,terminal,type, state
FROM V$SESSION 
ORDER BY sid;	

-- Init parameters
select name, value, isdefault, ismodified, description 
from v$parameter 
order by name;

-- Init parameters
select 'Modified parameters' mods, name, value, description 
from v$parameter 
where isdefault='FALSE'
order by name;



-- Instance state
select * 
from v$instance;


spool off


