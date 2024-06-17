-- =================================================
-- 2024.06.14 ~ 
-- =================================================

-- 실명확인번호 조건에 해당하는 데이터가 한 건이거나 소량일때 => NL조인 
SELECT c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
FROM 고객 c, 고객변경이력 h 
WHERE c.실명확인번호 = :rmnno
AND h.고객번호 = c.고객번호 
AND h.변경일시 = (SELECT max(변경일시) 
				FROM 고객변경이력 m 
				WHERE 고객번호 = c.고객번호 
				AND 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
				AND 변경일시 < trunc(sysdate, 'mm'));
			
-- 전체 300만 명 중 고객구분코드 조건을 만족하는 고객 100만명 
-- 아래 쿼리는 빠른 성능 낼 수 없음.
INSERT INTO 고객_임시 
SELECT c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
FROM 고객 c, 고객변경이력 h 
WHERE c.고객구분코드 = 'A001' -- 100만명 
AND h.고객번호 = c.고객번호 
AND h.변경일시 = (SELECT max(변경일시) 
				FROM 고객변경이력 m 
				WHERE 고객번호 = c.고객번호 
				AND 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
				AND 변경일시 < trunc(sysdate, 'mm'));
				
-- 데이터가 많으므로 Full Scan + 해시 조인 방식이 효과적 
INSERT INTO 고객_임시 
SELECT /*+ full(c) full(h) index_ffs(m.고객변경이력)
		   ordered no_merge(m) use_hash(m) use_hash(h) */
		c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
FROM 고객 c 
	,(SELECT 고객번호, max(변경일시) 최종변경일시 
	  FROM 고객변경이력 
	  WHERE 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
	  AND 변경일시 < trunc(sysdate, 'mm') 
	  GROUP BY 고객버호) m 
	, 고객변경이력 h 
WHERE c.고객구분코드 = 'A001'
AND m.고객번호 = c.고객번호 
AND h.고객번호 = m.고객번호 
AND h.변경일시 = m.최종변경일시; 

-- 고객 테이블 한 번만 읽고 싶을땐 아래 처럼
INSERT INTO 고객_임시
SELECT 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시 
FROM (SELECT /*+ full(c) full(h) leading(c) use_hash(h) */
			 c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
			 , rank() OVER(PARTITION BY h.고객번호 ORDER BY h.변경일시 desc) NO 
	  FROM 고객 c, 고객변경이력 h 
	  WHERE c.고객구분코드 = 'A001'
	  AND h.변경일시 >= trunc(add_months(sysdate, -12), 'mm')
	  AND h.변경일시 < trunc(sysdate, 'mm')
	  AND h.고객번호 = c.고객번호)
WHERE NO = 1 


SELECT 부서번호, SUM(수량)
FROM 판매집계 
WHERE 부서번호 LIKE '12%'
GROUP BY 부서번호; 

-- IOT / 클러스터형 인덱스 : 테이블 블록 데이터를 인덱스 리프 블록에서 모두 저장 
-- IOT는 인덱스 구조 테이블 -> 정렬 상태를 유지하면서 데이터 입력 
-- 테이블을 인덱스 구조로 만듬. 
create table index_org_t (a number, b varchar(10), constraint index_org_t_pk primary key (a));
organization index;

-- 일반 테이블 = '힙 구조 테이블' -> 데이터를 입력할 때 랜덤 방식을 사용 
create table heap_org_t (a number, b varchar(10), constraint heap_org_t_pk primary key (a));
organization heap; 

-- IOT는 인위적으로 클러스터링 팩터를 좋게 만드는 방법 중 하나. 
-- ex) 실등록은 일자별로 하고 실적조회는 사원별로 한다. 
--     -> 클러스터링 팩터가 매우 안 좋아서 조회 건수 만큼 블록 I/O 발생 
select substr(일자, 1, 6) 월도 
    , sum(판매금액) 총판매금액, avg(판매금액) 평균판매금액 
from 영업실적 
where 사번 = 'S1234'
and 일자 between '20180101' and '20181231'
group by substr(일자, 1, 6);

-- 사번이 첫 번째 정렬 기준이 되도록 IOT를 구성 -> 네 개 블록만 읽고 처리 가능 
create table 영업실적 (사번 varchar2(5), 일자 varchar2(8), ..., constraint 영업실적_pk primary key (사번, 일자)) organization index; 


-- 클러스터 테이블 : 키 값이 같은 데이터를 같은 공간에 저장해둘 뿐, IOT나 SQL Server의 클러스터형 인덱스처럼 정렬하지 않음. 
--  1. 인덱스 클러스터 
--    1) 클러스터 생성 
create cluster c_dept# (deptno number(2)) index; 
--    2) 클러스터 인덱스 정의 : 클러스터 인덱스는 데이터 검색 용도로 사용할 뿐만 아니라 데이터 저장될 위치를 찾을 때도 사용하기 때문에 반드시 정의 
create index c_dept#_idx on cluster c_dept#;
--    3) 클러스터 테이블 생성 
create table dept (
   deptno number(2) not null, 
   dname varchar2(14) not null, 
   loc varchar2(13)
)
cluster c_dept#(deptno);

