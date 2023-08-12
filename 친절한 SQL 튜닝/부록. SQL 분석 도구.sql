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



-- 3. SQL 트레이스 (tkprof)
ALTER SESSION SET sql_trace = TRUE;
SELECT * FROM emp WHERE empno = 7900;
SELECT * FROM dual;
ALTER SESSION SET sql_trace = FALSE;

SELECT value 
FROM v$diag_info
WHERE name = 'Diag Trace';

SELECT value 
FROM v$diag_info
WHERE name = 'Default Trace File';

-- 10g 이하 버전 
SELECT r.value || '/' || lower(t.instance_name) || 'ora'
		|| ltrim(to_char(p.spid)) || '.trc' trace_file
FROM v$process p, v$session s, v$parameter r, v$instance t 
WHERE p.addr = s.paddr
AND r.name = 'user_dump_dest'
AND s.sid = (SELECT sid FROM v$mystat WHERE rownum <= 1);



-- 4. DBMS_XPLAN 패키지
explain plan SET statement_id = 'SQL1' FOR 
SELECT * 
FROM emp e, dept d
WHERE d.deptno = e.DEPTNO
AND e.sal >= 1000;

-- TYPICAL, SERIAL, PRATITION, PARALLEL, PREDICATE, PROJECTION, ALLAS, REMOTE, NOTE
-- ALL, OUTLINE, ADVANCED
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'BASIC'));
SELECT * FROM table(dbms_xplan.display('PLAN_TABLE', 'SQL1', 'BASIC ROWS BYTES COST'));

-- 실행계획은 v$sql_plan에서 확인할 수 있음.
-- v$sql_plan 을 조회하려면 SQL에 대한 sql_id와 child_number값을 알아야 하는데,
-- 아래의 쿼리로 확인 가능
-- 직전에 수행한 SQL에 대한 sql_id 와 child_number를 출력해 주는 쿼리.
SELECT prev_sql_id AS sql_id, prev_child_number AS child_no
FROM v$session
WHERE sid = userenv('sid')
AND username IS NOT NULL 
AND prev_hash_value <> 0;

-- 더 이전에 수행한 SQL를 찾으려면 아래 SQL 텍스트로 검색
SELECT sql_id, child_number, sql_fulltext, last_active_time
FROM v$sql
WHERE sql_text LIKE '%select/* comment */%from%emp%dept%';

-- 직전에 수행한 SQL 정보 노출
SELECT * FROM table(dbms_xplan.display_cursor(NULL, NULL, 'BASIC ROWS BYTES COST PREDICATE'));

-- 위의 쿼리가 조회안되면 v$session, v$sql, v$sql_plan 뷰에 대한 조회 권한 추가
GRANT SELECT ON v$session TO SQLP;
GRANT SELECT ON v$sql TO SQLP;
GRANT SELECT ON v$sql_plan TO SQLP;

-- 캐싱된 커서의 Row Source별 수행 통계 출력
SELECT * FROM MDSYS.ALL_SDO_LRS_METADATA ble(dbms_xplan.display_cursor(NULL, NULL, 'ALLSTATS'));



-- 5. 실시간 SQL 모니터링 (11g 부터 제)
--  1) CPU time 또는 I/O time을 5초 이상 소비한 SQL
--  2) 병렬 SQL
--  3) monitor 힌트를 지정한 SQL
--  단, SQL 실행계획이 500라인을 넘으면 모니터링 대상 제외 
--  위의 제약을 피하려면 _sqlmon_max_palnlines 파라미터를 500 이상으로 설정 
--  수집한 정보는 v$sql_monitor, v$sql_plan_monitor 뷰를 통해 확인 
SELECT dbms_sqltune.report_sql_monitor(sql_id => '6x50yqwz81sfa') FROM dual;
SELECT dbms_sqltune.report_sql_monitor(sql_id => '6x50yqwz81sfa', TYPE=> 'html') FROM dual;



-- 6. V$SQL 
--  라이브러리 캐시에 캐싱돼 있는 각 SQL에 대한 수행통계를 보여줌. 
--  쿼리가 수행을 마칠 때마다 갱신되며, 오랫동안 수행되는 쿼리는 5초마다 갱신
SELECT
		sql_id, child_number, sql_text, sql_fulltext, parsing_schema_name,
		loads, invalidations, parse_calls, executions, fetches, rows_processed,
		cpu_time, elapsed_time,
		buffer_gets, disk_reads, sorts,
		first_load_time, last_active_time
FROM 
		v$sql;
		
SELECT 
		parsing_schema_name "업무",
		count(*) "SQL개수",
		round(avg(buffer_gets/executions)) "논리적I/O",
		round(avg(disk_reads/executions)) "물리적I/O",
		round(avg(rows_processed/executions)) "처리건수",
		round(avg(elapsed_time/executions/1000000), 2) "평균소요시간",
		count(CASE WHEN elapsed_time/executions/1000000 >= 10 THEN 1 END) "악성SQL",
		round(max(elapsed_time/executions/1000000), 2) "최대소요시간"
FROM 
		v$sql
WHERE
		parsing_schema_name IN ('EMP', 'DEPT')
AND 
		executions > 0
GROUP BY 
		parsing_schema_name;
