-- 5-1.소트 연산에 대한 이해

(1) Sort Aggregate 
  - Sort Aggregate는 아래처럼 전체 로우를 대상으로 집계를 수행할 때 나타남. 
  - 'Sort'라는 표현을 사용하지만, 실제로 데이터를 정렬하지 않고 Sort Area를 사용한다는 의미로 이해하면 됨.

SQL > select sum(sal), max(sal), min(sal), avg(sal) from emp;

---------------------------------------------------------------------------
| Id | Operation           | Name | Rows | Bytes | Cost (%CPU) | Time     |
---------------------------------------------------------------------------
|  0 | SELECT STATEMENT    |      |    1 |     4 |     3   (0) | 00:00:01 |
|  1 |  SORT AGGREGATE     |      |    1 |     4 |             |          |
|  2 |   TABLE ACCESS FULL |  EMP |   14 |    56 |     3   (0) | 00:00:01 |
---------------------------------------------------------------------------


(2) Sort Order By
  - Sort Order By는 데이터를 정렬할 때 나타남. 

SQL > select * from emp order by sal desc;

---------------------------------------------------------------------------
| Id | Operation           | Name | Rows | Bytes | Cost (%CPU) | Time     |
---------------------------------------------------------------------------
|  0 | SELECT STATEMENT    |      |   14 |   518 |    4   (25) | 00:00:01 |
|  1 |  SORT ORDER BY      |      |   14 |   518 |    4   (25) | 00:00:01 |
|  2 |   TABLE ACCESS FULL |  EMP |   14 |   518 |    3    (0) | 00:00:01 |
---------------------------------------------------------------------------


(3) Sort Group By
  - Sort Group By는 소팅 알고리즘을 사용해 그룹별 집계를 수행할 때 나타남. 

SQL > select deptno, sum(sal), max(sal), min(Sal), avg(sal)
  2   from emp
  3   group by deptno
  4   order by deptno

---------------------------------------------------------------------------
| Id | Operation           | Name | Rows | Bytes | Cost (%CPU) | Time     |
---------------------------------------------------------------------------
|  0 | SELECT STATEMENT    |      |   11 |   165 |    4   (25) | 00:00:01 |
|  1 |  SORT GROUP BY      |      |   11 |   165 |    4   (25) | 00:00:01 |
|  2 |   TABLE ACCESS FULL |  EMP |   14 |   210 |    3    (0) | 00:00:01 |
---------------------------------------------------------------------------

// 10gR2 버전에서 도입된 Hash Group By
// Sort Group By -> 소트 알고리즘, Hash Group By -> 해싱 알고리즘 
// 'Sort Group By'의 의미는 "소팅 알고리즘을 사용해 값을 집계한다"는 뜻일 뿐 결과의 정렬을 의미하지 않음. 
// 정렬을 하려면 Order By 절을 명시해야하고 이때도 실행계획은 똑같이 'Sort Group By'로 표시되므로 실행계획만 보고 정렬 여부 판단 x 
// [!!] 정렬된 그룹핑 결과를 얻고자 한다면, 실행계획에 설령 'Sort Group By'라고 표시되더라도 반드시 Order By를 명시. 
SQL > select deptno, sum(sal), max(sal), min(sal), avg(sal)
  2   from emp 
  3.  group by deptno; 

---------------------------------------------------------------------------
| Id | Operation           | Name | Rows | Bytes | Cost (%CPU) | Time     |
---------------------------------------------------------------------------
|  0 | SELECT STATEMENT    |      |   11 |   165 |    4   (25) | 00:00:01 |
|  1 |  HASH GROUP BY      |      |   11 |   165 |    4   (25) | 00:00:01 |
|  2 |   TABLE ACCESS FULL |  EMP |   14 |   210 |    3    (0) | 00:00:01 |
---------------------------------------------------------------------------

(4) Sort Unique
  - 옵티마이저가 서브쿼리를 풀어 일반 조인문으로 변환하는 것을 '서브쿼리 Unnesting'이라고 함. 
  - Unnesting된 서브쿼리가 M쪽 집합이면, 메인 쿼리와 조인하기 전에 중복 레코드부터 제거해야 하는데, 
    이때 아래와 같이 Sort Unique 오퍼레이션이 나타남. 
  - 만약 PK/Unique 제약 또는 Unique 인덱스를 통해 Unnesting된 서브쿼리의 유일성(Uniqueness)이 보장된다면,
    Sort Unique 오퍼레이션은 생략됨. 

