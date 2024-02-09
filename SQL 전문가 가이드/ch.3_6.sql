-- 소트 튜닝
-- sort aggregate 
explain plan FOR 
SELECT sum(sal), max(sal), min(sal) FROM emp;

SELECT * FROM table(dbms_xplan.display);

-- sort order by 
explain plan FOR
SELECT * FROM emp ORDER BY sal DESC;

-- sort group by (hash group by)
explain plan for
SELECT deptno, job, sum(sal), max(sal), min(sal)
FROM emp 
GROUP BY deptno, job;

-- sort unique (nosort)
explain plan for
SELECT DISTINCT deptno FROM emp ORDER BY deptno;

-- sort Join 
explain plan FOR
SELECT /*+ ordered use_merge(e) */ *
FROM emp e, dept d
WHERE d.deptno = e.deptno;

SELECT * FROM table(dbms_xplan.display);

-- window sort 
explain plan FOR 
SELECT empno, ename, job, mgr, row_number() over(ORDER BY hiredate)
FROM emp;

-- 소트가 발생하지 않도록 SQL 작성
-- Union을 Union All로 대체 
explain plan for
SELECT empno, job, mgr FROM emp WHERE deptno = 10
UNION 
SELECT empno, job, mgr FROM emp WHERE deptno = 20;

-- Top N 쿼리
-- [MsSQL]
-- select top 10 거래일시, 체결건수, 체결수량, 거래대금 
-- from 시간별종목거래
-- where 종목코드 = 'KR123456'
-- and 거래일시 >= '20080304';

-- [IBM DB2]
-- select 거래일시, 체결건수, 체결수량, 거래대금 
-- from 시간별종목거래
-- where 종목코드 = 'KR123456'
-- and 거래일시 >= '20080304'
-- order by 거래일시
-- fetch first 10 rows only ;

-- [Oracle]
-- select * from (
--	select 거래일시, 체결건수, 체결수량, 거래대금 
--	from 시간별종목거래
--	where 종목코드 = 'KR123456'
--	and 거래일시 >= '20080304'
--	order by 거래일시
-- ) 
-- where rownum <= 10; 

-- select *
-- from (select rownum no, 거래일시, 체결건수, 체결수량, 거래대금 
-- 		 from (select 거래일시, 체결건수, 체결수량, 거래대
--			   from 시간별종목거래
--			   where 종목코드 = 'KR123456'
--			   and 거래일시 >= '20080304'
--			   order by 거래일시
--	 		   ) 
--		 where rownum <= 100
-- 		 ) 
--	where no between 91 and 100; 

-- select 고객ID, 변경순번, 전화번호, 주소, 자녀수, 직업, 고객등급
-- from (select 고객ID, 변경순번
-- 				, rank() over(partition by 고객ID order by 변경순번) rnum 
--				, 전화번호, 주소, 자녀수, 직업, 고객등급
--		 from 고객변경이력) 
-- where rnum = 1;

-- 11g 이하 버전 
-- select 장비번호, 장비명 
-- 		, substr(최종이력, 1, 8) 최종변경일자
--		, to_number(substr(최종이력, 9, 4) 최종변경순번
--		, substr(최종이력, 13) 최종상태코드
-- from (
--			select 장비번호, 장비명 
--				 , (select /*+ index_desc(x 상태변경이력_px) */
--							변경일자 || LPAD(변경순번, 4) || 상태코드 
--					from 상태변경이력 x 
--					where 장비번호 = P.장비번호 
--					and rownum <= 1 ) 최종이력 	
--			from 장비 P
--			where 장비구분코드 = 'A001'
-- );

-- 12c 버전 이상 
-- select 장비번호, 장비
-- 		, substr(최종이력, 1, 8) 최종변경이력 
--		, to_number(substr(최종이력, 9, 4)) 최종변경순번
--		, substr(최종이력, 13) 최종상태코드 
-- from (
-- 		select 장비번호, 장비명
-- 			 , (select 변경일자 || LPAD(변경순번, 4) || 상태코드 
--				from (select 변경일자, 변경순번, 상태코드 
--			  		  from 상태변경이력
--			  		  where 장비번호 = p.장비번호
--			  		  order by 변경일자 desc, 변경순번 desc) 
--				where rownum <= 1) 최종이력
--		from 장비 p
--		where 장비구분코드 = 'A001'
-- )