-- 4-1.NL조인 
SELECT e.사원명, c.고객명, c.전화번호
FROM 사원 e, 고객 c
WHERE e.입사일자 >= '19960101'
AND c.관리자사원번호 = e.사원번호; 

-- PL/SQL 
begin
  for outer in (select 사원번호, 사원명 from 사원 where 입사일자 >= '19960101')
  loop    -- outer 루프 
    for inner in (select 고객명, 전화번호 from 고객 where 관리사원번호 = outer.사원번호)
    loop  -- inner 루프 
      dbms_output.put_line (
        outer.사원명 || ':' || inner.고객명 || ':' || inner.전화번호);
    end loop;
  end loop;
end;

-- NL 조인을 제어할 때는 아래와 같이 use_nl 힌트를 사용.
-- 사원 테이블 (-> Driving 또는 Outer Table) 기준으로 고객 테이블 (-> Inner 테이블)과 NL 방식으로 조인하라는 뜻. 
select /*+ ordered use_nl(c) */
       e.사원명, c.고객명, c.전화번호
from 사원 e, 고객 c
where e.입사일자 >= '19960101'
and c.관리사원번호 = e.사원번호

-- 세 개 이상 테이블을 조인할 때는 힌트를 아래처럼 사용. 
select /*+ ordered use_nl(B) use_nl(C) use_hash(D) */ *
from A, B, C, D
where .... 

SELECT /*+ ordered use_nl(b) index_desc(a (게시판구분, 등록일)) */ 
	   a.게시글ID, a.제목, b.작성자명, a.등록일시
FROM 게시판 a, 사용자 b 
WHERE a.게시판구분 = 'NEWS' -- 게시판IDX : 게시판구분 + 등록일시 
AND b.사용자ID = a.작성자ID
ORDER BY a.등록일시 DESC;


-- ========================================================================================
-- ========================================================================================
-- 4-2. 소트 머지 조인 
-- use_merge 힌트로 유도
-- 사원 테이블 기준으로(ordered) 고객 테이블과 조인할 때 소트 머지 조인 방식을 사용하라 (use_merge)고 지시
select /*+ ordered use_merge(c) */
       e.사원번호, e.사원명, e.입사일자
     , c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호 
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000


-- 1. [소트 단계] 사원 데이터를 읽어 조인컬럼인 사원번호 순으로 정렬. 
--    정렬한 결과집합은 PGA 영역에 할당된 Sort Area에 저장. 
--    정렬한 결과집합이 PGA에 담을 수 없을 정도로 크면, Temp 테이블스페이스에 저장. 
select 사원번호, 사원명, 입사일자
from 사원
where 입사일자 >= '18860101'
and 부서코드 = 'Z123'
order by 사원번호 


-- 2. [소트 단계] 고객 데이터를 읽어 조인컬럼인 관리사원번호 순으로 정렬. 
--    정렬한 결과집합은 PGA 영역에 할당된 Sort Area에 저장. 
--    정렬한 결과집합이 PGA에 담을 수 없을 정도로 크면, Temp 테이블스페이스에 저장. 
select 고객번호, 고객명, 전화번호, 최종주문금액, 관리사원번호 
from 고객 c
where 최종주문금액 >= 20000
order by 관리사원번호


-- 3. [머지 단계] 
--    PGA(또는 Temp 테이블스페이스)에 저장된 사원 데이터를 스캔하면서 PGA(또는 Temp 테이블스페이스)에 저장한 고객 데이터와 조인. 
begin
  for outer in (select * from PGA에_정렬된_사원)
  loop -- outer 루프 
    for inner in (select * from PGA에_정렬된_고객 where 관리사원번호 = outer.사원번호)
    loop -- inner 루프 
      dbms_output.put_line ( ... );
    end loop;
  end loop;
END;
 

-- ========================================================================================
-- ========================================================================================
-- 4-3.해시 조인  
-- use_hash 힌트 유도 
-- 사원 테이블 기준으로 (ordered) 고객 테이블과 조인할 때 해시 조인 방식을 사용하라 (use_hash)고 지시 
select /*+ ordered use_hash(c) */
       e.사원번호, e.사원명, e.입사일자, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호 
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000


