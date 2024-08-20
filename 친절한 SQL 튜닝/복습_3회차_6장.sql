-- =================================================================================
-- =================================================================================
-- 6-1.DML 튜닝
SQL> set autotrace traceonly exp

SQL> update emp set sal = sal * 1.1 where deptno = 40;

-------------------------------------------------------------------------------
| Id | Operation            | Name    | Rows | Bytes | Cost (%CPU) | Time     |
-------------------------------------------------------------------------------
|  0 | UPDATE STATEMENT     |         |    1 |     7 |     2   (0) | 00:00:01 |
|  1 |   UPDATE             | EMP     |      |       |             |          |
|  2 |     INDEX RANGE SCAN | EMP_X01 |    1 |     7 |     1   (0) | 00:00:01 |
-------------------------------------------------------------------------------

SQL> delete from emp where deptno = 40;

-------------------------------------------------------------------------------
| Id | Operation            | Name    | Rows | Bytes | Cost (%CPU) | Time     |
-------------------------------------------------------------------------------
|  0 | UPDATE STATEMENT     |         |    1 |    13 |     1   (0) | 00:00:01 |
|  1 |   DELETE             | EMP     |      |       |             |          |
|  2 |     INDEX RANGE SCAN | EMP_X01 |    1 |    13 |     1   (0) | 00:00:01 |
-------------------------------------------------------------------------------

SQL> update emp e set sal = sal * 1.1
  2  where exists
  3          (select 'x' from dept where deptno = e.deptno and loc = 'CHICAGO');

------------------------------------------------------------------------------------
| Id | Operation                           | Name     | Rows | Bytes | Cost (%CPU) | 
------------------------------------------------------------------------------------
|  0 | UPDATE STATEMENT                    |          |    5 |    90 |    5   (20) |
|  1 |   UPDATE                            | EMP      |      |       |             |
|  2 |     NESTED LOOPS                    |          |    5 |    90 |    5   (20) |
|  3 |       SORT UNIQUE                   |          |    1 |    11 |    2    (0) |
|  4 |         TABLE ACCESS BY INDEX ROWID | DEPT     |    1 |    11 |    2    (0) |
|  5 |           INDEX RANGE SCAN          | DEPT_X01 |    1 |       |    1    (0) |
|  6 |       INDEX RANGE SCAN              | EMP_X01  |    5 |    35 |    1    (0) |
------------------------------------------------------------------------------------

SQL> delete emp e set sal = sal * 1.1
  2  where exists
  3          (select 'x' from dept where deptno = e.deptno and loc = 'CHICAGO');

----------------------------------------------------------------------------------
| Id | Operation                         | Name     | Rows | Bytes | Cost (%CPU) | 
----------------------------------------------------------------------------------
|  0 | DELETE STATEMENT                  |          |    5 |   120 |    4   (25) |
|  1 |   DELETE                          | EMP      |      |       |             |
|  2 |     HASH JOIN SEMI                |          |    5 |   120 |    4   (25) |
|  3 |       INDEX FULL SCAN             | EMP_X01  |   14 |   182 |    1    (0) |
|  4 |       TABLE ACCESS BY INDEX ROWID | DEPT     |    1 |    11 |    2    (0) |
|  5 |         INDEX RANGE SCAN          | DEPT_X01 |    1 |       |    1    (0) |
----------------------------------------------------------------------------------

SQL> insert into emp
  2  select e.*
  3  from emp_t e
  4  where exists
  5          (select 'x' from dept where deptno = e.deptno and loc = 'CHICAGO');

