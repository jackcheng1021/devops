#!/bin/bash

echo "setup devops-salt"

source devops-openrc.sh

echo "check network"
ping -c1 www.baidu.com &> /dev/null
if [ $? -ne 0 ]; then
  echo "Unable to access the Internet, please check"
  exit
fi

ping -c1 ${compute01_ip} &> /dev/null
if [ $? -ne 0 ]; then
  echo "Unable to access compute01, please check"
  exit
fi

ping -c1 ${compute02_ip} &> /dev/null
if [ $? -ne 0 ]; then
  echo "Unable to access compute02, please check"
  exit
fi

echo "prepare the environment for saltstack"
n=$(cat /etc/yum.repos.d/CentOS-Base.repo | grep -o "aliyun\.com" | wc -l)
if [ $n -le 15 ]; then
  curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null
fi
rpm --import https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub &> /dev/null
curl -fsSL https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | tee /etc/yum.repos.d/salt.repo &>/dev/null
yum clean expire-cache &> /dev/null

echo "install saltstack"
yum -y install salt-master &> /dev/null
if [ $? -ne 0 ]; then
  echo "controller: salt-master install failed"
  exit
fi
yum -y install salt-minion &> /dev/null
if [ $? -ne 0 ]; then
  echo "controller: salt-minion install failed"
  exit
fi
sed -i 's#\#master: .*#master: controller#g' /etc/salt/minion
rpm -q expect &> /dev/null
if [ $? -ne 0 ]; then
  yum -y install expect &> /dev/null
fi

/usr/bin/expect << FLAGEOF
set timeout 600
spawn ssh $compute01_user@$compute01_ip
expect {
        "(yes/no)" {send "yes\r"; exp_continue}
        "password:" {send "$compute01_user_pass\r"}
}
expect "${compute01_user}@*" {send "[ $(cat /etc/yum.repos.d/CentOS-Base.repo | grep -o "aliyun\.com" | wc -l) -lt 15 ] && curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null\r"}
expect "${compute01_user}@*" {send "yum makecache &> /dev/null\r"}
expect "${compute01_user}@*" {send "rpm --import https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub &> /dev/null\r"}
expect "${compute01_user}@*" {send "curl -fsSL https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | tee /etc/yum.repos.d/salt.repo &>/dev/null\r"}
expect "${compute01_user}@*" {send "yum clean expire-cache &> /dev/null\r"}
expect "${compute01_user}@*" {send "yum -y install salt-minion &> /dev/null\r"}
expect "${compute01_user}@*" {send "sed -i 's#\#master: .*#master: controller#g' /etc/salt/minion\r"}
expect "${compute01_user}@*" {send "exit\r"}
expect eof

/usr/bin/expect << FLAGEOF
set timeout 600
spawn ssh $compute02_user@$compute02_ip
expect {
        "(yes/no)" {send "yes\r"; exp_continue}
        "password:" {send "$compute02_user_pass\r"}
}
expect "${compute02_user}@*" {send "[ $(cat /etc/yum.repos.d/CentOS-Base.repo | grep -o "aliyun\.com" | wc -l) -lt 15 ] && curl -o /etc/y
um.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null\r"}
expect "${compute02_user}@*" {send "yum makecache &> /dev/null\r"}
expect "${compute02_user}@*" {send "rpm --import https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub &> /dev/nul
l\r"}
expect "${compute02_user}@*" {send "curl -fsSL https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | tee /etc/yum.repos.d/salt.re
po &>/dev/null\r"}
expect "${compute02_user}@*" {send "yum clean expire-cache &> /dev/null\r"}
expect "${compute02_user}@*" {send "yum -y install salt-minion &> /dev/null\r"}
expect "${compute02_user}@*" {send "sed -i 's#\#master: .*#master: controller#g' /etc/salt/minion\r"}
expect "${compute02_user}@*" {send "exit\r"}
expect eof
FLAGEOF

echo "boot salt service"
systemctl restart salt-master
if [ $? -eq 0 ]; then
  systemctl enable salt-master &> /dev/null
else
  echo "controller: boot salt-master failed"
  exit
fi
systemctl restart salt-minion
if [ $? -eq 0 ]; then
  systemctl enable salt-minion &> /dev/null
else
  echo "controller: boot salt-minion failed" 
  exit
fi
/usr/bin/expect << FLAGEOF
set timeout 60
spawn ssh $compute01_user@$compute01_ip
expect {
        "(yes/no)" {send "yes\r"; exp_continue}
        "password:" {send "$compute01_user_pass\r"}
}
expect "${compute01_user}@*" {send "systemctl restart salt-minion\r"}
expect "${compute01_user}@*" {send "[ $? -eq 0 ] && systemctl enable salt-minion &> /dev/null || echo \"compute01: boot salt-minion failed\"\r"}
expect "${compute01_user}@*" {send "exit\r"}
expect eof
FLAGEOF
/usr/bin/expect << FLAGEOF
set timeout 60
spawn ssh $compute02_user@$compute02_ip
expect {
        "(yes/no)" {send "yes\r"; exp_continue}
        "password:" {send "$compute01_user_pass\r"}
}
expect "${compute02_user}@*" {send "systemctl restart salt-minion\r"}
expect "${compute02_user}@*" {send "[ $? -eq 0 ] && systemctl enable salt-minion &> /dev/null || echo \"compute02: boot salt-minion faile
d\"\r"}
expect "${compute02_user}@*" {send "exit\r"}
expect eof
FLAGEOF

sleep 10

echo "config salt authentication"
salt-key -A -y 
{
  test=$(salt '*' test.ping" | grep -o "true" | wc -l)
  if [ $test -ne 3 ]; then
    echo "salt authentication failed"
    exit
  fi
    
}&
wait

echo "config salt workspace"
mkdir -p /srv/salt/base/
echo "file_roots:" >> /etc/salt/master
echo "  base:" >> /etc/salt/master
echo "    - /srv/salt/base" >> /etc/salt/master
systemctl restart salt-master
if [ $? -ne 0 ]; then
  echo "config salt workspace failed"
  exit
fi

echo "devops-salt setup finish"