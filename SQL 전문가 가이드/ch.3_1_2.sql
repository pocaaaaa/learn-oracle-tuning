CREATE TABLE T
AS 
SELECT D.NO, E.*
FROM EMP E
	,(SELECT ROWNUM NO FROM DUAL CONNECT BY LEVEL <= 1000) D;
	
SELECT * FROM T;

CREATE INDEX T_X01 ON T(DEPTNO, NO);
CREATE INDEX T_X02 ON T(DEPTNO, JOB, NO);

-- T 테이블에 통계정보를 수집하는 Oracle 명령어 
-- EXEC dbms_stats.gather_table_stats(USER, 'T');

CREATE TABLE T1 
AS 
SELECT * FROM ALL_OBJECTS 
ORDER BY DBMS_RANDOM.VALUE;

-- 23,950 
SELECT count(*) FROM t1;

-- 13,497 
SELECT count(*) FROM T1 WHERE owner LIKE 'SYS%';

SELECT count(*) FROM T1 
WHERE OWNER LIKE 'SYS%'
AND OBJECT_NAME = 'ALL_OBJECTS';

CREATE INDEX T1_IDX ON T1(OWNER, OBJECT_NAME);
CREATE INDEX T1_IDX2 ON T1(OBJECT_NAME, OWNER);

DROP INDEX T1_IDX;
DROP INDEX T1_IDX2;

CREATE INDEX T1_IDX ON T1(OWNER);
DROP INDEX T1_IDX;

ALTER TABLE T1 ADD 
CONSTRAINT T1_PK PRIMARY KEY(OBJECT_ID);


-- ==================================================================
-- ==================================================================
explain plan SET statement_id = 'query1' FOR 
SELECT * FROM emp WHERE empno = 7900;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table','query1', 'ALL'));

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'serial'));

SELECT /*+ gather_plan_statistics */ * FROM emp WHERE empno = 7900;

SELECT *
FROM table(dbms_xplan.display_cursor(NULL, NULL, 'ALLSTATS'));