-- 1. [Build 단계] 조건에 해당하는 사원 데이터를 읽어 해시 테이블 생성. 
--    이때, 조인컬럼인 사원번호를 해시 테이블 키 값으로 사용. 해시 테이블은 PGA 영역에 할당된 Hash Area에 저장. 
--    해시 테이블이 너무 커 PGA에 담을 수 없으면, Temp 테이블스페이스에 저장. 
select 사원번호, 사원명, 입사일자
from 사원
where 입사일자 >= '19960101'
and 부서코드 = 'Z123'


-- 2. [Probe 단계] 조건에 해당하는 고객 데이터를 하나씩 읽어 앞서 생성한 해시 테이블을 탐색. 
--   즉, 관리사원번호를 해시 함수에 입력해서 반환된 값으로 해시 체인을 찾고, 그 해시 체인을 스캔해서 값이 같은 사원번호를 찾음. 
--   찾으면 조인 성공, 못 찾으면 실패. 
select 고객번호, 고객명, 전화번호, 최종주문금액, 관리사원번호
from 고객 
where 최종주문금액 >= 20000


-- 3. Probe 단계에서 조인하는 과정 (PL/SQL) 
begin
  for outer in (select 고객번호, 고객명, 전화번호, 최종주문금액, 관리사원번호 
                from 고객 
                where 최종주문금액 >= 20000)
  loop  -- outer 루프 
    for inner in (select 사원번호, 사원명, 입사일자 
                  from PGA에_생성한_사원_해시맵
                  where 사원번호 = outer.관리사원번호)
    loop  -- inner 루프 
      dbms_output.put_line ( ... );
    end loop;
  end loop;
end;


-- 옵티마이저가 Build Input 선택 
select /*+ use_hash(e c) */
       e.사원번호, e.사원명, e.입사일자, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호 
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000

-- ordered & leading 사용시 먼저 읽는 테이블을 Build Input 
select /*+ leading(e) use_hash(c) */  -- 또는 ordered use_hash(c)
       e.사원번호, e.사원명, e.입사일자, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호 
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000

-- swap_join_inputs 힌트로 Build Input 을 명시적으로 선택. 
select /*+ leading(e) use_hash(c) swap_join_inputs(c) */
       e.사원번호, e.사원명, e.입사일자, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호 
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000

SELECT trunc(add_months(sysdate, -1), 'mm')
	 , trunc(sysdate, 'mm') 
	 , sysdate - 7
	 , add_months(sysdate, -1)
FROM dual;


-- ========================================================================================
-- ========================================================================================
-- 4-4.서브쿼리 조 
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
     , (select 고객분류명 from 고객분류 where 고객분류코드 = c.고객분류코드)  -- 스칼라 서브쿼리 
from 고객 c 
   , (select 고객번호, avg(거래금액) 평균거래
           , min(거래금액) 최소거래, max(거래금액) 최대거래 
      from 거래 
      where 거래일시 >= trunc(sysdate, 'mm')
      group by 고객번호) t  -- 인라인 뷰
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호
and exists (select 'x'
            from 고객변경이력 h
            where h.고개번호 = c.고객번호
            and h.변경사유코드 = 'ZCH'
            and c.최종변경일시 between h.시작일시 and h.종료일시)  -- 중첩된 서브쿼리 
            
            
-- * 서브쿼리를 참조하는 메인 쿼리도 하나의 쿼리 블록이며, 옵티마이저는 쿼리 블록 단위로 최적화를 수행. 
-- * 서브쿼리별 최적화한 쿼리가 전체적으로도 최적화됐다고 말할 수는 없음 -> 서브쿼리를 풀어서 최적화 

-- <원본쿼리>
select c.고객번호, c.고객명
from 고객 c 
where c.가입일시 >= trunc(add_months(sysdate, -1) 'mm')
and exits (
      select 'x'
      from 거래 
      where 고객번호 = c.고객번호
      and 거래일시 >= trunc(sysdate, 'mm'))

-- <쿼리 블록 1>
select c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1) 'mm')

-- <쿼리 블록 2>
select 'x'
from 거래 
where 고객번호 = :cust_no 
and 거래일시 >= trunc(sysdate, 'mm')

-- <원본쿼리>
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c
   , (select 고객번호, avg(거래금액) 평균거래 
           , min(거래금액) 최소거래, max(거래금액) 최대거래
      from 거래
      where 거래일시 >= trunc(sysdate, 'mm')
      group by 고객번호) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호 

-- <쿼리 블록 1>
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c, SYS_VM_TEMP t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호 

