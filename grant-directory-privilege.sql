-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


set echo on

DEFINE priv='&1.'
DEFINE obj='&2.'
DEFINE tgt='&3.'

GRANT &priv. ON DIRECTORY &obj. TO &tgt.;