----------------------------------------------------------------------------------
| Id | Operation                         | Name     | Rows | Bytes | Cost (%CPU) | 
----------------------------------------------------------------------------------
|  0 | INSERT STATEMENT                  |          |    5 |   490 |    6   (17) |
|  1 |   LOAD TABLE CONVENTIONAL         | EMP      |      |       |             |
|  2 |     HASH JOIN SEMI                |          |    5 |   490 |    6   (17) |
|  3 |       TABLE ACCESS FULL           | EMP_T    |   14 |  1218 |    3    (0) |
|  4 |       TABLE ACCESS BY INDEX ROWID | DEPT     |    1 |    11 |    2    (0) |
|  5 |         INDEX RANGE SCAN          | DEPT_X01 |    1 |       |    1    (0) |
----------------------------------------------------------------------------------

select cust_nm, birthday, from customer where cust_id = :cust_id

call       count    cpu    elapsed   disk    query    current    rows
--------- ------ ------ ---------- ------ -------- ---------- -------
Parse          1   0.00       0.00      0        0          0       0
Execute     5000   0.18       0.14      0        0          0       0
Fetch       5000   0.21       0.25      0    20000          0   50000
--------- ------ ------ ---------- ------ -------- ---------- -------
total      10001   0.39       0.40      0    20000          0   50000

Misses in library cache during parse: 1

-- SQL 트레이스 리포트 - Call 통계
* Parse Call
  : SQL 파싱과 최적화를 수행하는 단계. 
    SQL과 실행계획을 라이브러리 캐시에서 찾으면, 최적화 단계는 생략할 수 있다. 
* Execute Call
  : 말 그대로 SQL을 실행하는 단계.
    DML은 이 단계에서 모든 과정이 끝나지만, SELECT 문은 Fetch 단계를 거침.
* Fetch Call
  : 데이터를 읽어서 사용자에게 결과집합을 전송하는 과정으로 SELECT 문에서만 나타남. 
    전송할 데이터가 많을 때는 Fetch Call이 여러 번 발생. 
    