-- <쿼리 블록 2>
select 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래
from 거래
where 거래일시 >= trunc(sysdate, 'mm')
group by 고객번호

-- * 필터 오퍼레이션 : 서브쿼리를 필터 방식으로 처리. 서브쿼리를 필터 방식으로 처리하려면 no_unnest 힌트 사용. 
--   - no_unnest : 서브쿼리를 풀어내지 말고 그대로 수행하라고 옵티아미저에 지시 
--   - 필터 오퍼레이션은 기본적으로 NL 조인과 처리 루틴이 같음. (NL 조인처럼 부분 범위 처리도 가능.) 
--   - 아래 실행계획에서 'FILTER'를 'NESTED LOOP'로 치환하고 처리 루틴을 해석햐면 됨. 

select c.고객번호, c.고객명
from 고객 c 
where c.가입일시 >= trunc(add_months(sysdate, -1) 'mm')
and exits (
      select /*+ no_unnest */ 'x'
      from 거래 
      where 고객번호 = c.고객번호
      and 거래일시 >= trunc(sysdate, 'mm'))

Execution Plan
--------------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=289 Card=1 Bytes=39)
1 0    FILTER
2 1      TABLE ACCESS (BY INDEX ROWID) OF '고객' (TABLE) (Cost=4 Card=190 ... )
3 2        INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=2 Card=190)
4 1      INDEX (RANGE SCAN) OF '거래_X01' (INDEX) (Cost=3 Card=4k Bytes=92K)

-- * NL 조인과 필터 오퍼레이션 차이점 
--   1) 필터는 메인쿼리(고객)의 한 로우가 서브쿼리(거래)의 한 로우와 조인에 성공하는 순간 진행을 멈추고, 메인쿼리의 다음 로우를 계속 처리.
--      이렇게 처리해야 메인쿼리 결과집합(고객)이 서브쿼리 M쪽 집합(거래) 수준으로 확장되는 현상(고객번호 중복)을 막을 수 있음. 

begin
  for outer in (select 고객번호, 고객명 from 고객 where ... )
  loop
    for inner in (select 'x' from 거래 where 고객번호 = outer.고객번호 and ... )
    loop
      dbms_output.put_line (outer.고객번호 || ',' || outer.고객명);
      exit; -- 조인에 성공하면 inner loop exit
    end loop;
  end loop;
end;

--   2) 필터는 캐싱기능을 갖음. 서브쿼리 입력 값에 따른 반환 값(true 또는 false)을 캐싱하는 기능. 
--      이 기능이 작동하므로 서브쿼리를 수행하기 전에 항상 캐시부터 확인. 
--      캐시에서 true/false 여부를 확신할 수 있다면, 서브쿼리를 수행하지 않아도 되므로 성능을 높이는 데 큰 도움이 됨. 
--      캐싱은 쿼리 단위로 이루어지고 쿼리를 시작할 때 PGA 메모리에 공간을 할당하고, 쿼리를 수행하면서 공간을 채워나가며,
--      쿼리를 마치는 순간 공간을 반환. 

--   3) 필터 서브쿼리는 일반 NL 조인과 달리 메인쿼리에 종속되므로 조인 순서가 고정. 항상 메인쿼리가 드라이빙 집합. 
  

-- * 서브쿼리 Unnesting -> 아래는 unnest 힌트 명시적으로 사용 (옵티마이저는 대개 Unnesting을 선택)
--   - 서브쿼리 Unnesting은 메인과 서브쿼리 간의 계층구조를 풀어 서로 같은 레벨(flat한 구조)로 만들어 준다는 의미에서 
--     '서브쿼리 Flattening'이라고 부르기도 함. 
--   - 서브쿼리를 그대로 두면 필터 방식을 사용할 수 밖에 없지만, Unnesting 하고 나면 일반 조인문처럼 다양한 최적화 기법을 사용할 수 있음.
--   - NL 세미 조인 (nl_sj)은 기본적으로 NL 조인과 같은 프로세스. 
--     조인에 성공하는 순간 진행을 멈추고 메인 쿼리의 다음 로우를 계속 처리한다는 점만 다름. 
--     오라클 10g부터는 NL 세미조인이 캐싱기능도 갖게 되었으므로 사실상 필터 오퍼레이션과 큰 차이 없음.
--   - 필터방식은 항상 메인쿼리가 드라이빙 집합이지만, Unnesting된 서브쿼리는 메인 쿼리 집합보다 먼저 처리할 수 있음.  

