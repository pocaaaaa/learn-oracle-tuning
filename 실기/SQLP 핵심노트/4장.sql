-- [17]
select … 
      , (select case when A.일할계산여부 = ‘Y’
                    then NVL(A.총청구건수, 0) - NVL(A.청구횟수, 0)
                    else B.할부개월수 - NVL(A.청구횟수, 0) end
        from 서비스할부 A, 할부계획 B
        where A.서비스계약 = MV.서비스계약번호 
        and A.할부상태코드 = ‘XR’
        and B.할부계획(+) = (case when A.일할계산여부 = ‘Y’
                                                    then null
                                                    else A.할부계획ID end)
        and rownum <= 1) as 청구횟수, …
from … MV
where … 



-- [43. 스칼라 서브쿼리 활용]
select 고객번호, 고객명
      , to_number(substr(거래금액, 1, 10)) 평균거래금액
      , to_number(substr(거래금액, 11, 10)) 최소거래금액
      , to_number(substr(거래금액, 21)) 최대거래금액
from (
      select c.고객번호, c.고객명
            , ( select lpad(avg(거래금액), 10) || lpad(min(거래금액), 10) || max(거래금액)
                from 거래
                where 거래일시 >= trunc(sysdate, 'mm') 
                and 고객번호 = c.고객번호) 거래금액
      from 고객
      where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
)

-- * lpad : 오라클에서 왼쪽, 오른쪽에 특정문자를 채워서 문자열 길이를 맞출 때는 LPAD, RPAD  함수를 사용.
-- * trunc(sysdate, 'mm') => sysdate : 20250725, result : 20250701
-- * trunc(add_months(sysdate, -1), 'mm') => sysdate : 20250725, result : 20250601
-- * to_number : number형 data로 변경해준다.
-- * substr(1, 2, 3) : 1 - column 이름 / 2 - 가져오기 시작할 인덱스 번호(0부터 X 1부터) / 3 - 가져올 string 의 개수


-- [43. 조인 조건 Pushdown 활용 (11g 이후)]
select /*+ ordered use_nl(t) */
      c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c,
    (select /*+ no_merge push_pref */ 
            고객번호
            , avg(거래금액) 평균거래
            , min(거래금액) 최소거래
            , max(거래금액) 최대거래
    from 거래
    where 거래일시 >= trunc(sysdate, 'mm')
    group by 고객번호) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호

-- select /*+ ordered use_nl(t) no_merge(t) push_pref(t) 로 기술해도됨.



-- [44. 인덱스 추가]
고객_X1 : 가입일시
거래_X2 : 고객번호 + 거래일시 

-- [44. SQL 수정 1안 : NO_UNNEST 힌트 활용]
select c.고객번호, c.고객명
      , ( select /*+ no_unnest */ round(avg(거래금액), 2) 평균거래금액
          from 거래
          where 거래일시 >= trunc(sysdate, 'mm')
          and 고객번호 = c.고객번호 
        )
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm');


-- [44. SQL 수정 2안 : 조인 조건 Pushdown 활용]
select /*+ ordered use_nl(t) */
        c.고객번호, c.고객명, c.평균거래금액
from 고객 c
    , ( select /*+ no_merge push_pred */ 
              고객번호, avg(거래금액) 평균거래금액
        from 거래
        where 거래일시 >= trunc(sysdate, 'mm')
        group by 고객번호
      ) t
where c.가입일시 >= trunc(add_months(sysdate), 'mm')
and t.고객번호(+) = c.고객번호;



-- [47] 
-- 모두 출력 
-- 주문상품 : 비파티션, 20만건 => 1억 2천만건중에 20만건 => 인덱스 필요 / 2만건 상품 고르게 주문  
-- 상품 : 2만건

-- 인덱스 재구성
주문상품_X1 : 할인유형코드 + 주문일시 

-- 1안
select  /*+ LEADING(P) USE_HASH(O) INDEX(O 주문상품_X1) FULL(P) */
        P.상품코드, MIN(P.상품명) 상품명, MIN(P.상품가격) 상품가격
        , SUM(O.주문수량) 총주문수량, SUM(O.주문금액) 총주문금액
from 주문상품 O, 상품 P
where O.주문일시 >= ADD_MONTHS(SYSDATE, -1)
and O.할인유형코드 = 'K890'
and P.상품코드 = O.상품코드
group by P.상품코드
order by 총주문금액 desc, 상품코드;


