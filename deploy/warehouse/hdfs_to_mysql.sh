#! /bin/bash

DATAX_HOME=/opt/module/datax

#DataX导出路径不允许存在空文件，该函数作用为清理空文件
handle_export_path(){
  for i in `hadoop fs -ls -R $1 | awk '{print $8}'`; do
    hadoop fs -test -z $i
    if [[ $? -eq 0 ]]; then
      echo "$i文件大小为0，正在删除"
      hadoop fs -rm -r -f $i
    fi
  done
}

#数据导出
export_data() {
  datax_config=$1
  export_dir=$2
  handle_export_path $export_dir
  $DATAX_HOME/bin/datax.py -p"-Dexportdir=$export_dir" $datax_config
}

case $1 in
  "ads_coupon_stats")
    export_data /opt/module/datax/job/export/gmall_report.ads_coupon_stats.json /warehouse/gmall/ads/ads_coupon_stats
  ;;
  "ads_new_order_user_stats")
    export_data /opt/module/datax/job/export/gmall_report.ads_new_order_user_stats.json /warehouse/gmall/ads/ads_new_order_user_stats
  ;;  
  "ads_order_by_province")
    export_data /opt/module/datax/job/export/gmall_report.ads_order_by_province.json /warehouse/gmall/ads/ads_order_by_province
  ;;
  "ads_order_continuously_user_count")
    export_data /opt/module/datax/job/export/gmall_report.ads_order_continuously_user_count.json /warehouse/gmall/ads/ads_order_continuously_user_count
  ;;
  "ads_order_stats_by_cate")
    export_data /opt/module/datax/job/export/gmall_report.ads_order_stats_by_cate.json /warehouse/gmall/ads/ads_order_stats_by_cate
  ;;
  "ads_order_stats_by_tm")
    export_data /opt/module/datax/job/export/gmall_report.ads_order_stats_by_tm.json /warehouse/gmall/ads/ads_order_stats_by_tm
  ;;  
  "ads_order_to_pay_interval_avg")
    export_data /opt/module/datax/job/export/gmall_report.ads_order_to_pay_interval_avg.json /warehouse/gmall/ads/ads_order_to_pay_interval_avg
  ;;
  "ads_page_path")
    export_data /opt/module/datax/job/export/gmall_report.ads_page_path.json /warehouse/gmall/ads/ads_page_path
  ;;
  "ads_repeat_purchase_by_tm")
    export_data /opt/module/datax/job/export/gmall_report.ads_repeat_purchase_by_tm.json /warehouse/gmall/ads/ads_repeat_purchase_by_tm
  ;;
  "ads_sku_cart_num_top3_by_cate")
    export_data /opt/module/datax/job/export/gmall_report.ads_sku_cart_num_top3_by_cate.json /warehouse/gmall/ads/ads_sku_cart_num_top3_by_cate
  ;;  
  "ads_sku_favor_count_top3_by_tm")
    export_data /opt/module/datax/job/export/gmall_report.ads_sku_favor_count_top3_by_tm.json /warehouse/gmall/ads/ads_sku_favor_count_top3_by_tm
  ;;
  "ads_traffic_stats_by_channel")
    export_data /opt/module/datax/job/export/gmall_report.ads_traffic_stats_by_channel.json /warehouse/gmall/ads/ads_traffic_stats_by_channel
  ;;
  "ads_user_action")
    export_data /opt/module/datax/job/export/gmall_report.ads_user_action.json /warehouse/gmall/ads/ads_user_action
  ;;
  "ads_user_change")
    export_data /opt/module/datax/job/export/gmall_report.ads_user_change.json /warehouse/gmall/ads/ads_user_change
  ;;  
  "ads_user_retention")
    export_data /opt/module/datax/job/export/gmall_report.ads_user_retention.json /warehouse/gmall/ads/ads_user_retention
  ;;
  "ads_user_stats")
    export_data /opt/module/datax/job/export/gmall_report.ads_user_stats.json /warehouse/gmall/ads/ads_user_stats
  ;;
  "all")
    export_data /opt/module/datax/job/export/gmall_report.ads_coupon_stats.json /warehouse/gmall/ads/ads_coupon_stats
    export_data /opt/module/datax/job/export/gmall_report.ads_new_order_user_stats.json /warehouse/gmall/ads/ads_new_order_user_stats
    export_data /opt/module/datax/job/export/gmall_report.ads_order_by_province.json /warehouse/gmall/ads/ads_order_by_province
    export_data /opt/module/datax/job/export/gmall_report.ads_order_continuously_user_count.json /warehouse/gmall/ads/ads_order_continuously_user_count
    export_data /opt/module/datax/job/export/gmall_report.ads_order_stats_by_cate.json /warehouse/gmall/ads/ads_order_stats_by_cate
    export_data /opt/module/datax/job/export/gmall_report.ads_order_stats_by_tm.json /warehouse/gmall/ads/ads_order_stats_by_tm
    export_data /opt/module/datax/job/export/gmall_report.ads_order_to_pay_interval_avg.json /warehouse/gmall/ads/ads_order_to_pay_interval_avg
    export_data /opt/module/datax/job/export/gmall_report.ads_page_path.json /warehouse/gmall/ads/ads_page_path
    export_data /opt/module/datax/job/export/gmall_report.ads_repeat_purchase_by_tm.json /warehouse/gmall/ads/ads_repeat_purchase_by_tm
    export_data /opt/module/datax/job/export/gmall_report.ads_sku_cart_num_top3_by_cate.json /warehouse/gmall/ads/ads_sku_cart_num_top3_by_cate
    export_data /opt/module/datax/job/export/gmall_report.ads_sku_favor_count_top3_by_tm.json /warehouse/gmall/ads/ads_sku_favor_count_top3_by_tm
    export_data /opt/module/datax/job/export/gmall_report.ads_traffic_stats_by_channel.json /warehouse/gmall/ads/ads_traffic_stats_by_channel
    export_data /opt/module/datax/job/export/gmall_report.ads_user_action.json /warehouse/gmall/ads/ads_user_action
    export_data /opt/module/datax/job/export/gmall_report.ads_user_change.json /warehouse/gmall/ads/ads_user_change
    export_data /opt/module/datax/job/export/gmall_report.ads_user_retention.json /warehouse/gmall/ads/ads_user_retention
    export_data /opt/module/datax/job/export/gmall_report.ads_user_stats.json /warehouse/gmall/ads/ads_user_stats
  ;;
esac

