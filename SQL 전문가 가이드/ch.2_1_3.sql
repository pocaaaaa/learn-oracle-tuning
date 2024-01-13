-- Function

-- ======================================================
--  1. 문자형 함수

-- result : sql expert
SELECT LOWER('SQL Expert') FROM DUAL; 

-- result : SQL EXPERT
SELECT UPPER('SQL Expert') FROM DUAL; 

-- result : 65
SELECT ASCII('A') FROM DUAL;

-- result : 'A'
-- MsSQL : CHAR(65) 
SELECT CHR(65) FROM DUAL; 

-- result : RDBMS SQL
-- MsSQL : 'RDBMS'+' SQL'
SELECT CONCAT('RDBMS', ' SQL'), 'RDBMS'||' SQL' FROM DUAL;

-- result : Exp 
-- MsSQL : SUBSTRING('SQL Expert', 5, 3)
SELECT SUBSTR('SQL Expert', 5, 3) FROM DUAL;

-- result : 10
-- MsSQL : LEN('SQL Expert)
SELECT LENGTH('SQL Expert') FROM DUAL;

-- result : YYZZxYZ
SELECT LTRIM('xxxYYZZxYZ', 'x') FROM DUAL;

-- result : XXYYzzXY, XXYYZZXXYZ
SELECT RTRIM('XXYYzzXYzz', 'z'), RTRIM('XXYYZZXXYZ     ')  FROM DUAL;

-- result : YYZZxYZ
SELECT TRIM('x' FROM 'xxYYZZxYZxx') FROM DUAL;


-- ======================================================
--  2. 숫자형 함

-- result : 15
SELECT ABS(-15) FROM DUAL;

-- result : -1, 0, 1
SELECT SIGN(-20), SIGN(0), SIGN(20)  FROM DUAL;

-- result : 1
-- MsSQL : 7%3
SELECT MOD(7, 3) FROM DUAL;

-- result : 39
-- MsSQL : CEILING(38.123) -> 39, CEILING(-38.123) -> -38
SELECT CEIL(38.123) FROM DUAL;

-- result : 38, -39
SELECT FLOOR(38.123), FLOOR(-38.123) FROM DUAL;

-- result : 38.524, 38.5, 39, 39
SELECT ROUND(38.5235, 3), ROUND(38.5235, 1), ROUND(38.5235, 0), ROUND(38.5235) FROM DUAL;

-- result : 38.523, 38.5, 38, 38
SELECT TRUNC(38.5235, 3), TRUNC(38.5235, 1), TRUNC(38.5235, 0), TRUNC(38.5235) FROM DUAL;

-- result : 0, 1, 0
SELECT SIN(0), COS(0), TAN(0) FROM DUAL;

-- result : 7.3890560989306502272304274605750078132
SELECT EXP(2) FROM DUAL;

-- result : 8
SELECT POWER(2, 3) FROM DUAL;

-- result : 2
SELECT SQRT(4) FROM DUAL;

-- result : 2, 0.5
-- MsSQL : LOG(100, 10)
SELECT LOG(10, 100) FROM DUAL;

-- result : 2.00000000014472075436630547335067377654 -> 2
SELECT LN(7.3890561) FROM DUAL;


-- ======================================================
--  3. 날짜형 함

-- result : 2024-01-12 14:47:46.000
-- MsSQL : GETDATE()
SELECT SYSDATE FROM DUAL;

-- result : 1980, 12, 17
-- MsSQL : DATEPART('YEAR'|'MONTH'|'DAY', d)
SELECT ENAME AS 사원명, HIREDATE AS 입사일자
	 , EXTRACT (YEAR FROM HIREDATE) AS 입사년도 
	 , EXTRACT (MONTH FROM HIREDATE) AS 입사월 
	 , EXTRACT (DAY FROM HIREDATE) AS 입사일 
FROM EMP;

-- result : 1980, 12, 17
-- MsSQL : YEAR(d), MONTH(d), DAY9d
SELECT ENAME AS 사원명, HIREDATE AS 입사일자
	 , TO_NUMBER(TO_CHAR(HIREDATE, 'YYYY')) AS 입사년도
	 , TO_NUMBER(TO_CHAR(HIREDATE, 'MM')) AS 입사월 
	 , TO_NUMBER(TO_CHAR(HIREDATE, 'DD')) AS 입사일 
FROM EMP;


-- ======================================================
--  4. 변환형 함수 

-- result : K01, 579
-- MsSQL : CAST (expression AS data_type [(length)])
SELECT 'K01' AS 팀ID, TO_NUMBER('123', '999') + TO_NUMBER('456', '999') AS 우편번호합 FROM DUAL;  

-- result : 2024/01/12, 2024. 1월 , 금요일
-- MsSQL : CONVERT (data_type [(length)], expression[, style])
SELECT TO_CHAR(SYSDATE, 'YYYY/MM/DD') AS 날짜
	 , TO_CHAR(SYSDATE, 'YYYY. MON, DAY') AS 문자형 
FROM DUAL;

-- result : $102,880.66, ￦123,456,789
SELECT TO_CHAR(123456789 / 1200, '$999,999,999.99') AS 환율반영달
	 , TO_CHAR(123456789, 'L999,999,999') AS 원화 
FROM DUAL;

-- result : TO_DATE (문자열 [, FORMAT])
-- MsSQL : CONVERT (data_type [(length)], expression[, style])


-- ======================================================
--  5. CASE 표현 
SELECT ENAME 
	   , CASE 
	   		WHEN SAL > 2000 THEN SAL
	   		ELSE 2000
	   	 END AS REVISED_SALARY
FROM EMP;

-- SIMPLE_CASE_EXPRESSION 조건 
SELECT LOC
	 , CASE LOC
	 		WHEN 'NEW YORK' THEN 'EAST'
	 		WHEN 'BOSTON' THEN 'EAST'
	 		WHEN 'CHICAGO' THEN 'CENTER'
	 		WHEN 'DALLAS' THEN 'CENTER'
	   		ELSE 'ETC'
	   END AS AREA
FROM DEPT;

-- SEARCH_CASE_EXPRESSION 조건 
SELECT ENAME
	 , CASE 
	 		WHEN SAL >= 3000 THEN 'HIGH'
	 		WHEN SAL >= 1000 THEN 'MID'
	 		ELSE 'LOW'
	 	END AS SALARY_GRADE 
FROM EMP; 
	 
SELECT ENAME, SAL 
	 , CASE 
	 		WHEN SAL >= 2000 THEN 1000 
	 		ELSE (CASE 
	 					WHEN SAL >= 1000 THEN 500
	 					ELSE 0
	 			  END
	 		)
	 END AS BONUS
FROM EMP;


-- ======================================================
--  5. NULL 관련 함수

-- result : NVL-OK
-- MsSQL : ISNULL(표현식1, 표현식2)
SELECT NVL(NULL, 'NVL-OK') AS NVL_TEST
FROM DUAL;

-- result : Not-Null
SELECT NVL('Not-Null', 'NVL-OK') NVL_TEST
FROM DUAL;

SELECT ENAME AS 사원명, SAL AS 월급, COMM AS 커미션	
	 , (SAL * 12) + COMM AS 연봉A, (SAL * 12) + NVL(COMM, 0) AS 연봉B
FROM EMP;

SELECT MAX(MGR) AS MGR1, NVL(MAX(MGR), 9999) AS MGR2
FROM EMP
WHERE ENAME = 'JSC';

-- MsSQL : NULLIF(표현식1, 표현식2)
SELECT ENAME, EMPNO, MGR, NULLIF(MGR, 7698) AS NIF FROM EMP;

SELECT ENAME, EMPNO, MGR 
	 , CASE
	 		WHEN MGR = 7698 THEN NULL 
	 		ELSE MGR
	   END AS NUIF
FROM EMP;
	 END
	 
-- COALESCE(표현식1, 표현식2)
SELECT ENAME, COMM, SAL, COALESCE(COMM, SAL) AS COAL FROM EMP;

SELECT ENAME, COMM, SAL
	 , CASE 
	 		WHEN COMM IS NOT NULL THEN COMM 
	 		ELSE (CASE
	 					WHEN SAL IS NOT NULL THEN SAL
	 					ELSE NULL
	 			  END
	 		) 
	   END AS COAL
FROM EMP;
	 





FROM EMP;