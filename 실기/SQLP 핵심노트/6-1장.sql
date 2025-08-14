-- [12]
* 계약_X2 : 상품번호 + 계약일자 

select /*+ leading(p) */ P.상품번호, P.상품명, P.상품명, P.상품가격, P.상품분류코드
from 상품 P 
where P.상품유형코드 = :PSLSCD
and exists (
              select /*+ unnest nl_sj */ 'x'
              from 계약 C
              where C.상품번호 = P.상품번호 
              and C.계약일자 >= trunc(add_months(sysdate, -12))
);


select P.상품번호, P.상품명, P.상품명, P.상품가격, P.상품분류코드
from 상품 P 
where P.상품유형코드 = :PSLSCD
and exists (
              select /*+ no_unnest */ 'x'
              from 계약 C
              where C.상품번호 = P.상품번호 
              and C.계약일자 >= trunc(add_months(sysdate, -12))
); 



-- [17]
select 변경일시
from (
  select 변경일시
  from 상품변경이력
  where 상품번호 = 'ZE367'
  and 변경구분코드 = 'C2'
  order by 변경일시 desc 
)
where rownum <= 1;



-- [22]
select 장비번호, 장비명
      , substr(최종이력, 13) 최종상태코드
      , substr(최종이력, 1, 8) 최종변경일자
      , substr(최종이력, 9, 4)
from (
  select 장비번호, 장비명
        , ( select 변경일자 || LPAD(변경순번, 4) || 상태코드
            from 상태변경이력
            where 장비번호 = P.장비번호 
            order by 변경일자 desc, 변경순번 desc)
  from 장비 P 
  where 장비구분코드 = 'A001'
);


select P.장비번호, P.장비명, H.상태코드, H.변경일자, H.변경순번
from 장비 P, 상태변경이력 H 
where P.장비구분코드 = 'A001'
and H.장비번호 = P.장비번호 
and (H.변경일자, H.변경순번) = 
              ( select 변경일자, 변경순번
                from (select 변경일자, 변경순번
                      from 상태변경이력 
                      where 장비번호 = P.장비번호
                      order by 변경일자 desc, 변경순번 desc)
                where rownum <= 1);



-- [31]
-- AS-IS
DELETE FROM TARGET_T;

COMMIT;

ALTER SESSION ENABLE PARALLEL DML;

INSERT /*+ APPEND */ INTO TARGET_T T1 
SELECT /*+ FULL(T2) PARALLEL(T2 4) */ *
FROM SOURCE_T T2; 

COMMIT; 

ALTER SESSION DISABLE PARALLEL DML;

-- TO-BE
TRUNCATE TABLE TARGET_T; 

ALTER TABLE TARGET_T MODIFY CONSTRAINT TARGET_T_PK DISABLE DROP INDEX;

ALTER SESSION ENABLE PARALLEL DML; 

ALTER TABLE TARGET_T NOLOGGING;

INSERT /*+ PARALLEL(T1 4) */ INTO TARGET_T T1
SELECT /*+ FULL(T2) PARALLEL(T2 4) */ *
FROM SOURCE_T T2;

COMMIT;

ALTER TABLE TARGET_T MODIFY CONSTRAINT TARGET_T_PK ENABLE NOVALIDATE; 

ALTER TABLE TARGET_T LOGGING;

ALTER SESSION DISABLE PARALLEL DML;



-- [33]
update (
  select  /*+ lading(c) use_nl(p) index(c 고객_X3) index(p 고객_PK) */ 
          c.법정대리인_연락처, p.연락처 
  from 고객 c, 고객 p 
  where c.성인여부 = 'N'
  and c.법정대리인_고객번호 is not null 
  and p.고객번호 = c.법정대리인_고객번호 
  and p.연락처 <> c.법정대리인_연락처 
)
set 법전대리인_연락처 = 연락처; 


merge /*+ leading(c) use_nl(p) index(c 고객_X3) index(p 고객_PK) */ into 고객 c 
using 고객 p 
on  (     c.성인여부 = 'N'
      and c.법정대리인_고객번호 is not null 
      and p.고객번호 = c.법정대리인_고객번호 
)  
when matched then update 
set c.법정대리인_연락처 = p.연락처 
where c.법정대리인_연락처 <> p.연락처;


update  c 
set     c.법정대리인_연락처 = p.연락처 
from    고객 c with(index(고객_X3)) inner join 고객 p WITH(INDEX(고객_PK))
on (    c.성인여부 = 'N'
    and c.법정대리인_고객번호 is not null 
    and p.고객번호 = c.법정대리인_고객번호 
    and p.연락처 <> c.법정대리인_연락처 
)
option (force order, loop join);



-- [34]
update /*+ leading(t) */ 상품재고 T 
set T.품절유지일 = 
    ( select trunc(sysdate) - to_date(max(변경일자), 'YYYYMMDD')
      from 상품재고이력
      where 상품번호 = T.상품번호)
where T.업체코드 = 'Z'
and T.가용재고량 = 0
and nvl(T.가상재고수량, 0) <= 0
and exists (select /*+ nl_sj unnest */ 'x'
            from 상품재고이력 
            where 상품번호 = T.상품번호);


update /*+ leading(t) */ 상품재고 T 
set T.품절유지일 = 
    ( select trunc(sysdate) - to_date(max(A.변경일자), 'YYYYMMDD')
      from (select 변경일자
            from 상품재고이력 
            where 상품번호 = T.상품번호 
            order by 변경일자 desc) A 
      where rownum <= 1)
where T.업체코드 = 'Z'
and T.가용재고량 = 0
and nvl(T.가상재고수량, 0) <= 0
and exists (select /*+ nl_sj unnest */ 'x'
            from 상품재고이력 
            where 상품번호 = T.상품번호);


merge into 상품재고 X
using (
  select  /*+ leading(a) no_merge(b) use_nl(b) push_pred(b) */
          a.상품재고, b.신규_품절유지일 
  from 상품재고 A 
      , ( select 상품재고
                , (trunc(sysdate) - to_date(max(변경일자), 'YYYYMMDD')) 신규_품절유지일 
          from 상품재고이력 
          group by 상품번호) B 
  where A.업체코드 = 'Z'
  and A.가용재고량 = 0 
  and nvl(A.가상재고수량, 0) <= 0 
  and A.상품번호 = B.상품번호 
  and A.품절유지일 <> B.신규_품절유지일
) Y 
on (X.상품번호 = Y.상품번호)
when matched then update set X.품절유지일 = Y.신규_품절유지일;