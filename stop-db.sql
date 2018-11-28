-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================


DEFINE sysPwd=&1.
connect sys/&sysPwd. as sysdba
shutdown immediate
exit
/


