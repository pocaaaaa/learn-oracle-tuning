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

