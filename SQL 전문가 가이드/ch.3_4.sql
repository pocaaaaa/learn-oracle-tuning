-- 스칼라 서브 쿼리 
explain plan for
SELECT EMPNO, ENAME, SAL, HIREDATE 
    , (
       SELECT D.DNAME -- 출력 값 : D.DNAME 
       FROM DEPT D 
       WHERE D.DEPTNO = E.DEPTNO -- 입력 값 : E.DEPTNO
    ) DNAME 
FROM EMP E
WHERE SAL >= 2000;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));

SELECT /*+ ordered use_nl(D) */ E.EMPNO, E.ENAME, E.HIREDATE, D.DNAME 
FROM EMP E RIGHT OUTER JOIN DEPT D 
ON D.DEPTNO = E.DEPTNO 
WHERE E.SAL >= 2000;

-- 조인 조건 Pushdown 
SELECT D.DEPTNO, D.DNAME, AVG_SAL, MIN_SAL, MAX_SAL
FROM DEPT D RIGHT OUTER JOIN 
    (SELECT DEPTNO, AVG(SAL) AVG_SAL, MIN(SAL) MIN_SAL, MAX(SAL) MAX_SAL 
     FROM EMP GROUP BY DEPTNO) E
ON E.DEPTNO = D.DEPTNO 
WHERE D.LOC = 'CHICAGO';

--SELECT D.DEPTNO, D.DNAME 
--    , (SELECT AVG(SAL), MIN(SAL), MAX(SAL) FROM EMP WHERE DEPTNO = D.DEPTNO)
--FROM DEPT D 
--WHERE D.LOC = 'CHICAGO';

SELECT D.DEPTNO, D.DNAME 
    , (SELECT AVG(SAL) FROM EMP WHERE DEPTNO = D.DEPTNO) AVG_SAL
    , (SELECT MIN(SAL) FROM EMP WHERE DEPTNO = D.DEPTNO) MIN_SAL
    , (SELECT MAX(SAL) FROM EMP WHERE DEPTNO = D.DEPTNO) MAX_SAL
FROM DEPT D
WHERE D.LOC = 'CHICAGO';

SELECT DEPTNO, DNAME 
    , TO_NUMBER(SUBSTR(SAL, 1, 7)) AVG_SAL 
    , TO_NUMBER(SUBSTR(SAL, 8, 7)) MIN_SAL
    , TO_NUMBER(SUBSTR(SAL, 15)) MAX_SAL
FROM (
   SELECT D.DEPTNO, D.DNAME 
      ,  (SELECT LPAD(AVG(SAL), 7) || LPAD(MIN(SAL), 7) || MAX(SAL)
         FROM EMP
         WHERE DEPTNO = D.DEPTNO) SAL 
   FROM DEPT D 
   WHERE D.LOC = 'CHICAGO'
)

-- SQL Server 
-- select deptno, dname 
--       , cast(substring(sal, 1, 7) as float) avg_sal 
--      , cast(substring(sal, 8, 7) as int) min_sal
--      , cast(substring(sal, 15, 7) as int) max_sal 
-- from ( 
--          select d.deptno, d.dname 
--             , (select str(avg(sal), 7, 2) + str(min(sal), 7) + str(max(sal), 7) 
--               from emp where deptno = d.deptno) sal 
--         from dept d 
--          where d.loc = 'CHICAGO'
-- ) x

-- 스칼라 서브 쿼리 Unnesting (옵티마지저가 사용자 대신 자동으로 쿼리 변환해줌)
explain plan for
SELECT EMPNO, ENAME, SAL, HIREDATE 
    , (
       SELECT /*+ unnest */ D.DNAME
       FROM DEPT D 
       WHERE D.DEPTNO = E.DEPTNO 
    ) DNAME 
FROM EMP E
WHERE SAL >= 2000;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table', NULL, 'all'));


-- ====================================================================
-- ====================================================================
SELECT to_char(sysdate, 'yyyymmdd') FROM dual;
SELECT to_char(add_months(sysdate, -20*12), 'yyyymmdd') FROM dual;

-- select c.고객번호, c.고객명, c1.고객등급, c2.전화번호 
-- from 고객 c, 고객등급이력 c1, 전화번호변경이력 c2
-- where c.고객번호 = :cust_num
-- and c1.고객번호 = c.고객번호 
-- and c2.고객번호 = c.고객번호
-- and to_char(sysdate, 'yyyymmdd') between c1.시작일자 and c1.종료일자
-- and to_char(sysdate, 'yyyymmdd') between c2.시작일자 and c2.종료일자

-- SQL Server 
-- and convert(varchar(8), getdate(), 112) between c1.시작일자 and c1.종료일자
-- and convert(varchar(8), getdate(), 112) between c2.시작일자 and c2.종료일자 

-- select /*+ ordered use_nl(b) rowid(b) */
--         a.고객명, a.거주지역, a.주소, a.연락처, b.연체금액, b.연체개월수 
-- from 고객 a, 고객별연체이력 b
-- where a.가입회사 = 'C70'
-- and b.rowid = (select /*+ index(c 고객별연체이력_idx01) */ rowid
--               from 고객별연체이력 c 
--               where c.고객번호 = a.고객번호
--              and c.변경일자 <= a.서비스만료일 
--              and rownum <= 1); 


-- ====================================================================
-- ====================================================================

-- select 연체개월수, 연체금액
-- from 고객별연체금액
-- where 고객번호 = :cust_num 
-- and to_char(sysdate, 'yyyymmdd') between 시작일자 and 종료일자;

-- select a.거래일자, a.종목코드,b.종목한글명, b.종목영문명, b.상장주식수 
-- 		, a.시가, a.종가, a.체결건수, a.체결수량, a.거래대금
-- from 일별종목거래및시세 a, 종목이력 b
-- where a.거래일자 between to_char(add_monthes(sysdate, -20*12), 'yyyymmdd')
--					  and to_char(sysdate-1, 'yyyymmdd')
-- and a.종가 = a.최고가
-- and b.종목코드 = a.종목코드 
-- and to_char(sysdate, 'yyyymmdd') between b.시작일자 and b.종료일자;

-- select /*+ ordered use_nl(b) rowid(b) */ 
--		  a.고객명, a.거주지역, a.주소, a.연락처, b.연체금액, b.연체개월수 
-- from 고객 a, 고객별연체이력 b 
-- where a.가입회사 = 'C70'
-- and b.rowid = (select /*+ index(c 고객별연체이력_idx01) */
-- 				  from 고객별연체이력 c 
-- 				  where c.고객번호 = a.고객번호
-- 				  and c.변경일자 <= a.서비스만료일 
--				  and rownum <=1 )
				