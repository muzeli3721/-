#!/bin/bash
APP=gmall

if [ -n "$2" ] ;then
   do_date=$2
else 
   echo "请传入日期参数"
   exit
fi

dwd_trade_cart_add_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_trade_cart_add_inc partition (dt)
select data.id,
       data.user_id,
       data.sku_id,
       date_format(data.create_time, 'yyyy-MM-dd') date_id,
       data.create_time,
       data.sku_num,
       date_format(data.create_time, 'yyyy-MM-dd')
from ${APP}.ods_cart_info_inc
where dt = '$do_date'
  and type = 'bootstrap-insert';
"
dwd_trade_order_detail_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_trade_order_detail_inc partition (dt)
select
    od.id,
    order_id,
    user_id,
    sku_id,
    province_id,
    activity_id,
    activity_rule_id,
    coupon_id,
    date_format(create_time, 'yyyy-MM-dd') date_id,
    create_time,
    sku_num,
    split_original_amount,
    nvl(split_activity_amount,0.0),
    nvl(split_coupon_amount,0.0),
    split_total_amount,
    date_format(create_time,'yyyy-MM-dd')
from
(
    select
        data.id,
        data.order_id,
        data.sku_id,
        data.create_time,
        data.sku_num,
        data.sku_num * data.order_price split_original_amount,
        data.split_total_amount,
        data.split_activity_amount,
        data.split_coupon_amount
    from ${APP}.ods_order_detail_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) od
left join
(
    select
        data.id,
        data.user_id,
        data.province_id
    from ${APP}.ods_order_info_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) oi
on od.order_id = oi.id
left join
(
    select
        data.order_detail_id,
        data.activity_id,
        data.activity_rule_id
    from ${APP}.ods_order_detail_activity_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) act
on od.id = act.order_detail_id
left join
(
    select
        data.order_detail_id,
        data.coupon_id
    from ${APP}.ods_order_detail_coupon_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) cou
on od.id = cou.order_detail_id;
"
dwd_trade_pay_detail_suc_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_trade_pay_detail_suc_inc partition (dt)
select
    od.id,
    od.order_id,
    user_id,
    sku_id,
    province_id,
    activity_id,
    activity_rule_id,
    coupon_id,
    payment_type,
    pay_dic.dic_name,
    date_format(callback_time,'yyyy-MM-dd') date_id,
    callback_time,
    sku_num,
    split_original_amount,
    nvl(split_activity_amount,0.0),
    nvl(split_coupon_amount,0.0),
    split_total_amount,
    date_format(callback_time,'yyyy-MM-dd')
from
(
    select
        data.id,
        data.order_id,
        data.sku_id,
        data.sku_num,
        data.sku_num * data.order_price split_original_amount,
        data.split_total_amount,
        data.split_activity_amount,
        data.split_coupon_amount
    from ${APP}.ods_order_detail_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) od
join
(
    select
        data.user_id,
        data.order_id,
        data.payment_type,
        data.callback_time
    from ${APP}.ods_payment_info_inc
    where dt='$do_date'
    and type='bootstrap-insert'
    and data.payment_status='1602'
) pi
on od.order_id=pi.order_id
left join
(
    select
        data.id,
        data.province_id
    from ${APP}.ods_order_info_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) oi
on od.order_id = oi.id
left join
(
    select
        data.order_detail_id,
        data.activity_id,
        data.activity_rule_id
    from ${APP}.ods_order_detail_activity_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) act
on od.id = act.order_detail_id
left join
(
    select
        data.order_detail_id,
        data.coupon_id
    from ${APP}.ods_order_detail_coupon_inc
    where dt = '$do_date'
    and type = 'bootstrap-insert'
) cou
on od.id = cou.order_detail_id
left join
(
    select
        dic_code,
        dic_name
    from ${APP}.ods_base_dic_full
    where dt='$do_date'
    and parent_code='11'
) pay_dic
on pi.payment_type=pay_dic.dic_code;
"
dwd_trade_cart_full="
insert overwrite table ${APP}.dwd_trade_cart_full partition(dt='$do_date')
select
    id,
    user_id,
    sku_id,
    sku_name,
    sku_num
from ${APP}.ods_cart_info_full
where dt='$do_date'
and is_ordered='0';
"
dwd_trade_trade_flow_acc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_trade_trade_flow_acc partition(dt)
select
    oi.id,
    user_id,
    province_id,
    date_format(create_time,'yyyy-MM-dd'),
    create_time,
    date_format(callback_time,'yyyy-MM-dd'),
    callback_time,
    date_format(finish_time,'yyyy-MM-dd'),
    finish_time,
    original_total_amount,
    activity_reduce_amount,
    coupon_reduce_amount,
    total_amount,
    nvl(payment_amount,0.0),
    nvl(date_format(finish_time,'yyyy-MM-dd'),'9999-12-31')
from
(
    select
        data.id,
        data.user_id,
        data.province_id,
        data.create_time,
        data.original_total_amount,
        data.activity_reduce_amount,
        data.coupon_reduce_amount,
        data.total_amount
    from ${APP}.ods_order_info_inc
    where dt='$do_date'
    and type='bootstrap-insert'
)oi
left join
(
    select
        data.order_id,
        data.callback_time,
        data.total_amount payment_amount
    from ${APP}.ods_payment_info_inc
    where dt='$do_date'
    and type='bootstrap-insert'
    and data.payment_status='1602'
)pi
on oi.id=pi.order_id
left join
(
    select
        data.order_id,
        data.create_time finish_time
    from ${APP}.ods_order_status_log_inc
    where dt='$do_date'
    and type='bootstrap-insert'
    and data.order_status='1004'
)log
on oi.id=log.order_id;
"
dwd_tool_coupon_used_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_tool_coupon_used_inc partition(dt)
select
    data.id,
    data.coupon_id,
    data.user_id,
    data.order_id,
    date_format(data.used_time,'yyyy-MM-dd') date_id,
    data.used_time,
    date_format(data.used_time,'yyyy-MM-dd')