-- 2안 
-- 먼저 groupby -> 조인 횟수 1/10로 줄여줌. 해시 조인은 정렬 순서 보장 X -> order by 마지막에 기술 
-- order by 없는 inline View는 옵티마이저에 의해 Merging 될 수 있기 때문에 no_merge 힌트 필요. 
select  /*+ LEADING(O) USE_HASH(P) FULL(P) */ -- 또는 LEADING(P) USE_HASH(O) FULL(P)
        P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
from (select  /*+ INDEX(A 주문상품_X1) NO_MERGE */
              상품코드, sum(주문수량) 총주문수량, sum(주문금액) 총주문금액
      from 주문상품 A
      where 주문일시 >= ADD_MONTHS(SYSDATE, -1)
      and 할인유형코드 = 'K890'
      group by 상품코드) O, 상품 P
where P.상품코드 = O.상품코드
order by 총주문금액 desc, 상품코드



-- [48]
-- 모두 출력 
-- 주문상품 
--  : 월 단위 파티션 (주문일시 기준), 
--    20만건 => 파티션되어 있으므로 20만건 랜덤 액세스보다는 Full Scan, 
--    대부분 상품을 한 달에 한 개 이상 주문 => group by 결과 집합은 2만여 건. 
--    상품코드당 주문 상품은 평균 10개 => group by 조인 횟수를 1/10로 줄일 수 있음. 
-- 상품 : 2만건 

-- 상품 데이터를 PGA에 충분히 담을 수 있으 분만 아니라 2만 개 상품을 고르게 주문하므로 불필요한 상품을 PGA에 적재하는 비효율 X
-- 해시 조인은 출력 순서를 보장 X => order by 명시 
-- order by 없는 inline View는 옵티마이저에 의해 Merging 될 수 있기 때문에 no_merge 힌트 필요.
select  /*+ LEADING(O) USE_HASH(P) FULL(P) */ -- 또는 LEADING(P) USE_HASH(O) FULL(P)
        P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
from (  select  /*+ FULL(A) NO_MERGE */
                상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
        from 주문상품 A
        where 주문일시 >= ADD_MONTHS(SYSDATE, -1)
        and 할인유형코드 = 'K890'
        group by 상품코드) O, 상품 P
where P.상품코드 = O.상품코드
order by 총주문금액 desc, 상품코드



-- [49]
-- 모두 출력
-- 주문상품
--  : 월 단위 파티션 (주문일시)
--    20만건 => 파티션되어 있으므로 20만건 랜덤 액세스보다는 Full Scan, 
--    조건으로 판매되는 상품은 100여개 => group by 결과 집합도 100여 건
--    상품당 주문상품은 평균 2,000건이므로 group by를 먼저 처리하면 조인 횟수 감소 
-- 상품 : 2만건 

select  /*+ LEADING(O) USE_NL(P) */ 
        P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액 
from (select  /*+ FULL(A) NO_MERGE */
              상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
      from 주문상품 A
      where 주문일시 >= ADD_MONTHS(SYSDATE, -1)
      and 할인유형코드 = 'K890'
      group by 상품코드) O, 상품 P -- 상품 2만여건 중 실제 조인되는건 100여건이라서 nl_join 사용한듯. 
where P.상품코드 = O.상품코드
order by 총주문금액 DESC, 상품코드



-- [50]
-- 모두 출력
-- 주문상품
--  : 월 단위 파티션 (주문일시), 20만건 => 인덱스로 20만 건을 랜덤 액세스하는 것보다는 Full Scan이 유리
--    2만 개 상품을 한 달에 한 개 이상 주문 => group by 한 집합 2만여 건
--    상품 코드 당 주문상품은 평균 10건이므로 group by 후 조인하면 조인 횟수를 1/10로 줄일 수 있음. 
-- 상품 : 2만건 

-- 1안
-- 총주문금액 내림차순, 상품코드 오름차순으로 정렬한 2만여 개 결과집합 중 상위 100개만 추출해야 하므로 order by는 인라인 뷰 안에 기술. 
-- 등록된 2만개 상품 중 100개만 조인하므로 해시조인보다 NL 조인이 유리.
select  /*+ LEADING(O) USE_NL(P) */
        P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
from (select  /*+ FULL(A) */
              상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
      from 주문상품 A
      where 주문일시 >= ADD_MONTHS(SYSDATE, -1)
      and 할인유형코드 = 'K890'
      group by 상품코드
      order by 총주문금액 desc, 상품코드) O, 상품 P 