-- // unnest + nl_sj => NL 세미조인 방식으로 실행. 
select c.고객번호, c.고객명
from 고객 c 
where c.가입일시 >= trunc(add_months(sysdate, -1) 'mm')
and exits (
      select /*+ unnest nl_sj */ 'x'
      from 거래 
      where 고객번호 = c.고객번호
      and 거래일시 >= trunc(sysdate, 'mm'))

-- // Unnesting된 서브쿼리가 드라이빙되도록 leading 힌트를 사용했을 때 실행계획 
select /*+ leading(거래@subq) use_nl(c) */ c.고객번호, c.고객명
from 고객 c 
where c.가입일시 >= trunc(add_months(sysdate, -1) 'mm')
and exits (
      select /*+ qb_name(subq) unnest */ 'x'
      from 거래 
      where 고객번호 = c.고객번호
      and 거래일시 >= trunc(sysdate, 'mm'))

Execution Plan
--------------------------------------------------------------------
0    SELECT STATEMENT Optimizer-ALL_ROWS (Cost=253K Card=190 Bytes=11K)
1 0    NESTED LOOPS
2 1      NESTED LOOPS (Cost=253K Card=190 Bytes=11K)
3 2        SORT (UNIQUE) (Cost=2K Card=427K Bytes=9M)
4 3          TABLE ACCESS (BY INDEX ROWID) OF '거래' (TABLE) (Cost=2K ...)
5 4            INDEX (RANGE SCAN) OF '거래_X02' (INDEX) (Cost=988 Card=427K)
6 2        INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=1 Card=190)
7 1      TABLE ACCESS (BY INDEX ROWID) OF '고객' (TABLE) (Cost=3 Card=1 ...)

-- // 아래 쿼리처럼 변환 
select /*+ no_merge(t) leading(t) use_nl(c) */ c.고객번호, c.고객명
from (select distinct 고객번호
      from 거래 
      where 거래일시 >= trunc(sysdate, 'mm')) t, 고객 c 
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and c.고객번호 = t.고객번호 

-- // 서브쿼리를 Unnesting 하고 나서 해시 세미 조인 방식으로 실행되도록 hash_sj 힌트를 사용. 
select c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and exists (
      select /*+ unnest hash_sj */
      from 거래
      where 고객번호 = c.고객번호 
      and 거래일시 >= trunc(sysdate, 'mm'))

Execution Plan
--------------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=2K Card=38 Bytes=2K)
1 0    FILTER
2 1      HASH JOIN (SEMI) (Cost=2K Card=38 Bytes=2K)
3 2        TABLE ACCESS (BY INDEX ROWID) OF '고객' (TABLE) (Cost=3 Card=38 ...)
4 3          INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=2 Card=38)
5 2        TABLE ACCESS (BY INDEX ROWID) OF '거래' (TABLE) (Cost=2K ...)
6 5          INDEX (RANGE SCAN) OF '거래_X02' (INDEX) (Cost=988 Card=427K)


-- * 서브쿼리 Pushing : 서브쿼리 필터링을 먼저 처리하게 함. push_subq 힌트 사용.

select /*+ leading(p) use_nl(t) */ count(distinct p.상품번호), sum(t.주문금액)
from 상품 p, 주문 t
where p.상품번호 = t.상품번호
and p.등록일시 >= trunc(add_months(sysdate, -3), 'mm')
and t.주문일시 >= trunc(sysdate - 7)
and exists (select /*+ NO_UNNEST PUSH_SUBQ */ 'x' from 상품분류 
            where 상품분류코드 = p.상품분류코드
            and 상위분류코드 = 'AK')

Rows  Row Source Operation
---- -----------------------------------------------------
   0 STATEMENT
   1  SORT AGGREGATE (cr=1903 pr=0 pw=0 time=128943 us)
3000    NESTED LOOPS (cr=1903 pr=0 pw=0 time=153252 us)
 150      TABLE ACCESS FULL 상품 (cr=101 pr=0 pw=0 time=18230 us)
   1        TABLE ACCESS BY INDEX ROWID 상품분류 (cr=6 pr=0 pw=0 time=135 us)
   3          INDEX UNIQUE SCAN 상품분류_PK (cr=3 pr=0 pw=0 time=100092 us)
