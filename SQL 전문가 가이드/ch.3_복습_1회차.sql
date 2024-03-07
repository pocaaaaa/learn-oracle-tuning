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


-- 3-3장. 인덱스튜닝 
-- Range Scan (SQL Server 에서는 Index Seek)
CREATE INDEX emp_deptno_idx ON emp(deptno);
explain plan FOR 
SELECT /*+ index(emp emp_deptno_idx) */ * FROM emp WHERE deptno = 20;
SELECT * FROM table(dbms_xplan.display);

-- Index Full Scan (SQL Server 에서는 Index Scan)
CREATE INDEX emp_idx ON emp (ename, sal);
explain plan FOR 
SELECT /*+ index(emp emp_idx) */ * FROM emp WHERE sal > 2000 ORDER BY ename;
SELECT * FROM table(dbms_xplan.display);

SELECT /*+ first_rows */ * FROM emp 
WHERE sal > 1000 
ORDER BY ename;

-- Index Unique Scan (SQL Server 에서는 Index Seek)
CREATE UNIQUE INDEX pk_emp ON emp(empno);
ALTER TABLE emp ADD 
CONSTRAINT pk_emp PRIMARY key(empno) USING INDEX pk_emp; 

explain plan FOR 
SELECT /*+ index(emp EMP_EMPNO_PK) */ empno, ename 
FROM emp 
WHERE empno = 7788;

-- Index Skip Scan 
explain plan for
SELECT /* index_ss(emp emp_idx) */ * 
FROM emp 
WHERE sal BETWEEN 2000 AND 4000;

-- Index Fast Full Scan (인덱스 세그먼트 전체를 Multiblock Read 방식으로 스캔) 

-- Index Range Scan Descending 
explain plan for
SELECT * FROM emp 
WHERE empno IS NOT NULL 
ORDER BY empno DESC;

SELECT * FROM table(dbms_xplan.display);

-- max
CREATE INDEX emp_x02 ON emp(deptno, sal);
explain plan for
SELECT deptno, dname, loc 
	 , (SELECT max(sal) FROM emp WHERE deptno = d.deptno) 
FROM dept d;

-- 클러스터 인덱스 
-- create cluster c_deptno# (deptno number(2)) index;
-- create index i_deptno# on cluster c_deptno#;
-- create table emp 
-- cluster c_deptno# (deptno)
-- as 
-- select * from scott.emp; 

-- create clustered index 영업실적_idx on 영업실적 (사번, 일자);
-- create table 영업실적 (사번 varchar2(5), 일자 varcahr2(8), ...
-- , constraint 영업실적_PK primary key (사번, 일자)) organization index; 

-- select * from 업체 where substr(업체명, 1, 2) = '대한'
-- select * from 업체 where 업체명 like '대한%'

-- select * from 사원 where 월급여 * 12 = 36000000
-- select * from 사원 where 월급여 = 36000000 / 12 

-- select * from 주문 where to_char(일시, 'yyyymmdd) = :dt 
-- select * from 주문 where 일시 >= to_date(:dt, 'yyyymmdd) and 일시 < to_date(:dt, 'yyyymmdd) + 1

-- select * from 고객 where 연령 || 직업 = '30공무원' 
-- select * from 고객 where 연령 = 30 and 직업 = '공무원'

-- select * from 회원사지점 where 회원번호 || 지점번호 = :str 
-- select * from 회원사지점 where 회원번호 = substr(:str, 1, 2) and 지점번호 = substr(:str, 3, 4)

CREATE INDEX emp_x03 ON emp (deptno, job, empno);
explain plan FOR 
SELECT /* batch_table_access_by_rowid(e) */ *
FROM emp e 
WHERE deptno = 20 
ORDER BY job, empno;

SELECT * FROM table(dbms_xplan.display);

-- select 고객ID, 상품명, 지역, ...
-- from 가입상품
-- where :reg is null 
-- and 회사 = :com 
-- and 상품명 like :prod || '%'
-- union all
-- select 고객ID, 상품명, 지역, ...
-- from 가입상품 
-- where :reg is not null
-- and 회사 = :com 
-- and 지역 = :reg 
-- and 상품명 like :prod || '%'


-- 3-4장. 조인 튜닝 
-- 1) NL 조인 
explain plan for
SELECT /*+ ordered use_nl(b) */ e.empno, e.ename, d.dname 
FROM emp e, dept d 
WHERE d.deptno = e.deptno;

