-- 부록 
--  1. 실행계획 확인 
SELECT owner, synonym_name, table_owner, table_name 
FROM all_synonyms 
WHERE SYNONYM_NAME = 'PLAN_TABLE';

-- SQL*Plus 에서 실행계획 확인 
-- explain plan 명령어를 수행하면 SQL 실행계획이 plan_table에 저장 
SQL> explain plan for
  2  select * from emp where empno = 7900;

Explained.

SQL>set linesize 200
SQL> @?/rdbms/admin/utlxpls

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Plan hash value: 4120447789

--------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name	   		| Rows  | Bytes | Cost (%CPU)| Time	   |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|		   		|	 1 |	38 |	 1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP	 	  	|	 1 |	38 |	 1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 |	   |	 0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------

2 - access("EMPNO"=7900)

14 rows selected.


SQL> select * from table(dbms_xplan.display(null, null, 'advanced'));

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Plan hash value: 4120447789

--------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name	   		| Rows  | Bytes | Cost (%CPU)| Time	   |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|		   		|	 1 |	38 |	 1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP	   		|	 1 |	38 |	 1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 |	   |	 0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------

Query Block Name / Object Alias (identified by operation id):

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------

   1 - SEL$1 / EMP@SEL$1
   2 - SEL$1 / EMP@SEL$1

Outline Data
-------------

  /*+
      BEGIN_OUTLINE_DATA
      INDEX_RS_ASC(@"SEL$1" "EMP"@"SEL$1" ("EMP"."EMPNO"))

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      OUTLINE_LEAF(@"SEL$1")
      ALL_ROWS
      DB_VERSION('11.2.0.2')
      OPTIMIZER_FEATURES_ENABLE('11.2.0.2')
      IGNORE_OPTIM_EMBEDDED_HINTS
      END_OUTLINE_DATA
  */

Predicate Information (identified by operation id):
---------------------------------------------------


PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   2 - access("EMPNO"=7900)

Column Projection Information (identified by operation id):
-----------------------------------------------------------

   1 - "EMPNO"[NUMBER,22], "EMP"."ENAME"[VARCHAR2,10], "EMP"."JOB"[VARCHAR2,9],
       "EMP"."MGR"[NUMBER,22], "EMP"."HIREDATE"[DATE,7], "EMP"."SAL"[NUMBER,22],
       "EMP"."COMM"[NUMBER,22], "EMP"."DEPTNO"[NUMBER,22]
   2 - "EMP".ROWID[ROWID,10], "EMPNO"[NUMBER,22]

42 rows selected.


-- ========================================================================================
-- ========================================================================================
-- 2. AUTO Trace 

SQL> set autotrace on
SQL> select * from emp where empno = 7900;

     EMPNO ENAME      JOB	       MGR 		HIREDATE	 SAL       COMM     DEPTNO
---------- ---------- --------- ---------- --------- ---------- --------- ----------
      7900 JAMES      CLERK	      7698 		03-DEC-81	950 				30


Execution Plan
----------------------------------------------------------
Plan hash value: 4120447789

--------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name	   		| Rows  | Bytes | Cost (%CPU)	| Time	   |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|		   		|	 1 	|	38 	|	 1   (0)	| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP	   		|	 1 	|	38 	|	 1   (0)	| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 	|	   	|	 0   (0)	| 00:00:01 |
--------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7900)


Statistics
----------------------------------------------------------
	  1  recursive calls
	  0  db block gets
	  2  consistent gets
	  2  physical reads
	  0  redo size
	889  bytes sent via SQL*Net to client
	512  bytes received via SQL*Net from client
	  1  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
	  1  rows processed
	  
-- set autotrace on 
-- set autotrace on explain 
-- set autotrace on statistics 
-- set autotrace traceonly
-- set autotrace traceonly explain
-- set autotrace traceonly statistics 

	  
-- ========================================================================================
-- ========================================================================================
-- 3. SQL 트레이스 
SQL> alter session set sql_trace = true;

Session altered.

SQL> select * from emp where empno = 7900;

     EMPNO ENAME      JOB	       MGR HIREDATE	    SAL       COMM     DEPTNO
---------- ---------- --------- ---------- --------- ---------- ---------- ----------
      7900 JAMES      CLERK	      7698 03-DEC-81	    950 		   30

SQL> select * from dual;

D
-
X

SQL> alter session set sql_trace = false;

Session altered.

SQL> select value 
  2  from v$diag_info
  3  where name = 'Diag Trace';

 SELECT value 
 FROM v$diag_info 
 WHERE name = 'Default Trace File';
 
SELECT r.value || '/' || lower(t.instance_name) || '_ora_' 
	|| ltrim(to_char(p.spid)) || '.trc' trace_file 
FROM v$process p, v$session s, v$parameter r, v$instance t 
WHERE p.addr = s.paddr 
AND r.name = 'user_dump_dest'
AND s.sid = (SELECT sid FROM v$mystat WHERE rownum <= 1);

-- tkprof
