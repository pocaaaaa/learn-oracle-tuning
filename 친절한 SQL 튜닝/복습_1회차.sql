-- 1장 
SELECT e.empno, e.ename, e.job, d.dname, d.loc 
FROM emp e, dept d
WHERE e.deptno = d.deptno 
ORDER BY e.ename;

CREATE TABLE t 
AS 
SELECT d.NO, e.* 
FROM sqlp.emp e 
   , (SELECT rownum NO FROM dual CONNECT BY LEVEL <= 1000) d;
   
CREATE INDEX t_x01 ON t(deptno, no);
CREATE INDEX t_x02 ON t(deptno, job, no);

explain plan FOR 
SELECT * FROM t WHERE deptno = 10 AND NO = 1;

SELECT * FROM table(dbms_xplan.display);

SELECT /*+ gather_plan_statistics */ * 
FROM t 
WHERE deptno = 10 
AND NO = 1;

SELECT * FROM table(dbms_xplan.display_cursor(NULL, NULL, 'ALLSTATS LAST'));

explain plan FOR 
SELECT /*+ index(t t_x02) */* FROM t WHERE deptno = 10 AND NO = 1;

explain plan FOR 
SELECT /*+ full(t) */* FROM t WHERE deptno = 10 AND NO = 1;

SELECT * FROM table(dbms_xplan.display);

-- /*+ INDEX(A A_X01) INDEX(B, B_X03) */ -> 모두 유효 
-- /*+ INDEX(C) FULL(D) */ -> 첫 번쨰 힌트만 유효 


-- 2장
-- select 장비번호, 장비명, 상태코드 
-- 		, substr(최종이력, 1, 8) 최종변경일자
--      , substr(최종이력, 9) 최종변경순번 
-- from ( 
-- 		  select 장비번호, 장비명, 상태코드 
--				, (select max(변경일자 || 변경순번) 
--				   from 상태변경이력
--				   where 장비번호 = p.장비번호) 최종이력 '
--		  from 장비 p 
-- 		  where 장비구분코드 = 'A001' 
-- ) 

-- 데이터 타입이 3번쨰 인자에 의해서 결정됨 (decode)
SELECT round(avg(sal)) avg_sal
	 , min(sal) min_sal 
	 , max(sal) max_sal 
	 , max(decode(job, 'PRESIDENT', NULL, sal)) max_sal2 
FROM emp;

SELECT round(avg(sal)) avg_sal
	 , min(sal) min_sal 
	 , max(sal) max_sal 
	 , max(decode(job, 'PRESIDENT', to_number(NULL), sal)) max_sal2 
FROM emp;

explain plan FOR 
SELECT * FROM emp WHERE deptno = 20;

SELECT * FROM table(dbms_xplan.display);

explain plan FOR 
SELECT * FROM emp WHERE sal > 2000 ORDER BY ename;

explain plan FOR
SELECT * FROM emp WHERE empno > 0 ORDER BY empno DESC;


