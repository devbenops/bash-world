#!/bin/bash
#### This bash script will generate system/server health report based on mem/cpu/filesystem usage
set -e 

MOUNT=$(mount|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -u -t' ' -k1,2)
FS_USAGE=$(df -PTh|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -k6n|awk '!seen[$1]++')
IUSAGE=$(df -PThi|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -k6n|awk '!seen[$1]++')

#--------Checking the availability of sysstat package..........#
if [ ! -x /usr/bin/mpstat ]
then
    printf "\nError : Either \"mpstat\" command not available OR \"sysstat\" package is not properly installed. Please make sure this package is installed and working properly!, then run this script.\n\n"
    exit 1
fi

echo -e "\nOperating System Details" 
echo -e "$D"
printf "Hostname :" $(hostname -f > /dev/null 2>&1) && printf " $(hostname -f)" || printf " $(hostname -s)"

[ -x /usr/bin/lsb_release ] &&  echo -e "\nOperating System :" $(lsb_release -d|awk -F: '{print $2}'|sed -e 's/^[ \t]*//')  || echo -e "\nOperating System :" $(cat /etc/system-release)

#--------Print system uptime-------#
UPTIME=$(uptime)
echo $UPTIME|grep day 2>&1 > /dev/null
if [ $? != 0 ]
then
  echo $UPTIME|grep -w min 2>&1 > /dev/null && echo -e "System Uptime : "$(echo $UPTIME|awk '{print $2" by "$3}'|sed -e 's/,.*//g')" minutes"  || echo -e "System Uptime : "$(echo $UPTIME|awk '{print $2" by "$3" "$4}'|sed -e 's/,.*//g')" hours" 
else
  echo -e "System Uptime :" $(echo $UPTIME|awk '{print $2" by "$3" "$4" "$5" hours"}'|sed -e 's/,//g') 
fi
echo -e "Current System Date & Time : "$(date +%c)


#--------Checking disk usage on all mounted file systems--------#
echo -e "\n\nChecking For Disk Usage On Mounted File System[s]"
echo "========================================================"
echo -e "( 0-90% = OK/HEALTHY, 90-95% = WARNING, 95-100% = CRITICAL )"
echo -e "Mounted File System[s] Utilization (Percentage Used):\n" 

echo "$FS_USAGE"|awk '{print $1 " "$7}' > /tmp/s1.out
echo "$FS_USAGE"|awk '{print $6}'|sed -e 's/%//g' > /tmp/s2.out
> /tmp/s3.out

for i in $(cat /tmp/s2.out);
do
{
  if [ $i -ge 95 ];
   then
     echo -e $i"% ------------------Critical" >> /tmp/s3.out;
   elif [[ $i -ge 90 && $i -lt 95 ]];
   then
     echo -e $i"% ------------------Warning" >> /tmp/s3.out; 
   else
     echo -e $i"% ------------------Good/Healthy" >> /tmp/s3.out;
  fi
} 
done
paste -d"\t" /tmp/s1.out /tmp/s3.out|column -t

#--------Checking for RAM Utilization--------#
MEM_DETAILS=$(cat /proc/meminfo)
echo -e "\n\nChecking Memory Usage Details"

echo -e "Total RAM (/proc/meminfo) : "$(echo "$MEM_DETAILS"|grep MemTotal|awk '{print $2/1024}') "MB OR" $(echo "$MEM_DETAILS"|grep MemTotal|awk '{print $2/1024/1024}') "GB"
echo -e "Used RAM in MB : "$(free -m|grep -w Mem:|awk '{print $3}')", in GB : "$(free -m|grep -w Mem:|awk '{print $3/1024}')
echo -e "Free RAM in MB : "$(echo "$MEM_DETAILS"|grep -w MemFree|awk '{print $2/1024}')" , in GB : "$(echo "$MEM_DETAILS"|grep -w MemFree |awk '{print $2/1024/1024}')

#--------Check for load average (current data)--------#
echo -e "\n\nChecking For Load Average"
echo -e "$D"
echo -e "Current Load Average : $(uptime|grep -o "load average.*"|awk '{print $3" " $4" " $5}')"

#------Print most recent 3 reboot events if available----#
echo -e "\n\nMost Recent 3 Reboot Events"

last -x 2> /dev/null|grep reboot 1> /dev/null && /usr/bin/last -x 2> /dev/null|grep reboot|head -3 || echo -e "No reboot events are recorded."


#--------Print top 3 most memory consuming resources---------#
echo -e "\n\nTop 3 Memory Resource Hog Processes"

ps -eo pmem,pcpu,pid,ppid,user,stat,args | sort -k 1 -r | head -4|sed 's/$/\n/'

#--------Print top 3 most CPU consuming resources---------#
echo -e "\n\nTop 3 CPU Resource Hog Processes"

ps -eo pcpu,pmem,pid,ppid,user,stat,args | sort -k 1 -r | head -4|sed 's/$/\n/'

echo "System Health report has been generated successfully"
