-- Hint 
-- 1. ordered : FROM에 기술한 순서대로 조인 
-- 2. leading() :  
-- 3. use_nl() : NL방식으로 조인하라고 지시할 때 사용. 
-- 4. index() 
-- 5. nlj_batching 
-- 6. no_nlj_batching  
-- 7. use_merge() : 소트 머지 조인 유도 
-- 8. use_hash() : 해시 조인 유도 
-- 9. swap_join_inputs()
-- 10. no_swap_join_inputs()

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

/*+ leading(T1, T2, T3) swap_join_inputs(T2) */ 
/*+ leading(T1, T2, T3) swap_join_inputs(T3) */ 
/*+ leading(T1, T2, T3) swap_join_inputs(T2) swap_join_inputs(T3) */
/*+ leading(T1, T2, T3) no_swap_join_inputs(T3) */ 
SELECT /*+ leading(T1, T2, T3) use_hash(T2) use_hash(T3) */ *
FROM T1, T2, T3 
WHERE T1.KEY = T2.KEY 
AND T2.KEY = T3.KEY; 
