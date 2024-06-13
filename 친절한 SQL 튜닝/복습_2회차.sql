-- =================================================
-- 2024.06.14 ~ 
-- =================================================

-- 실명확인번호 조건에 해당하는 데이터가 한 건이거나 소량일때 => NL조인 
SELECT c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
FROM 고객 c, 고객변경이력 h 
WHERE c.실명확인번호 = :rmnno
AND h.고객번호 = c.고객번호 
AND h.변경일시 = (SELECT max(변경일시) 
				FROM 고객변경이력 m 
				WHERE 고객번호 = c.고객번호 
				AND 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
				AND 변경일시 < trunc(sysdate, 'mm'));
			
-- 전체 300만 명 중 고객구분코드 조건을 만족하는 고객 100만명 
-- 아래 쿼리는 빠른 성능 낼 수 없음.
INSERT INTO 고객_임시 
SELECT c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
FROM 고객 c, 고객변경이력 h 
WHERE c.고객구분코드 = 'A001' -- 100만명 
AND h.고객번호 = c.고객번호 
AND h.변경일시 = (SELECT max(변경일시) 
				FROM 고객변경이력 m 
				WHERE 고객번호 = c.고객번호 
				AND 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
				AND 변경일시 < trunc(sysdate, 'mm'));
				
-- 데이터가 많으므로 Full Scan + 해시 조인 방식이 효과적 
INSERT INTO 고객_임시 
SELECT /*+ full(c) full(h) index_ffs(m.고객변경이력)
		   ordered no_merge(m) use_hash(m) use_hash(h) */
		c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
FROM 고객 c 
	,(SELECT 고객번호, max(변경일시) 최종변경일시 
	  FROM 고객변경이력 
	  WHERE 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
	  AND 변경일시 < trunc(sysdate, 'mm') 
	  GROUP BY 고객버호) m 
	, 고객변경이력 h 
WHERE c.고객구분코드 = 'A001'
AND m.고객번호 = c.고객번호 
AND h.고객번호 = m.고객번호 
AND h.변경일시 = m.최종변경일시; 

-- 고객 테이블 한 번만 읽고 싶을땐 아래 처럼
INSERT INTO 고객_임시
SELECT 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시 
FROM (SELECT /*+ full(c) full(h) leading(c) use_hash(h) */
			 c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
			 , rank() OVER(PARTITION BY h.고객번호 ORDER BY h.변경일시 desc) NO 
	  FROM 고객 c, 고객변경이력 h 
	  WHERE c.고객구분코드 = 'A001'
	  AND h.변경일시 >= trunc(add_months(sysdate, -12), 'mm')
	  AND h.변경일시 < trunc(sysdate, 'mm')
	  AND h.고객번호 = c.고객번호)
WHERE NO = 1 