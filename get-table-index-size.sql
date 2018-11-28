-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


SET VERIFY OFF

DEFINE tgtOwner=&1.
DEFINE tgtTbl=&2.

SELECT SUM(seg.BYTES/(1024*1024)) MB, SUM(seg.extents) EXTS, COUNT(seg.SEGMENT_NAME) NUM_IDXS
	FROM DBA_SEGMENTS seg, DBA_INDEXES idx
	WHERE idx.TABLE_NAME='&tgtTbl.'
		AND idx.TABLE_OWNER='&tgtOwner.'
		AND seg.SEGMENT_TYPE='INDEX'
		AND idx.OWNER=seg.OWNER
		AND idx.INDEX_NAME=seg.SEGMENT_NAME
;

SET VERIFY ON


