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
  
 