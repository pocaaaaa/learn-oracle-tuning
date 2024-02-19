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