explain plan for
SELECT /*+ leading(e) use_nl(b) */ e.empno, e.ename, d.dname 
FROM emp e, dept d 
WHERE d.deptno = e.deptno;

SELECT * FROM table(dbms_xplan.display);

-- [SQL Server]
-- select e.empno, e.ename, d.dname 
-- from emp e inner join dept d on d.deptno = e.deptno 
-- option (force order)

-- select e.empno, e.ename, d.dname 
-- from emp e, dept d 
-- where d.deptno = e.deptno 
-- option (force order, loop join)

-- 테이블 Prefetch 
-- : 인덱스를 이용해 테이블을 액세스하다가 디스크 I/O가 필요하면, 이어서 곧 읽게 될 블록까지 미리 읽어서 버퍼캐시에 적재.
--   nlj_prefetch, no_nlj_prefetch 
-- 배치 I/O
--  : 디스크 I/O Call을 미뤘다가 읽을 블록이 일정량 샇이면 한꺼번에 처리하는 기능. 
--    nlj_batching, no_nlj_batching 
-- 두 기능 모두 읽는 블록을 건건이 I/O Call을 발생시키는 비효울을 줄이기 위해 고안. 


-- 2) 소트 머지 조인 
-- 소트 단계 : 양쪽 집합을 조인 칼럼 기준으로 정렬
-- 머지 단계 : 정렬된 양쪽 집합을 서로 머지(merge)
-- 조인 컬럼에 인덱스가 있으면, 소트 단계를 거치지 않고 곧바로 조인 할 수 있음. 
-- "OracleXML" le은 조인 연산자가 부동호이거나 아예 조인 조건이 없어도 소트 머지 조인 처리 가능. 
-- SQL Server는 조인 연산자가 '=' 일 때만 소트 머지 조인을 수행할 수 있다. 

SELECT /*+ ordered use_merge(e) */ d.deptno, d.dname, e.ename 
FROM dept d, emp e 
WHERE d.deptno = e.deptno;

SELECT * FROM table(dbms_xplan.display);

-- [SQL Server]
-- select d.deptno, d.dname, e.empno, e.ename 
-- from dept d, emp e 
-- where d.deptno = e.deptno 
-- option(force order, merge join)

-- 3) 해시 조인 
SELECT /*+ ordered use_hash(e) */ d.deptno, d.dname, e.empno, e.ename 
FROM dept d, emp e 
WHERE d.deptno = e.deptno;

SELECT * FROM table(dbms_xplan.display);

-- [SQL Server]
-- select d.deptno, d.dname, e.empno, e.ename 
-- from dept d, emp e 
-- where d.deptno = e.deptno 
-- option(force order, hash join)

-- 해시 조인은 둘 중 작은 집합 (Build Input)을 읽어 해시 영역 (Hash Area)에 해시 테이블(=해시 맵)을 생성하고, 
-- 반대쪽 큰 집합(Probe Input)을 읽어 해시 테이블을 탐색하면서 조인하는 방식. 

-- 해시 충돌 : 다른 입력값에 대한 출력값이 같을 수 있는 것 => 입력값이 다른 엔트리가 한 해시 버킷에 담길 수 있다. 

-- Build Input이 작을 때라야 효과적. 
-- 해시 키 값으로 사용되는 칼럼에 중복 값이 거의 없을 때라야 효과적. 
-- 해시 테이블을 만드는 단계는 전체범위처리가 불가피하지만, 반대쪽 Probe Input을 스캔하는 단계는 NL 조인처럼 부분범위 처리가 가능. 

-- Grace 해시 조인 : 조인되는 양쪽 집합 모두 조인 칼럼에 해시 함수를 적용 -> 반환된 해시 값에 따라 동적으로 파티셔닝. 
-- 독립적으로 처리할 수 있는 여러 개의 작은 서브 집합으로 분할함으로써 파티션 짝(pair)을 생성하는 단계. 
-- => 분할/정복 방식 

-- Recursive 해시 조인 (=Nested-loops 해시 조인)

-- 수행 빈도가 낮고 + 쿼리 수행 시간이 오래 걸리는 + 대용량 테이블 => 배치 프로그램, DW, OLAP성 쿼리의 특징. 
 

-- 4) 스칼라 서브 쿼리 (캐싱 기법)
SELECT empno, ename, sal, hiredate 
   , (SELECT d.dname FROM dept d WHERE d.deptno = e.deptno) dname 
FROM EMP e 
WHERE sal >= 2000; 

