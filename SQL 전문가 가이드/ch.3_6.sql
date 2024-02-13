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

-- 병렬처리
-- select /*+ full(o) parallel(o, 4) */
-- 		  count(*) 주문건수, sum(주문수) 주문수량, sum(주문금액) 주문금액
-- from 주문 o
-- where 주문일시 between '20100101' and '20101231'

-- select /*+ index_ffs(o, 주문_idx) parallel_index(o, 주문_idx, 4) */
-- 		  count(*) 주문건수
-- from 주문 o
-- where 주문일시 between '20100101' and '20101231'

-- select /* full(고객) parallel(고객 4) */ *
-- from 고객 
-- order by 고객명

-- select /*+ ordered use_hash(e) full(d) noparallel(d) full(e) parallel(e 2) pq_distribute(e boardcast none) */ *
-- from d, emp e
-- where d.deptno = e.deptno 
-- order by e.ename 

-- 고급 SQL 활용
-- CASE문 활용
-- INSERT INTO 월별요금납주실적 
-- (고객번호, 납입월, 지로, 자동이체, 신용카드, 핸드폰, 인터넷) 
-- SELECT 고객번호, 납입월 
-- 		, NVL(SUM(CASE WHEN 납입방법코드 = 'A' THEN 납입금액 END), 0) 지로 
-- 		, NVL(SUM(CASE WHEN 납입방법코드 = 'B' THEN 납입금액 END), 0) 자동이 
-- 		, NVL(SUM(CASE WHEN 납입방법코드 = 'C' THEN 납입금액 END), 0) 신용카
-- 		, NVL(SUM(CASE WHEN 납입방법코드 = 'D' THEN 납입금액 END), 0) 핸드 
-- 		, NVL(SUM(CASE WHEN 납입방법코드 = 'E' THEN 납입금액 END), 0) 인터넷 
-- FROM 월별납입방법별집계
-- WHERE 납입월 = '200903'
-- GROUP BY 고객번호, 납입월;

-- Union ALL
-- select 상품, 연월, nvl(sum(계획수량), 0) as 계획수량, nvl(sum(실적수량), 0) as 실적수량
-- from (
-- 			select '계획' as 구분, 상품, 계획연월 as 연월, 판매부서, null as 판매채널 
--				 , 계획수량, to_number(null) as 실적수량 
-- 			from 부서별판매계획
-- 			where 계획연월 between '200901' and '200903'
-- 			union all
-- 			select '실적', 상품, 판매연월 as 연월, null as 판매부서, 판매채널 
-- 		 		 , to_number(null) as 계획수량, 판매수량 
-- 			from 채널별판매실적 
-- 			where 판매연월 between '200901' and '200903'
-- ) a
-- group by 상품, 연월; 

-- select 일련번호, 측정값
-- 		, last_value(상태코드 ignore nulls)
--			over(order by 일련번호 rows betwwen unbounded preceding and current row) 상태코드
-- from 장비측정
-- order by 일련번호 

-- with 구문 활용
