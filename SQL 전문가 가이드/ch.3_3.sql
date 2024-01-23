explain plan FOR
SELECT * FROM emp WHERE empno = 7900;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'serial'));

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- ============================================================================
-- ============================================================================
-- 1. Index Range Scan 
CREATE INDEX emp_deptno_idx ON emp(deptno);

explain plan FOR 
SELECT /*+ INDEX(emp emp_deptno_idx) */ * FROM emp WHERE deptno = 20;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

-- 2. Index Full Scan 
CREATE INDEX emp_idx ON emp (ename, sal);

explain plan for
SELECT * FROM emp 
WHERE sal > 2000
ORDER BY ename;

explain plan for
SELECT * FROM emp 
WHERE sal > 5000
ORDER BY ename;

explain plan for
SELECT /*+ first_rows */ * FROM emp 
WHERE sal > 1000
ORDER BY ename;

explain plan for
SELECT /*+ index_ffs(emp EMP_IDX) */ * FROM emp 
WHERE sal > 1000
ORDER BY ename;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

-- 3. Index Unique Scan
explain plan for 
SELECT empno, ename FROM emp WHERE empno = 7788;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

-- 4. Index Skip Scan
explain plan FOR 
SELECT /*+ INDEX(emp EMP_IDX) */ * FROM emp WHERE sal BETWEEN 2000 AND 4000;

explain plan FOR 
SELECT /*+ INDEX(emp EMP_IDX) */ * FROM emp WHERE ename IN ('SMITH', 'ALLEN') AND sal BETWEEN 2000 AND 4000;

-- 5. Index Range Scan Descending 
explain plan for
SELECT * FROM emp 
WHERE empno IS NOT NULL 
ORDER BY empno DESC;

-- 6. first row
CREATE INDEX emp_x02 ON emp(deptno, sal);

explain plan for
SELECT deptno, dname, loc 
    , (SELECT /*+ index(emp emp_x02)*/ max(sal) FROM emp WHERE deptno = d.deptno)
FROM dept d;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- ============================================================================
-- ============================================================================
-- 1. 묵시적 형변환
explain plan FOR  
SELECT * FROM emp WHERE deptno = '20';

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- ============================================================================
-- ============================================================================
-- 1. 배치 I/O
CREATE INDEX emp_x01 ON emp (deptno, job, empno);

explain plan for
SELECT /*+ batch_table_access_by_rowid(e) */ *
FROM emp e 
WHERE deptno = 20
ORDER BY job, empno;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- ============================================================================
-- ============================================================================
-- 1. NL 조인
explain plan FOR 
SELECT /*+ ordered use_nl(d) */ e.empno, e.ename, d.dname
FROM emp e, dept d 
WHERE d.deptno = e.deptno;

explain plan FOR 
SELECT /*+ leading(e) use_nl(d) */ e.empno, e.ename, d.dname
FROM emp e, dept d 
WHERE d.deptno = e.deptno;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

-- MsSQL
-- select e.empno, e.ename, d.dname
-- from emp e inner loop join dept d on d.deptno = e.deptno 
-- option(force order);

-- select e.empno, e.ename, d.dname
-- from emp e, dept d 
-- where d.deptno = e.deptno 
-- option (force order, loop join)

-- Prefetch 실행계획
explain plan FOR 
SELECT /*+ use_nl(e d nlj_prefetch(e, 100)) */ *
FROM emp e, dept d 
WHERE d.deptno = e.deptno;

-- 배치 I/O (방지하려면 no_nlj_batching, ORDER BY 절에 정렬 순서 명시)
explain plan FOR 
SELECT /*+ use_nl(e d nlj_batching(e, 100)) */ *
FROM emp e, dept d 
WHERE d.deptno = e.deptno;

-- 2. 소트 머지 조인
--  1) 소트 단계 : 양쪽 집합을 조인 칼럼 기준으로 정렬한다. (조인 컬럼에 인덱스가 있으면 생략)
--  2) 머지 단계 : 정렬된 양쪽 집합을 서로 머지(merge)한다. 
--  => Oracle은 조인 연산자가 부동호이거나 아예 조인 조건이 없어도 소트 머지 조인으로 처리할 수 있음.
--  => SQL Server는 조인 연산자가 '=' 일 때만 소트 머지 조인을 수행한다는 사실도 유념. 
explain plan for
SELECT /*+ ordered use_merge(e) */ d.deptno, d.dname, e.empno, e.ename
FROM dept d, emp e 
WHERE d.deptno = e.deptno;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

-- MsSQL 
-- select d.deptno, d.dname, e.empno, e.ename
-- from dept d, emp e 
-- where d.deptno = e.deptno 
-- option(force order, merge join)

-- 3. 해시 조인 
--  => 둘 중 작은 집합(Build Input) 을 읽어 해시 영역 (Hash Area)에 해시 테이블 (=해시 맵)을 생성하고, 
--     반대쪽 큰 집합(Probe Input) 을 읽어 해시 테이블을 탐색하면서 조인하는 방식. 
--  => 해시 테이블 생성하는 비용이 수반됨. 
--  => Bild Input 으로 선택된 테이블이 작은 것도 중요하지만 해시 키 값으로 사용되는 컬럼에 중복 값이 거의 없을 때라야 효과적. 
-- 
--  1) 한 쪽 테이블이 가용 메모리에 담길 정도로 충분히 작아야 함. 
--  2) Build Input 해시 키 칼럼에 중복 값이 거의 없어야 함. 
explain plan for
SELECT /*+ ordered use_hash(e) */ d.deptno, d.dname, e.empno, e.ename 
FROM dept d, emp e 
WHERE d.deptno = e.deptno;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

-- MsSQL
-- select d.deptno, d.dname, e.empno, e.ename 
-- from dept d, emp e 
-- where d.deptno = e.deptno 
-- option (force order, hash join);