SELECT /*+ ordered use_nl(b) */ e.empno, e.ename, e.sal, e.hiredate, d.dname 
FROM emp e RIGHT OUTER JOIN dept d 
ON d.deptno = e.deptno 
WHERE e.sal >= 2000;

-- 캐싱 -> 해싱 알고리즘 사용 
-- 입력 값의 종류가 소수여서 해시 충돌 가능성이 적은 때라야 캐싱 효과를 얻을 수 있음. 
-- 반대의 경우라면 캐시를 확인하는 비용 때문에 오히려 성능은 저하되고 CPU 사용률만 높게 만듬. 
-- SQL Server에서는 2005버전부터 해당 기능을 제거. 
SELECT empno, ename, sal, hiredate 
   , (
      SELECT d.dname    -- 출력 값 : d.dname 
      FROM dept d 
      WHERE d.deptno = e.empno -- 입력 값 : e.empno
   )
FROM emp e 
WHERE sal >= 2000;

SELECT d.deptno, d.dname, avg_sal, min_sal, max_sal 
FROM dept d RIGHT OUTER JOIN 
   (SELECT deptno, avg(sal) avg_sal, min(sal) min_sal, max(sal) max_sal 
    FROM emp GROUP BY deptno) e   
ON e.deptno = d.deptno 
WHERE d.loc = 'CHICAGO';

SELECT deptno, dname 
    , to_number(substr(sal, 1, 7)) avg_sal 
    , to_number(substr(sal, 8, 7)) min_sal
    , to_number(substr(sal, 15)) max_sal 
FROM (
   SELECT d.deptno, d.dname 
      , (SELECT lpad(avg(sal), 7) || lpad(min(sal), 7) || max(sal)
         FROM emp WHERE deptno = d.deptno) sal
   FROM dept d 
   WHERE d.loc = 'CHICAGO'
)

-- lpad(deptno, 5) : 왼쪽에 공백을 채움 
-- lpad(deptno, 5, ' ') : 왼쪽에 공백을 채움 
-- lpad(deptno, 5, '0') : 왼쪽에 '0'을 채움 
-- lpad(deptno, 5, 'A') : 왼쪽에 'A'를 채움 

-- [SQL Server]
-- select deptno, dname 
--       , cast(substring(sal, 1, 7) as float) avg_sal 
--      , cast(substring(sal, 8, 7) as int) min_sal 
--      , cast(substring(sal, 15, 7) as int) max_sal
-- from (
--      select d.deptno, d.dname 
--         , (select str(avg(sal), 7, 2) + str(min(sal), 7) + str(max(sal), 7) 
--            from emp where deptno = d.deptno) sal 
--      from dept d 
--       where d.loc = 'CHICAGO'
-- ) x 

-- 스칼라 서브 쿼리 Unnesting 
-- select c.고객번호, c.고객명 
--       , (select /*+ unnest */ round(avg(거래금액), 2) 평균거래금액 
--         from 거래 
--          where 거래일시 >= trunc(sysdate, 'mm')
--         and 고객번호 = c.고객번호) 
-- from 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm') 

-- 5) 고급 조인 기법 
-- 대부분 조인은 1:M 관계인 테이블끼리의 조인. 
-- 조인 결과는 M쪽 집합과 같은 단위가 된다. 
-- 이를 다시 1쪽 집합 단위로 그룹핑해야 한다면, M쪽 집합을 먼저 1쪽 단위로 그룹핑하고 나서 조인하는 것이 유리. 
-- 조인 횟수를 줄여줌 => 인라인 뷰 사용 가능. 

-- select t2.상품명, t1.판매수량, t1.판매금액 
-- from (select 상품코드, sum(판매수량) 판매수량, sum(판매금액) 판매금액 
--       from 일별상품판매 
--        where 판매일자 between '20090101' and '20091231'
--       group by 상품코드) t1, 상품 t2 
-- where t1.상품코드 = t2.상품코드 

-- select /*+ ordered use_nl(b) use_nl(c) */ 
--      , a.작업일련번호, a.작업자ID, a.작업상태코드 
--      , nvl(b.고객번호, c.고객번호) 고객번호 
--      , NVL(b.주소, c.주소) 주소, ......
-- from 작업지시 a, 개통신청 b, 장애접수 c
-- where a.방문예정일시 between :방문예정일시1 and :방문예정일시2 
-- and b.개통신청번호 (+) = a.개통신청번호 
-- and c.장애접수번호 (+) = a.장애접수번호 

