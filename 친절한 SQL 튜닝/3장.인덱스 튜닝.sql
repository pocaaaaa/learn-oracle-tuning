-- p146 ~ p , 인덱스 컬럼 추가 
explain plan FOR 
SELECT /* index(emp e_x01) */ *
FROM emp 
WHERE deptno = 30
AND sal >= 2000;

SELECT * FROM table(dbms_xplan.display(NULL, NULL, 'ALL'));

SELECT * FROM emp WHERE DEPTNO = 30 AND job = 'CLERK';


--p152, 인덱스 구조 테이블 (IOT)
CREATE TABLE index_org_t (a NUMBER, b varchar(10), CONSTRAINT index_org_pk PRIMARY KEY (a))
organization INDEX;

CREATE TABLE heap_org_t (a NUMBER, b varchar(10), CONSTRAINT heap_org_pk PRIMARY KEY (a))
organization heap;


-- p155, 인덱스 클러스터 테이블
-- [인덱스 클러스터 테이블 구]
--  1. 클러스터 생성 
CREATE CLUSTER c_dept#(deptno NUMBER(2)) INDEX;

--  2. 클러스터 인덱스 정의 
--   : 클러스터 인덱스는 데이터 검색 용도로 사용할 뿐만 아니라 데이터가 저장될 위치를 찾을 때도 사용. 
CREATE INDEX c_dept#_idx ON CLUSTER c_dept#;

--  3. 클러스터 테이블 생성
CREATE TABLE dept2 (
	deptno number(2) NOT NULL, 
	dname varchar2(14) NOT NULL, 
	loc varchar2(13)
)
CLUSTER c_dept#(deptno);


-- p157, 해시 클러스터 테이블 
--  1. 클러스터 생성 
CREATE CLUSTER c_dept2# (deptno NUMBER(2)) hashkeys 4;

--  2. 클러스터 테이블 생성 
CREATE TABLE dept3 (
	deptno number(2) NOT NULL, 
	dname varchar2(14) NOT NULL, 
	loc varchar2(13)
)
CLUSTER c_dept2# (deptno);

explain plan FOR
SELECT * FROM dept3 WHERE deptno = 10;

SELECT * FROM table(dbms_xplan.display(NULL, NULL, 'ALL'));