3000      TABLE ACCESS BY INDEX ROWID 주문 (cr=1802 pr=0 pw=0 time=100092 us)
3000        INDEX RANGE SCAN 주문_PK (cr=302 pr=0 pw=0 time=41733 us)


-- // 뷰를 독립적으로 최적화
-- // 당월 거래 전체를 읽어 고객번호 수준으로 Group By 하는 실행계획을 수립. 
-- // 고객 테이블과 조인은 그 다음에 처리
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c 
   , (select 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래 
      from 거래 
      where 거래일시 >= trunc(sysdate, 'mm')  -- 당월 발생한 거래
      group by 고객번호) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')  -- 전월 이후 가입 고객 
and t.고객번호 = c.고객번호

Execution Plan
----------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=1M Card=1K Bytes=112K)
1 0    NESTED LOOPS
2 1      NESTED LOOP (Cost=1M Card=1K Bytes=112K)
3 2        VIEW (Cost=2K Card=427K Bytes=21M)
4 3          HASH (GROUP BY) (Cost=2K Card=427K Bytes=14M)
5 4            TABLE ACCESS (BY INDEX ROWID) OF '거래' (TABLE) (Cost=2K ... )
6 5              INDEX (RANGE SCAN) OF '거래_X01' (INDEX) (Cost=988 Card=427K)
7 2        INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=1 Card=190)
8 1      TABLE ACCESS (BY INDEX ROWID) OF '고객' (TABLE) (Cost=3 Card=1 ... )

-- // 위의 쿼리의 문제점은 고객 테이블에서 '전월 이후 가입한 고객' 을 필터링하는 조건이 인라인 뷰 바깥에 있다는 사실. 
-- // merge 힌트를 이용해 뷰를 메인 쿼리와 머징(Merging) 하도록 함. 뷰 머징을 방지하고자 할 땐 no_merge 
-- // 고객_X01 : 가입일시
-- // 거래_X02 : 고객번호 + 거래일시 
-- // 단점은 성공한 전체 집합을 Group By 하고서야 데이터를 출력할 수 있기 때문에 부분범위처리가 불가능. 
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c 
   , (select /*+ merge */ 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래 
      from 거래 
      where 거래일시 >= trunc(sysdate, 'mm')  -- 당월 발생한 거래
      group by 고객번호) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')  -- 전월 이후 가입 고객 
and t.고객번호 = c.고객번호

Execution Plan
----------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=4 Card=1 Bytes=27)
1 0    HASH (GROUP BY) (Cost=4 Card=1 Bytes=27)
2 1      NESTED LOOPS (Cost=3 Card=5 Bytes=135)
3 2        TABLE ACCESS (BY INDEX ROWID) OF '고객' (TABLE) (Cost=2 Card=1 ... )
4 3          INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=1 Card=1)
5 2        TABLE ACCESS (BY INDEX ROWID) OF '거래' (TABLE) (Cost=1 Card=5 ... )
6 5          INDEX (RANGE SCAN) OF '거래_X02' (INDEX) (Cost=0 Card=5)

-- // 위의 쿼리가 아래 형식으로 변환
select c.고객번호, c.고개명, avg(t.거래금액) 평균거래, min(t.거래금액) 최소거래, max(t.거래금액) 최대거래
from 고객 c, 거래 t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호
and t.거래일시 >= trunc(sysdate, 'mm')
group by c.고객번호, c.고객명


-- * 조인 조건 Pushdown (11g 이후) -> 쿼리 변환 기능 
--   - 메인 쿼리를 실행하면서 조인 조건절 값을 건건이 뷰 안으로 밀어 넣는 기능. 
--   - 실행계획에 VIEW PUSHED PREDICATE 오퍼레이션을 통해 이 기능 작동 여뷰를 알 수 있음. 
--   - push_pred 힌트 사용. no_merge 힌트와 함께 사용해야함. 

select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c
   , (select /*+ no_merge push_pred */ 
             고객번호, avg(거래금액) 편균거래, min(거래금액) 최소거래, max(거래금액) 최대거래 
      from 거래
      where 거래일시 >= trunc(sysdate, 'mm')
      group by 고객번호) t 
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호 

