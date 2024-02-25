-- 3-1장. SQL 수행 구조 
SELECT * FROM t;

SELECT * FROM table(dbms_xplan.display);

explain plan FOR 
SELECT * FROM t 
WHERE deptno = 10
AND NO = 1;

explain plan FOR 
SELECT /*+ index(t t_x02) */ * FROM t 
WHERE deptno = 10
AND NO = 1;

explain plan FOR 
SELECT /*+ full(t) */ * FROM t 
WHERE deptno = 10 
AND NO = 1;