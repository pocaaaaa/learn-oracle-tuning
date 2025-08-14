-- 실전모의고사1 > 실기1 
-- [전통적인 NL 조인 실행계획]
Execution Plan 
-------------------------------------------------------
NESTED LOOPS 
  TABLE ACCESS (BY INDEX ROWID) OF '계좌'
    INDEX (RANGE SCAN) OF '계좌_X1'
  TABLE ACCESS (BY INDEX ROWID) OF '고객변경이력'
    INDEX (UNIQUE SCAN) OF '고객번경이력_PK'
      SORT (AGGREGATE)
        TABLE ACCESS (BY INDEX ROWID) OF '고객변경이력'
          INDEX (RANGE SCAN) OF '고객변경이력_PK'

-- [테이블 Prefetch 실행계획]
Execution Plan 
-------------------------------------------------------
TABLE ACCESS (BY INDEX ROWID) OF '고객변경이력'
  NESTED LOOPS 
    TABLE ACCESS (BY INDEX ROWID) OF '계좌'
      INDEX (RANGE SCAN) OF '계좌_X1'
    INDEX (UNIQUE SCAN) OF '고객번경이력_PK'
      SORT (AGGREGATE)
        TABLE ACCESS (BY INDEX ROWID) OF '고객변경이력'
          INDEX (RANGE SCAN) OF '고객변경이력_PK'

-- [배치 I/O 실행계획]
NESTED LOOPS
  NESTED LOOPS 
    TABLE ACCESS (BY INDEX ROWID) OF '계좌'
      INDEX (RANGE SCAN) OF '계좌_X1'
    INDEX (UNIQUE SCAN) OF '고객번경이력_PK'
      SORT (AGGREGATE)
        TABLE ACCESS (BY INDEX ROWID) OF '고객변경이력'
          INDEX (RANGE SCAN) OF '고객변경이력_PK'
  TABLE ACCESS (BY INDEX ROWID) OF '고객변경이력'



-- 실전모의고사2 > 실기2 
select  /*+ leading(a x@subq b c) */
        a.고객명, min(b.휴대폰번호) as 휴대폰번호, sum(c.이용금액) as 이용금액 
from 고객 a, 고객 b, 서비스이용명세 c 
where a.고객구분코드 = 'INF'
and b.고객번호 = a.법정대리고객번호 
and c.고객번호 = b.고객번호 
and c.이용일자 between :dt1 and :dt2 
and not exists (
  select /*+ qb_name(subq) */ 'x'
  from SMS거부등록 x 
  where 거부여부 = 'Y'
  and 고객여부 = a.법정대리고객번호 
)
group by a.고객명, b.고객번호

* 고객_X1: 고객구분코드 
* SMS거부등록_X1: 거부여부 + 고객번호 (또는 고객번호 + 거부여부)


select a.고객명, min(b.휴대폰번호) as 휴대폰번호, sum(c.이용금액) as 이용금액 
from 고객 a, 고객 b, 서비스이용명세 c 
where a.고객구분코드 = 'INF'
and b.고객번호 = a.법정대리고객번호 
and c.고객번호 = b.고객번호
and c.이용일자 between :dt1 and :dt2 
and not exists (
  select /*+ no_unnest push_subq */ 'x'
  from SMS거부등록 x 
  where 거부여부 = 'Y'
  and 고객번호 = a.법정대리고객번호
)
group by a.고객명, b.고객번호

* 고객_X1: 고객구분코드 + 법정대리인고객번호 
* SMS거부등록_X1: 거부여부 + 고객번호 (또는 고객번호 + 거부여부)
