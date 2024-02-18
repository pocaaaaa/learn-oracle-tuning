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