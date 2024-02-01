-- 묵시적 형변환
explain plan for
SELECT round(avg(SAL)) avg_sal 
	 , max(sal) max_sal
	 , min(sal) min_sal 
	 , max(decode(job, 'PRESIDENT', NULL, sal)) max_sal2
FROM EMP;

SELECT round(avg(SAL)) avg_sal 
	 , max(sal) max_sal
	 , min(sal) min_sal 
	 , max(decode(job, 'PRESIDENT', TO_NUMBER(NULL), sal)) max_sal2
FROM EMP;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- 함수기반 인덱스(FBI)
ALTER TABLE emp ADD v_deptno varchar2(2);

UPDATE emp SET v_deptno = deptno;

CREATE INDEX emp_x01 ON emp(v_deptno);

explain plan for
SELECT /*+ index(emp emp_x01) */ * FROM emp WHERE v_deptno = 20;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

DROP INDEX emp_x01; 

CREATE INDEX emp_x01 ON emp(to_number(v_deptno)); -- 함수기반 인덱스 생성 


-- Index Range Scan
CREATE INDEX emp_deptno_idx ON emp(deptno);

explain plan FOR
SELECT * FROM emp WHERE deptno = 20;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- Index Full Scan 
CREATE INDEX emp_idx ON emp (ename, sal);

explain plan for
SELECT /*+ index(emp emp_idx) */ * FROM emp WHERE sal > 2000;

-- 인덱스를 이용한 소트 연산 대체
explain plan for
SELECT /*+ first_rows */ * FROM emp 
WHERE sal > 1000
ORDER BY ename;


-- Index Unique Scan 
explain plan for
SELECT empno, ename FROM emp WHERE empno = 7788;


-- Index Skip Scan (index_ss, no_index_ss)
-- select /*+ index_ss(사원 사원_IDX) */ * 
-- from 사원
-- where 연봉 between 2000 and 4000; 


-- Index Fast Full Scan (index_ffs, no_index_ffs)
-- 쿼리에 사용되는 모든 컬럼이 인덱스 컬럼에 포함돼 있을 때만 사용 가능. 
-- select /*+ ordered use_nl(b) no_merge(b) rowid(b) */ b.*
-- from (select /*+ index_fss(공급업체 공급업체_X01) */ rowid rid
--       from 공급업체
--       where instr(업체명, '네트웍스') > 0) a, 공급업체 b
-- where b.rowid = rid;


-- Index Range Scan Descending 
explain plan for
SELECT * FROM emp 
WHERE empno > 0
ORDER BY empno DESC;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

CREATE INDEX emp_x02 ON emp (deptno, sal);

explain plan for
SELECT deptno, dname, loc 
	 , (SELECT max(sal) FROM emp WHERE deptno = d.deptno)
FROM dept d;

explain plan for
SELECT deptno, dname, loc
	 , (SELECT /*+ index_desc(emp emp_x02) */ sal 
	 	FROM emp 
	 	WHERE deptno = d.deptno 
	 	AND rownum <= 1)
FROM dept d;


-- And-Equal 
-- CREATE INDEX emp_deptno_idx ON emp(deptno);
CREATE INDEX emp_job_idx ON emp (job);

explain plan for
SELECT /*+ and_equal(e emp_deptno_idx emp_job_idx) */ *
FROM emp e 
WHERE deptno = 30
AND job = 'SALESMAN';

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- Index Combine 
explain plan for
SELECT /*+ index_combine(e emp_deptno_idx emp_job_idx) */ *
FROM emp e 
WHERE deptno = 30
AND job = 'SALESMAN';

explain plan for
SELECT /*+ index_combine(e emp_deptno_idx emp_job_idx) */ *
FROM emp e 
WHERE deptno = 30 OR job = 'SALESMAN';

SELECT * 
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- Index Join 
explain plan for
SELECT /*+ index_join(e EMP_DEPTNO_IDX EMP_JOB_IDX) */ deptno, job 
FROM emp e 
WHERE deptno = 30 
AND job = 'SALESMAN';


-- 클러스터링 팩터 
--SQL> create table t 
--  2  as 
--  3  select * from all_objects
--  4  order by object_id;
--
--Table created.
--
--SQL> SQL> select count(*) from t;
--
--  COUNT(*)
------------
--     17782
--
--SQL> create index t_object_idx on t(object_id);
--
--Index created.
--
--SQL> create index t_object_name_idx on t(object_name);
--
--Index created.
--
--SQL> exec dbms_stats.gather_table_stats(user, 'T');
--
--PL/SQL procedure successfully completed.
--
--SQL> select i.index_name, t.blocks table_blocks, i.num_rows, i.clustering_factor
--  2  from user_tables t, user_indexes i
--  3  where t.table_name = 'T'
--  4  and i.table_name = t.table_name;
--
--INDEX_NAME		       TABLE_BLOCKS   NUM_ROWS CLUSTERING_FACTOR
-------------------------------- ------------ ---------- -----------------
--T_OBJECT_NAME_IDX			237	 17782		    7883
--T_OBJECT_IDX				237	 17782		     237

