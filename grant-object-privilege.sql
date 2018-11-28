-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


set echo on

DEFINE priv='&1.'
DEFINE owner='&2.'
DEFINE obj='&3.'
DEFINE tgt='&4.'

GRANT &priv. ON &owner..&obj. TO &tgt.;


