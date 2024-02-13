-- Lock 
-- [MsSQL]
-- 공유 Lock
-- begin tran
-- select 적립포인트, 방문횟수, 최근방문일시, 구매실적
-- from 고객 with (holdlock)
-- where 고객번호 = :cust_num

-- 새로운 적립포인트 계산
-- update 고객 set 적립포인트 = :적립포인트 where 고객번호 = :cust_num

-- commit 

-- 갱신 lock 
-- begin tran
-- select 적립포인트, 방문횟수, 최근방문일시, 구매실적
-- from 고객 with (updlock)
-- where 고객번호 = :cust_num

-- 새로운 적립포인트 계산
-- update 고객 set 적립포인트 = :적립포인트 where 고객번호 = :cust_num
