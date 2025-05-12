#!/bin/bash
APP=gmall

# 如果输入的日期按照取输入日期；如果没输入日期取当前时间的前一天
if [ -n "$2" ] ;then
    do_date=$2
else 
    do_date=`date -d "-1 day" +%F`
fi

dws_trade_user_order_td="
insert overwrite table ${APP}.dws_trade_user_order_td partition (dt = '$do_date')
select nvl(old.user_id, new.user_id),
       if(old.user_id is not null, old.order_date_first, '$do_date'),
       if(new.user_id is not null, '$do_date', old.order_date_last),
       nvl(old.order_count_td, 0) + nvl(new.order_count_1d, 0),
       nvl(old.order_num_td, 0) + nvl(new.order_num_1d, 0),
       nvl(old.original_amount_td, 0) + nvl(new.order_original_amount_1d, 0),
       nvl(old.activity_reduce_amount_td, 0) + nvl(new.activity_reduce_amount_1d, 0),
       nvl(old.coupon_reduce_amount_td, 0) + nvl(new.coupon_reduce_amount_1d, 0),
       nvl(old.total_amount_td, 0) + nvl(new.order_total_amount_1d, 0)
from (
         select user_id,
                order_date_first,
                order_date_last,
                order_count_td,
                order_num_td,
                original_amount_td,
                activity_reduce_amount_td,
                coupon_reduce_amount_td,
                total_amount_td
         from ${APP}.dws_trade_user_order_td
         where dt = date_add('$do_date', -1)
     ) old
         full outer join
     (
         select user_id,
                order_count_1d,
                order_num_1d,
                order_original_amount_1d,
                activity_reduce_amount_1d,
                coupon_reduce_amount_1d,
                order_total_amount_1d
         from ${APP}.dws_trade_user_order_1d
         where dt = '$do_date'
     ) new
     on old.user_id = new.user_id;
"

dws_user_user_login_td="
insert overwrite table ${APP}.dws_user_user_login_td partition (dt = '$do_date')
select nvl(old.user_id, new.user_id)                                        user_id,
       if(new.user_id is null, old.login_date_last, '$do_date')           login_date_last,
       if(old.login_date_first is null, '$do_date', old.login_date_first) login_date_first,
       nvl(old.login_count_td, 0) + nvl(new.login_count_1d, 0)              login_count_td
from (
         select user_id,
                login_date_last,
                login_date_first,
                login_count_td
         from ${APP}.dws_user_user_login_td
         where dt = date_add('$do_date', -1)
     ) old
         full outer join
     (
         select user_id,
                count(*) login_count_1d
         from ${APP}.dwd_user_login_inc
         where dt = '$do_date'
         group by user_id
     ) new
     on old.user_id = new.user_id;
"

case $1 in
    "dws_trade_user_order_td" )
        hive -e "$dws_trade_user_order_td"
    ;;
    "dws_user_user_login_td" )
        hive -e "$dws_user_user_login_td"
    ;;
    "all" )
        hive -e "$dws_trade_user_order_td$dws_user_user_login_td"
    ;;
esac

