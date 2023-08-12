-- [Sample Data] 1장. SQL 처리 과정과 I/O
-- SQLP 계정에 권한 주기 
grant unlimited tablespace to SQLP;

-- [출처 tobesoft docs (http://docs.tobesoft.com/difingo3/764a525203dbb29b) 
drop table dept;
drop table emp;
drop table salgrade;



create table dept(
    deptno number(2),
    dname varchar2(14),
    loc varchar2(13),
    constraint DEPT_DEPTNO_PK primary key(deptno)
);

insert into dept values(10,'ACCOUNTING','NEW YORK');
insert into dept values(20,'RESEARCH','DALLAS');
insert into dept values(30,'SALES','CHICAGO');
insert into dept values(40,'OPERATIONS','BOSTON');



create table emp(
    empno number(4),
    ename varchar2(10),
    job varchar2(9),
    mgr number(4),
    hiredate date,
    sal number(7,2),
    comm number(7,2),
    deptno number(2) not null,
    constraint EMP_DEPTNO_FK FOREIGN key(deptno) REFERENCES dept(deptno),
    constraint EMP_EMPNO_PK primary key(empno)
);

insert into emp values(7369,'SMITH','CLERK',7902,'80/12/17',800, NULL,20);
insert into emp values(7499,'ALLEN','SALESMAN',7698,'81/02/20',1600,300,30);
insert into emp values(7521,'WARD','SALESMAN',7698,'81/02/22',1250,500,30);
insert into emp values(7566,'JONES','MANAGER',7839,'81/04/02',2975,NULL,20);
insert into emp values(7654,'MARTIN','SALESMAN',7698,'81/09/28',1250,1400,30);
insert into emp values(7698,'BLAKE','MANAGER',7839,'81/05/01',2850,NULL,30);
insert into emp values(7782,'CLARK','MANAGER',7839,'81/05/09',2450,NULL,10);
insert into emp values(7788,'SCOTT','ANALYST',7566,'87/04/19',3000,NULL,20);
insert into emp values(7839,'KING','PRESIDENT',NULL,'81/11/17',5000,NULL,10);
insert into emp values(7844,'TURNER','SALESMAN',7698,'81/09/08',1500,0,30);
insert into emp values(7876,'ADAMS','CLERK',7788,'87/05/23',1100,NULL,20);
insert into emp values(7900,'JAMES','CLERK',7698,'81/12/03',950,NULL,30);
insert into emp values(7902,'FORD','ANALYST',7566,'81/12/03',3000,NULL,20);
insert into emp values(7934,'MILLER','CLERK',7782,'82/01/23',1300,NULL,10);



create table salgrade(
    grade number,
    losal number,
    hisal number
);

insert into salgrade values(1,700,1200);
insert into salgrade values(2,1201,1400);
insert into salgrade values(3,1401,2000);
insert into salgrade values(4,2001,3000);
insert into salgrade values(5,3001,9999);