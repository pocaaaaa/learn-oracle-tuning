-- 옵티마이저 
-- [Oracle] select /*+ first_rows(10) */ * from t where ; 
-- [MsSql] select * from t where OPTION(fast 10);

-- 서울시와 경기도처럼 선택도 (Selectivity)가 높은 값이 입력될 때는 Full Table Scan이 유리하고, 
-- 강원도나 제주도처럼 선택도가 낮은 값이 입력될 때는 인덱스를 경유해 테이블 액세스 하는 것이 유리.
-- select * from 아파트매물 where 도시 = :CITY;

-- select /*+ FULL(a) */ * 
-- from 아파트매물 a 
-- where :CITY in ('서울시', '경기도')
-- and 도시 = :CITY
-- union all 
-- select /*+ INDEX(a IDX01) */ *
-- from 아파트매물 a 
-- and :CITY not in ('서울시', '경긱도')
-- and 도시 = :CITY;

-- 쿼리변환 
-- 서브쿼리 Unnesting 

SELECT * FROM emp 
WHERE deptno IN (SELECT dpetno FROM dept);

SELECT * 
FROM (SELECT deptno FROM dept) a, emp b 
WHERE b.deptno = a.deptno; 

SELECT emp.* FROM dept, emp 
WHERE emp.deptno = dept.deptno; 

-- unnest : 서브쿼리를 Unnestin 함으로써 조인방식 최적화 유도 
-- no_unnest : 서브쿼리를 그대로 둔 상태에서 필터 방식으로 최적화 유도 

-- 조건절 pushdown 
explain plan FOR
SELECT deptno, avg_sal 
FROM (SELECT deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) a 
WHERE deptno = 30;

explain plan for
SELECT b.deptno, b.dname, a.avg_sal
FROM (SELECT deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) a, dept b 
WHERE a.deptno = b.deptno 
AND b.deptno = 30;

SELECT b.deptno, b.dname, a.avg_sal
FROM (SELECT deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) a, dept b 
WHERE a.deptno = b.deptno 
AND b.deptno = 30
AND a.deptno = 30;

SELECT * 
FROM table(dbms_xplan.display);

-- 조건절 Pullup 
explain plan for
SELECT * FROM 
(SELECT deptno, avg(sal) FROM emp WHERE deptno = 10 GROUP BY deptno) e1, 
(SELECT deptno, min(sal), max(sal) FROM emp GROUP BY deptno) e2 
WHERE e1.deptno = e2.deptno;

SELECT * FROM 
(SELECT deptno, avg(sal) FROM emp WHERE deptno = 10 GROUP BY deptno) e1, 
(SELECT deptno, min(sal), max(sal) FROM emp WHERE deptno = 10 GROUP BY deptno) e2 
WHERE e1.deptno = e2.deptno;

SELECT * FROM table(dbms_xplan.display);

-- 조인 조건 pushdown
explain plan for
SELECT d.deptno, d.dname, e.avg_sal
FROM dept d,
	 (SELECT /*+ no_merge push_pred */ deptno, avg(sal) avg_sal FROM emp GROUP BY deptno) e 
WHERE e.deptno (+)= d.deptno; 

SELECT d.deptno, d.dname
	 , (SELECT avg(sal) FROM emp WHERE deptno = d.deptno) avg_sal
	 , (SELECT min(sal) FROM emp WHERE deptno = d.deptno) min_sal 
	 , (SELECT max(sal) FROM emp WHERE deptno = d.deptno) max_sal 
FROM dept d;

SELECT deptno, dname 
	 , to_number(substr(sal, 1, 7)) avg_sal
	 , to_number(substr(sal, 8, 7)) min_sal 
	 , to_number(substr(sal, 15)) max_sal 
FROM (
	SELECT /*+ no_merge */ d.deptno, d.dname
		 , (SELECT lpad(avg(sal), 7) || lpad(min(Sal), 7) || max(sal)
		 	FROM emp WHERE deptno = d.deptno) sal 
	FROM dept d
);

-- 조건절 이행 
explain plan for
SELECT * FROM dept d, emp e 
WHERE e.job = 'MANAGER'
AND e.deptno = 10
AND d.deptno = e.deptno;

SELECT * FROM dept d, emp e 
WHERE e.job = 'MANAGER'
AND e.deptno = 10
AND d.deptno = 10;

-- OR 조건을 Union으로 변환
explain plan FOR 
SELECT * FROM emp 
WHERE job = 'CLERK' OR deptno = 20;

SELECT * FROM table(dbms_xplan.display);

explain plan FOR 
SELECT /*+ use_concat */ * FROM emp 
WHERE job = 'CLERK' OR deptno = 20;

explain plan FOR 
SELECT /*+ no_expand */ * FROM emp 
WHERE job = 'CLERK' OR deptno = 20;

