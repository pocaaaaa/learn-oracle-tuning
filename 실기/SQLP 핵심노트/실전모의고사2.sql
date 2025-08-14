-- [실기2]

select  /*+ leading(a x@subq b c) */
        a.고객명, min(b.휴대폰번호) as 휴대폰번호, sum(c.이용금액) as 이용금액
from 고객 a, 고객 b, 서비스이용명세 c
where a.고객구분코드 = 'INF' -- 미성년
and b.고객번호 = a.법정대리고객번호
and c.고객번호 = b.고객번호
and c.이용일자 between :dt1 and :dt2 
and not exists (
          select /*+ qb_name(subq) */ 'x'
          from SMS거부등록 x 
          where 거부여부 = 'Y'
          and 고객번호 = a.법정대리고객번호 
)
group by a.고객명, b.고객번호;


select a.고객명, min(b.휴대폰번호) as 휴대폰번호, sum(c.이용금액) as 이용금액
from 고객 a, 고객 b, 서비스이용명세 c 
where a.고객구분코드 = 'INF' -- 미성년
and b.고객번호 = a.법정대리고객번호 
and c.고객번호 = b.고객번호
and c.이용일자 between :dt1 and :dt2 
and not exists (
          select /*+ no_unnest push_pred */ 'x'
          from SMS거부등록 x 
          where 거부여부 = 'Y'
          and 고객번호 = a.법정대리고객번호
)
group by a.고객명, b.고객번호