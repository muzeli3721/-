#!/bin/bash
APP=gmall

# 如果是输入的日期按照取输入日期；如果没输入日期取当前时间的前一天
if [ -n "$2" ] ;then
    do_date=$2
else 
    do_date=`date -d "-1 day" +%F`
fi

dws_trade_province_order_nd="
insert overwrite table ${APP}.dws_trade_province_order_nd partition(dt='$do_date')
select
    province_id,
    province_name,
    area_code,
    iso_code,
    iso_3166_2,
    sum(if(dt>=date_add('$do_date',-6),order_count_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_original_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),activity_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),coupon_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_total_amount_1d,0)),
    sum(order_count_1d),
    sum(order_original_amount_1d),
    sum(activity_reduce_amount_1d),
    sum(coupon_reduce_amount_1d),
    sum(order_total_amount_1d)
from ${APP}.dws_trade_province_order_1d
where dt>=date_add('$do_date',-29)
and dt<='$do_date'
group by province_id,province_name,area_code,iso_code,iso_3166_2;
"

dws_trade_user_sku_order_nd="
insert overwrite table ${APP}.dws_trade_user_sku_order_nd partition(dt='$do_date')
select
    user_id,
    sku_id,
    sku_name,
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    category3_id,
    category3_name,
    tm_id,
    tm_name,
    sum(if(dt>=date_add('$do_date',-6),order_count_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_num_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_original_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),activity_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),coupon_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_total_amount_1d,0)),
    sum(order_count_1d),
    sum(order_num_1d),
    sum(order_original_amount_1d),
    sum(activity_reduce_amount_1d),
    sum(coupon_reduce_amount_1d),
    sum(order_total_amount_1d)
from ${APP}.dws_trade_user_sku_order_1d
where dt>=date_add('$do_date',-30)
group by  user_id,sku_id,sku_name,category1_id,category1_name,category2_id,category2_name,category3_id,category3_name,tm_id,tm_name;
"

case $1 in
    "dws_trade_province_order_nd" )
        hive -e "$dws_trade_province_order_nd"
    ;;
    "dws_trade_user_sku_order_nd" )
        hive -e "$dws_trade_user_sku_order_nd"
    ;;
    "all" )
        hive -e "$dws_trade_province_order_nd$dws_trade_user_sku_order_nd"
    ;;
esac