SQL > select /*+ ordered use_nl(dept) */ * from dept 
  2   where deptno in (select /*+ unnest */ deptno from emp where job = 'CLERK'); 

----------------------------------------------------------------------------------
| Id | Operation                      | Name        | Rows | Bytes | Cost (%CPU) | 
----------------------------------------------------------------------------------
|  0 | SELECT STATEMENT               |             |    3 |    87 |    4   (25) |
|  1 |  NESTED LOOPS                  |             |    3 |    87 |    4   (25) |
|  2 |   SORT UNIQUE                  |             |    3 |    33 |    2   (0)  |
|  3 |    TABLE ACCESS BY INDEX ROWID |         EMP |    3 |    33 |    2   (0)  |
|  4 |     INDEX RANGE SCAN           | EMP_JOB_IDX |    3 |       |    1   (0)  |
|  5 |    TABLE ACCESS BY INDEX ROWID |        DEPT |    1 |    18 |    1   (0)  |
|  6 |     INDEX UNIQUE SCAN          |     DEPT_PK |    1 |       |    0   (0)  |
----------------------------------------------------------------------------------

  - Union, Minus, Intersect 같은 집합(Set) 연산자를 사용할 떄도 아래와 같이 Sort Unique 오퍼레이션이 나타남. 

SQL > select job, mgr from emp where deptno = 10
  2   union
  3   select job, mgr from emp where deptno = 20; 

----------------------------------------------------------------------------
| Id | Operation            | Name | Rows | Bytes | Cost (%CPU) | Time     |
----------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |      |   10 |   150 |    8   (63) | 00:00:01 |
|  1 |  SORT UNIQUE         |      |   10 |   150 |    8   (63) | 00:00:01 |
|  2 |   UNION-ALL          |      |      |       |             |          |
|  3 |    TABLE ACCESS FULL |  EMP |    5 |    75 |    3    (0) | 00:00:01 |
|  4 |    TABLE ACCESS FULL |  EMP |    5 |    75 |    3    (0) | 00:00:01 |
----------------------------------------------------------------------------

SQL > select job, mgr from emp where deptno = 10
  2   minus
  3   select job, mgr from emp where deptno = 20; 

----------------------------------------------------------------------------
| Id | Operation            | Name | Rows | Bytes | Cost (%CPU) | Time     |
----------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |      |    5 |   150 |    8   (63) | 00:00:01 |
|  1 |  MINUS               |      |      |       |             |          |
|  2 |   SORT UNIQUE        |      |    5 |    75 |    4   (25) | 00:00:01 |
|  3 |    TABLE ACCESS FULL |  EMP |    5 |    75 |    3    (0) | 00:00:01 |
|  4 |   SORT UNIQUE        |      |    5 |    75 |    4   (25) | 00:00:01 |
|  5 |    TABLE ACCESS FULL |  EMP |    5 |    75 |    3    (0) | 00:00:01 |
----------------------------------------------------------------------------

SQL > select distinct job, mgr from emp where deptno = 10

----------------------------------------------------------------------------
| Id | Operation            | Name | Rows | Bytes | Cost (%CPU) | Time     |
----------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |      |    3 |     9 |    5   (40) | 00:00:01 |
|  1 |  SORT UNIQUE         |      |    3 |     9 |    4   (25) | 00:00:01 |
|  2 |   TABLE ACCESS FULL  |  EMP |      |    42 |    2    (0) | 00:00:01 |
----------------------------------------------------------------------------
----------------------------------------------------------------------------
| Id | Operation            | Name | Rows | Bytes | Cost (%CPU) | Time     |
----------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |      |    3 |     9 |    5   (40) | 00:00:01 |
|  1 |  HASH UNIQUE         |      |    3 |     9 |    4   (25) | 00:00:01 |
|  2 |   TABLE ACCESS FULL  |  EMP |      |    42 |    2    (0) | 00:00:01 |
----------------------------------------------------------------------------

(5) Sort Join 
  - Sort Join 오퍼레이션은 소트 머지 조인을 수행할 때 나타남.

SQL > select /*+ ordered use_merge(e) */ *
  2   from dept d, emp e
  3   where d.deptno = e.deptno;

