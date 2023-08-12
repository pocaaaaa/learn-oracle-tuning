-- p18
SELECT E.EMPNO, E.ENAME, E.JOB, D.DNAME, D.LOC
FROM EMP E, DEPT D
WHERE E.DEPTNO = D.DEPTNO 
ORDER BY E.ENAME;

-- p21 ~ p25
-- 옵티마이저가 특정 실행계획을 선택하는 근거 테스트 
CREATE TABLE T 
AS 
SELECT D.NO, E.*
FROM EMP E, (SELECT rownum NO FROM DUAL CONNECT BY LEVEL <= 1000) D;

CREATE INDEX t_x01 ON t(deptno, no);
CREATE INDEX t_x02 ON t(deptno, job, no);

DROP INDEX t_xol;

-- t 테이블 통계정보 수집 
EXEC dbms_stats.gather_table_stats(user, 't');

SET autotrace traceonly EXP;
SELECT * FROM T 
WHERE DEPTNO = 10
AND NO = 1;

select /*+ index(t t_x02) */ * from t
where deptno = 10
and no = 1;

SELECT /*+ full(t) */ * FROM t 
WHERE deptno = 10
AND NO = 1;
