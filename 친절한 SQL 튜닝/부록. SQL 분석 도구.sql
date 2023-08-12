-- 1. 실행계획 확인 
--[PLAN_TABLE 생성]
-- : 10g 버전부터는 기본적으로 오라클이 sys.paln_table 테이브을 만들고,
--   'PLAN_TABLE' 로 명명한 public synony도 생성하므로 사용자가 별도로 plan_table을 만들 필요가 없음. 
SELECT owner, synonym_name, table_owner, table_name
FROM all_synonyms
WHERE synonym_name = 'PLAN_TABLE';

-- 실행계획 확인 
-- 1) SQL 실행계획이 plan_table에 저장 
EXPLAIN PLAN FOR
SELECT * FROM EMP WHERE EMPNO = 7900;

EXPLAIN PLAN
SET STATEMENT_ID = 'PLAN1' INTO PLAN_TABLE
FOR
SELECT * FROM EMP WHERE EMPNO = 7900;

-- 2) plan_talbe에 저장된 실행계획을 확인 
SELECT * FROM table(dbms_xplan.display);
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'PLAN1', NULL));

-- 첫 번째 인자 : sql_id
-- 두 번째 인자 : child_no 
-- 세 번째 인자 : serial, parallel, outline, alias, projection, all
SELECT * FROM table(dbms_xplan.display(NULL, NULL, 'advanced'));


-- 2. AUTO Trace (sqlPlus 에서 실행. dbeaver 에서 실행 안됨.)
--  1) SQL을 실행하고 결과집합과 함께 예상 실행계획 및 실행통계 출력
SQL> set autotrace on
SQL> select * from emp where empno = 7900;

--  2) SQL을 실행하고 결과집합과 함께 예상 실행계획을 출력 
SQL> set autotrace on explain
SQL> select * from emp where empno = 7900;

--  3) SQL을 실행하고 결과집합과 함께 실행통계를 출력
SQL> set autotrace on statistics
SQL> select * from emp where empno = 7900;

--  4) SQL을 실행하지만 결과는 출력하지 않고, 예상 실행계획과 실행통계만 출력 
SQL> set autotrace traceonly
SQL> select * from emp where empno = 7900;

--  5) SQL을 실행하지 않고, 예상 실행계획만 출력
SQL> set autotrace traceonly explain
SQL> select * from emp where empno = 7900;

--  6) SQL을 실행하지만 결과는 출력하지 않고, 실행통계 출력 
SQL> set autotrace traceonly statistics
SQL> select * from emp where empno = 7900;


     EMPNO ENAME      JOB	       MGR     HIREDATE	    SAL       COMM         DEPTNO
---------- ---------- --------- ---------- ---------- ---------- ---------- ----------
      7900 JAMES      CLERK	      7698     03-DEC-81	950					 30


Execution Plan
----------------------------------------------------------
Plan hash value: 4120447789

--------------------------------------------------------------------------------------------

| Id  | Operation		    		| Name	   		| Rows  | Bytes | Cost (%CPU) | Time	|

--------------------------------------------------------------------------------------------

|   0 | SELECT STATEMENT	    	|		   		|	 1 |	87 |	 1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP	   		|	 1 |	87 |	 1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 |	   |	 1   (0)| 00:00:01 |

--------------------------------------------------------------------------------------------


Predicate Information (identified by operation id):
---------------------------------------------------
   2 - access("EMPNO"=7900)


Statistics
----------------------------------------------------------
	  1  recursive calls
	  0  db block gets
	  2  consistent gets
	  0  physical reads
	  0  redo size
	889  bytes sent via SQL*Net to client
	513  bytes received via SQL*Net from client
	  1  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
	  1  rows processed