----------------------------------------------------------------------------
| Id | Operation            | Name | Rows | Bytes | Cost (%CPU) | Time     |
----------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |      |   14 |   770 |    8   (25) | 00:00:01 |
|  1 |  MERGE JOIN          |      |   14 |   770 |    8   (25) | 00:00:01 |
|  2 |   SORT JOIN          |      |    4 |    72 |    4   (25) | 00:00:01 |
|  3 |    TABLE ACCESS FULL | DEPT |    4 |    72 |    3    (0) | 00:00:01 |
|  4 |   SORT JOIN          |      |   14 |   518 |    4   (25) | 00:00:01 |
|  5 |    TABLE ACCESS FULL |  EMP |   14 |   518 |    3    (0) | 00:00:01 |
----------------------------------------------------------------------------


(6) Window Sort 
  - Window Sort는 윈도우 함수(=분석 함수)를 수행할 때 나타남. 

SQL > select empno, ename, job, mgr, sal
  2        , avg(sal) over (partition by deptno)
  3   from emp;

----------------------------------------------------------------------------
| Id | Operation            | Name | Rows | Bytes | Cost (%CPU) | Time     |
----------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |      |   14 |   406 |    4   (25) | 00:00:01 |
|  1 |  WINDOW SORT         |      |   14 |   406 |    4   (25) | 00:00:01 |
|  2 |   TABLE ACCESS FULL  |  EMP |   14 |   406 |    3    (0) | 00:00:01 |
----------------------------------------------------------------------------


-- =================================================================================
-- =================================================================================
-- 5-2.소트가 발생하지 않도록 SQL 작성
select 결제번호, 결제수단코드, 주문번호, 결제금액, 결제일자, 주문금액 ...
from 결제 
where 결제일자 = '20180316'
UNION ALL 
select 결제번호, 결제수단코드, 주문번호, 결제금액, 결제일자, 주문금액 ...
from 결제 
where 주문일자 = '20180316'
and 결제일자 <> '20180316'

Execution Plan
------------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=0 Card=2 Bytes=106)
1 0    UNION-ALL
2 1      FILTER
3 2        TABLE ACCESS (BY INDEX ROWID) OF '결제' (TABLE) (Cost=0 Card=1 ... )
4 3          INDEX (RANGE SCAN) OF '결제_N2' (INDEX) (Cost=0 Card=1)
5 1      FILTER
6 5        TABLE ACCESS (BY INDEX ROWID) OF '결제' (TABLE) (Cost=0 Card=1 ... )
7 6          INDEX (RANGE SCAN) OF '결제_N3' (INDEX) (Cost=0 Card=1)

-- // 결제일자가 Null 허용 컬럼이면 맨 아래 조건절을 아래와 같이 변경
and (결제일자 <> '20180316' or 결제일자 is null)

-- // 또는 LNNVL 함수 사용
and LNNVL(결제일자 = '20180316')

-- <before>
-- // 상품유형코드 조건절에 해당하는 상품에 대해 계약일자 조건 기간에 발생한 계약 데이터를 모두 읽는 비효율이 존재.
-- // 상품 수는 적고 상품별 계약 건수가 많을수록 비효율이 큰 패턴.
select DISTINCT p.상품번호, p.상품명, p.상품가격, ...
from 상품 p, 계약 c
where p.상품유형코드 = :pclscd
and c.상품번호 = p.상품번호
and c.계약일자 between :dt1 and :dt2
and c.계약구분코드 = :cptcd

-- <after>
-- // Exists 서브쿼리는 데이터 존재 여부만 확인하면 되기 때문에 조건절을 만족하는 데이터를 모두 읽지 않음. 
-- // Distinct 연산자를 사용하지 않았으므로 상품 테이블에 대한 부분범위 처리도 가능. 
select p.상품번호, p.상품명, p.상품가격 ...
from 상품 p
where p.상품유형코드 = :pclscd
and EXITS (select 'x' from 계약 c
           where c.상품번호 = p.상품번호
           and c.계약일자 between :dt1 and dt2
           and c.계약구분코드 = :ctpcd)

