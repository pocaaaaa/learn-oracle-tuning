-- p87 ~ p90 , 인덱스를 Range Scan 할 수 없는 이유 
CREATE INDEX e_x01 ON emp(deptno);
CREATE INDEX e_x02 ON emp(deptno, job);
CREATE INDEX e_x03 ON emp(job);

EXPLAIN PLAN FOR 
SELECT /*+ index(E e_x01) */ * FROM EMP E WHERE E.DEPTNO BETWEEN 10 AND 20;

-- INDEX RANGE SCAN (e_x02)
explain plan FOR 
SELECT E.JOB FROM EMP E WHERE E.JOB = 'MANAGER';

-- INDEX FULL SCAN (e_x03)
explain plan FOR 
SELECT E.JOB FROM EMP E WHERE substr(E.JOB, 1, 2) = 'A';

-- INDEX RANGE SCAN (e_x01)
EXPLAIN PLAN FOR 
SELECT E.DEPTNO FROM EMP E WHERE E.DEPTNO = 20;

-- 책에는 INDEX RANGE SCAN 안된다는데 e_x01 인덱스 사용되서 INDEX RANGE SCAN이 됨..... 
EXPLAIN PLAN FOR 
SELECT E.DEPTNO FROM EMP E WHERE NVL(E.DEPTNO, 0) < 20;

-- INDEX FULL SCAN (e_x03)
EXPLAIN PLAN FOR 
SELECT E.JOB FROM EMP E WHERE E.JOB LIKE '%NAG%';

-- INDEX FULL SCAN (e_x02)
EXPLAIN PLAN FOR 
SELECT E.JOB, E.DEPTNO FROM EMP E WHERE (E.DEPTNO = 20 OR E.JOB = 'MANAGER');

-- OR Expansion
EXPLAIN PLAN FOR
SELECT JOB, DEPTNO 
FROM EMP 
WHERE DEPTNO = 20
UNION ALL
SELECT JOB, DEPTNO 
FROM EMP
WHERE JOB = 'MANAGER'
AND (DEPTNO != 20 OR DEPTNO IS NULL);

-- use concat
EXPLAIN PLAN FOR
SELECT /*+ use_concat */ E.JOB, E.DEPTNO FROM EMP E
WHERE (E.DEPTNO = 20 OR E.JOB = 'MANAGER');

-- INLIST ITERATOR (RANGE SCAN, e_x01)
EXPLAIN PLAN FOR
SELECT DEPTNO 
FROM EMP 
WHERE DEPTNO IN (10, 20);

-- UNION ALL 방식 (RANGE SCAN + RANGE SCAN)
EXPLAIN PLAN FOR
SELECT DEPTNO
FROM EMP
WHERE DEPTNO = 10
UNION ALL
SELECT DEPTNO
FROM EMP
WHERE DEPTNO = 20;

-- 실행계획 확인 
SELECT * FROM TABLE(dbms_xplan.display(NULL, NULL, 'ALL'));


-- p95, 인덱스를 이용한 소트 연산 생략
EXPLAIN PLAN FOR
SELECT /*+ index(E e_x02) */ E.DEPTNO FROM EMP E 
WHERE E.DEPTNO = 10;

EXPLAIN PLAN FOR
SELECT E.DEPTNO FROM EMP E
WHERE E.DEPTNO = 10
ORDER BY E.JOB;

EXPLAIN PLAN FOR
SELECT /*+ index(E e_x02) */ E.DEPTNO FROM EMP E
WHERE E.DEPTNO = 10
ORDER BY E.ENAME;

EXPLAIN PLAN FOR
SELECT E.DEPTNO FROM EMP E
WHERE E.DEPTNO = 10
ORDER BY E.JOB DESC;

-- 실행계획 확인
SELECT * FROM TABLE(dbms_xplan.display(NULL, NULL, 'ALL'));


-- p97, order by 절에서 컬럼 가공
EXPLAIN PLAN FOR
SELECT * 
FROM EMP E
WHERE E.DEPTNO = 10
ORDER BY E.DEPTNO, E.JOB;

EXPLAIN PLAN FOR
SELECT * 
FROM EMP E
WHERE E.DEPTNO = 10
ORDER BY E.DEPTNO || E.JOB;

-- 실행계획 확인
SELECT * FROM TABLE(dbms_xplan.display(NULL, NULL, 'ALL'));


-- p100, SELECT-LIST 에서 컬럼 가공 
EXPLAIN PLAN FOR
SELECT MAX(E.JOB)
FROM EMP E
WHERE E.DEPTNO = 10;

EXPLAIN PLAN FOR
SELECT MIN(E.JOB)
FROM EMP E
WHERE E.DEPTNO = 10;

EXPLAIN PLAN FOR
SELECT MIN(E.EMPNO)
FROM EMP E
WHERE E.DEPTNO = 10;


-- P104, 자동형변환
EXPLAIN PLAN FOR
SELECT E.DEPTNO 
FROM EMP E
WHERE E.DEPTNO = 10;

-- filter(TO_CHAR("E"."DEPTNO")='10')
-- filter(TO_CHAR("E"."DEPTNO") LIKE '10%')
EXPLAIN PLAN FOR
SELECT E.DEPTNO 
FROM EMP E
WHERE E.DEPTNO LIKE '10%';

EXPLAIN PLAN FOR
SELECT E.DEPTNO 
FROM EMP E
WHERE E.DEPTNO LIKE NULL || '%';

-- 실행계획 확인
SELECT * FROM TABLE(dbms_xplan.display(NULL, NULL, 'ALL'));


-- p112, Index Full Scan
SQL> create index emp_ename_sal_idx on emp (ename, sal);
SQL> set autotrace traceonly exp
SQL> select * from emp
     where sal > 2000
     order by ename;
    
-------------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name				| Rows	| Bytes | Cost (%CPU)| Time	|
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|					|     6 |   522 |     2(0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP				|     6 |   522 |     2(0)| 00:00:01 |
|*  2 |   INDEX FULL SCAN	    	| EMP_ENAME_SAL_IDX |     1 |		|     1(0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

    
-- p116, Index Unique Scan 
SQL> set autotrace traceonly exp
SQL> select empno, ename from emp where empno = 7788;
 
Execution Plan
----------------------------------------------------------
Plan hash value: 4120447789
--------------------------------------------------------------------------------------------
| Id  | Operation			    	| Name	   		| Rows  | Bytes | Cost (%CPU)	| Time	   |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	 	   	|		  	 	|	 1 	|	20 	|	 1   (0)	| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP		   	|	 1 	|	20 	|	 1   (0)	| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 	|	   	|	 1   (0)	| 00:00:01 |
--------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   2 - access("EMPNO"=7788)
   

-- p125, Index Range Scan Descending
SQL>set autotrace traceonly exp
SQL> select * from emp 
     where empno > 0
     order by empno desc;

Execution Plan
----------------------------------------------------------
Plan hash value: 2095357872
---------------------------------------------------------------------------------------------
| Id  | Operation		     			| Name		    | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	     		|		    	|	 14 |  1218 |	  1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID 	| EMP	    	|	 14 |  1218 |	  1   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN DESCENDING	| EMP_EMPNO_PK 	|	  1 |	    |	  2   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   2 - access("EMPNO">0)
