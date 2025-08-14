-- [3]
create table 주문 (
    주문번호 number
  , 주문일시 date
  , 고객ID varchar2(5)
  , 주문금액 number)
partition by range(주문일시)
( partition P2020_H1 values less than (to_date('20200701', 'YYYYMMDD'))
, partition P2020_H2 values less than (to_date('20210101', 'YYYYMMDD'))
, partition P2021_H1 values less than (to_date('20210701', 'YYYYMMDD'))
, partition P2021_H2 values less than (to_date('20220101', 'YYYYMMDD'))
, partition P9999_MX values less than (maxvalue)
)


-- [51] ROWNUM -> ROW_NUMBER() OVRE(...)
create table 주문_t
parallel 4
as 
select  /*+ parallel(주문 4) */ 
        row_number() over(order by 고객번호, 주문일자, 주문순번) as 주문일련번호
        , 고객번호, 주문일자, 상품번호, 주문량, 주문금액
from 주문;



-- [52] ROWNUM -> ROW_NUMBER() OVRE(...)
merge /*+ full(t1) parallel(t1 4) */ into 주문 t1 
using ( select /*+ full(주문) parallel(주문 4) */ 고객번호, 주문순번
              , row_number() over(order by 고객번호, 주문순번) as 주문일련번호
        from 주문
        where 주문일자 = to_char(sysdsate, 'YYYYMMDD')) t2 
  on  ( t1.주문일자 = to_char(sysdate, 'YYYYMMDD')
    and t1.고객번호 = t2.고객번호
    and t1.주문순번 = t2.주문순번 )
when matched then update 
  set t1.주문일련번호 = t2.주문일련번호;

merge /*+ full(t1) parallel(t1 4) */ into 주문 t1 
using ( select /*+ full(주문) parallel(주문 4) */ rowid as rid
            , row_number() over(order by rowid) as 주문일련번호 
        from 주문
        where 주문일자 = to_char(sysdate, 'YYYYMMDD')) t2 
  on  ( t1.주문일자 = to_char(sysdate, 'YYYYMMDD')
    and t1.rowid = t2.rid )
when matched then update 
  set t1.주문일련번호 = t2.주문일련번호;



-- [54]
insert /*+ append */ into 상품기본이력 ( ... )
select /*+ ordered full(a) full(b) full(c) full(d)
          parallel(a, 16) parallel(b, 16) parallel(c, 16) parallel(d, 16) 
          pq_distribute(b, none, partition)
          pq_distribute(c, none, broadcast)
          pq_distribute(d, hash, hash)
          swap_join_inputs(c)
          no_swap_join_inputs(d) */ ... 
from 상품기본이력임시 a, 상품기본 b, 코드상세 c, 상품상세 d 
where a.상품번호 = b.상품번호 
and ... 



-- [55]
select  deptno 부서번호
      , decode(no, 1, to_char(empno), 2, '부서계') 사원번호
      , sum(sal) 급여합
      , round(avg(sal)) 급여평균
from emp a, (select rounum no from dual connect by level <= 2)
group by deptno, no, decode(no, 1, to_char(empno), 2, '부서계')
order by 1, 2;



-- [56]
select 고객번호, 고객명, 컬럼명 as 연락처구분, 컬럼값 as 연락처구분 
from 고객 unpivot (컬럼값 for 컬럼명
                        in (집전화번호, 사무실번호, 휴대폰번호)) a 
where 고객구분코드 = 'VIP';


select  a.고객번호 
      , a.고객명
      , (case b.no
            when 1 then '집전화번호'
            when 2 then '사무실전화번호'
            when 3 then '휴대폰번호' end) 연락처구분코드 
      , (case b.no
            when 1 then a.집전화번호
            when 2 then a.사무실전화번호
            when 3 then a.휴대폰번호 end) 연락처번호
from 고객 a 
    , (select rownum no from dual connect by level <= 3) b 
where a.고객구분코드 = 'VIP'
and b.no in ( (case when a.집전화번호     is not null then 1 end)
            , (case when a.사무실전화번호  is not null then 2 end)
            , (case when a.휴대폰번호     is not null then 3 end)
            );



