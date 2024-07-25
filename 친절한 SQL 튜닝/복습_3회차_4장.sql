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

