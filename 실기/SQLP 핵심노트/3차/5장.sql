-- [32]
select /*+ full */ count(*)
from 고객 c 
where c.가입일시 < trunc(add_months(sysdate, -1))
and not exists (
  select /*+ unnest hash_aj index_ffs(거래 거래_PK) */ 'x'
  from 거래
  where 고객번호 = c.고객번호
);



-- [33]
select 
from 상품 p, 주문 t 
where t.상품번호 = p.상품번호 
and t.주문일시 >= trunc(sysdate - 7)
and exists (  select /*+ no_unnest push_subq */ 'x'
              from 상품분류
              where 상품분류코드 = p.상품분류코드
              and 상위분류코드 = 'AK');



-- [39]
select  고객번호, 고객명 
        , to_number(substr(거래금액, 1, 10)) 평균거래금액 
        , to_number(substr(거래금액, 11, 10)) 최소거래금액 
        , to_number(substr(거래금액, 21)) 최대거래금액
from (
  select  c.고객번호, c.고객명 
          , ( select lpad(avg(거래금액), 10) || lpad(min(거래금액), 10) || max(거래금액)
              from 거래
              where 거래일시 >= trunc(sysdate, 'mm')
              and 고객번호 = c.고객번호) 거래금액 
  from 고객 c 
  where c.가입일시 >= trunc(add_months(sysdate-1), 'mm')
);

-- select /*+ ordered use_nl(t) no_merge(t) push_pred(t) */
select  /*+ ordered use_nl(t) */
        c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c
    , ( select /*+ no_merge push_pred */ 
              고객번호 
              , avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래 
        from 거래
        where 거래일시 >= trunc(sysdate, 'mm')
        group by 고객번호) t 
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호 



-- [45]
select * 
from emp e, dept d 
where e.deptno = d.deptno 
and e.job = 'CLERK'
and (d.loc = 'DALLAS' or e.mgr = 7782)