--SQL> set autotrace traceonly explain 
--SQL> select /*+ index(t t_object_idx) */ count(*) from t 
--  2  where object_name >= ' '
--  3  and object_id > 0;
--
--Execution Plan
------------------------------------------------------------
--Plan hash value: 2009120224
--
-----------------------------------------------------------------------------------------------
--| Id  | Operation		   	  			| Name	    	| Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
--|   0 | SELECT STATEMENT	     		|		   		|	  1 |	 25 |	278   (1)| 00:00:04 |
--|   1 |  SORT AGGREGATE 	     		|		   	 	|	  1 |	 25 |			 |		    |
--|*  2 |   TABLE ACCESS BY INDEX ROWID	| T	 		   	| 17782 |	434K|	278   (1)| 00:00:04 |
--|*  3 |    INDEX RANGE SCAN	     	| T_OBJECT_IDX 	| 17782 |	    |	 40   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------
--
--Predicate Information (identified by operation id):
-----------------------------------------------------
--   2 - filter("OBJECT_NAME">=' ')
--   3 - access("OBJECT_ID">0)

--SQL> set autotrace traceonly explain
--SQL> select /*+ index(t t_object_name_idx) */ count(*) from t 
--  2  where object_name >= ' '
--  3  and object_id >= 0; 
--
--Execution Plan
------------------------------------------------------------
--Plan hash value: 843348828
--
----------------------------------------------------------------------------------------------------
--
--| Id  | Operation		     			| Name		 		| Rows  | Bytes | Cost(%CPU)| Time	 |
----------------------------------------------------------------------------------------------------
--|   0 | SELECT STATEMENT	     		|			 		|     1 |    25 |  7965(1)| 00:01:36 |
--|   1 |  SORT AGGREGATE 	     		|			 		|     1 |    25 |  	   	  | 	 	 |
--|*  2 |   TABLE ACCESS BY INDEX ROWID	| T				 	| 17782 |   434K|  7965(1)| 00:01:36 |
--|*  3 |    INDEX RANGE SCAN	     	| T_OBJECT_NAME_IDX | 17782 |	 	|    76(0)| 00:00:01 |
----------------------------------------------------------------------------------------------------
--
--Predicate Information (identified by operation id):
-----------------------------------------------------
--   2 - filter("OBJECT_ID">=0)
--   3 - access("OBJECT_NAME">=' ')

CREATE TABLE good_cl_factor
PCTFREE 0 
AS 
SELECT t.*, LPAD('x', 630) x FROM SYSTEM.T  
ORDER BY object_id;

CREATE TABLE bad_cl_factor
PCTFREE 0 
AS 
SELECT t.*, LPAD('x', 630) x FROM SYSTEM.T  
ORDER BY dbms_random.value;

SELECT table_name, num_rows, blocks, avg_row_len, num_rows/blocks row_per_block
FROM user_tables
WHERE table_name IN ('GOOD_CL_FACTOR', 'BAD_CL_FACTOR');


-- PK 인덱스에 컬럼 추가 
explain plan for
SELECT /*+ ordered use_nl(d) */ *
FROM emp e, dept d 
WHERE d.deptno = d.deptno 
AND d.loc = 'NEW YORK';

SELECT * 
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

CREATE INDEX dept_x01 ON dept(deptno, loc);

explain plan for
SELECT /*+ ordered use_nl(b) rowid(b) */ b.*
FROM (
		SELECT /*+ index(emp emp_pk) no_merge */ rowid rid 
		FROM emp 
		ORDER BY rowid) a, emp b 
WHERE b.rowid = a.rid;


--SQL> create cluster c_deptno# (deptno number(2)) index;
--
--Cluster created.
--
--SQL> create index i_deptno# on cluster c_deptno#;
--
--Index created.
--
--SQL> create table cemp
--  2  cluster c_deptno# (deptno)
--  3  as 
--  4  select * from sqlp.emp;
--
--Table created.
--
--SQL> create table cdept
--  2  cluster c_deptno# (deptno)
--  3  as
--  4  select * from sqlp.dept;
--
--Table created.
--
--SQL> select owner, table_name from dba_tables where cluster_name = 'C_DEPTNO#';
--
--OWNER			       TABLE_NAME
-------------------------------- ------------------------------
--SYSTEM			       CDEPT
--SYSTEM			       CEMP

--SQL> break on deptno skip 1
--SQL> select d.deptno, e.empno, e.ename
--  2  , dbms_rowid.rowid_block_number(d.rowid) dept_block_no
--  3  , dbms_rowid.rowid_block_number(e.rowid) emp_block_no
--  4  from dept d, emp e
--  5  where e.deptno = d.deptno
--  6  order by d.deptno;
--
--    DEPTNO	EMPNO ENAME	 DEPT_BLOCK_NO EMP_BLOCK_NO
------------ ---------- ---------- ------------- ------------
--	10	 7782 CLARK		 45041	      45185
--		 7839 KING		 45041	      45185
--		 7934 MILLER		 45041	      45185
--
--	20	 7566 JONES		 45041	      45185
--		 7902 FORD		 45041	      45185
--		 7876 ADAMS		 45041	      45185
--		 7369 SMITH		 45041	      45185
--		 7788 SCOTT		 45041	      45185
--
--	30	 7521 WARD		 45041	      45185
--
--    DEPTNO	EMPNO ENAME	 DEPT_BLOCK_NO EMP_BLOCK_NO
------------ ---------- ---------- ------------- ------------
--	30	 7844 TURNER		 45041	      45185
--		 7499 ALLEN		 45041	      45185
--		 7900 JAMES		 45041	      45185
--		 7698 BLAKE		 45041	      45185
--		 7654 MARTIN		 45041	      45185
--
--
--14 rows selected.