-- [57]
select  a.고객번호
      , min(a.고객명) 고객명
      , min(case when b.연락처구분코드 = 'HOM' then b.연락처번호 end) 집
      , min(case when b.연락처구분코드 = 'OFC' then b.연락처번호 end) 사무실 
      , min(case when b.연락처구분코드 = 'MBL' then b.연락처번호 end) 휴대폰
from 고객 a, 고객연락처 b 
where a.고객구분코드 = 'VIP'
and b.고객번호 = a.고객번호 
group by a.고객번호;


select a.고객번호, a.고객명, b.집, b.사무실, b.휴대폰
from  고객 a 
    , 고객연락처 
      pivot (min(연락처번호) for 연락처구분코드
                          in ('HOM' as 집, 'OFC' as 사무실, 'MBL' as 휴대폰)) b 
where a.고객구분코드 = 'VIP'
and b.고객번호 = a.고객번호;


select a.고객번호, a.고객명, b.집, b.사무실, b.휴대폰
from  고객 a 
    , ( select 고객번호, 집, 사무실, 휴대폰
        from 고객연락처 
        pivot (min(연락처번호) for 연락처구분코드
                            in ('HOM' as 집, 'OFC' as 사무실, 'MBL' as 휴대폰))
    ) b
where a.고객구분코드 = 'VIP'
and b.고객번호 = a.고객번호;



-- [58]
select a.고객번호, a.고객명, b.연락처구분_XML as 연락처
from  고객 a 
    , 고객연락처 pivot xml(min(연락처번호) as 연락처번호
              for 연락처구분코드 in (any)) b 
where a.고객구분코드 = 'VIP'
and b.고객번호 = a.고객번호;


select  a.고객번호, min(a.고객명) 고객명 
      , listagg('(' || b.연락처구분코드 || ')' || b.연락처번호, ', ')
        within group (order by b.영ㄴ락처구분코드, b.연락처번호) 연락처
from 고객 a, 고객연락처 b 
where a.고객구분코드 = 'VIP'
and b.고객번호 = a.고객번호 
group by a.고객번호;



-- [60]
select 고객ID, sum(입금액) 입금액, sum(출금액) 출금액 
from (
  select 고객ID, 입금액, to_number(null) 출금액 
  from 입금 
  union all 
  select 고객ID, to_number(null) 입금액, 출금액 
  from 출금 
)
group by 고객ID;



-- [61]
select 지점코드, 판매월, 매출금액 
      , sum(매출금액) over(partition by 지점코드 order by 판매월
                          range between unbounded preceding and current row) 누적매출 
from 월별지첨매출; 


select t1.지점코드, t1.판매월 
      , min(t1.매출금액) 매출금액, sum(t2.매출금액) 누적매출금액
from 월별지점매출 t1, 월별지점매출 t2 
where t2.지점코드 = t1.지점코드 
and t2.판매월 <= t1.판매월 
group by t1.지점코드, t1.판매월 
order by t1.지점코드, t1.판매월;



-- [62]
select p.장비번호, p.장비명, p.장비구분코드 
      , h.상태코드, h.변경일자, h.변경일자
from 장비 p 
    , ( select 장비번호, 변경일자, 변경순번, 상태코드
            , row_number() over(partition by 장비번호 order by 변경일자 desc, 변경순번 desc) rnum 
        from 상태변경이력) h 
where h.장비번호 = p.장비번호 
and h.rnum = 1;


select p.장비번호, p.장비명, p.장비구분코드 
      , h.상태코드, h.변경일자, h.변경일자 
from 장비 p 
    , ( select 장비번호 
            , max(변경일자) 변경일자
            , max(변경순번) keep (dense_rank last order by 변경일자, 변경순번) 변경순번
            , max(상태코드) keep (dense_rank last order by 변경일자, 변경순번) 상태코드 
        from 상태변경이력
        group by 장비번호 ) h
where h.장비번호 = p.장비번호; 