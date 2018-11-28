-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


set echo off

DEFINE tblOwner=&1.
DEFINE tblName=&2.
DEFINE tbsName=&3.


set heading off
set pagesize 0
set verify off

select 'alter index ' || OWNER || '.' || INDEX_NAME || ' rebuild tablespace &tbsName.;'
	from DBA_INDEXES
	where TABLE_OWNER='&tblOwner.'
		and TABLE_NAME='&tblName.';

set verify on
set pagesize 25
set heading on

set echo on