Execution Plan
----------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=4 Card=1 Bytes=61)
1 0    NESTED LOOPS (Cost=4 Card=1 Bytes=61)
2 1      TABLE ACCESS (BY INDEX ROWID BATCHED) OF '고객' (TABLE) (Cost=2 ...)
3 2        INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=1 Card=1)
4 1      VIEW PUSHED PREDICATE (Cost=2 Card=1 Bytes=41)
5 4        SORT (GROUP BY) (Cost=2 Card=1 Bytes=7)
6 5          TABLE ACCESS (BY INDEX ROWID BATCHED) OF '거래' (TABLE) (Cost=2 ...)
7 6            INDEX (RANGE SCAN) OF '거래_X02' (INDEX) (Cost=1 Card=5)

-- // 아래는 허용되지 않는 문법이지만(ORA-00904 에러 발생), 
-- // 옵티마이저가 내부에서 쿼리를 이와 같은 형태로 변환해서 최적화했다고 이해하면 쉽다. 
-- // 부분범위 처리 가능. 
-- // 뷰를 독립접으로 실행할 때처럼 당월 거래를 모두 읽지 않아도 되고, 뷰를 머징할 때처럼 조인에 성공한 전체 집합을 Group By 하지 않아도 됨.
-- // 이 방식은 전월 이후 가입한 고객을 대상으로 '건건이' 당월 거래 데이터만 읽어서 조인하고 Group By를 수행. 
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c
   , (select 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래 
      from 거래
      where 거래일시 >= trunc(sysdate, 'mm')
      and 고객번호 = c.고객번호
      group by 고객번호) t 
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')


-- // get_dname 함수 
create or replace function GET_DNAME(p_deptno number) return varchar2
is
  l_dname dept.dname%TYPE;
begin
  select dname into l_dname from dept where deptno = p_deptno;
  return l_dname;
exception
  when others then 
    return null;
end;
/

-- // get_dname 함수 사용하는 아래 쿼리를 실행하면, 함수 안에 있는 SELECT 쿼리를 메인쿼리 수만큼 '재귀적으로' 반복
explain plan for
select empno, ename, sal, hiredate, GET_DNAME(e.deptno) as dname
from emp e
where sal >= 2000

SELECT * FROM TABLE(dbms_xplan.display(NULL, NULL, 'ALL'));

-- // 스칼라 서브쿼리는 메인쿼리 레코드마다 정확히 하나의 값만 반환. 
-- // 메인쿼리 건수만큼 DEPT 테이블을 반복해서 읽는다는 측면에서 함수와 비슷해 보이지만, 함수처럼 '재귀적으로' 실행하는 구조는 아님.
-- // 컨텍스트 스위칭 없이 메인쿼리와 서브쿼리를 한 몸체처럼 실행.
select empno, ename, sal, hiredate
     , (select d.dname from dept d where d.deptno = e.deptno) as dname
from emp e
where sal >= 2000

-- // 더 쉽게 설명하면 스칼라 서브쿼리를 사용한 위 쿼리문은 아래 Outer 조인문처럼 NL 조인 방식으로 실행됨.
-- // DEPT와 조인에 실패하는 EMP 레코드는 DNAME에 NULL 값을 출력한다는 점도 같음.
-- // 차이가 있다면, 스칼라 서브쿼리는 처리 과정에서 캐싱 작용이 일어남. 
select /*+ ordered use_nl(d) */ e.empno, e.ename, e.sal, e.hiredate, d.dname
from emp e, dept d
where d.deptno(+) = e.deptno
and e.sal >= 2000

select empno, ename, sal, hiredate
     , (select d.dname              -> 출력 값 : d.dname
        from dept d
        where d.deptno = e.empno    -> 입력 값 : e.empno
     )
from emp e
where sal >= 2000

-- // 많이 활용되는 튜닝 기법 
-- // SELECT-LIST에 사용한 함수는 메인쿼리 결과건수만큼 반복 수행되는데, 아래와 같이 스칼라 서브쿼리를 덧씌우면 호출 횟수를 최소화.
select empno, ename, sal, hiredate, (select GET_DNAME(e.deptno) from dual) dname
from emp e
where sal >= 2000


-- // SQL 튜너들이 전통적으로 많이 사용해 온 방식
select 고객번호, 고객명
     , to_number(substr(거래금액, 1, 10)) 평균거래금액
     , to_number(substr(거래금액, 11, 10)) 최소거래금액
     , to_number(substr(거래금액, 21)) 최대거래금액