-- select /*+ ordered use_nl(b) use_nl(c) */
--         a.작업일련번호, a.작업자ID, a.작업상태코드 
--      , nvl(b.고객번호, c.고객번호) 고객번호
--      , nvl(b.주소, c.주소) 주소, ......
-- from 작업지시 a, 개통신청 b, 장애접수 c 
-- where a.방문예정일시 between :방문예정일시1 and :방문예정일시2 
-- and b.개통신청번호(+) = decode(a.작업구분, '1', a.접수번호)
-- and c.장애접수번호(+) = decode(a.작업구분, '2', a.접수번호)

-- select 지점, 판매월, 매출 
--      , sum(매출) over (partition by 지점 order by 판매월 range between unbounded preceding and current row) 누적매출 
-- from 월별지점매출

-- select t1.지점, t1.판매월, min(t1.매출) 매출, sum(t2.매출) 누적매출 
-- from 월별지점매출 t1, 월별지점매출 t2 
-- where t2.지점 = t1.지점 
-- and t2.판매월 <= t1.판매월 
-- group by t1.지점, t1.판매월 
-- order by t1.지점, t1.판매월 

-- select 고객번호, 연체금액, 연체개월수 
-- from 고객별연체금액 
-- where 고객번호 = '123'
-- and '20040815' between b.시작일자 and b.종료일자; 

-- select 연체개월수, 연체금액 
-- from 고객별연체금액 
-- where 고객번호 = :cust_nm 
-- and to_char(sysdate, 'yyyymmdd') between 시작일자 and 종료일자 

-- [SQL Server]
-- select 연체개월수, 연체금액 
-- from 고객별연체금액 
-- where 고객번호 = :cust_nm 
-- and covert(varchar(8), getdate(), 112) between 시작일자 and 종료일자 

-- select a.거래일자, a.종목코드, b.종목한글명, b.종목영문명, b.상장주식수 
--       , a.시가, a.종가, a.체결건수, a.체결수량, a.거래대금 
-- from 일별종목거래및시세 a, 종목이력 b 
-- where a.거래일자 between to_char(add_months(sysdate, -20*12), 'yyyymmdd') and to_char(sysdate-1, 'yyyymmdd')
-- and a.종가 = a.최고가 
-- and b.종목코드 = a.종목코드 
-- and a.거래일자 between b.시작일자 and b.종료일자 => 거래 시점의 종목명과 상장주식수 
-- and to_char(sysdate, 'yyyymmdd') between b.시작일자 and b.종료일자 => 현재(최종) 시점의 종목명과 상장주식수 

-- select /*+ ordered use_nl(b) rowid(b) */ 
--        a.고객명, a.거주지역, a.주소, a.연락처, b.연체금액, b.연체개월수 
-- from 고객 a, 고객별연체이력 b 
-- where a.가입회사 = 'C70'
-- and b.rowid = (select /*+ index(c 고객별연체이력_idx01) */ rowid 
--              from 고객별연체이력 c 
--              where c.고객번호 = a.고객번호 
--              and c.변경일자 <= a.서비스만료일 
--              and rownum <= 1) 

SELECT rowid, emp.* FROM emp;


-- 3-5장. 옵티마이저 
-- 1. 규칙기반 옵티마이저
-- 2. 비용기반 옵티마이저
--  1) 오브젝트 통계 : 레코드 개수, 블록 개수, 평균 행 길이, 컬럼 값의 수, 칼럼 값의 분포, 인덱스 높이, 클러스터링 팩터
--  2) 시스템 통계정보 : CPU 속도, 디스크 I/O 속도 

-- 전체 처리속도 최적화 : 시스템 리소스(I/O, CPU, 메모리 등)를 가장 적게 사용하는 실행계획을 선택. 

-- Oracle 옵티마이저 모드 변경 
ALTER SESSION SET optimizer_mode = all_rows; -- 시스템 레벨 변경 
ALTER SESSION SET optimizer_mode = all_rows; -- 세션 레벨 변경 
SELECT /*+ all_rows */ * FROM t WHERE ...; -- 쿼리 레벨 변경 

-- 최초 응답속도 최적화 : 전체 결과 집합 중 일부만 읽다가 멈추는 것을 전제로, 가장 빠른 응답 속도를 낼 수 잇는 실행계획을 선택. 

