-- 3장.테이블 엑세스 최소화
INSERT INTO 고객_임시 
SELECT /*+ full(c) full(h) index_ffs(m.고객변경이력) 
		   ordered no_merge(m) use_hash(m) use_hash(h) */
		c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
FROM 고객 c 
	,(SELECT 고객번호, max(변경일시) 최종변경일시 
	  FROM 고객변경이력 
	  WHERE 변경일시 >= trunc(add_months(sysdate, -12), 'mm') 
	  AND 변경일시 < trunc(sysdate, 'mm')
	  GROUP BY 고객번호) m
	, 고객변경이력 h 
WHERE c.고구분코드 = 'A001'
AND m.고객번호 = c.고객번호 
AND h.고객번호 = m.고객번호 
AND h.변경일시 = m.최종변경일시; 


INSERT INTO 고객_임시 
SELECT 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시 
FROM (
		SELECT /*+ full(c) full(h) leading(c) use_hash(h) */
				c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시 
				, rank() OVER (PARTITION BY h.고객번호 ORDER BY h.변경일시 desc) NO 
		FROM 고객 c, 고객변경이력 h 
		WHERE c.고구분코드 = 'A001'
		AND h.변경일시 >= trunc(add_months(sysdate, -12), 'mm') 
		AND h.변경일시 < trunc(sysdate, 'mm')
		AND h.고객번호 = c.고객번호 
)
WHERE NO = 1; 