where P.상품코드 = O.상품코드 
and ROWNUM <= 100 -- 100개만 조인
order by 총주문금액 desc, 상품코드; -- 배치 I/O 작동할 경우 출력 순서 보장 X


-- 2안 
select  /*+ LEADING(O) USE_NL(P) NO_NLJ_BATCHING(P) */
        P.상품코드, P.상품명, P.상품가격, O.총주문수량, O.총주문금액
from (select  /*+ FULL(A) */
              상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액
      from 주문상품 A
      where 주문일시 >= ADD_MONTHS(SYSDATE, -1)
      and 할인유형코드 = 'K890'
      group by 상품코드
      order by 총주문금액 desc, 상품코드) O, 상품 P 
where P.상품코드 = O.상품코드
and rownum <= 100;



-- [51]
-- 일부(보통 상위 100개)만 출력하고 멈추는 애플리케이션 => 부분범위 처리 => 소트 연산 생략 
-- 주문상품 : 비파티션 / 10만 건 / 대부분 상품을 한 달에 한 개 이상 주문  
-- 상품 : 50만개, 속성은 500개 

-- [인덱스 재구성]
* 상품_X1 : 등록일시
* 주문상품_X2 : 할인유형코드 + 상품코드 + 주문일시 (또는 상품코드 + 할인유형코드 + 주문일시)

-- 반드시 Join Predicate Pushdown 기능이 작동해야 함. 
select  /*+ LEADING(P) USE_NL(O) INDEX_DESC(P 상품_X1) */
        P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID, O.총주문수량, O.총주문금액 
from (select  /*+ NO_MERGE PUSH_PRE INDEX(A 주문상품_X2) */
              상품코드, SUM(주문수량) 총주문수량, SUM(주문금액) 총주문금액 
      from 주문상품 A
      where 주문일시 >= ADD_MONTHS(SYSDATE, -1)
      and 할인유형코드 = 'K890'
      group by 상품코드) O, 상품 P
where O.상품코드 = P.상품코드
order by p.등록일시 desc;



-- [52]
-- 일부(보통 상위 100개)만 출력하고 멈추는 애플리케이션 => 부분범위 처리 => 소트 연산 생략 
-- 주문상품 : 월 단위 파티션 (주문일시) / 10만 건 / 대부분 상품을 한 달에 한 개 이상 주문 / 'K890' 조건으로 판매되는 상품은 5,000개 
-- 상품 : 50만개, 속성은 500개 

-- [인덱스 재구성]
* 상품_X1 : 등록일시 + 상품코드 (또는 상품코드 + 등록일시)
* 주문상품_X1 : 할인유형코드 + 주문일시 

-- 1안 
select  /*+ LEADING(O) USE_NL(P) NO_NLJ_BATCHING(P) */
        P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID, O.총주문수량, O.총주문금액 
from (select  /*+ FULL(A) INDEX_FFS(B) LEADING(B) USE_HASH(A) */
              A.상품코드, MIN(B.등록일시) 등록일시
              , SUM(A.주문수량) 총주문수량, SUM(A.주문금액) 총주문금액
      from 주문상품 A, 상품 B 
      where A.주문일시 >= ADD_MONTHS(sysdate, -1)
      and A.할인유형코드 = 'K890'
      and B.상품코드 = A.상품코드
      group by A.상품코드
      order by 등록일시 desc) O, 상품 P 
where P.상품코드 = O.상품코드;


-- 2안 
select  /*+ LEADING(O) USE_NL(P) */
        P.상품코드, P.상품명, P.등록일시, P.상품가격, P.공급자ID, O.총주문수량, O.총주문금액
from (select  /*+ FULL(A) INDEX_FFS(B) LEADING(B) USE_HASH(A) */
              A.상품코드, MIN(B.등록일시) 등록일시, MIN(B.ROWID) RID 
              , SUM(A.주문수량) 총주문수량, SUM(A.주문금액) 총주문금액 
      from 주문상품 A, 상품 B
      where A.주문일시 >= ADD_MONTHS(SYSDATE, -1)
      and A.할인유형코드 = 'K890'
      and B.상품코드 = A.상품코드
      group by A.상품코드
      order by 등록일시 desc) O, 상품 P 
where P.ROWID = O.RID;