SELECT /*+ first_rows(10) */ * FROM t WHERE; -- Oracle  
SELECT * FROM t WHERE option(fast 10); -- SQL Server 

-- 통계정보 
-- 1. 테이블 통계 : 전체 레코드 수, 총 블록 수, 빈 블록 수, 한 행당 평균 크기 등 
-- 2. 인덱스 통계 : 인덱스 높이, 리프 블록 수, 클러스터링 팩터, 인덱스 레코드 수 등 
-- 3. 칼럼 통계 : 값의 수, 최저 값, 최고 값, 밀도, null 값 개수, 칼럼 히스토그램 등 
-- 4. 시스템 통계 : CPU 속도, 평균 I/O 속도, 초당 I/O 처리량 등 

-- 선택도 -> 커디널리티 -> 비용 -> 액세스 방식, 조인 순서, 조인 방법 등 결정 
-- 선택도 = 1/distinct value 개수 
-- 카디널리티 = 총 로우 수 x 선택도

-- 히스토그램 : 도수분호, 높이균형, 상위도수분포, 하이브리드 

-- 비용 : 쿼리를 수행하는 데 소요되는 일량 또는 시간을 뜻 (어디까지나 예쌍치)
-- I/O 비용 모델 
-- 비용 = blevel                        -- 인덱스 수직적 탐색 비용 
--       + (리프 블록 수 x 유효 인덱스 선택도)      -- 인덱스 수평적 탐색 비용 
--       + (클러스터링 팩터 x 유효 테이블 선택도)   -- 테이블 램덤 액세스 비용 

-- 라이브러리캐시 : SQL과 실행계획이 캐싱되는 영역 (프로시저 캐시)

-- 쿼리 변환 
-- 1. 휴리스틱 쿼리 변환 : 결과만 보장된다면 무조건 쿼리 변환을 수행. 
-- 2. 비용기반 쿼리 변환 : 변환된 쿼리 비용이 더 낮을 때만 그것을 사용하고, 그렇지 않을 때는 원본 쿼리 그대로 두고 최적화 수행.

-- 서브쿼리 Unnesting : 중첩된 서브쿼리를 풀어내는 것 (서브쿼리 Flatting)
-- 서브쿼리를 메인쿼리와 같은 레벨로 풀어낸다면 다양한 액세스 경로와 조인 메소드를 평가할 수 있음. 
-- 중첩된 서브쿼리 (nested subquery) 는 메인쿼리와 부모와 자식이라는 종속적이고 계층적인 관계가 존재 => 필터방식. 
-- 즉, 메인 쿼리에서 읽히는 레코드마다 서브쿼리를 반복 수행하면서 조건에 맞지 않는 데이터를 골라내는 것. 

-- 서브플래(Subplan) 으로 최적화 : 각각 메인쿼리/서브쿼리를 최적화 하는 방식 => 필터 오퍼레이션 
explain plan for
SELECT * FROM emp 
WHERE deptno IN (SELECT /* no_unnest */ deptno FROM dept);

SELECT * FROM table(dbms_xplan.display);

-- Unnesting 
SELECT * 
FROM (SELECT deptno FROM dept) a, emp b 
WHERE b.deptno = a.deptno;

-- View Merging 
SELECT emp.* FROM dept, emp 
WHERE emp.deptno = dept.deptno;

-- unnest : 서브쿼리를 Unnesting 함으로써 조인방식으로 최적화하도록 유도한다. 
-- no_unnest : 서브쿼리를 그대로 둔 상태에서 필터 방식으로 최적화하도록 유도한다. 

-- 1쪽 집합 기준으로 M쪽 집합 필터링 
SELECT * FROM dept 
WHERE deptno IN (SELECT deptno FROM emp);

-- sort unique 오퍼레이션 수행 
-- 세미 조인(Semi join) 방식으로 조인 

ALTER TABLE dept DROP PRIMARY KEY;
CREATE INDEX dept_deptno_idx ON dept(deptno);
SELECT * FROM emp 
WHERE deptno IN (SELECT deptno FROM dept);

-- sort unique 오퍼레이션 -> 아래와 같은 형식으로 쿼리 변환 
SELECT b.*
FROM (SELECT /*+ no_merge */) DISTINCT deptno FROM dept ORDER BY deptno) a, emp b 
WHERE b.deptno = a.deptno; 