-- <before>
-- // Distinct, Minus 연산자를 사용하는 쿼리는 대부분 Exists 서브쿼리로 변환 가능.
SELECT ST.상황접수번호, ST.관제일련번호, ST.상황코드, ST.관제일시
FROM 관제진행상황 ST
WHERE 상황코드 = '0001' -- 신고접수
AND 관제일시 BETWEEN :V_TIMEFROM || '000000' AND :V_TIMETO || '235959'
MINUS
SELECT ST.상황접수번호, ST.관제일련번호, ST.상황코드, ST.관제일시
FROM 관제진행상황 ST, 구조활동 RPT
WHERE 상황코드 = '0001'
AND 관제일시 BETWEEN :V_TIMEFROM || '000000' AND :V_TIMETO || '235959' 
AND PRT.출동센터ID = :V_CNTR_ID
AND ST.상황접수번호 = RPT.상황접수번호
ORDER BY 상황접수번호, 관제일시

-- <after>
SELECT ST.상황접수번호, ST.관제일련번호, ST.상황코드, ST.관제일시
FROM 관제진행상황 ST
WHERE 상황코드 = '0001' -- 신고접수
AND 관제일시 BETWEEN :V_TIMEFROM || '000000' AND :V_TIMETO || '235959'
AND NOT EXISTS (SELECT 'X' FROM 구조활동
                WHERE 출동센터ID = :V_CNTR_ID
                AND 상황접수번호 = ST.상황접수번호)
ORDER BY ST.상황접수번호, ST.관제일시


-- =================================================================================
-- =================================================================================
-- 5-3.소트가 발생하지 않도록 SQL 작성
-- * 종목거래_PK : 종목코드 + 거래일시
-- * 종목거래_N1 : 종목코드 

select 거래일시, 체결건수, 채결수량, 거래대금
from 종목거래
where 종목코드 = 'KR123456'
order by 거래일시 

-- // 종목거래_N1 
--------------------------------------------------------------------------------
| Id | Operation                     | Name      |  Rows | Bytes | Cost (%CPU) |
--------------------------------------------------------------------------------
|  0 | SELECT STATEMENT              |           | 40000 | 3515K |  2041   (1) |
|  1 |  SORT ORDER BY                |           | 40000 | 3515K |  2041   (1) |
|  2 |   TABLE ACCESS BY INDEX ROWID | 종목       | 40000 | 3515K |  1210   (1) |
|  3 |    INDEX RANGE SCAN           | 종목거래_N1 | 40000 | 3515K |    96   (2) |
--------------------------------------------------------------------------------

-- // 종목거래_PK
-- // 소트 연산을 생략함으로써 종목코드 = 'KR123456' 조건을 만족하는 전체 레코드를 읽지 않고도 바로 결과집합 출력 
-- // 부분범위 처리 가능한 상태가 되었음. 
--------------------------------------------------------------------------------
| Id | Operation                     | Name      |  Rows | Bytes | Cost (%CPU) |
--------------------------------------------------------------------------------
|  0 | SELECT STATEMENT              |           | 40000 | 3515K |  1372   (1) |
|  1 |   TABLE ACCESS BY INDEX ROWID | 종목       | 40000 | 3515K |  1372   (1) |
|  2 |    INDEX RANGE SCAN           | 종목거래_PK | 40000 | 3515K |   258   (2) |
--------------------------------------------------------------------------------

-- SQL Server 나 Sybase 
select TOP 10 거래일시, 체결건수, 체결수량, 거래대금
from 종목거래
where 종목코드 = 'KR123456'
and 거래일시 >= '20180304'
group by 거래일시

-- IBM DB2 -> Row Limiting 
select 거래일시, 체결건수, 체결수량, 거래대금
from 종목코드
where 종목코드 = 'KR123456'
and 거래일시 >= '20180304'
order by 거래일시
FETCH FIRST 10 ROWS ONLY;

-- 오라클
-- '종목코드 + 거래일시' 순으로 구성된 인덱스를 이용하면, 옵티마이저는 소트 연산을 생략. 
select * from (
  select 거래일시, 체결건수, 체결수량, 거래대금
  from 종목거래
  where 종목코드 = 'KR123456'
  and 거래일시 >= '20180304'
  order by 거래일시
)
where rownum <= 10

-- Order By 아래 쪽 ROWNUM은 단순한 조건절이 아님.
-- 'Top N Stopkey' 알고리즘을 작동하게 하는 열쇠. 
select *
from (
  select rownum no, a.*
  from 
    (
      select 거래일시, 체결건수, 체결수량, 거래대금
      from 종목거래
      where 종목코드 = 'KR123456'
      and 거래일시 >= '20180304'
      order by 거래일시
    )
  where rownum <= (:page * 10)
  )
