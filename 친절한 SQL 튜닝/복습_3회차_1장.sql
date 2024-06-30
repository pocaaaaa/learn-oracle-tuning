-- 1.1 SQL 파싱과 최적화
explain plan for  
SELECT * 
FROM emp e, dept d 
WHERE e.deptno = d.deptno;

SELECT * FROM TABLE(dbms_xplan.display(NULL, NULL, 'ALL'));

CREATE TABLE t 
AS 
SELECT d.NO, e.* 
FROM emp e, (SELECT rownum NO FROM dual CONNECT BY LEVEL <= 1000) d; 

SELECT * FROM t;

CREATE INDEX t_x01 ON t(deptno, no);
CREATE INDEX t_x02 ON t(deptno, job, no);

-- 실행계획 
SQL> exec dbms_stats.gather_table_stats(user, 't');

PL/SQL procedure successfully completed.

SQL> set autotrace traceonly exp;
SQL> select * from t 
  2  where deptno = 10
  3  and no = 1;

Execution Plan
----------------------------------------------------------
Plan hash value: 481254278

-------------------------------------------------------------------------------------
| Id  | Operation		    		| Name  | Rows  | Bytes | Cost (%CPU)| Time		|
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|	    |	  5 |	210 |	  2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| T     |	  5 |	210 |	  2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN	    	| T_X01 |	  5 |	    |	  1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------
   2 - access("DEPTNO"=10 AND "NO"=1)

   
SQL> select /*+ index(t t_x02) */ * from t 
  2  where deptno = 10
  3  and no = 1;

Execution Plan
----------------------------------------------------------
Plan hash value: 3077781317

-------------------------------------------------------------------------------------
| Id  | Operation		    		| Name  | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|	    |	  3 |	126 |	  7   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| T     |	  3 |	126 |	  7   (0)| 00:00:01 |
|*  2 |   INDEX SKIP SCAN	    	| T_X02 |	  3 |	    |	  6   (0)| 00:00:01 |
-------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("DEPTNO"=10 AND "NO"=1)
       filter("NO"=1)
       
SQL> select /*+ full(t) */ * from t 
  2  where deptno = 10
  3  and no = 1;

Execution Plan
----------------------------------------------------------
Plan hash value: 1601196873

--------------------------------------------------------------------------
| Id  | Operation	  		| Name 	| Rows  | Bytes | Cost (%CPU)| Time	 |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  	|	 	|     3 |   126 |    27   (4)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL	| T	 	|     3 |   126 |    27   (4)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("NO"=1 AND "DEPTNO"=10)
   

   
-- ========================================================================================
-- ========================================================================================
-- 1.2 SQL 공유 및 재사용 
SELECT * FROM v$sql;


-- ========================================================================================
-- ========================================================================================
-- 1.3 데이터 저장 구조 및 I/O 메커니즘 
SELECT segment_name, segment_type, tablespace_name, extent_id, file_id, block_id, blocks
FROM dba_extents 
WHERE owner = USER 
-- AND segment_name = ''
ORDER BY extent_id;

SELECT value FROM v$parameter WHERE name = 'db_block_size';

SELECT * FROM v$sga;