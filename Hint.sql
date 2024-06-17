-- Hint 
-- 1. ordered : FROM에 기술한 순서대로 조인 
-- 2. leading() :  
-- 3. use_nl() : NL방식으로 조인하라고 지시할 때 사용. 
-- 4. index() 
-- 5. nlj_batching 
-- 6. no_nlj_batching  


-- ex) A -> B -> C -> D순으로 조인하되, B와 조인할 때 그리고 이어서 C와 조인할 때는 NL 방식으로 조인하고, 
--     D와 조인할 때는 해시 방식으로 조인하라는 뜻.  
SELECT /*+ ordered use_nl(B) use_nl(C) use_hash(D) */ *
FROM A, B, C, D
WHERE .... 

-- ex) ordered 대신 leading 사용. leading 을 사용하면 FROM절을 바꾸지 않고도 마음껏 순서를 제어. 
SELECT /*+ leading(C, A, D, B) use_nl(A) use_nl(D) use_hash(B) */ *
FROM A, B, C, D
WHERE .... 

-- ex) ordered 나 leading 힌트를 기술하지 않고 네 개 테이블을 NL 방식으로조인하되 순서는 옵티마이저 스스로가 정하도록 맡긴 것 
SELECT /*+ use_nl (A, B, C, D) */ *
FROM A, B, C, D
WHERE .... 

