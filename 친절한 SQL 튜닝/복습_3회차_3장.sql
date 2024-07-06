-- 3장.테이블 엑세스 최소화
INSERT INTO 고객_임시 
SELECT /*+ full(c) full(h) index_ffs(m.고객변경이력) 
		   ordered no_merge(m) use_hash(m) use_hash(h) */
		c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
FROM 고객 c 
	,(SELECT 고객번호, max(변경일시) 최종변경일시 
	  FROM 고객변경이력 
	  WHERE 변경일시 >= trunc(add_months(sysdate, -12), 'mm') 
	  AND 변경일시 < trunc(sysdate, 'mm')
	  GROUP BY 고객번호) m
	, 고객변경이력 h 
WHERE c.고구분코드 = 'A001'
AND m.고객번호 = c.고객번호 
AND h.고객번호 = m.고객번호 
AND h.변경일시 = m.최종변경일시; 


INSERT INTO 고객_임시 
SELECT 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시 
FROM (
		SELECT /*+ full(c) full(h) leading(c) use_hash(h) */
				c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
				, rank() OVER (PARTITION BY h.고객번호 ORDER BY h.변경일시 desc) NO 
		FROM 고객 c, 고객변경이력 h 
		WHERE c.고구분코드 = 'A001'
		AND h.변경일시 >= trunc(add_months(sysdate, -12), 'mm') 
		AND h.변경일시 < trunc(sysdate, 'mm')
		AND h.고객번호 = c.고객번호 
)
WHERE NO = 1; 

CREATE TABLE 영업실적 (사번 varchar2(5), 일자 varchar2(8), CONSTRAINT 영업실적_pk PRIMARY KEY (사번, 일자)) 
organization INDEX;

-- 인덱스 클러스터 테이블 구성
-- 1. 클러스터 생성
create cluster c_dept# (deptno number(2)) index;

-- 2. 클러스터 인덱스 정의 -> 클러스터 인덱스는 데이터 검색 용도로 사용할 뿐만 아니라 데이터가 저장된 위치를 찾을때도 사용. 
create index c_dept#_idx on cluster c_dept#;

-- 3. 클러스터 테이블 생성
create table dept (
  deptno number(2) not null
, dname varchar2(14) not null
, loc varchar2(13) )
cluster c_dept#(deptno);

-- 4. 클러스터 인덱스로 조회할 때 실행계획 
SQL > select * from dept where deptno = :deptno;

Execution Plan
-------------------------------------------------------------------
0   SELECT STATEMENT Optimizer=ALL_ROWS (Cost=1 Card=1 Bytes=30)
1 0  TABLE ACCESS (CLUSTER) OF 'DEPT' (CLUSTER) (Cost=1 Card=1 Bytes=30)
2 1   INDEX (UNIQUE SCAN) OF 'C_DEPT#_IDX' (INDEX (CLUSTER)) (Cost=1 Card=1) 


-- 해시 클러스터 테이블 구성
-- 1. 클러스터 생성
create cluster c_dept# (deptno number(2)) hashkeys 4 ;

-- 2. 클러스터 테이블 생성
create table dept (
  deptno number(2) not null
, dname varchar2(14) not null
, loc varchar2(13) )
cluster c_dept#( deptno );

-- 3. 해시 클러스터 조회할 때 실행계획 
SQL > select * from dept where deptno = :deptno;

Execution Plan
-------------------------------------------------------------------
0   SELECT STATEMENT Optimizer=ALL_ROWS (Cost=0 Card=1 Bytes=30)
1 0  TABLE ACCESS (HASH) OF 'DEPT' (CLUSTER (HASH)) (Card=1 Bytes=30)


-- ========================================================================================
-- ========================================================================================
-- 3-2. 부분범위 처리 활용 

SQL> create index emp_x01 on emp(deptno, job, empno);

Index created.

SQL> set autotrace traceonly exp;
SQL> select * from emp e where deptno = 20 order by job, empno;

Execution Plan
----------------------------------------------------------
Plan hash value: 1549005378

---------------------------------------------------------------------------------------
| Id  | Operation		    		| Name    | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	    	|	      |     5 |   190 |     2	(0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP     |     5 |   190 |     2	(0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN	    	| EMP_X01 |     5 |       |     1	(0)| 00:00:01 |
---------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("DEPTNO"=20)

   
-- ========================================================================================
-- ========================================================================================
-- 3-3. 인덱스 스캔 효율화 
SELECT * FROM dual WHERE NULL LIKE '' || '%';