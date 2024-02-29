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

SELECT trunc(sysdate - 2) FROM dual;

-- [Oracle]
SELECT /*+ leading(o) use_nl(e) index(d dept_loc_idx) */ *
FROM emp e, dept d
WHERE e.deptno = e.deptno 
AND d.loc = 'CHICAGO';

-- [MsSQL]
-- select * 
-- from dept d with (index(dept_loc_idx)), emp e 
-- where e.deptno = d.deptno
-- and d.loc = 'CHICAGO'
-- optopn (forace order, loop join)


-- 3-2장. SQL 분석 도구 
-- explain : 실행계획 확인 
explain plan SET statement_id = 'query1' FOR 
SELECT * FROM emp WHERE empno = 7900;

SELECT * FROM table(dbms_xplan.display);

-- AutoTrace : 실행계획 + 실행통계 
--SQL> set autotrace traceonly
--SQL> select * from emp where empno = 7900;
--
--
--Execution Plan
------------------------------------------------------------
--Plan hash value: 4120447789
--
----------------------------------------------------------------------------------------------
--| Id  | Operation		    			| Name	   		| Rows  | Bytes | Cost (%CPU)	| Time	   |
----------------------------------------------------------------------------------------------
--|   0 | SELECT STATEMENT	    		|		   		|	 1 	|	38 	|	 1   (0)	| 00:00:01 |
--|   1 |  TABLE ACCESS BY INDEX ROWID	| EMP	   		|	 1 	|	38 	|	 1   (0)	| 00:00:01 |
--|*  2 |   INDEX UNIQUE SCAN	    	| EMP_EMPNO_PK 	|	 1 	|	   	|	 0   (0)	| 00:00:01 |
----------------------------------------------------------------------------------------------
--
--
--Predicate Information (identified by operation id):
-----------------------------------------------------
--
--   2 - access("EMPNO"=7900)
--
--
--Statistics
------------------------------------------------------------
--	120  recursive calls
--	  0  db block gets
--	161  consistent gets
--	  4  physical reads
--	  0  redo size
--	889  bytes sent via SQL*Net to client
--	513  bytes received via SQL*Net from client
--	  1  SQL*Net roundtrips to/from client
--	  8  sorts (memory)
--	  0  sorts (disk)
--	  1  rows processed
--

-- DBMS_XPLAN
SELECT plan_table_output 
FROM TABLE(dbms_xplan.display('plan_table', NULL, 'serial'));

explain plan SET statement_id = 'SQL1' FOR 
SELECT *
FROM emp e, dept d
WHERE d.deptno = e.deptno 
AND e.sal >= 1000;

SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'BASIC'));
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'TYPICAL'));
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'SERIAL'));
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'ALL'));
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'BASIC ROWS BYTES COST'));

-- SQL Server 
-- use pubs 
-- go
-- set showplan_text on 
-- go 

-- select a.*, b.* 
-- from dbo.employee a, dbo.jobs b 
-- where a.job_id = b.job_id 
-- go 

-- 더 자세한 예상 실행계획 
-- set showplan_all on 
-- go 

-- 현재 자신이 접속해 있는 세션에만 트레이스를 설정 
alter session set sql_trace = true;
select * from emp where empno = 7900;
select * from dual; 
alter session set sql_trace = false;

SELECT r.value || '/' || lower(t.instance_name) || '_ora_' || ltrim(to_char(p.spid)) || '.trc' trace_file 
FROM v$process p, v$session s, v$parameter r, v$instance t
WHERE p.addr = s.paddr 
AND r.name = 'user_dump_dest'
AND s.sid = (SELECT sid FROM v$mystat WHERE rownum = 1);

--Statistics
------------------------------------------------------------
--	120  recursive calls
--	  0  db block gets							=> current 
--	161  consistent gets						=> query 
--	  4  physical reads							=> disk 
--	  0  redo size
--	889  bytes sent via SQL*Net to client
--	513  bytes received via SQL*Net from client
--	  1  SQL*Net roundtrips to/from client		=> fetch count 
--	  8  sorts (memory)
--	  0  sorts (disk)
--	  1  rows processed							=> fetch rows 

SELECT /*+ gather_plan_statistics */ * FROM emp WHERE empno = 7900;
SELECT * FROM table(dbms_xplan.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

-- SQL Server 의 SQL 트레이스 설정 
-- use Northwind 
-- go 
-- set statistics profile on 
-- set statistics io on 
-- set statistics time on 
-- go 

-- db file sequential read => SingleBlock I/O 
-- db file scattered read => Multiblock I/O 

-- Response Time = Service Time (CPU Time) + Wait Time (Queue Time)
--  => AWR (Automatic Workload Repository) : 응답 시간 분석 방법론을 지원하는 Oracle의 표준도구 
--     1) 부하 프로필 
--     2) 인스턴스 효율성 
--     3) 공유 풀 
--     4) 통계
--     5) 최상위 5개 대기 이벤트 

-- 3 => 1 Explain Plan으로는 예상 실행계획만 확인할 수 있다
-- 4 => 4 
-- 1 => 1
-- wait 

