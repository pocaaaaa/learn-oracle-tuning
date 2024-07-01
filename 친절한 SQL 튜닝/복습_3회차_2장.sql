-- 2.1 인덱스 구조 및 탐색
CREATE INDEX 고객_N1 ON 고객 (고객명);


-- ========================================================================================
-- ========================================================================================
-- 2.2 인덱스 기본 사용법
SELECT round(avg(sal)) avg_sal
	 , min(sal) min_sal
	 , max(sal) max_sal
	 , max(decode(job, 'PRESIDENT', NULL, sal)) max_sal2 
FROM emp;

SELECT round(avg(sal)) avg_sal
	 , min(sal) min_sal
	 , max(sal) max_sal
	 , max(decode(job, 'PRESIDENT', to_number(NULL), sal)) max_sal2 
FROM emp;


-- ========================================================================================
-- ========================================================================================
-- 2.3 인덱스 확장기능 사용법 
CREATE INDEX emp_deptno_idx ON emp (deptno);
COMMIT;

SQL> create index emp_ename_sal_idx on emp (ename, sal);

Index created.

SQL> set autotrace traceonly EXP

SQL> select * from emp 
  2  where sal > 2000
  3  order by ename;

Execution Plan
----------------------------------------------------------
Plan hash value: 3797164079

-------------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name				| Rows	| Bytes | Cost (%CPU)| Time		|
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|					|    10 |   380 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP				|    10 |   380 |     2   (0)| 00:00:01 |
|*  2 |   INDEX FULL SCAN	    	| EMP_ENAME_SAL_IDX |    10 |		|     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SAL">2000)
       filter("SAL">2000)
       
       
SQL> select * 
  2  from emp
  3  where sal > 9000
  4  order by ename;

Execution Plan
----------------------------------------------------------
Plan hash value: 3797164079

-------------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name				| Rows	| Bytes | Cost (%CPU)| Time		|
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|					|     1 |    38 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP				|     1 |    38 |     2   (0)| 00:00:01 |
|*  2 |   INDEX FULL SCAN	    	| EMP_ENAME_SAL_IDX |     1 |		|     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SAL">9000)
       filter("SAL">9000)
       
       
SQL> select /*+ first_rows */ *
  2  from emp 
  3  where sal > 1000
  4  order by ename;

Execution Plan
----------------------------------------------------------
Plan hash value: 3797164079

-------------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name				| Rows	| Bytes | Cost (%CPU)| Time		|
-------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|					|    13 |   494 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP				|    13 |   494 |     2   (0)| 00:00:01 |
|*  2 |   INDEX FULL SCAN	    	| EMP_ENAME_SAL_IDX |    13 |		|     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SAL">1000)
       filter("SAL">1000)
       

SQL> select empno, ename from emp where empno = 7788;

Execution Plan
----------------------------------------------------------
Plan hash value: 4120447789

--------------------------------------------------------------------------------------------
| Id  | Operation		    		| Name	   		| Rows  | Bytes | Cost (%CPU)| Time	   |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|		   		|	 1 |	10 |	 1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP	   		|	 1 |	10 |	 1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 |	   |	 0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7788)


-- create unique index pk_emp on emp(empno);
-- alter table emp add constraint pk_emp primary key(empno) using index pk_emp; 
   

SELECT /*+ index_ss(사원 사원_IDX) */ *
FROM 사원 
WHERE 연봉 BETWEEN 2000 AND 4000; 


SQL> select * from emp
  2  where empno > 0
  3  order by empno desc;

Execution Plan
----------------------------------------------------------
Plan hash value: 2095357872

---------------------------------------------------------------------------------------------
| Id  | Operation		     			| Name	    	| Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	     		|		    	|	 14 |	532 |	  2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID 	| EMP	    	|	 14 |	532 |	  2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN DESCENDING	| EMP_EMPNO_PK 	|	 14 |	    |	  1   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO">0)

   
SQL> select deptno, dname, loc 
  2  , (select max(sal) from emp where deptno = d.deptno)
  3  from dept d;

Execution Plan
----------------------------------------------------------
Plan hash value: 3928207977

----------------------------------------------------------------------------------------
| Id  | Operation		     			| Name    	| Rows  | Bytes | Cost (%CPU)| Time    |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	     		|	       	|     4 |    80 |     2	 (0)| 00:00:01 |
|   1 |  SORT AGGREGATE 	     		|	       	|     1 |     7 |	    	|	       |
|   2 |   FIRST ROW		     			|	       	|     1 |     7 |     1	 (0)| 00:00:01 |
|*  3 |    INDEX RANGE SCAN (MIN/MAX)	| EMP_X02 	|     1 |     7 |     1	 (0)| 00:00:01 |
|   4 |  TABLE ACCESS FULL	     		| DEPT    	|     4 |    80 |     2	 (0)| 00:00:01 |
----------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - access("DEPTNO"=:B1)