from ${APP}.ods_coupon_use_inc
where dt='$do_date'
and type='bootstrap-insert'
and data.used_time is not null;
"
dwd_interaction_favor_add_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_interaction_favor_add_inc partition(dt)
select
    data.id,
    data.user_id,
    data.sku_id,
    date_format(data.create_time,'yyyy-MM-dd') date_id,
    data.create_time,
    date_format(data.create_time,'yyyy-MM-dd')
from ${APP}.ods_favor_info_inc
where dt='$do_date'
and type = 'bootstrap-insert';
"
dwd_traffic_page_view_inc="
set hive.cbo.enable=false;
insert overwrite table ${APP}.dwd_traffic_page_view_inc partition (dt='$do_date')
select
    common.ar province_id,
    common.ba brand,
    common.ch channel,
    common.is_new is_new,
    common.md model,
    common.mid mid_id,
    common.os operate_system,
    common.uid user_id,
    common.vc version_code,
    page.item page_item,
    page.item_type page_item_type,
    page.last_page_id,
    page.page_id,
    page.from_pos_id,
    page.from_pos_seq,
    page.refer_id,
    date_format(from_utc_timestamp(ts,'GMT+8'),'yyyy-MM-dd') date_id,
    date_format(from_utc_timestamp(ts,'GMT+8'),'yyyy-MM-dd HH:mm:ss') view_time,
    common.sid session_id,
    page.during_time
from ${APP}.ods_log_inc
where dt='$do_date'
and page is not null;
set hive.cbo.enable=true;
"

dwd_user_register_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${APP}.dwd_user_register_inc partition(dt)
select
    ui.user_id,
    date_format(create_time,'yyyy-MM-dd') date_id,
    create_time,
    channel,
    province_id,
    version_code,
    mid_id,
    brand,
    model,
    operate_system,
    date_format(create_time,'yyyy-MM-dd')
from
(
    select
        data.id user_id,
        data.create_time
    from ${APP}.ods_user_info_inc
    where dt='$do_date'
    and type='bootstrap-insert'
)ui
left join
(
    select
        common.ar province_id,
        common.ba brand,
        common.ch channel,
        common.md model,
        common.mid mid_id,
        common.os operate_system,
        common.uid user_id,
        common.vc version_code
    from ${APP}.ods_log_inc
    where dt='$do_date'
    and page.page_id='register'
    and common.uid is not null
)log
on ui.user_id=log.user_id;
"

dwd_user_login_inc="
insert overwrite table ${APP}.dwd_user_login_inc partition (dt = '$do_date')
select user_id,
       date_format(from_utc_timestamp(ts, 'GMT+8'), 'yyyy-MM-dd')          date_id,
       date_format(from_utc_timestamp(ts, 'GMT+8'), 'yyyy-MM-dd HH:mm:ss') login_time,
       channel,
       province_id,
       version_code,
       mid_id,
       brand,
       model,
       operate_system
from (
         select user_id,
                channel,
                province_id,
                version_code,
                mid_id,
                brand,
                model,
                operate_system,
                ts
         from (select common.uid user_id,
                      common.ch  channel,
                      common.ar  province_id,
                      common.vc  version_code,
                      common.mid mid_id,
                      common.ba  brand,
                      common.md  model,
                      common.os  operate_system,
                      ts,
                      row_number() over (partition by common.sid order by ts) rn
               from ${APP}.ods_log_inc
               where dt = '$do_date'
                 and page is not null
                 and common.uid is not null) t1
         where rn = 1
     ) t2;
"

case $1 in
    "dwd_trade_cart_add_inc" )
        hive -e "$dwd_trade_cart_add_inc"
    ;;
    "dwd_trade_order_detail_inc" )
        hive -e "$dwd_trade_order_detail_inc"
    ;;
    "dwd_trade_pay_detail_suc_inc" )
        hive -e "$dwd_trade_pay_detail_suc_inc"
    ;;
    "dwd_trade_cart_full" )
        hive -e "$dwd_trade_cart_full"
    ;;   
    "dwd_trade_trade_flow_acc" )
        hive -e "$dwd_trade_trade_flow_acc"
    ;;  
    "dwd_tool_coupon_used_inc" )
        hive -e "$dwd_tool_coupon_used_inc"
    ;;
    "dwd_interaction_favor_add_inc" )
        hive -e "$dwd_interaction_favor_add_inc"
    ;;
    "dwd_traffic_page_view_inc" )
        hive -e "$dwd_traffic_page_view_inc"
    ;;
    "dwd_user_register_inc" )
        hive -e "$dwd_user_register_inc"
    ;;   
    "dwd_user_login_inc" )
        hive -e "$dwd_user_login_inc"
    ;; 
    "all" )
        hive -e "$dwd_trade_cart_add_inc$dwd_trade_order_detail_inc$dwd_trade_pay_detail_suc_inc$dwd_trade_cart_full$dwd_trade_trade_flow_acc$dwd_tool_coupon_used_inc$dwd_interaction_favor_add_inc$dwd_traffic_page_view_inc$dwd_user_register_inc$dwd_user_login_inc"
    ;;
esac