--  2. 해시 클러스터 
--    1) 클러스터 생성
create cluster c_dept# (deptno number(2)) hashkeys 4;
--    2) 클러스터 테이블 생성 
create table dept (
   deptno number(2) not null, 
   dname varchar2(14) not null, 
   loc varchar2(13)
)
cluster c_dept#(deptno);


-- 부분범위처리 : 앞쪽 일부만 출력하고 멈출수 있는가. 

-- 배치 I/O
create index emp_x01 on emp(deptno, job, empno);
set autotrace traceonly exp;
select * from emp e where deptno = 20 order by job, empno; 

select /*+ batch_table_access_by_rowid(e) */ *
from emp e 
where deptno = 20 
order by job, empno; 


-- 인덱스를 이용한 테이블 액세스 비용 
-- 비용 = 인덱스 수직적 탐색 비용 + 인덱스 수평적 탐색 비용 + 테이블 랜덤 액세스 비용 
--     = 인덱스 루트와 브랜치 레벨에서 읽는 블록 수 +
--       인덱스 리프 블록을 스캔하는 과정에서 읽는 블록 수 + 
--       테이블 액세스 과정에서 읽는 블록 수 


-- 4장.조인튜닝 
SELECT e.사원명, c.고객명, c.전화번호
FROM 사원 e, 고객 c 
WHERE e.입사일자 >= '19960101'
AND c.관리사원번호 = e.사원번호; 

-- 일반적으로 NL조인은 Outer와 Inner 양쪽 테이블 모두 인덱스를 이용. 
BEGIN
	FOR OUTER IN (SELECT 사원번호, 사원명 FROM 사원 WHERE 입사일자 >= '19960101')
	loop -- OUTER 루프
		FOR INNER IN (SELECT 고객명, 전화번호 FROM 고객
					  WHERE 관리사원번호 = OUTER.사원번호) 
		loop -- INNER 루프 
			dbms_output.put_line (
				OUTER.사원명 || ' : ' || INNER.고객명 || ' : ' || INNER.전화번호 
			);
		end loop;		
	end loop;
END;

-- use_nl 힌트
-- ordred 와 use_nl 힌트를 같이 사용했으므로 사원 테이블 (-> Driving 또는 Outger Table) 기준으로 고객 테이블 (-> Inner 테이블)과 NL 방식으로 조인하라는 뜻. 
SELECT /*+ ordered use_nl(c) */
		e.사원명, c.고객명, c.전화번호
FROM 사원 e, 고객 c 
WHERE e.입사일자 >= '19960101'
AND c.관리사원번호 = e.사원번호;

-- 사원_PK : 사원번호
-- 사원_X1 : 입사일자 * 
-- 고객_PK : 고객번호 
-- 고객_X1 : 관리사원번호 *  
-- 고객_X2 : 최종주문금액 
SELECT /+ ordered use_nl(c) index(e) index(c) */ 
		e.사원번호, e.사원명, e.입사일자,
		c.고객번호, c.고객명, c.전화번호, c.최종주문금액 
FROM 사원 e, 고객 c 
WHERE c.관리사원번호 = e.사원번호 -- 3 
AND e.입사일자 >= '19960101' -- 1
AND e.부서코드 = 'Z123' -- 2
AND c.최종주문금액 >= 20000; -- 4

-- [중요] 각 단계를 모두 완료하고 다음 단계로 넘어가는 게 아니라 한 레코드씩 순차적으로 진행. 

-- NL 조인 특성 => 소량 데이터를 주로 처리하거나 부분 범위 처리가 가능한 온라인 트랜잭션 처리(OLTP) 시스템에 적합. 
-- 1) 랜덤 액세스 위주의 조인 방식 
-- 2) 한 레코드씩 순차적으로 진행한다는 점
--    -> 대량의 데이터 처리 시 치명적인 한계 발생 
--    -> 아무리 큰테이블을 조인해도 매우 빠른 속도를 낼 수 있음. (부분범위 처리가 가능한 상황이라면) 
-- 3) 인덱스 구성 전략이 특히 중요 

SELECT /*+ ordered use_nl(b) index_desc(a(게시판구분, 등록일시)) */ 
	a.게시글ID, a.제목, b.작성자명, a.등록일시 
FROM 게시판 a, 사용자 b 
WHERE a.게시판구분 = 'NEWS'	-- 게시판IDX: 게시판구분 + 등록일시 
AND b.사용자ID = a.작성자 ID 	-- 사용자IDX: 사용자ID 
ORDER BY a.등록일시 DESC; 

-- cr : 논리적인 블록 요청 횟수 
-- pr : 디스크에서 읽은 블록 수 
-- pw : 디스크에 쓴 블록 수 

-- NL 조인 성능 높이기 위해 '테이블 Prefetch', '배치 I/O' 기능을 도입. 