-- 세미 조인(Semi join) 
-- Outer(=Driving) 테이블의 한 로우가 Inner 테이블의 한 로우와 조인에 성공하는 순간 진행을 멈추고 
-- Outer 테이브르이 다음 로우를 계속 처리하는 방식. 
SELECT * FROM emp 
WHERE deptno IN (SELECT /* unnest nl_sj */ deptno FROM dept);

-- 뷰 Merging 
SELECT * 
FROM (SELECT * FROM emp WHERE job = 'SALESMAN') a
   ,(SELECT * FROM dept WHERE loc = 'CHICAGO') b 
WHERE a.deptno = b.deptno;

SELECT * 
FROM emp a, dept b 
WHERE a.deptno = b.deptno 
AND a.job = 'SALESMAN'
AND b.loc = 'CHICAGO';

CREATE OR REPLACE VIEW emp_salesman
AS 
SELECT empno, ename, job, mgr, hiredate, sal, comm, deptno 
FROM emp 
WHERE job = 'SALESMAN';

SELECT * FROM emp_salesman;

explain plan for
SELECT e.empno, e.ename, e.job, e.mgr, e.sal, d.dname 
FROM emp_salesman e, dept d 
WHERE d.deptno = e.deptno 
AND e.sal >= 1500;

SELECT * FROM table(dbms_xplan.display);

-- 뷰 Merging 
SELECT e.empno, e.ename, e.job, e.mgr, e.sal, d.dname 
FROM emp e, dept d 
WHERE d.deptno = e.deptno 
AND e.job = 'SALESMAN'
AND e.sal >= 1500;

-- group by, select-list에 distinct 연산자 포함일 경우에 사용하면 뷰 Merging하면 오히려 성능이 나빠질 수 있음. 

-- merge, no_merge 

-- 뷰 Merging 불가능 
-- 1. 집합(set) 연산자(union, union all, intersect, minus)
-- 2. connect by절 
-- 3. ROWNUM pseudo 칼럼 
-- 4. select-list에 집계 함수 (avg, count, max, min, sum) 사용 
-- 5. 분석 함수 (Analytic Function)

SELECT * FROM v$session_wait;
SELECT * FROM v$lock;

-- tx : 행과 관련된 락 
-- tm : 테이블에 거는 락 
-- tx락의 x(배타적)는 같은 행에 대하여 다른 모든 락을 허용하지 않음. 
-- RX 또는 RS모드의 TM락(테이블 락)은 다른 세션이 같은 테이블에 대해 RX 또는 RS 모드로 TM락을 걸 수 있음.
-- RX모드의 TM락이 걸렸다면 테이블의 정의는 변경하는 작업은 할 수 없지만, 테이블에 대해 여러 트랜잭션을 수행할 수 있음. 


-- 조건절(Predicate) Pushing : 뷰를 참조하는 쿼리 블록의 조건절을 뷰 쿼리 블록 안으로 밀어 넣는 기능
-- 뷰 안에서의 처리 일량을 최소화하게 됨은 물론 리턴되는 결과 건수를 줄임으로써 다음 단계에서 처리해야 할 일량을 줄일 수 있음. 

-- 1. 조건절(Predicate) Pushdown
--   : 쿼리 블록 밖에 있는 조건절을 쿼리 블록 안쪽으로 밀어 넣는 것을 말함

SELECT deptno, avg_sal
FROM (SELECT /*+ INDEX(emp EMP_DEPTNO_IDX) */ deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) a 
WHERE deptno =30;

explain plan for
SELECT b.deptno, b.dname, a.avg_sal 
FROM (SELECT deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) a, dept b 
WHERE a.deptno = b.deptno 
AND b.deptno =30;

SELECT * FROM table(dbms_xplan.display);

-- '조건절 이행' 쿼리 변환 => a.deptno = 30 조건절이 인라인 뷰 안쪽으로 Pushing 
SELECT b.deptno, b.dname, a.avg_sal
FROM (SELECT deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) a, dept b 
WHERE a.deptno = b.deptno 
AND b.deptno = 30
AND a.deptno = 30;

-- 2. 조건절(Predicate) Pullup
--   : 쿼리 블록 안에 있는 조건절을 쿼리 블록 밖으로 내오는 것을 말하며, 그것을 다시 다른 쿼리 블록에 Pushdown 하는 데 사용
-- 3. 조인 조건(Join Predicate) Pushdown 
--   : NL 조인 수행 중에 드라이빙 테이블에서 읽은 값을 건건이 Inner 쪽 (=right side) 뷰 쿼리 블록 안으로 밀어 넣는 것을 말함. 