-- 전통적인 방식의 UPDATE
update 고객 c
set 최종거래일시 = (select max(거래일시) from 거래 
                    where 고객번호 = c.고객번호
                    and 거래일시 >= trunc(add_months(sysdate, -1)))
  , 최근거래횟수 = (select count(*) from 거래
                    where 고객번호 = c.고객번호)
  , 최근거래금액 = (select sum(거래금액) from 거래
                    where 고객번호 = c.고객번호
                    and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (select 'x' from 거래
              where 고객번호 = c.고객번호
              and 거래일시 >= trunc(add_months(sysdate, -1)))

-- 수정_1. 한 달 이내 고객별 거래 데이터를 두 번 조회. 
-- 총 고객수와 한 달이내 거래 고객 수에 따라 성능이 좌우됨. 
update 고객 c
set (최정거래일시, 최근거래횟수, 최근거래금액) =
    (select max(거래일시), count(*), sum(거래금액)
     from 거래
     where 고객번호 = c.고객번호
     and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (select 'x' from 거래
              where 고객번호 = c.고객번호
              and 거래일시 >= trunc(add_months(sysdate, -1)))

-- 수정_2. 총 고객 수가 아주 많으면 해시 세미 조인으로 유도하는 것도 고려 가능.
update 고객 c
set (최정거래일시, 최근거래횟수, 최근거래금액) =
    (select max(거래일시), count(*), sum(거래금액)
     from 거래
     where 고객번호 = c.고객번호
     and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (select /*+ unnest hash_sj */ 'x' from 거래
              where 고객번호 = c.고객번호
              and 거래일시 >= trunc(add_months(sysdate, -1)))
-- 다른 테이블과 조인이 필요할 때 전통적인 UPDATE 문을 사용하면 비효율을 완전히 해소할 수 없음
-- 수정가능 조인 뷰 : 입력, 수정, 삭제가 허용되는 조인 뷰 
-- (단, 1쪽 집합과 조인하는 M쪽 집합에만 입력, 수정, 삭제가 허용되는 조인 뷰)
-- 아래 쿼리는 12c 이상 버전에서만 정상적으로 실행됨.
update 
( select /*+ ordered use_hash(c) no_merge(t) */
         c.최종거래일시, c.최근거래횟수, c.최근거래금액, t.거래일시, t.거래횟수, t.거래금액
  from (select 고객번호
             , max(거래일시) 거래일시, count(*) 거래횟수, sum(거래금액) 거래금액
        from 거래
        where 거래일시 >= trunc(add_months(sysdate, -1))
        group by 고객번호) t
      , 고객 c
  where c.고객번호 = t.고객번호
)
set 최종거래일시 = 거래일시
  , 최근거래횟수 = 거래횟수
  , 최근거래금액 = 거래금액;
  

-- Merge
merge into customer t using customer_delta s on (t.cust_id = s.cust_id)
when matched then update
  set t.cust_nm = s.cust_nm, t.email = s.email, ...
when not matched then insert
  (cust_id, cust_nm, email, tel_no, region, addr, reg_dt) values
  (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt);

-- Optional Clauses
-- UPDATE와 INSERT를 선택적으로 처리할 수 있음. 
merge into customer t using customer_delta s on (t.cust_id = s.cust_id)
when matched then update
  set t.cust_nm = s.cust_nm, t.email = s.email, ...

merge into customer t using customer_delta s on (t.cust_id = s.cust_id)
when not matched then insert
  (cust_id, cust_nm, email, tel_no, region, addr, reg_dt) values
  (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt);

-- 수정가능 조인 뷰 -> Merge 문으로 대체 가능
update 
  (select d.deptno, d.avg_sal as d_avg_sal, e.avg_sal as e_avg_sal
   from (select deptno, round(avg(sal), 2) avg_sal from emp group by deptno) e
       , dept d
   where d.deptno = e.deptno)
set d_avg_sal = e_avg_sal;

merge into dept d
using (select deptno, round(avg(sal), 2) avg_sal from emp group by deptno) e
on (d.deptno = e.deptno)
when matched then update set d.avg_sal = e.avg_sal

-- Conditional Operations 
-- ON 절에 기술한 조인문 외에 아래와 같이 추가로 조건절을 기술할 수 있음.
merge into customer t using customer_delta s on (t.cust_id = s.cust_id)
when matched then update
  set t.cust_nm = s.cust_nm, t.email = s.email, ...
  where reg_dt >= to_date('20000101', 'yyyymmdd')
when not matched then insert
  (cust_id, cust_nm, email, tel_no, region, addr, reg_dt) values
  (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt)
  where reg_dt < trunc(sysdate);
 
-- DELETE Caluse
-- 이미 저장된 데이터를 조건에 따라 지우는 기능도 제공
-- 예시한 MERGE문에서 UPDATE가 이루어진 결과로서 탈퇴일시(withdraw_dt)가 Null이 아닌 레코드만 삭제됨. 
-- 즉, 탈퇴일시가 Null이 아니었어도 MERGE문을 수행한 결과가 Null이면 삭제하지 않음. 
-- 또 MERGE문 DELETE 절은 조인에 성공한 데이터만 삭제할 수 있다.
-- 결국 DELETE절은, 조인에 성공한(Matched) 데이터를 모두 UPDATE 하고서 
-- 그 결과 값이 DELETE WHERE 조건절을 만족하면 삭제하는 기능.
merge into customer t using customer_delta s on (t.cust_id = s.cust_id)
when matched then 
  update set t.cust_nm = s.cust_nm, t.email = s.email, ...
  delete where t.withdraw_dt is not null  -- 탈퇴일시가 null이 아닌 레코드 삭제
when not matched then insert
  (cust_id, cust_nm, email, tel_no, region, addr, reg_dt) values
  (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt);
 
-- Merge Into 활용 예
-- 저장하려는 레코드가 기존에 있던 것이면 UPDATE, 그렇지 않으면 INSERT 하려고 함. 

-- 아래 방식은 SQL을 '항상 두 번씩' 수행.
select count(*) into :cnt from dept where deptno = :val1;

if :cnt = 0 then
  insert into dept(deptno, dname, loc) values (:val1, :val2, :val3);
else
  update dept set dname = :val2, loc = :val3 where deptno = :val1;
end if;

-- 아래 방식은 SQL 을 '최대 두 번' 수행
update dept set dname = :val2, loc = :val3 where deptno = :val1;

if sql$rowcount = 0 then 
  insert into dept(deptno, dname, loc) values (:val1, :val2, :val3);
end if;

-- MERGE 문을 활용하면 SQL을 '한 번만' 수행
merge into dept a
using (select :val1 deptno, :val2 dname, :val3 loc from dual) b
on (b.deptno = a.deptno)
when matched then 
  update set dname = b.dname, loc = b.loc
when not matched then 
  insert (a.deptno, a.dname, a.loc) values (b.deptno, b.dname, b.loc);
  
 
 
 
-- =================================================================================
-- =================================================================================
-- 6-2.Direct Path I/O
-- DML을 병렬로 처리하려면, 먼저 아래와 같이 병렬 DML을 활성화.
alter session enable parallel dml;

-- 각 DML 문에 아래와 같이 힌트 사용. 
-- 대상 레코드를 찾는 작업 (INSERT는 SELECT 쿼리, UPDATE/DELETE는 조건절 검색)은 물론 
-- 데이터 추가/변경/삭제도 병렬로 진행. 
insert /*+ parallel(c 4) */ into 고객 c
select /*+ full(o) parallel(o 4) */ * from 외부가입고객 o;

update /*+ full(c) parallel(c 4) */ 고객 c set 고객상태코드 = 'WD'
when 최종거래일시 < '20100101';

delete /*+ full(c) parallel(C 4) */ from 고객 c
when 탈퇴일시 < '20100101';

-- 병렬 INSERT는 append를 지정하지 않아도 Direct Path Insert 방식을 사용. 
-- 하지만, 병렬 DML이 작동하지 않을 경우를 대비해 아래와 같이 append 힌트를 같이 사용하는게 좋음.
insert /*+ append parallel(c 4) */ into 고객 c;
select /*+ full(o) parallel(o 4) */ from 외부가입고객 o;

-- 12c 부터는 아래와 같이 enable_parallel_dml 힌트도 지원
insert /*+ enable_parallel_dml parallel(c 4) */ into 고객 c;
select /*+ full(o) parallel(o 4) */ from 외부가입고객 o;

update /*+ enable_parallel_dml full(c) parallel(c 4) */ 고객 c
set 고객상태코드 = 'WD'
where 최종거래일시 < '20100101';

delete /*+ enable_parallel_dml full(c) parallel(c 4) */ from 고객 c
where 탈퇴일시 < '20100101';

-- 병렬 DML이 잘 작동하는지 확인하는 방법
-- 아래와 같이 UPDATE(또는 DELETE/INSERT)가 'PX COORDINATOR' 아래쪽에 나타나면 UPDATE를 각 병렬 프로세스가 처리.
-----------------------------------------------------------------------------------------------
| Id | Operation                   | Name     | Pstart | Pstop | TQ     | IN-OUT | PQ Distrib |
-----------------------------------------------------------------------------------------------
|  0 | UPDATE STATEMENT            |          |        |       |        |        |            |
|  1 |   PX COORDINATOR            |          |        |       |        |        |            |
|  2 |     PX SEND QC (RANDOM)     | :TQ10000 |        |       |  Q1,00 | P -> S | QC (RAND)  |
|  3 |       UPDATE                | 고객      |        |       |  Q1,00 | PCWP   |            |
|  4 |         PX BLOCK ITERATOR   |          |      1 |     4 |  Q1,00 | PCWC   |            |
|  5 |           TABLE ACCESS FULL | 고객      |      1 |     4 |  Q1,00 | PCWP   |            |
-----------------------------------------------------------------------------------------------

-- 아래와 같이 UPDATE(또는 DELETE/INSERT)가 'PX COORDINATOR' 위쪽에 나타나면 UPDATE를 QC가 처리. 
-----------------------------------------------------------------------------------------------
| Id | Operation                   | Name     | Pstart | Pstop | TQ     | IN-OUT | PQ Distrib |
-----------------------------------------------------------------------------------------------
|  0 | UPDATE STATEMENT            |          |        |       |        |        |            |
|  1 |  UPDATE                     | 고객      |        |       |        |        |            |
|  2 |    PX COORDINATOR           |          |        |       |        |        |            |
|  3 |      PX SEND QC (RANDOM)    | :TQ10000 |        |       |  Q1,00 | P -> S | QC (RAND)  |
|  4 |        PX BLOCK ITERATOR    |          |      1 |     4 |  Q1,00 | PCWC   |            |
|  5 |          TABLE ACCESS FULL  | 고객      |      1 |     4 |  Q1,00 | PCWP   |            |
----------------------------------------------------------------------------------------------



-- =================================================================================
-- =================================================================================
-- 6-3.파티션을 활용한 DML 튜닝
-- 주문 테이블을 주문일자 기준으로 분기별 Range 파티셔닝하는 방법을 예시. 
create table 주문 (주문번호 number, 주문일자 varchar2(8), 고객ID varchar2(5)
                   , 배송일자 varchar2(8) 주문금액 number, ...)
partition by range(주문일자) (
   partition P2017_Q1 values less than ('20170401')
 , partition P2017_Q2 values less than ('20170701')
 , partition P2017_Q3 values less than ('20171001')
 , partition P2017_Q4 values less than ('20180101')
 , partition P2018_Q1 values less than ('20180401')
 , partition P9999_MX values less than ('20170401')  → 주문일자 >= '20180401'
);

-- 해시 파티션은 고객ID 처럼 변별력이 좋고 데이터 분포가 고른 컬럼을 파티션 기준으로 선정해야 효과적. 
create table 고객 (고객ID varchar2(5), 고객명 varchar2(10), ...)
partition by hash(고객ID) partition 4;

-- 지역분류 기준으로 인터넷매물 테이블을 리스트 파티셔닝하는 방법을 예시
create table 인터넷매물 (물건코드 varchar2(5), 지역분류 varchar2(4), ... )
partition by list(지역분류) (
   partition P_지역1 values ('서울')
 , partition P_지역2 values ('경기', '인천')
 , partition P_지역3 values ('부산', '대구', '대전', '광주')
 , partition P_기타 values (DEFAULT)  → 기타 지역
);

create table 주문 (주문번호 number, 주문일자 varchar2(8), 고객ID varchar2(5)
                   , 배송일자 varchar2(8) 주문금액 number, ...)
partition by range(주문일자) (
   partition P2017_Q1 values less than ('20170401')
 , partition P2017_Q2 values less than ('20170701')
 , partition P2017_Q3 values less than ('20171001')
 , partition P2017_Q4 values less than ('20180101')
 , partition P2018_Q1 values less than ('20180401')
 , partition P9999_MX values less than ('20170401')  → 주문일자 >= '20180401'
);

-- 로컬 파티션 인덱스를 만드는 방법은 CREATE INDEX 문 뒤에 'LOCAL' 옵션을 추가. 
create index 주문_x01 on 주문 (주문일자, 주문금액) LOCAL;

create index 주문_x01 on 주문 (고객ID, 주문일자) LOCAL;

create table 주문 (주문번호 number, 주문일자 varchar2(8), 고객ID varchar2(5)
                   , 배송일자 varchar2(8) 주문금액 number, ...)
partition by range(주문일자) (
   partition P2017_Q1 values less than ('20170401')
 , partition P2017_Q2 values less than ('20170701')
 , partition P2017_Q3 values less than ('20171001')
 , partition P2017_Q4 values less than ('20180101')
 , partition P2018_Q1 values less than ('20180401')
 , partition P9999_MX values less than ('20170401')  → 주문일자 >= '20180401'
);

-- 주문금액 + 주문일자 글로벌 파티션 인덱스 생성
-- CREATE INDEX 문 뒤에 'GLOBAL' 키워드를 추가하고, 파티션을 정의
create index 주문_x03 on 주문 (주문금액, 주문일자) GLOBAL
partition by range(주문금액) (
   partition P_01 values less than (100000)
 , partition P_MX values less than 
);

-- 일반 CREATE INDEX 문으로 생성
create index 주문_x04 on 주문 (고객ID, 배송일자);

-- 위의 예시에서 만든 '주문' 테이블에 인덱스 조회
SQL> select i.index_name, i.partitioned, p.partitioning_type
  2       , p.locality, p.alignment
  3  from   user_indexes i, user_part_indexes p 
  4  where  i.table_name = '주문'
  5  and    p.index_name (+) = i.index_name
  6  order by i.index_name;

INDEX_NAME    PAR PARTITION LOCALI ALIGNMENT
------------- --- --------- ------ ---------
주문_X01      YES RANGE     LOCAL  PREFIXED        → 로컬 Prefixed 파티션 인덱스
주문_X02      YES RANGE     LOCAL  NON_PREFIXED    → 로컬 Nonprefixed 파티션 인덱스
주문_X03      YES RANGE     GLOBAL PREFIXED        → 글로벌 Prefixed 파티션 인덱스
주문_X04      NO                                   → 비파티션 인덱스

-- 1. 임시 테이블 (거래_t) 을 생성한다. 할 수 있다면 nologging 모드로 생성.
create table 거래_t
nologging 
as 
select * from 거래 where 1 = 2;

-- 2. 거래 데이터를 읽어 임시 테이블에 입력하면서 상태코드 값을 수정.
insert /*+ append */ into 거래_t
select 고객번호, 거래일자, 거래순번, ...
     , (case when 상태코드 <> 'ZZZ' then 'ZZZ' else 상태코드 end) 상태코드
from 거래
where 거래일자 < '20150101';

-- 3. 임시 테이블에 원본 테이블과 같은 구조로 인덱스 생성. 할 수 있다면 nologging 모드로 생성.
create unique index 거래_t_pk on 거래_t (고객번호, 거래일자, 거래순번) nologging;
create index 거래_t_x1 on 거래_t(거래일자, 고객번호) nologging;
create index 거래_t_x2 on 거래_t(상태코드, 거래일자) nologging;

-- 4. 2014년 12월 파티션과 임시 테이블을 Exchange 함.
alter table 거래
exchange partition p201412 with table 거래_t
including indexes without validation;

-- 5. 임시 테이블 Drop
drop table 거래_t;

-- 6. (nologging 모드로 작업했다면) 파티션을 logging 모드로 전환.
alter table 거래 modify partition p201412 logging;
alter index 거래_pk modify partition p201412 logging;
alter index 거래_x1 modify partition p201412 logging;
alter index 거래_x2 modify partition p201412 logging;

[파티션 Drop을 이용한 대량 데이터 삭제]
 - 테이블 삭제 조건절 컬럼 기준으로 파티셔닝돼 있고 인덱스도 로컬 파티션이라면 
   아래 문장 하나로 대량 데이터를 순식간에 삭제할 수 있음.

alter table 거래 drop partition p201412;
alter table 거래 drop partition for('20141201'); -- 11g 부터는 대상 파티션 지정 가능.

[파티션 Truncate를 이용한 대량 데이터 삭제]
 - (상태코드 <> 'ZZZ' or 상태코드 is null) 조건을 만족하는 데이터가 소수일 때 아래 delete 문 사용. 

delete from 거래 
where 거래일자 < '20150101'
and (상태코드 <> 'ZZZ' or 상태코드 is null);

- (상태코드 <> 'ZZZ' or 상태코드 is null) 조건을 만족하는 데이터가 대다수이면,
  대량 데이터를 지울 게 아니라 남길 데이터만 백업했다가 재입력하는 방식이 빠름. 

-- 1. 임시 테이블(거래_t)을 생성하고, 남길 데이터만 복제.
create table 거래_t
as 
select *
from 거래
where 거래일시 < '20150101'
and 상태코드 = 'ZZZ';          -- 남길 데이터만 임시 세그먼트로 복제 

-- 2. 삭제 대상 테이블 파티션 Truncate 함. 
alter table 거래 truncate partition p201412;
-- 오라클 11g 부터는 대상 파티션 지정 가능.
alter table 거래 truncate partition for('20141201');

-- 3. 임시 테이블에 복제해 둔 데이터를 원본 테이블에 입력
insert into 거래
select * from 거래_t;          -- 남길 데이터만 입력

-- 4. 임시 테이블을 Drop 
drop table 거래_t;

-- 1. (할 수 있다면) 테이블을 nologging 모드로 전환
alter table target_t nologging;

-- 2. 인덱스를 Unusable 상태로 전환
alter index target_t_x01 unusable;

-- 3. (할 수 있다면 Direct Path Insert 방식으로) 대량 데이터를 입력
insert /*+ append */ into target_t
select * from source t;

-- 4. (할 수 있다면, nologging 모드로) 인덱스를 재생성
alter index target_t_x01 rebuild nologging;

-- 5. (nologging 모드로 작업했다면) logging 모드로 전환
alter table target_t logging;
alter table target_t_x01 logging;

-- 1. (할 수 있다면) 작업 대상 테이블 파티션을 nologging 모드로 전환
alter table target_t modify partition p_201712 nologging;

-- 2. 작업 대상 테이블 파티션과 매칭되는 인덱스 파티션을 Unusable 상태로 전환
alter index target_t_x01 modify partition p_201712 unusable;

-- 3. (할 수 있다면 Direct Path Insert 방식으로) 대량 데이터를 입력
insert /*+ append */ into target_t
select * from source_t where dt between '20171201' and '20171231';

-- 4. (할 수 있다면, nologging 모드로) 인덱스 파티션을 재생성
alter index target_t_x01 rebuild partition p_201712 nologging;

-- 5. (nologging 모드로 작업했다면) 작업 파티션을 logging 모드로 전환
alter table target_t_modify partition p_201712 logging;
alter index target_t_x01 modify partition p_201712 logging;


-- =================================================================================
-- =================================================================================
-- 6-4.Lock과 트랜잭션 동시성 제어
-- 커밋 명령 네 가지 
SQL> COMMIT WRITE IMMEDIATE WAIT;
SQL> COMMIT WRITE IMMEDIATE NOWAIT;
SQL> COMMIT WRITE BATCH WAIT;
SQL> COMMIT WRITE BATCH NOWAIT;

* WAIT(Default) : LGWR가 로그버퍼를 파일에 기록했다는 완료 메세지를 받을 때까지 기다린다. (동기식 커밋)
* NOWAIT : LGWR의 완료 메시지를 기다리지 않고 바로 다음 트랜잭션을 진행한다. (비동기식 커밋)
* IMMEDIATE(Default) : 커밋 명령을 받을 때마다 LGWR가 로그 버퍼를 파일에 기록한다.
* BATCH : 세션 내부에 트랜잭션 데이터를 일정량 버퍼링했다가 일괄 처리한다. 

-- before
-- 고객의 다양한 실적정보를 읽고 복잡한 산출공식을 이용해 적립포인트를 계산하는 동안 다른 트랜잭션이 
-- 같은 고객의 실적정보를 변경한다면 문제가 발생할 수 있음. 
select 적립포인트, 방문횟수, 최근방문일시, 구매실적 from 고객
where 고객번호 = :cust_num;

-- 새로운 적립포인트 계산

update 고객 set 적립포인트 = :적립포인트 where 고객번호 = :cust_nm

-- after
-- SELECT문에 FOR UPDATE를 사용하면 고객 레코드에 Lock을 설정하므로 데이터가 잘못 갱신되는 문제를 방지할 수 있음.
select 적립포인트, 방문횟수, 최근방문일시, 구매실적 from 고객
where 고객번호 = :cust_num for update;

-- 비관성 동시성 제어는 시스템 동시성을 심각하게 떨어뜨릴 우려가 있지만, 
-- FOR UPDATE에 WAIT 또는 NOWAIT 옵션을 함께 사용하면 Lock을 얻기 위해 무한정 기다리지 않아도 됨.
for update nowait  → 대기없이 Exception(ORA-00054)을 던짐
for update wait 3  → 3초 대기 후 Exception(ORA-30006)을 던짐

-- 큐(Queue) 테이블 동시성 제어
-- skip locked 옵션을 사용하면, Lock이 걸린 레코드는 생략하고 다음 레코드를 계속 읽도록 구현할 수 있음
select cust_id, rcpt_amt from cust_rcpt_Q
where yn_upd = 'Y' FOR UPDATE SKIP LOCKED;

-- SELECT-LIST에서 네 개 컬럼을 참조했을 때의 낙관성 동시성 제어 예시
select 적립포인트, 방문횟수, 최근방문일시, 구매실적 into :a, :b, :c, :d
from 고객
where 고객번호 = :cust_num;

-- 새로운 적립포인트 계산

update 고객 set 적립포인트 = :적립포인트
where 고객번호 = :cust_num
and 적립포인트 = :a
and 방문횟수 = :b
and 최근방문일시 = :c
and 구매실적 = :d;

if sql%rowcount = 0 then 
  alter('다른 사용자에 의해 변경되었습니다.');
end if;

-- SELECT 문에 읽을 컬럼이 많고 UPDATE 대상 테이블에 최종변경일시를 관리하는 컬럼이 있다면,
-- 이를 조건절에 넣어 간단히 해당 레코드의 갱신여부를 판단.
select 적립포인트, 방문횟수, 최근방문일시, 구매실적, 변경일시
into :a, :b, :c, :d, :mod_dt
from 고객
where 고객번호 = :cust_num;

-- 새로운 적립포인트 계산

update 고객 set 적립포인트 = :적립포인트, 변경일시 = SYSDATE
where 고객번호 = :cust_num
and 변경일시 = :mod_dt;  → 최종 변경일시가 앞서 읽은 값과 같은지 비교 

if sql%rowcount = 0 then 
  alter('다른 사용자에 의해 변경되었습니다.');
end if;

-- 낙관적 동시성 제어에서도 UPDATE 전에 아래 SELECT 문을 한 번 더 수행함으로써 Lock에 대한 예외를 처리 한다면,
-- 다른 트랜잭션이 설정한 Lock을 기다리지 않게 구현할 수 있음.
select 고객번호
from 고객
where 고객번호 = :cust_num
and 변경일시 = :mod_dt
for update nowait;

-- 계좌마스터와 주문 테이블이 위와 같을때
-- 쿼리를 아래와 같이 작성하면 계좌 마스터와 주문 테이블 모두에 로우 Lock이 걸림
select b.주문수량
from 계좌마스터 a, 주문 b
where a.고객번호 = :cust_no
and b.계좌번호 = a.계좌번호
and b.주문일자 = :ord_dt
for update

-- 아래와 같이 작성하면 주문수량이 있는 주문 테이블에만 로우 Lock이 걸림
select b.주문수량
from 계좌마스터 a, 주문 b
where a.고객번호 = :cust_no
and b.계좌번호 = a.계좌번호
and b.주문일자 = :ord_dt
for update of b.주문수량


insert into 상품거래(거래일련번호, 계좌번호, 거래일시, 상품코드, 거래가격, 거래수량)
values ((select max(거래일련번호) + 1 from 상품거래)
       , :acnt_no, sysdate, :prod_cd, :trd_price, :trd_qty);
