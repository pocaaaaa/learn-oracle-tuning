-- 묵시적 형변환
explain plan for
SELECT round(avg(SAL)) avg_sal 
	 , max(sal) max_sal
	 , min(sal) min_sal 
	 , max(decode(job, 'PRESIDENT', NULL, sal)) max_sal2
FROM EMP;

SELECT round(avg(SAL)) avg_sal 
	 , max(sal) max_sal
	 , min(sal) min_sal 
	 , max(decode(job, 'PRESIDENT', TO_NUMBER(NULL), sal)) max_sal2
FROM EMP;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- 함수기반 인덱스(FBI)
ALTER TABLE emp ADD v_deptno varchar2(2);

UPDATE emp SET v_deptno = deptno;

CREATE INDEX emp_x01 ON emp(v_deptno);

explain plan for
SELECT /*+ index(emp emp_x01) */ * FROM emp WHERE v_deptno = 20;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

DROP INDEX emp_x01; 

CREATE INDEX emp_x01 ON emp(to_number(v_deptno)); -- 함수기반 인덱스 생성 


-- Index Range Scan
CREATE INDEX emp_deptno_idx ON emp(deptno);

explain plan FOR
SELECT * FROM emp WHERE deptno = 20;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- Index Full Scan 
CREATE INDEX emp_idx ON emp (ename, sal);

explain plan for
SELECT /*+ index(emp emp_idx) */ * FROM emp WHERE sal > 2000;

-- 인덱스를 이용한 소트 연산 대체
explain plan for
SELECT /*+ first_rows */ * FROM emp 
WHERE sal > 1000
ORDER BY ename;


-- Index Unique Scan 
explain plan for
SELECT empno, ename FROM emp WHERE empno = 7788;


-- Index Skip Scan (index_ss, no_index_ss)
-- select /*+ index_ss(사원 사원_IDX) */ * 
-- from 사원
-- where 연봉 between 2000 and 4000; 


-- Index Fast Full Scan (index_ffs, no_index_ffs)
-- 쿼리에 사용되는 모든 컬럼이 인덱스 컬럼에 포함돼 있을 때만 사용 가능. 
-- select /*+ ordered use_nl(b) no_merge(b) rowid(b) */ b.*
-- from (select /*+ index_fss(공급업체 공급업체_X01) */ rowid rid
--       from 공급업체
--       where instr(업체명, '네트웍스') > 0) a, 공급업체 b
-- where b.rowid = rid;


-- Index Range Scan Descending 
explain plan for
SELECT * FROM emp 
WHERE empno > 0
ORDER BY empno DESC;

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

CREATE INDEX emp_x02 ON emp (deptno, sal);

explain plan for
SELECT deptno, dname, loc 
	 , (SELECT max(sal) FROM emp WHERE deptno = d.deptno)
FROM dept d;

explain plan for
SELECT deptno, dname, loc
	 , (SELECT /*+ index_desc(emp emp_x02) */ sal 
	 	FROM emp 
	 	WHERE deptno = d.deptno 
	 	AND rownum <= 1)
FROM dept d;


-- And-Equal 
-- CREATE INDEX emp_deptno_idx ON emp(deptno);
CREATE INDEX emp_job_idx ON emp (job);

explain plan for
SELECT /*+ and_equal(e emp_deptno_idx emp_job_idx) */ *
FROM emp e 
WHERE deptno = 30
AND job = 'SALESMAN';

SELECT *
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- Index Combine 
explain plan for
SELECT /*+ index_combine(e emp_deptno_idx emp_job_idx) */ *
FROM emp e 
WHERE deptno = 30
AND job = 'SALESMAN';