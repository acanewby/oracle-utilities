-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


SET VERIFY OFF

DEFINE tgtOwner=&1.
DEFINE tgtTbl=&2.

SELECT SUM(BYTES/(1024*1024)) MB, SUM(extents) EXTS
	FROM DBA_SEGMENTS
	WHERE OWNER='&tgtOwner.'
		AND SEGMENT_NAME='&tgtTbl.'
		AND SEGMENT_TYPE='TABLE'
;

SET VERIFY ON

-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================