from (
  select c.고객번호, c.고객명
       , (select lpad(avg(거래금액), 10) || lpad(min(거래금액), 10) || max(거래금액)
          from 거래
          where 거래일시 >= trunc(sysdate, 'mm')
          and 고객번호 = c.고객번호) 거래금액
  from 고객 c
  where c.가입일시 >= trunc(add_months(sysdate-1), 'mm')
)

-- // 조인 조건 Pushdown
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c
   , (select /*+ no_merge push_pred */ 
             고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래
      from 거래
      where 거래일시 >= trunc(sysdate, 'mm')
      group by 고객번호) t
where c.가입일시 >= trunc(add_months(sysdate, -1) 'mm')
and t.고객번호 (+) = c.고객번호 

Execution Plan
-----------------------------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=4 Card=1 Bytes=61)
1 0    NESTED LOOPS (OUTER) (Cost=4 Card=1 Bytes=61)
2 1      TABLE ACCESS (BY INDEX ROWID BATCHED) OF '고객' (TABLE) (Cost=2 ...)
3 2        INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=1 Card=1)
4 1      VIEW PUSHED PREDICATE (Cost=2 Card=1 Bytes=41)
5 4        SORT (GROUP BY) (Cost=2 Card=1 Bytes=41)
6 5          TABLE ACCESS (BY INDEX ROWID BATCHED) OF '거래' (TABLE) (Cost=2 ...)
7 6            INDEX (RANGE SCAN) OF '거래_X02' (INDEX) (Cost=1 Card=5)


-- // 스칼라 서브쿼리 Unnesting 할 때의 실행계획 
-- // 스칼라 서브쿼리인데도 NL 조인이 아닌 해시 조인으로 실행될 수 있는 이유는 Unnesting 되었기 때문.
select c.고객번호, c.고개명
     , (select /*+ unnest */ round(avg(거래금액), 2) 평균거래금액 
        from 거래
        where 거래일시 >= trunc(sysdate, 'mm')
        and 고객번호 = c.고객번호)
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')

Execution Plan
--------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=7 Card=4 Bytes=184)
1 0    HASH JOIN (OUTER) (Cost=7 Card=4 Bytes=184)
2 1      TABLE ACCESS (FULL) OF '고객' (TABLE) (Cost=3 Card=4 Bytes=80)
3 1      VIEW OF 'SYS.VM_SSQ_1' (VIEW) (Cost=4 Card=3 Bytes=78)
4 3        HASH (GROUP BY) (Cost=4 Card=3 Bytes=21)
5 4          TABLE ACCESS (FULL) OF '거래' (TABLE) (Cost=3 Card=14 Bytes=98)

-- // unnest + merge 힌트를 같이 사용한 실행계획 
Execution Plan
--------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=7 Card=15 Bytes=405)
1 0    HASH (GROUP BY) (Cost=7 Card=15 Bytes=405)
2 1      HASH JOIN (OUTER) (Cost=6 Card=15 Bytes=405)
3 2        TABLE ACCESS (FULL) OF '고객' (TABLE) (Cost=3 Card=4 Bytes=80)
4 2        TABLE ACCESS (FULL) OF '거래' (TABLE) (Cost=3 Card=14 Bytes=98)

-- // 12c 업그레이드 이후 스칼라 서브쿼리 Unnesting으로 인해 일부 쿼리에 문제가 생겼을때, 
-- // _optimizer_unnest_scalar_sq = false로 설정하지 않고 no_unnest 힌트를 이용해 부분적으로 문제 해결 가능. 
select c.고객번호, c.고객명
     , (select /*+ no_unnest */ round(avg(거래금액), 2) 평균거래금액
        from 거래 
        where 거래일시 >= trunc(sysdate, 'mm')
        and 고객번호 = c.고객번호)
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')

Execution Plan
--------------------------------------------------------------
0    SELECT STATEMENT Optimizer=ALL_ROWS (Cost=7 Card=4 Bytes=80)
1 0    SORT (AGGREGATE) (Card=1 Bytes=7)
2 1      TABLE ACCESS (BY INDEX ROWID) OF '거래' (TABLE) (Cost=2 ...)
3 2        INDEX (RANGE SCAN) OF '거래_X02' (INDEX) (Cost=1 Card=5)
4 0    TABLE ACCESS (BY INDEX ROWID) OF '고객' (TABLE) (Cost=3 Card=4 Bytes=80)
5 4      INDEX (RANGE SCAN) OF '고객_X01' (INDEX) (Cost=1 Card=1)