-- 3장 
-- insert into 고객_임시
-- select /*+ full(c) full(h) index_ffs(m.고객변경이력) ordered no_merge(m) use_hash(m) use_hash(h) */ 
-- 		  c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
-- from 고객 c 
-- 		, (select 고객번호, max(변경일시) 최종변경일시 
-- 		   from 고객변경이력 
-- 		   where 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
--		   and 변경일시 < trunc(sysdate, 'mm)
--		   group by 고객번호) m 
-- 		, 고객변경이력 h 
-- where c.고객구분코드 = 'A001'
-- and m.고객번호 = c.고객번호
-- and h.고객번호 = m.고객번호 
-- and h.변경일시 = m.최종변경일시 

-- insert into 고객_임시
-- select 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시
-- from (select /*+ full(c) full(h) leading(c) use_hash(h) */ 
--				c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
--				, rank() over(partition by h.고객번호 order by h.변경일시 desc) no 
--		 from 고객 c, 고객변경이력 h
--		 where c.고객구분코드 = 'A001'
--		 and h.변경일시 >= trunc(add_months(sysdate, -12), 'mm')
--		 and h.변경일시 < trunc(sysdate, 'mm')
--		 and h.고객번호 = c.고객번호) 
-- where no = 1

-- create table index_org_t (a number, b varchar(10), constraint index_org_t_pk primary key (a) )
-- organization index; 

-- create table heap_org_t (a number, b varchar(10), constraint heap_org_t_pk primary key (a) )
-- organization heap; 

-- create cluster c_dept#(deptno number(2)) index;
-- create index c_dept#_idx on cluster c_dept#;

-- create table dept (
-- 		deptno number(2) not null
--		, dname varchar2(14) not null
--		, loc varchar2(13) )
-- cluster c_dept#(deptno); 

-- create cluster c_dept# (deptno number(2)) hashkeys 4;
-- create table dept (
-- 		deptno number(2) not null
--		, dname varchar2(14) not null
--		, loc varchar2(13) )
-- cluster c_dept#(deptno); 

-- select * from 거래 
-- where :cust_id is null
-- and 거래일자 between :dt1 and :dt2
-- union all
-- select * from 거래 
-- where :cust_id is not null
-- and 고객ID = :cust_id 
-- and 거래일자 between :dt1 and dt2 

-- NULL 허용 컬럼에 사용할 수 없음. (nvl, decode)
-- select * from 거래 
-- where 고객ID = nvl(:cust_id, 고객ID)
-- and 거래일자 between :dt1 and :dt2

-- select * from 거래 
-- where 고객ID = decode(:cust_id, null, 고객ID, :cust_id)
-- and 거래일자 between :dt1 and :dt2

SELECT * FROM dual WHERE NULL = NULL;

SELECT * FROM dual WHERE NULL IS NULL;

SELECT 	trunc(sysdate - 3)
		, to_char(trunc(sysdate - 3), 'YYYYMMDD')
		, to_date('2024-02-20', 'YYYY-MM-DD')
		, to_char(sysdate-10, 'YYYYMMDD') 
		, to_char(add_months(sysdate, -12), 'yyyy-mm-dd')
		, to_char(add_months(sysdate, -12), 'YYYY-MM-DD')
FROM dual; 


-- 4장 
-- select /*+ ordered use_nl(c) */ 
-- 		  e.사원명, c.고객명, c.전화번호
-- from 사원 e, 고객 c 
-- where e.입사일자 >= '19960101'
-- and c.관리사원번호 = e.사원번호;

-- select /*+ ordered use_nl(B) use_nl(C) use_hash(D) */ *
-- from A, B, C, D
-- where ... ... 

-- select /*+ leading(C, A, D, B) use_nl(A) use_nl(D) use_hash(B) */ *
-- from A, B, C, D 
-- where ... ... 

-- select /*+ use_nl(A, B, C, D) */ *
-- from A, B, C, D 
-- where ... ...

-- 소트 머지 조인 (Sort Merge Join)
-- select /*+ ordered use_merge(c) */
--		  e.사원번호, e.사원명, e.입사일자
--		, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
-- from 사원 e, 고객 c 
-- where c.관리사원번호 = e.사원번호 
-- and e.입사일자 >= '19960101'
-- and e.부서코드 = 'Z123'
-- and c.최종주문금액 >= 20000 

-- select /*+ ordered use_hash(c) */
--		  e.사원번호, e.사원명, e.입사일자
--		, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
-- from 사원 e, 고객 c 
-- where c.관리사원번호 = e.사원번호 
-- and e.입사일자 >= '19960101'
-- and e.부서코드 = 'Z123'
-- and c.최종주문금액 >= 20000 

-- select /*+ leading(e) use_hash(c) swap_join_inputs(c) */
--		  e.사원번호, e.사원명, e.입사일자
--		, c.고객번호, c.고객명, c.전화번호, c.최종주문금액
-- from 사원 e, 고객 c 
-- where c.관리사원번호 = e.사원번호 
-- and e.입사일자 >= '19960101'
-- and e.부서코드 = 'Z123'
-- and c.최종주문금액 >= 20000 

-- select /*+ leading(T1, T2, T3) use_hash(T2) use_hash(T3) */ *
-- from T1, T2, T3
-- where T1.key = T2.key
-- and T2.key = T3.key 

-- select /*+ leading(T1, T2, T3) swap_join_inputs(T2) */ *
-- select /*+ leading(T1, T2, T3) swap_join_inputs(T3) */ *
-- select /*+ leading(T1, T2, T3) swap_join_inputs(T2) swap_join_inputs(T3) */ *
-- select /*+ leading(T1, T2, T3) no_swap_join_inputs(T3) */ *

-- 서브쿼리 : 스칼라 서브쿼리, 인라인 뷰, 중첩된 서브쿼
-- select c고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래 
--		,(select 고객분류명 from 고객분류 where 고객분류코드 = c.고객분류코)
-- from 고객 c 
-- 	  , (select 고객번호, avg(거래금액) 평균거래, min(거래금래) 최소거래, max(거래금액) 최대거래 
--		 from 거래 
--		 where 거래일시 >= trunc(sysdate, 'mm')
--		 group by 고객번호) t 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and t.고객번호 = c.고객번호 
-- and exists (select 'x'
--			   from 고객변경이력 h
--			   where h.고객번호 = c.고객번호
--			   and h.변경사유코드 = 'ZCH'
--			   and c.최종변경일시 between h.시작일시 and h.종료일시) 

-- no_unnest : 서크뤄리 필터 방식으로 처리. 항상 메인쿼리가 드라이빙 집합. 
-- select c.고객번호, c.고객명
-- from 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and exists (
-- 		select /*+ no_unnest */ 'x'
-- 		from 거래 
-- 		where 고객번호 = c.고객번호
--		and 거래일시 >= trunc(sysdate, 'mm)) 

-- unnest : 서브쿼리 flattening 
-- nl_sj : 조인에 성공하는 순간 진행을 멈추고 메인 쿼리의 다음 로우를 계속 처리함. 나머지는 nl조인과 동일함. 
-- select c.고객번호, c.고객명
-- from 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and exists (
-- 		select /*+ unnest nl_sj */ 'x'
-- 		from 거래 
-- 		where 고객번호 = c.고객번호
--		and 거래일시 >= trunc(sysdate, 'mm)) 

-- select /*+ leading(거래@subq) use_nl(c) */ c.고객번호, c.고객명
-- from 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and exists (
-- 		select /*+ qb_name(subq) unnest */ 'x'
-- 		from 거래 
-- 		where 고객번호 = c.고객번호
--		and 거래일시 >= trunc(sysdate, 'mm)) 

-- 아래와 같이 변
-- select /*+ no_merge(t) leading(t) use_nl(c) */ c.고객번호, c.고객명 
-- from (select distinct 고객번호 
--		 from 거래 
--  	 where 거래일시 >= trunc(sysdate, 'mm')) t, 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and c.고객번호 = t.고객번호

-- select c.고객번호, c.고객명
-- from 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and exists (
-- 		select /*+ unnest hash_sj */ 'x'
-- 		from 거래 
-- 		where 고객번호 = c.고객번호
--		and 거래일시 >= trunc(sysdate, 'mm)) 

-- rownum을 사용하면 unnest가 방지됨. 

-- pushing 서브쿼리 : 서브쿼리 필터링을 가능한 한 앞 단계에서 처리하도록 강제하는 기능 (push_subq / no_push_subq)
-- unnesting 되지 않은 서브쿼리에만 작동 => push_subq 힌트는 항상 no_unnest 힌트와 같이 기술. 
-- select /*+ leading(p) use_nl(t) */ count(distinct p.상품코), sum(t.주문금액) 
-- from 상품 p, 주문 t
-- where p.상품번호 = t.상품번호
-- and p.등록일시 >= trunc(add_months(sysdate, -3), 'mm')
-- and t.주문일시 >= trunc(sysdate - 7)
-- and exists (select /*+ no_unnest push_subq */ 'x' from 상품분류 
--		where 상품분류코드 = p.상품분류코드 
--		and 상위분류코드 = 'AK')

-- Pushing 서브쿼리와 반대로 서브쿼리 필터링을 가능한 나중에 처리하려면 
-- no_unnest 와 no_push_subq 를 같이 사용. 

-- 뷰머징 : 메인 쿼리와 머징. 뷰머징 방지는 no_merge 
-- select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
-- from 고객 c 
-- 		, (select /*+ merge */ 고객번호, avg(거래금액) 평균거래 
--				, min(거래금액) 최소거래, max(거래금액) 최대거래 
-- 		   from 거래 
-- 		   where 거래일시 >= trunc(sysdate, 'mm')
-- 		   group by 고객번호) t
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and t.고객번호 = c.고객번호 

-- 조인조건 pushdown : 조인 조건절 값을 건건이 뷰 안으로 밀어 넣는 기능. 
-- 부분범위처리 가능.
-- VIEW PUSHED PREDICATE 
-- select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
-- from 고객 c 
-- 		, (select /*+ no_merge push_pred */ 고객번호, avg(거래금액) 평균거래 
--				, min(거래금액) 최소거래, max(거래금액) 최대거래 
-- 		   from 거래 
-- 		   where 거래일시 >= trunc(sysdate, 'mm')
-- 		   group by 고객번호) t
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and t.고객번호 = c.고객번호 

-- select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
-- from 고객 c 
-- 		, (select /*+ no_merge push_pred */ 고객번호, avg(거래금액) 평균거래 
--				, min(거래금액) 최소거래, max(거래금액) 최대거래 
-- 		   from 거래 
-- 		   where 거래일시 >= trunc(sysdate, 'mm')
--		   and 고객번호 = c.고객번호 -- 오류발생 (ORA-00904)
-- 		   group by 고객번호) t
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')

-- select * from 사원 e
--			LATERAL (select * from 조직 where 조직코드 = e.조직코드)

-- select * from 사원 e
--			OUTER APPLY (select * from 조직 where 조직코드 = e.조직코드) 

-- select * from 사원 e
--			CROSS APPLY (select * from 조직 where 조직코드 = e.조직코드)

-- select empno, ename, sal, hiredate 
--		, (select d.dname from dept d where d.deptno = e.deptno) as dname 
-- from emp e 
-- where sal >= 2000

-- 서브쿼리 캐싱 효과
-- SELECT empno, ename, sal, hiredate 
-- 		, (select GET_DNAME(e.deptno) from dual) dname 
-- from emp e
-- where sal >= 2000 

-- select 고객번호, 고객명
--		, to_number(substr(거래금액, 1, 10)) 평균거래금액
--		, to_number(substr(거래금액, 11, 20)) 최소거래금액
--		, to_number(substr(거래금액, 21)) 최대거래금액 
-- from (
--	select c.고객번호, c.고객명
-- 		, (select lpad(avg(거래금액), 10) || lpad(min(거래금액), 10) || max(거래금액)
-- 		   from 거래 
--		   where 거래일시 >= trunc(sysdate, 'mm')
--		   and 고객번호 = c.고객번호) 거래금액
-- from 고객 c 
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- ) 

-- select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
-- from 고객 c 
-- 		, (select /*+ no_merge push_pred */ 
--		   		  고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래 
--		   from 거래 
-- 		   where 거래일시 >= trunc(sysdate, 'mm')
--		   group by 고객번호) t
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
-- and t.고객번호 (+)= c.고객번호 

-- 스칼라 서브쿼리 UNNESTING
-- select c.고객번호, c.고객명
--		, (select /*+ unnest */ round(avg(거래금액), 2) 평균거래금액 
--		   from 거래 
--		   where 거래일시 >= trunc(sysdate, 'mm')
--		   and 고객번호 = c.고객번호)
-- from 고객 c
-- where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm') 


-- 5장 소트튜닝 
-- select distinct p.상품번호, p.상품명, p.상품가격, ... 
-- from 상품 p, 계약 c 
-- where p.상품유형코드 = :pclscd 
-- and c.상품번호 = p.상품번호 
-- and c.계약일자 between :dt1 and :dt2 
-- and c.계약구분코드 = :ctpcd 

-- select p.상품번호, p.상품명, p.상품가격, ...
-- from 상품 p 
-- where p.상품유형코드 = :pclscd 
-- and exists (select 'x' from 계약 c 
--			   where c.상품번호 = p.상품번호
--			   and c.계약일자 between :dt1 and :dt2 
--			   and c.계약구분코드 = :ctpcd)

-- <튜닝전> 
-- select st.상황접수번호, st.관제일련번호, st.상황코드, st.관제일시
-- from 관제진행상황 st 
-- where 상황코드 = '0001' -- 신고접수 
-- and 관제일시 between :v_timefrom || '000000' and :v_timeto || '235959'
-- minus 
-- select st.상황접수번호, st.관제일련번호, st.상황코드, st.관제일시
-- from 관제진행상황 st, 구조활동 rpt 
-- where 상황코드 = '0001'
-- and 관제일시 between :v_timefrom || '000000' and :v_timeto || '235959'
-- and rpt.출동센터ID = :v_cntr_id 
-- and st.상황접수번호 = rpt.상황접수번호 
-- order by 상황접수번호, 관제일시 

-- <튜닝후>
-- select st.상황접수번호, st.관제일련번호, st.상황코드, st.관제일시
-- from 관제진행상황 st 
-- where 상황코드 = '0001' -- 신고접수 
-- and 관제일시 between :v_timefrom || '000000' and :v_timeto || '235959'
-- and not exists (select 'x' from 구조활동 
--				   where 출동센터ID = :v_cntr_id
--				   and 상황접수번호 = st.상황접수번호)
-- order by st.상황접수번호, st.관제일시 

-- top N
-- <MsSQL>
-- select top 10 거래일시, 체결건수, 체결수량, 거래대금
-- from 종목거래
-- where 종목코드 = 'KR123456'
-- and 거래일시 >= '20180304'
-- order by 거래일시

-- <IBM DB2>
-- select 거래일시, 체결건수, 체결수량, 거래대금
-- from 종목거래 
-- where 종목코드 = 'KR123456'
-- and 거래일시 >= '20180304'
-- order by 거래일시
-- fetch first 10 rows only; 

-- <Oracle>
-- select * from (
--	select 거래일시, 체결건수, 체결수량, 거래대금 
--  from 종목거래
--	where 종목코드 = 'KR123456'
--	and 거래일시 >='20180304'
--	order by 거래일시
-- )
-- where rownum <= 10 

-- 페이징처리
-- select *
-- from (
-- 	select rownum no, a.* 
--	from 
--		(
--			/* SQL Body */
--		) a
--	where rownum <= (:page * 10)
--	)
-- where no >= (:page-1) * 10 + 1

-- select * 
-- from (
--	select rownum no, a.*
--	from 
--		(
--			select 거래일시, 체결건수, 체결수량, 거래대금
--			from 종목거래
--			where 종목코드 = 'KR123456'
--			and 거래일시 >= '20180304'
--			order by 거래일시
--		) a
-- 	where rownum <= (:page * 10)
--	)
-- where no >= (:page-1) * 10 + 1

CREATE INDEX emp_x1 ON emp(sal);

explain plan FOR
SELECT max(sal) FROM emp; 

SELECT * FROM table(dbms_xplan.display);

CREATE INDEX emp_x2 ON emp(deptno, mgr, sal);
CREATE INDEX emp_x3 ON emp(deptno, sal, mgr);

explain plan FOR 
SELECT /*+ index(emp emp_x3) */ max(sal) FROM emp WHERE deptno = 30 AND mgr = 7698;

CREATE INDEX emp_x4 ON emp(deptno, sal);

explain plan FOR
SELECT * 
FROM (
	SELECT sal 
	FROM emp 
	WHERE deptno = 30 
	AND mgr = 7968
	ORDER BY sal desc
)
WHERE rownum <= 1;

-- select 장비번호, 장비명 
-- 		, substr(최종이력, 1, 8) 최종변경일자
--		, to_number(substr(최종이력, 9, 4)) 최종변경순번
--		, substr(최종이력, 13) 최종상태코드
-- from (
--		select 장비번호, 장비명
--			, (select /*+ index_desc(x 상태변경이력_PX) */
--					  변경일자 || LPAD(변경순번, 4) || 상태코드 
--			   from 상태변경이력 x 
--			   where 장비번호 = p.장비번호
--			   and rownum <= 1 ) 최종이력 
-- 		from 장비 p
--		where 장비구분코드 = 'A001'
-- ) 

-- Predicate Pushing 쿼리 변환 작동 
-- select 장비번호, 장비명 
-- 		, substr(최종이력, 1, 8) 최종변경일자
--		, to_number(substr(최종이력, 9, 4)) 최종변경순번
--		, substr(최종이력, 13) 최종상태코드
-- from (
--		select 장비번호, 장비명
--			, (select 변경일자 || LPAD(변경순번, 4) || 상태코드 
--			   from (select 장비번호, 변경일자, 변경순번, 상태코드
--					 from 상태변경이력
--					 order by 변경일자 desc, 변경순번 desc) 
--			   where 장비번호 = p.장비번호
--			   and rownum <= 1 ) 최종이력 
-- 		from 장비 p
--		where 장비구분코드 = 'A001'
-- ) 

-- select 장비번호, 장비명 
-- 		, substr(최종이력, 1, 8) 최종변경일자
--		, to_number(substr(최종이력, 9, 4)) 최종변경순번
--		, substr(최종이력, 13) 최종상태코드
-- from (
--		select 장비번호, 장비명
--			, (select 변경일자 || LPAD(변경순번, 4) || 상태코드 
--			   from (select 장비번호, 변경일자, 변경순번, 상태코드
--					 from 상태변경이력
--					 where 장비번호 = p.장비번
--					 order by 변경일자 desc, 변경순번 desc) 
--			   where rownum <= 1 ) 최종이력 
-- 		from 장비 p
--		where 장비구분코드 = 'A001'
-- ) 

-- select P.장비번호, P.장비명 
-- 		, H.변경일자 AS 최종변경일자
--		, H.변경순번 AS 최종변경순번 
--		, H.상태코드 AS 최종상태코드 
-- from 장비 P 
-- 		, (select 장비번호, 변경일자, 변경순번, 상태코드
--				, row_number() over(partition by 장비번호 order by 변경일자 desc, 변경순번 desc) RNUM
--		   from 상태변경이력 ) H
-- where H.장비번호 = P.장비번호 
-- and H.RNUM = 1; 

-- select P.장비번호, P.장비명 
-- 		, H.변경일자 AS 최종변경일자
--		, H.변경순번 AS 최종변경순번 
--		, H.상태코드 AS 최종상태코드 
-- from 장비 P 
-- 		, (select 장비번호
--				, max(변경일자) 변경일자 
--				, max(변경순번) KEEP (DENSE_RANK LAST ORDER BY 변경일자, 변경순번) 변경순번
--				, max(상태코드) KEEP (DENSE_RANK LAST ORDER BY 변경일자, 변경순번) 상태코
--		   from 상태변경이력
--		   group by 장비번 ) H
-- where H.장비번호 = P.장비번호;

-- select P.장비번호, P.장비명 
--		, H.상태코드, H.유효시작일자, H.유효종료일자, H.변경순번 
-- from 장비 P, 상태변경이력 H 
-- where P.장비구분코드 = 'A001'
-- and H.장비번호 = P.장비번호 
-- and H.유효종료일자 = '99991231'

-- select P.장비번호, P.장비명 
--		, H.상태코드, H.유효시작일자, H.유효종료일자, H.변경순번 
-- from 장비 P, 상태변경이력 H 
-- where P.장비구분코드 = 'A001'
-- and H.장비번호 = P.장비번호 
-- and :base_dt between H.유효시작일자 and H.유효종료일자 