where no >= (:page-1)*10 + 1

SELECT 장비번호, 장비명, 상태코드
     , SUBSTR(최종이력, 1, 8) 최종변경일자
     , TO_NUMBER(SUBSTR(최종이력, 9, 4)) 최종변경순번
FROM (
  SELECT 장비번호, 장비명, 상태코드
       , (SELECT MAX(H.변경일자 || LPAD(H.변경순번, 4))
          FROM 상태변경이력 H
          WHERE 장비번호 = P.장비번호) 최종이력
  FROM 장비 P
  WHERE 장비구분코드 = 'A001'
)

-- 장비별 상태변경이력이 많아 성능에 문제가 된다면, 차라리 아래와 같이 쿼리하는 게 나음. 
-- 쿼리가 복잡하고 상태변경이력을 세 번 조회하는 비효율은 있지만, 'First Row Stopkey' 알고리즘이 잘 작동하므로 성능은 비교적 좋음. 
SELECT 장비번호, 장비명, 상태코드
     , (SELECT MAX(H.변경일자)
        FROM 상태변경이력 H
        WHERE 장비번호 = P.장비번호) 최종변경일자
     , (SELECT MAX(H.변경순번)
        FROM 상태변경이력 H
        WHERE 장비번호 = P.장비번호
        AND 변경일자 = (SELECT MAX(H.변경일자)
                      FROM 상태변경이력 H
                      WHERE 장비번호 = P.장비번호)) 최종변경순번
FROM 장비 P
WHERE 장비구분코드 = 'A001'

-- INDEX_DESC 힌트 활용 
-- 이 방식의 성능은 좋지만 인덱스 구성이 완벽해야만 쿼리가 잘 작동하는 문제가 있다. 
SELECT 장비번호, 장비명
     , SUBSTR(최종이력, 1, 8) 최종변경일자
     , TO_NUMBER(SUBSTR(최종이력, 9, 4)) 최종변경순번
     , SUBSTR(최종이력, 13) 최종상태코드
FROM (
  SELECT 장비번호, 장비명
       , (SELECT /*+ INDEX_DESC(X 상태변경이력_PK) */
                 변경일자 || LPAD(변경순번, 4) || 상태코드
          FROM 상태변경이력 X
          WHERE 장비번호 = P.장비번호
          AND ROWNUM <= 1) 최종이력
  FROM 장비 P
  WHERE 장비구분코드 = 'A001'
)

-- 12c에서는 아래와 같은 패턴도 SQL 파싱 오류 없이 'Top N Stopkey' 알고리즘이 잘 작동함. 
SELECT 장비번호, 장비명
     , SUBSTR(최종이력, 1, 8) 최종벼경일자
     , TO_NUMBER(SUBSTR(최종이력, 9, 4)) 최종변경순번
     , SUBSTR(최종이력, 13) 최종상태코드
FROM (
    SELECT 장비번호, 장비명
         , (SELECT 변경일자 || LPAD(변경순번, 4) || 상태코드
            FROM (SELECT 변경일자, 변경순번, 상태코드
                  FROM 상태변경이력
                  WHERE 장비번호 = P.장비번호
                  ORDER BY 변경일자 DESC, 변경순번 DESC)
            WHERE ROWNUM <= 1) 최종이력
     FROM 장비 P
     WHERE 장비구분코드 = 'A001'
)

-- 전체 장비의 이력을 조회할 때는 아래와 같이 윈도우 함수를 이용하는 것이 효과적.
-- Full Scan과 해시 조인을 이용하기 때문에 오랜 과거 이력까지 모두 읽지만, 인덱스를 이용하는 방식보다 빠름. 
SELECT P.장비번호, P.장비명
     , H.변경일자 AS 최종변경일자
     , H.변경순번 AS 최종변경순번
     , H.상태코드 AS 최종상태코드
FROM 장비 P
   , (SELECT 장비번호, 변경일자, 변경순번, 상태코드
           , ROWNUM() OVER (PARTITION BY 장비번호 ORDER BY 변경일자 DESC, 변경순번 DESC) RNUM
      FROM 상태변경이력) H
