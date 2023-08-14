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

DROP INDEX t_x01;
DROP INDEX t_x02;

COMMIT;

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


-- p41 세그먼트에 할당된 익스텐트 목록 조회 
SELECT segment_type, tablespace_name, extent_id, file_id, block_id, blocks
FROM dba_extents
WHERE owner = USER
AND segment_name = 'MY_SEGMENT'
ORDER BY extent_id;


-- p45 오라클 데이터베이스의 블록 사이즈를 확인하는 방법
SQL> show parameter block_size;
SELECT value FROM v$parameter WHERE name = 'db_block_size';


-- p58 오라클에서 손수레에 한 번에 담는 양 => db_file_multiblock_read_count
SQL> alter session set db_file_multiblock_read_count = 128;
SQL> show parameter db_file_multiblock_read_count;