SELECT * 
FROM PRA_HST_STC a, ODEM_TRMS b 
WHERE a.SALE_ORG_ID = :sale_org_id 
AND b.STRD_GRP_ID = a.STRD_GRP_ID
AND b.STRD_ID = a.STRD_ID
ORDER BY a.STC_DT DESC; 

SELECT /*+ ordered use_nl(b) */ 
		A.등록일시, A.번호, A.제목, B.회원명, A.게시판유형, A.질문유형 
FROM (
	SELECT A.*, ROWNUM NO 
	FROM (
		SELECT 등록일시, 번호, 제목, 작성자번호, 게시판유형, 질문유형 
		FROM 게시판 
		WHERE 게시판유형 = :TYPE
		ORDER BY 등록일시 DESC -- 인덱스 구성 : 게시판유형 + 등록일시 
	) A 
	WHERE ROWNUM <= (:page * 10)
) A, 회원 B
WHERE A.NO >= (:page - 1) * 10 + 1
AND B.회원번호 = A.작성자번호 
ORDER BY A.등록일시 DESC; -- 11g부터 여기에 ORDER BY를 명시해야 정렬 순서 보장 

-- 소트 머지 조인 
--  1) 소트 단계 : 양쪽 집합을 조인 컬럼 기준으로 정렬 
--  2) 머지 단계 : 정렬한 양쪽 집합을 서로 머지 (Merge)

SELECT /*+ ordered use_merge(c) */
		e.사원번호, e.사원명, e.입사일자 
		, c.고객번호, c.고객명, c.전화번호, c.최종주문금액 
FROM 사원 e, 고객 c 
WHERE c.고객사원번호 = e.사원번호 
AND e.입사일자 >= '19960101'
AND e.부서코드 = 'Z123'
AND c.최종주문금액 >= 20000; 

-- 1) [소트단계] 아래 결과집합을 PGA 영역에 할당된 Sort Area에 저장 -> PGA 담을수 없을 정도로 크면, Temp 테이블 스페이스에 저장. 
SELECT 사원번호, 사원명, 입사일자 
FROM 사원 
WHERE 입사일자 >= '19960101'
AND 부서코드 = 'Z123'
ORDER BY 사원번호; 

-- 2) [소트단계] 아래 결과집합을 PGA 영역에 할당된 Sort Area에 저장 -> PGA 담을수 없을 정도로 크면, Temp 테이블 스페이스에 저장. 
SELECT 고객번호, 고객명, 전화번호, 최종주문금액, 관리사원번호 
FROM 고객 c 
WHERE 최종주문금액 >= 20000 
ORDER BY 관리사원번호; 

-- 3) [머지단계]
BEGIN 
	FOR OUTER IN (SELECT * FROM PGA에_정렬된_사원)
	loop -- OUTER 루프 
		FOR INNER IN (SELECT * FROM PGA에_정렬된_고객
					  WHERE 관리사원번호 = OUTER.사원번호)
		loop -- INNER 루프 
			dbms_output.put_line ( ... );
		end loop;
	end loop;
END;


-- 해시 조인 
--  1) Build 단계 : 작은 쪽 테이블(Build Input)을 읽어 해시 테이블(해시 맵)을 생성한다. 
--  2) Probe 단계 : 큰 쪽 테이블(Probe Input)을 읽어 해시 테이블을 탐색하면서 조인한다. 

SELECT /*+ ordered use_hash(c) */
		e.사원번호, e.사원명, e.입사일자 
		, c.고객번호, c.고객명, c.전화번호, c.최종주문금액 
FROM 사원 e, 고객 c 
WHERE c.고객사원번호 = e.사원번호 
AND e.입사일자 >= '19960101'
AND e.부서코드 = 'Z123'
AND c.최종주문금액 >= 20000; 

-- 1) Build : 해시 테이블 생성. PGA 영역에 할당된 Hash Area에 저장. PGA에 담을 수 없으면 Temp 테이블스페이스에 저장. 
SELECT 사원번호, 사원명, 입사일자 
FROM 사원 
WHERE 입사일자 >= '19960101'
AND 부서코드 = 'Z123';

-- 2) Probe : 고객 데이터를 하나씩 읽어 1)에서 생성한 해시 테이블을 탐색. 
SELECT 고객번호, 고객명, 전화번호, 최종주문금액, 관리사원번호 
FROM 고객 
WHERE 최종주문금액 >= 20000; 

-- 3) PL/SQL
BEGIN 
	FOR OUTER IN (SELECT 고객번호, 고객명, 전화번호, 최종주문금액, 관리사원번호
				  FROM 고객 
				  WHERE 최종주문금액 >= 20000)
	loop -- OUTER 루프 
		FOR INNER JOIN (SELECT 사원번호, 사원명, 입사일자 
						FROM PGA에_생성한_사원_해시맵
						WHERE 사원번호 = OUTER.관리사원번호)
		loop -- INNER 루프 
			dbms_output.put_line( ... );
		end loop;
	end loop;
END;
