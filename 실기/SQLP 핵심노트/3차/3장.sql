-- [28]
select 주문번호, 주문일시, 고객ID, 총주문금액, 처리상태
from 주문 
where 주문상태코드 in (0, 1, 2, 4, 5)
and 주문일자 between :dt1 and :dt2;


select  /*+ unnest(@subq) leading(주문상태@subq) use_nl(주문) */
        주문번호, 주문일시, 고객ID, 총주문금액, 처리상태
from 주문 
where 주문상태코드 in ( 
                    select /*+ qb_name(subq) */ 주문상태코드
                    from 주문상태
                    where 주문상태코드 <> 3)
and 주문일자 between :dt1 and :dt2;


select  /*+ ordered use_nl(b) */
        주문번호, 주문일시, 고객ID, 총주문금액, 처리상태
from (
  select 주문상태코드 
  from 주문상태
  where 주문상태코드 <> 3
) a, 주문 b  
where b.주문상태코드 = a.주문상태코드
and b.주문일자 between :dt1 and :dt2;


select  /*+ use_concat */
        주문번호, 주문일시, 고객ID, 총주문금액, 처리상태
from 주문 
where (주문상태코드 < 3 or 주문상태코드 > 3)
and 주문일자 between :dt1 and :dt2;


select 주문번호, 주문일시, 고객ID, 총주문금액, 처리상태
from 주문 
where 주문상태코드 < 3
and 주문일자 between :dt1 and :dt2
union all 
select 주문번호, 주문일시, 고객ID, 총주문금액, 처리상태
from 주문 
where 주문상태코드 > 3
and 주문일자 between :dt1 and :dt2;



-- [29]
update 월별계좌상태 set 상태구분코드 = '07'
where 상태구분코드 <> '01'
and 기준년월 = :BASE_DT 
and (계좌번호, 계좌일련번호) in 
      ( select 계좌번호, 계좌일련번호
        from 계좌원장
        where 개설일자 like :STD_YM || '%');



-- [30]
select  /*+ use_concat */ 거래일자
        , sum(decode(지수구분코드, '1', 지수종가, 0)) KOSPI200_IDX 
        , sum(decode(지수구분코드, '1', 누적거래량, 0)) KOSPI200_IDX_TRDVOL
        , sum(decode(지수구분코드, '2', 지수종가, 0)) KOSDAQ_IDX
        , sum(decode(지수구분코드, '2', 누적거래량, 0)) KOSDAQ_IDX_TRDVOL
from 일별지수업종별거래 A 
where 거래일자 between :startDd and :endDd
and (지수구분코드, 지수업종코드) in (('1', '001'), ('2', '003'))
group by 거래일자;


select  거래일자
        , sum(decode(지수구분코드, '1', 지수종가, 0)) KOSPI200_IDX 
        , sum(decode(지수구분코드, '1', 누적거래량, 0)) KOSPI200_IDX_TRDVOL
        , sum(decode(지수구분코드, '2', 지수종가, 0)) KOSDAQ_IDX
        , sum(decode(지수구분코드, '2', 누적거래량, 0)) KOSDAQ_IDX_TRDVOL
from 월별지수업종별거래 A 
where 거래일자 between :startDd and :endDd 
and 지수구분코드 = '1'
and 지수업종코드 = '001'
group by 거래일자 
union all 
select  거래일자
        , sum(decode(지수구분코드, '1', 지수종가, 0)) KOSPI200_IDX 
        , sum(decode(지수구분코드, '1', 누적거래량, 0)) KOSPI200_IDX_TRDVOL
        , sum(decode(지수구분코드, '2', 지수종가, 0)) KOSDAQ_IDX
        , sum(decode(지수구분코드, '2', 누적거래량, 0)) KOSDAQ_IDX_TRDVOL
from 월별지수업종별거래 A 
where 거래일자 between :startDd and :endDd 
and 지수구분코드 = '2'
and 지수업종코드 = '003'
group by 거래일자;



-- [31]
select nvl(max(주문번호) + 1, 1)
from 주문 
where 주문일자 = :주문일자 



-- [48]
-- 인덱스
* 증서번호 + 투입인출구분코드 + 이체사유발생일자 (+ 거래코드)
* 투입인출구분코드 + 증서번호 + 이체사유발생일자 (+ 거래코드)

select (G_기본이체금액 + G_정산이자) - (S_기본이체금액 + S_정산이자)
from (
  select  nvl(sum(case when 투입인출구분코드 = 'G' then 기본이체금액 end), 0) G_기본이체금액 
        , nvl(sum(case when 투입인출구분코드 = 'G' then 정산이자 end), 0) G_정산이자
        , nvl(sum(case when 투입인출구분코드 = 'S' then 기본이체금액 end), 0) S_기본이체금액 
        , nvl(sum(case when 투입인출구분코드 = 'S' then 정산이자 end), 0) S_정산이자  
  from 거래 
  where 증서번호 = :증서번호 
  and 이체사유발생일자 <= :일자 
  and 거래코드 not in ('7411', '7412', '7503', '7504')
  and 투입인출구분코드 in ('G', 'S')
)