-- [53]
-- 실제방문일자 역순으로 최근 10건만 출력 => 부분범위처리 
-- 개통접수와 장애접수를 인라인 뷰 바깥에서 조인하면 좋다고 생각할 수 있지만, 
-- 인덱스만 잘 구성해 주면 어차피 10건 읽고 멈추기 때문에 상관없음. 

-- [인덱스 구성]
* 작업지시_X1 : 작업자ID + 실제방문일자 

-- 튜닝
select *
from (
        select  /*+ ordered use_nl(b) use_nl(c) */
                a.작업일련번호, b.실제방문일자
                , nvl2(b.개통접수번호, '개통', '접수') 접수구분
                , nvl2(b.개통접수번호, b.고객번호, c.고객번호) 고객번호
                , nvl2(b.개통접수번호, b.주소, c.주소) 주소
        from 작업지시 a, 개통접수 b, 장애접수 c 
        where a.작업자ID = :작업자ID 
        and a.실제방문일자 >= trunc(add_months(sysdate, -1))
        and b.개통접수번호(+) = a.개통접수번호 
        and c.장애접수번호(+) = a.개통접수번호
        order by a.실제방문일자 desc 
)
where rownum <= 10; 

-- * NVL2("값", "지정값1", "지정값2") -> NVL2("값", "NOT NULL", "NULL") 



-- [54]
-- 모두 출력 
select x.작업일련번호, x.작업자ID, '개통' as 작업구분, y.고객번호, y.주소 
from 작업지시 x, 개통접수 y 
where x.작업구분코드 = 'A'
and x.방문예정일자 = to_char(sysdate, 'yyyymmdd')
and y.개통접수번호 = x.접수번호 
union all 
select x.작업일련번호, x.작업자ID, '장애' as 작업구분, y.고객번호, y.주소 
from 작업지시 x, 장애접수 y 
where x.작업구분코드 = 'B'
and x.방문예정일자 = to_char(sysdate, 'yyyymmdd')
and y.장애접수번호 = x.접수번호;



-- [55]
-- 모두 출력 
select a.작업일련번호, a.작업자ID 
      , decode(a.작업구분코드, 'A', '개통', 'B', '장애') AS 작업구분 
      , decode(a.작업구분코드, 'A', b.고객번호, 'B', c.고객번호) AS 고객번호
      , decode(a.작업구분코드, 'A', b.주소, 'B', c.주소) AS 주소 
from 작업지시 a, 개통접수 b, 장애접수 c 
where a.방문예정일자 = to_char(sysdate, 'yyyymmdd')
and b.개통접수번호(+) = decode(a.작업구분코드, 'A', a.접수번호)
and c.장애접수번호(+) = decode(a.작업구분코드, 'B', a.접수번호);



-- [56]
-- 접수일자가 오늘인 개통접수 및 장애접수 모두 출력 
-- NL 조인 기준 최적 쿼리, 힌트 지정 불가 
-- 개통접수일시와 장애접수일시 데이터 타입은 DATA 

-- [인덱스 구성]
* 작업지시_X1 : 작업구분코드 + 접수번호 (또는 접수번호 + 작업구분코드) 
* 개통접수_X1 : 개통접수일시 
* 장애접수_X1 : 장애접수일시 

-- 조회 조건이 개통접수 및 장애접수 테이블에 있고 NL 조인으로 처리해야 유리한 소량의 결과집합 => UNION ALL 
select y.작업일련번호, y.작업자ID, '개통' as 작업구분, x.고객번호, x.주소
from 개통접수 x, 작업지시 y 
where x.개통접수일시 >= trunc(sysdate)
and x.개통접수일시 < trunc(sysdate + 1)
and y.작업구분코드 = 'A'
and y.접수번호 = x.개통접수번호 
union all 
select y.작업일련번호, y.작업자ID, '장애' as 작업구분, x.고객번호, x.주소
from 장애접수 x, 작업지시 y 
where x.장애접수일시 >= trunc(sysdate)
and x.장애접수일시 < trunc(sysdate + 1)
and y.작업구분코드 = 'A'
and y.접수번호 = x.장애접수번호;



-- [57]
-- 장비구분코드 = 'A001'인 장비는 10건
-- 결과집합을 장비번호 순으로 정렬 

