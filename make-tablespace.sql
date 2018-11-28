-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


-- Set up variables
DEFINE TbsNm=&1.
DEFINE TbsSz=&2.
DEFINE dataFile=&3.
DEFINE TbsExtSz=&4.
DEFINE SgmtSpcMgt=&5.

-- Make tablespace
CREATE BIGFILE TABLESPACE &TbsNm.
        LOGGING
        DATAFILE '&dataFile.'
        SIZE &TbsSz. REUSE
        extent management local uniform size &TbsExtSz.
        segment space management &SgmtSpcMgt.;


