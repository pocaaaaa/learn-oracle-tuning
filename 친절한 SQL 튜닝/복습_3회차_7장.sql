-- =================================================================================
-- =================================================================================
-- 7-1.통계정보와 비용 계산 원리
-- 테이블 통계를 수집하는 명령어
begin
  dbms_stats.gather_table_stats('scott', 'emp')
end;
/

-- 조회하는 쿼리. all_tab_statistics 뷰에서도 같은 정보 확인 가능
select num_rows, blocks, avg_row_len, sample_size, last_analyzed
from all_tables
where owner = 'SCOTT'
and table_name = 'EMP'

-- 인덱스 통계만 수집
begin
  dbms_stats.gather_index_stats(ownname => 'scott', indname => 'emp_x01');
end;
/

-- 테이블 통계를 수집하면서 인덱스 통계도 같이 수집
begin
  dbms_stats.gather_table_stats('scott', 'emp', cascade=>true);
end;
/

-- 수집된 인덱스 통계정보는 아래와 같이 조회할 수 있으며, all_ind_statistics 뷰에서도 같은 정보 확인 가능.
select blevel, leaf_blocks, num_rows, distinct_keys
     , avg_leaf_blocks_per_key, avg_data_blocks_per_key, clustering_factor
     , sample_size, last_analyzed
from all_indexes
where owner = 'SCOTT'
and table_name = 'EMP'
and index_name = 'EMP_X01';

select num_distinct, density, avg_col_len, low_value, high_value, num_nulls
     , last_analyzed, sample_size
from all_tab_columns
where owner = 'SCOTT'
and table_name = 'EMP'
and column_name = 'DEPTNO';

-- 히스토그램을 수집하려면, 테이블 통계 수집할 때 아래와 같이 method_opt 파라미터를 지정
begin
  dbms_stats.gather_table_stats('scott', 'emp'
       , cascade => false, method_opt => 'for columns ename size 10, deptno size 4');
end;
/

begin
  dbms_stats.gather_table_stats('scott', 'emp'
       , cascade => false, method_opt => 'for all columns size 75');
end;
/

begin
  dbms_stats.gather_table_stats('scott', 'emp'
       , cascade => false, method_opt => 'for all columns size auto');
end;
/

-- 수집된 컬럼 히스토그램은 아래와 같이 조회
-- all_tab_histograms 뷰에서도 같은 정보를 확인할 수 있음. 
select endpoint_value, endpoint_number
from all_histograms
where owner = 'SCOTT'
and table_name = 'EMP'
and column_name = 'DEPTNO'
order by endpoint_value;

ENDPOINT_VALUE ENDPOINT_NUMBER
-------------- ---------------
            10               3
            20               8
            30              14



-- =================================================================================
-- =================================================================================
-- 7-2.옵티마이저에 대한 이해
-- alter system 또는 alter session 명령어로 옵티마이저 모드를 설정할 때
-- N으로 지정할 수 있는 값은 아래와 같이 1, 10, 100, 1000 네 가지.
alter session set optimizer_mode = first_rows_1;
alter session set optimizer_mode = first_rows_10;
alter session set optimizer_mode = first_rows_100;
alter session set optimizer_mode = first_rows_1000;

-- FIRST_ROWS(n) 힌트로 설정할 때는 괄호 안에 0보다 큰 어떤 정수값이라도 입력 가능
selet /*+ first_rows(30) */ col1, col2, col3 from t where ...

SELECT * 
FROM (
  SELECT ROWNUM NO, 등록일자, 번호, 제목
       , 회원명, 게시판유형명, 질문유형명, 아이콘, 댓글개수
  FROM (
    SELECT A.등록일자, A.번호, A.제목, B.회원명, C.게시판유형명, D.질문유형명
         , GET_ICON(D.질문유형코드) 아이콘, (SELECT ... FROM ... ) 댓글개수
    FROM 게시판 A, 회원 B, 게시판유형 C, 질문유형 D
    WHERE A.게시판유형 = :TYPE
    AND B.회원번호 = A.작성자번호
    AND C.게시판유형 = A.게시판유형
    AND D.질문유형 = A.질문유형
    ORDER BY A.등록일자 DESC, A.질문유형, A.번호
  )
  WHERE ROWNUM <= (:page * 10)
)
WHERE NO >= (:page-1) * 10 + 1

-- 수정
-- 최종 결과 집합 10건에 대해서만 함수를 호출하고, 스칼라 서브 쿼리 수행
-- 최종 결과 집합 10건에 대해서만 NL 조인 수행 
SELECT /*+ ORDERED USE_NL(B) USE_NL(C) USE_NL(D) */
       A.등록일자, A.번호, A.제목, B.회원명, C.게시판유형명, D.질문유형명
     , GET_ICON(D.질문유형콛) 아이콘, (SELECT ... FROM ...) 댓글개수
FROM (
       SELECT A.*, ROWNUM NO
       FROM (
              SELECT 등록일자, 번호, 제목, 작성자번호, 게시판유형, 질문유형
              FROM 게시판
              WHERE 게시판유형 = :TYPE
              AND 작성자번호 IS NOT NULL
              AND 게시판유형 IS NOT NULL
              AND 질문유형 IS NOT NULL
              ) A
       WHERE ROWNUM <= (:page * 10)
      ) A, 회원 B, 게시판유형 C, 질문유형 D
WHERE A.NO >= (:page-1) * 10 + 1
AND B.회원번호 = A.작성자번호
AND C.게시판유형 = A.게시판유형
AND D.질문유형 = A.질문유형
ORDER BY A.등록일자 DESC, A.질문유형, A.번호