-- 1안 
select P.장비번호, P.장비명, H.상태코드 AS. 최종상태코드
      , H.변경일자 AS 최종변경일자, H.변경순번 AS 최종변경순번
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
and H.장비번호 = P.장비번호 
and (H.변경일자, H.변경순번) = 
      ( select 변경일자, 변경순번 
        from (select 변경일자, 변경순번
              from 상태변경이력
              where 장비번호 = P.장비번호
              order by 변경일자 desc, 변경순번 desc)
        where rownum <= 1)
order by P.장비번호; 


-- 2안 
select P.장비번호, P.장비명, H.상태코드 as 최종상태코드
      , H.변경일자 AS 최종변경일자, H.변경순번 AS 최종변경순번
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
-- and H.장비번호 = P.장비번호 -> 이 조건절은 없어도 무방 
and H.ROWID = 
      ( select RID 
        from (select ROWID AS RID
              from 상태변경이력 
              where 장비번호 = P.장비번호 
              order by 변경일자 desc, 변경순번 desc)
        where rownum <= 1)
order by P.장비번호 



-- [58]
-- 직전일의(=상태변경이력의 변경일자가 장비의 최종상태변경일자보다 작은) 마지막 상태코드, 변경일자, 변경순번을 출력 
-- 장비구분코드 = 'A001'인 장비는 10건
-- 결과집합을 장비번호 순으로 정렬 

-- 1안 
select P.장비번호, P.장비명, P.최종상태코드, H.상태코드 AS 직전상태코드 
      , H.변경일자 AS 직전변경일자, H.변경순번 AS 직전변경순번
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
and H.장비번호 = P.장비번호 
and (H.변경일자, H.변경순번) = 
      ( select 변경일자, 변경순번
        from (select 변경일자, 변경순번
              from 상태변경이력 
              where 장비번호 = P.장비번호
              and 변경일자 < P.최종상태변경일자
              order by 변경일자 desc, 변경순번 desc)
        where rownum <= 1)
order by P.장비번호;


-- 2안 
select P.장비번호, P.장비명, P.최종상태코드, H.상태코드 AS 직전상태코드 
      , H.변경일자 AS 직전변경일자, H.변경순번 AS 직전변경순번
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
-- and H.장비번호 = P.장비번호 -> 이 조인절은 없어도 무방 
and H.ROWID =
    ( select RID
      from (select ROWID as RID
            from 상태변경이력
            where 장비번호 = P.장비번호
            and 변경일자 < P.최종상태변경일자
            order by 변경일자 desc, 변경순번 desc)
      where rownum <= 1)
order by P.장비번호; 



-- [59]
-- 장비의 현재(=최종) 상태코드와 변경일자
-- 장비구분코드 = 'A001'인 장비는 10건
-- 결과집합을 장비번호 순으로 정렬 
-- 상태변경이력은 선분이력 테이블 
-- 장비 테이블의 최종변경일시와 상태변경이력의 유효시작일시, 유효종료일시는 DATA 형 

select P.장비번호, P.장비명, H.상태코드 AS 최종상태코드 
      , TO_CHAR(H.유효시작일시, 'YYYYMMDD') AS 최종상태변경일자
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
and H.장비번호 = P.장비번호 
and H.유효시작일시 <= SYSDATE
and H.유효종료일시 >= SYSDATE 
order by P.장비번호;



-- [60]
-- 장비의 최종 상태코드와 변경일자, 그리고 직전(=상태변경이력의 유효시작일자가 장비의 최종상태변경일시보다 작은)
-- 장비구분코드 = 'A001'인 장비는 10건
-- 결과집합을 장비번호 순으로 정렬 
-- 상태변경이력은 선분이력 테이블 
-- 장비 테이블의 최종변경일시와 상태변경이력의 유효시작일시, 유효종료일시는 DATA 형 

-- 유효시작일시 : 20250726 15:00:00
-- 유효종료일시 : 20250727 15:00:00 
-- 최종상태변경일시 : 20250727 15:00:01 -> 데이터 업데이트 시간....?
-- 유효시작일자 = 최종상태변경일시...? 

select P.장비번호, P.장비명, P.최종상태코드 
      , TO_CHAR(P.최종상태변경일시, 'YYYYMMDD') as 최종변경일자 
      , H.상태코드 AS 직전상태코드
      , TO_CHAR(H.유효시작일시, 'YYYYMMDD') AS 직저변경일자 
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
and H.장비번호 = P.장비번호 
and H.유효시작일자 < P.최종상태변경일시 
and H.유효종료일시 >= P.최종상태변경일시 - 1/(60*60*24)
order by P.장비번호 
