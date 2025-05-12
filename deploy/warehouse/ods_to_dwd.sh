#!/bin/bash

APP=gmall
# 如果是输入的日期按照取输入日期；如果没输入日期取当前时间的前一天
if [ -n "$2" ] ;then
    do_date=$2
else 
    do_date=`date -d "-1 day" +%F`
fi

dwd_interaction_favor_add_inc="
insert overwrite table ${APP}.dwd_interaction_favor_add_inc partition(dt='$do_date')
select
    data.id,
    data.user_id,
    data.sku_id,
    date_format(data.create_time,'yyyy-MM-dd') date_id,
    data.create_time
from ${APP}.ods_favor_info_inc
where dt='$do_date'
and type = 'insert';
"

dwd_tool_coupon_used_inc="
insert overwrite table ${APP}.dwd_tool_coupon_used_inc partition(dt='$do_date')
select
    data.id,
    data.coupon_id,
    data.user_id,
    data.order_id,
    date_format(data.used_time,'yyyy-MM-dd') date_id,
    data.used_time
from ${APP}.ods_coupon_use_inc
where dt='$do_date'
and type='update'
and array_contains(map_keys(old),'used_time');
"

dwd_trade_cart_add_inc="
insert overwrite table ${APP}.dwd_trade_cart_add_inc partition (dt = '$do_date')
select data.id,
       data.user_id,
       data.sku_id,
       date_format(from_utc_timestamp(ts * 1000, 'GMT+8'), 'yyyy-MM-dd')                          date_id,
       date_format(from_utc_timestamp(ts * 1000, 'GMT+8'), 'yyyy-MM-dd HH:mm:ss')                 create_time,
       if(type = 'insert', data.sku_num, cast(data.sku_num as int) - cast(old['sku_num'] as int)) sku_num
from ${APP}.ods_cart_info_inc
where dt = '$do_date'
  and (type = 'insert'
    or (type = 'update' and old['sku_num'] is not null and cast(data.sku_num as int) > cast(old['sku_num'] as int)));
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
    oi.order_id,
    user_id,
    province_id,
    order_date_id,
    order_time,
    nvl(oi.payment_date_id,pi.payment_date_id),
    nvl(oi.payment_time,pi.payment_time),
    nvl(oi.finish_date_id,log.finish_date_id),
    nvl(oi.finish_time,log.finish_time),
    order_original_amount,
    order_activity_amount,
    order_coupon_amount,
    order_total_amount,
    nvl(oi.payment_amount,pi.payment_amount),
    nvl(nvl(oi.finish_time,log.finish_time),'9999-12-31')
from
(
    select
        order_id,
        user_id,
        province_id,
        order_date_id,
        order_time,
        payment_date_id,
        payment_time,
        finish_date_id,
        finish_time,
        order_original_amount,
        order_activity_amount,
        order_coupon_amount,
        order_total_amount,
        payment_amount
    from ${APP}.dwd_trade_trade_flow_acc
    where dt='9999-12-31'
    union all
    select
        data.id,
        data.user_id,
        data.province_id,
        date_format(data.create_time,'yyyy-MM-dd') order_date_id,
        data.create_time,
        null payment_date_id,
        null payment_time,
        null finish_date_id,
        null finish_time,
        data.original_total_amount,
        data.activity_reduce_amount,
        data.coupon_reduce_amount,
        data.total_amount,
        null payment_amount
    from ${APP}.ods_order_info_inc
    where dt='$do_date'
    and type='insert'
)oi
left join
(
    select
        data.order_id,
        date_format(data.callback_time,'yyyy-MM-dd') payment_date_id,
        data.callback_time payment_time,
        data.total_amount payment_amount
    from ${APP}.ods_payment_info_inc
    where dt='$do_date'
    and type='update'
    and array_contains(map_keys(old),'payment_status')
    and data.payment_status='1602'
)pi
on oi.order_id=pi.order_id
left join
(
    select
        data.order_id,
        date_format(data.create_time,'yyyy-MM-dd') finish_date_id,
        data.create_time finish_time
    from ${APP}.ods_order_status_log_inc
    where dt='$do_date'
    and type='insert'
    and data.order_status='1004'
)log
on oi.order_id=log.order_id;
"

dwd_trade_order_detail_inc="
insert overwrite table ${APP}.dwd_trade_order_detail_inc partition (dt='2022-06-09')
select
    od.id,
    order_id,
    user_id,
    sku_id,
    province_id,
    activity_id,
    activity_rule_id,
    coupon_id,
    date_id,
    create_time,
    sku_num,
    split_original_amount,
    nvl(split_activity_amount,0.0),
    nvl(split_coupon_amount,0.0),
    split_total_amount
from
(
    select
        data.id,
        data.order_id,
        data.sku_id,
        date_format(data.create_time, 'yyyy-MM-dd') date_id,
        data.create_time,
        data.sku_num,
        data.sku_num * data.order_price split_original_amount,
        data.split_total_amount,
        data.split_activity_amount,
        data.split_coupon_amount
    from ${APP}.ods_order_detail_inc
    where dt = '$do_date'
    and type = 'insert'
) od
left join
(
    select
        data.id,
        data.user_id,
        data.province_id
    from ${APP}.ods_order_info_inc
    where dt = '$do_date'
    and type = 'insert'
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
    and type = 'insert'
) act
on od.id = act.order_detail_id
left join
(
    select
        data.order_detail_id,
        data.coupon_id
    from ${APP}.ods_order_detail_coupon_inc
    where dt = '$do_date'
    and type = 'insert'
) cou
on od.id = cou.order_detail_id;
"

dwd_trade_pay_detail_suc_inc="
insert overwrite table ${APP}.dwd_trade_pay_detail_suc_inc partition (dt='$do_date')
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
    split_total_amount
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
    where (dt = '$do_date' or dt = date_add('$do_date',-1))
    and (type = 'insert' or type = 'bootstrap-insert')
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
    and type='update'
    and array_contains(map_keys(old),'payment_status')
    and data.payment_status='1602'
) pi
on od.order_id=pi.order_id
left join
(
    select
        data.id,
        data.province_id
    from ${APP}.ods_order_info_inc
    where (dt = '$do_date' or dt = date_add('$do_date',-1))
    and (type = 'insert' or type = 'bootstrap-insert')
) oi
on od.order_id = oi.id
left join
(
    select
        data.order_detail_id,
        data.activity_id,
        data.activity_rule_id
    from ${APP}.ods_order_detail_activity_inc
    where (dt = '$do_date' or dt = date_add('$do_date',-1))
    and (type = 'insert' or type = 'bootstrap-insert')
) act
on od.id = act.order_detail_id
left join
(
    select
        data.order_detail_id,
        data.coupon_id
    from ${APP}.ods_order_detail_coupon_inc
    where (dt = '$do_date' or dt = date_add('$do_date',-1))
    and (type = 'insert' or type = 'bootstrap-insert')
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
dwd_user_register_inc="
insert overwrite table ${APP}.dwd_user_register_inc partition(dt='$do_date')
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
    operate_system
from
(
    select
        data.id user_id,
        data.create_time
    from ${APP}.ods_user_info_inc
    where dt='$do_date'
    and type='insert'
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

