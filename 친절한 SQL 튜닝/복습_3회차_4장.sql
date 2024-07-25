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
end;