WHERE H.장비번호 = P.장비번호
AND H.RNUM = 1;

-- KEEP 절을 활용할 수도 있음. 
SELECT P.장비번호, P.장비명
     , H.변경일자 AS 최종변경일자
     , H.변경순번 AS 최종변경순번
     , H.상태코드 AS 최종상태코드
FROM 장비 P
   , (SELECT 장비번호
           , MAX(변경일자) 변경일자
           , MAX(변경순번) KEEP (DENSE_RANK LAST ORDER BY 변경일자, 변경순번) 변경순번
           , MAX(상태코드) KEEP (DENSE_RANK LAST ORDER BY 변경일자, 변경순번) 상태코드
      FROM 상태변경이력
      GROUP BY 장비번호) H
WHERE H.장비번호 = P.장비번호

-- 선분이력 (유효시작일자, 유효종료일자) 모델을 채택하면, 아래와 같이 간단한 쿼리로 쉽게 이력을 조회할 수 있고
-- 쿼리가 간단한만큼 성능 측면에 이점이 생김
SELECT P.장비번호, P.장비명
     , H.상태코드, H.유효시작일자, H.유효종료일자, H.변경순번
FROM 장비 P, 상태변경이력 H
WHERE P.장비구분코드 = 'A001'
AND H.장비번호 = P.장비번호
AND H.유효종료일자 = '99991231'

SELECT P.장비번호, P.장비명
     , H.상태코드, H.유효시작일자, H.유효종료일자, H.변경순번
FROM 장비 P, 상태변경이력 H
WHERE P.장비구분코드 = 'A001'
AND H.장비번호 = P.장비번호
AND :BASE_DT BETWEEN H.유효시작일자 AND H.유효종료일자


-- =================================================================================
-- =================================================================================
-- 5-4.Sort Area를 적게 사용하도록 SQL 작성
-- [1번] 보다 [2번]이 Sort Area를 더 적게 사용. 
-- [1번] 
select lpad(상품번호, 30) || lpad(상품명, 30) || lpad(고객ID, 10)
    || lpad(고객명, 20) || to_char(주문일시, 'yyyymmdd hh24:mi:ss')
from 주문상품
where 주문일시 between :start and :end 

-- [2번]
select lpad(상품번호, 30) || lpad(상품명, 30) || lpad(고객ID, 10)
    || lpad(고객명, 20) || to_char(주문일시, 'yyyymmdd hh24:mi:ss')
from (
  select 상품번호, 상품면, 고객ID, 고객명, 주문일시
  from 주문상품
  where 주문일시 between :start and :end
  order by 상품번호
)

-- [1번] 보다 [2번]이 Sort Area를 더 적게 사용. 
-- [1번]
SELECT *
FROM 예수금원장
ORDER BY 총예수금 desc

Execution Plan
---------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=184K Card=2M Bytes=716M)
1 0    SORT (ORDER BY) (Cost=184K Card=2M Bytes=716M)
2 1      TABLE ACCESS (FULL) OF '예수금원장' (TABLE) (Cost=25K Card=2M Bytes=716M) 

-- [2번] 
SELECT 계좌번호, 총예수금
FROM 예수금원장
ORDER BY 총예수금 desc

Execution Plan
---------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=31K Card=2M Bytes=17M)
1 0    SORT (ORDER BY) (Cost=31K Card=2M Bytes=17M)
2 1      TABLE ACCESS (FULL) OF '예수금원장' (TABLE) (Cost=24K Card=2M Bytes=17M) 


-- 윈도우 함수 중 rank나 row_number 함수는 max 함수보다 소트 부하가 적음. 
-- Top N 소트 알고리즘이 작동하기 때문. 
-- before
select 장비번호, 변경일자, 변경순번, 상태코드, 메모
from (select 장비번호, 변경일자, 변경순번, 상태코드, 메모
           , max(변경순번) over(partition 장비번호) 최종변경순번
      from 상태변경이력
      where 변경일자 = :upd_dt)
where 변경순번 = 최종변경순번

-- after 
select 장비번호, 변경일자, 변경순번, 상태코드, 메모
from (select 장비번호, 변경일자, 변경순번, 상태코드, 메모
           , rank() over(partition 장비번호 order by 변경순번 desc) rnum
      from 상태변경이력
      where 변경일자 = :upd_dt)
where rnum = 1

