#!/bin/bash
username=root
pass=taosdata

function one {
clear
echo -e "\t\t\t\033[32;1mCPU Memory info\033[0m"
echo ""
top -bc  -n 1|grep '/usr/bin/taosadapter\|/usr/bin/taosd\|/usr/bin/taosx\|/usr/bin/taos-explorer\|/usr/bin/taoskeeper' |grep -v grep
echo ""
free -g

echo ""
echo -e "\t\t\t\033[32;1mCorefile info\033[0m"
echo ""
 a=$(grep core_pattern /etc/sysctl.conf|awk -F"=" '{print $2}')
 ls -lhtr ${a%/*}|tail -2
echo ""

echo -e "\t\t\t\033[33;1mDnode offline\033[0m"
taos -u$username -p$pass -s "select dnode_ep from (select last_row(status) as s,dnode_ep from log.d_info group by dnode_ep)where s!='ready'\G"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query
echo ""
echo -e "\t\t\t\033[33;1mMnode offline\033[0m"
taos -u$username -p$pass -s "select mnode_ep from (select last_row(role) as s,mnode_ep from log.m_info group by mnode_ep)where s='offline'\G;" |grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query
echo ""

echo -e "\t\t\t\033[32;1mLeader vnodes info\033[0m"
echo ""
taos -u$username -p$pass -s "select v1_dnode dnodeid,sum(sum) leader_nums from(   select v1_dnode,count(*) sum from information_schema.ins_vgroups where  v1_status='leader' and db_name !='log' and db_name != 'audit'  group by v1_dnode union all select v2_dnode,count(*) from information_schema.ins_vgroups where  v2_status ='leader' and db_name !='log' and db_name != 'audit' group by v2_dnode union all select v3_dnode,count(*) from information_schema.ins_vgroups where  v3_status='leader' and db_name !='log' and db_name != 'audit' group by v3_dnode order by v1_dnode) group by v1_dnode order by v1_dnode;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query
echo ""

echo -e "\t\t\t\033[32;1mSlow SQL info\033[0m"
echo ""
taos -u$username -p$pass -s "select  sql,app,\`user\`,end_point,create_time,exec_usec from performance_schema.perf_queries where exec_usec>5000000 order by exec_usec desc;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query
taos -u$username -p$pass -s "select  sql,app,\`user\`,end_point,create_time,exec_usec from performance_schema.perf_queries where exec_usec>5000000\G;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query >>slowsql.log
date >>slowsql.log
echo ""

echo -e "\t\t\t\033[32;1mOther info\033[0m"
echo ""
taos -u$username -p$pass -s "select count(*) as total_dnodes from information_schema.ins_dnodes\G;select count(*) as total_mnodes from information_schema.ins_mnodes\G;select count(*) as connections_num from performance_schema.perf_connections\G;select count(*) as queries_num from performance_schema.perf_queries\G;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v '\*'|grep -v 'Query'
taos -u$username -p$pass -s "select \`app\`,\`user\`,\`sql\`,count(*) as queries_num from performance_schema.perf_queries group by \`app\`,\`user\`,\`sql\`;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v 'Query'
echo ""

sleep 3
clear
}

function other {
clear
echo -e "\t\t\t\033[32;1mCPU Memory info\033[0m"
echo ""
top -bc  -n 1|grep '/usr/bin/taosadapter\|/usr/bin/taosd\|/usr/bin/taosx\|/usr/bin/taos-explorer\|/usr/bin/taoskeeper' |grep -v grep
echo ""
free -g

echo ""
echo -e "\t\t\t\033[32;1mCorefile info\033[0m"
echo ""
 a=$(grep core_pattern /etc/sysctl.conf|awk -F"=" '{print $2}')
 ls -lhtr ${a%/*}|tail -2
echo ""
echo -e "\t\t\t\033[33;1mDnode offline\033[0m"
taos -u$username -p$pass -s "select dnode_ep from (select last_row(dnode_ep) dnode_ep,last_row(status) s from log.taosd_dnodes_status group by dnode_ep)where s=0\G;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query
echo ""
echo -e "\t\t\t\033[33;1mMnode offline\033[0m"
taos -u$username -p$pass -s "select mnode_ep from (select last_row(mnode_ep) mnode_ep,last_row(role) s from log.taosd_mnodes_info group by mnode_ep)where s=0\G;" |grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query
echo ""

echo -e "\t\t\t\033[32;1mLeader vnodes info\033[0m"
echo ""
taos -u$username -p$pass -s "select dnode_id,dnode_ep,cast(last(masters) as int) as leaders_num from log.taosd_dnodes_info group by dnode_ep  order by dnode_id ;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query 
echo ""

echo -e "\t\t\t\033[32;1mSlow SQL info\033[0m"
echo ""
taos -u$username -p$pass -s "select  sql,app,\`user\`,end_point,create_time,exec_usec from performance_schema.perf_queries where exec_usec>5000000\G;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query 
taos -u$username -p$pass -s "select  sql,app,\`user\`,end_point,create_time,exec_usec from performance_schema.perf_queries where exec_usec>5000000\G;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query >>slowsql.log
date >>slowsql.log
echo ""

echo -e "\t\t\t\033[32;1mOther info\033[0m"
echo ""
taos -u$username -p$pass -s "select count(*) as total_dnodes from (select distinct dnode_ep from log.taosd_dnodes_status group by dnode_ep)\G;select count(*) as total_mnodes from(select distinct mnode_ep from log.taosd_mnodes_info group by mnode_ep)\G;select count(*) as connections_num from performance_schema.perf_connections\G;select count(*) as queries_num from performance_schema.perf_queries\G;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v '\*'|grep -v 'Query'
taos -u$username -p$pass -s "select \`app\`,\`user\`,\`sql\`,count(*) as queries_num from performance_schema.perf_queries group by \`app\`,\`user\`,\`sql\`;"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v 'Query'
echo ""

sleep 3
clear
}

while :;do
[[  $(taos -u$username -p$pass -s  "select server_version()"|grep -v Welcome|grep -v Copyright|grep -v 'taos>'|grep -v Query|grep -v 'server'|grep -v ==|awk -F "|" '{print $1}') =~ [0-9]\.[1].[0-9] ]]
if [ $? == 0 ];then
one
else
other
fi
done

