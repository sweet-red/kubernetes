#!/bin/bash
echo -e "\033[31m 这个是centos7系统初始化脚本，针对K8S主机！Please continue to enter or ctrl+C to cancel \033[0m"
sleep 5

#配置阿里云源/基础组件安装
yum_config(){
    yum install -y wget
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum -y install jq psmisc telnet git lvm2 iotop iftop net-tools lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel  vim ncurses-devel autoconf automake zlib-devel  python-devel bash* wget net-tools nfs-utils lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel epel-release openssh-server socat  ipvsadm conntrack ntpdate yum-utils device-mapper-persistent-data 
}

#关闭firewalld，安装iptables
iptables_config(){
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    yum install iptables-services -y
    systemctl enable iptables
    systemctl start iptables
    iptables -F
    service iptables save
}

#关闭NetworkManager
networkmanager_config(){
	systemctl stop NetworkManager
    systemctl disable NetworkManager
}

#关闭selinux
selinux_config(){
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
    timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
    #yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service 
}

#关闭swap分区
swap_config(){
swapoff -a && sed  -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab 
}

#配置时间同步
time_config(){
	timedatectl set-timezone Asia/Shanghai
	timedatectl set-local-rtc 0
	systemctl restart rsyslog
	systemctl restart crond
	echo "* */2 * * *  /sbin/ntpdate cn.pool.ntp.org" >> /var/spool/cron/root
}

#配置ulimit
ulimit_config(){
    echo "ulimit -SHn 102400" >> /etc/rc.local
    cat >> /etc/security/limits.conf << EOF
    *           soft   nofile       1024000
    *           hard   nofile       1024000
    *           soft   nproc        1024000
    *           hard   nproc        1024000
EOF
}

#升级最新kernel
kernel_config(){
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install -y kernel-lt
VERSION=`awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg | head -1 | awk -F ':' '{print $2}'`
grub2-set-default '${VERSION}'
}

#安装基础软件包
base_soft(){
yum install -y yum-utils device-mapper-persistent-data lvm2 wget net-tools nfs-utils lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel epel-release openssh-server socat  ipvsadm conntrack ntpdate telnet rsync
}

#安装docker-ce,官方建议版本19.03
docker_config(){
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
## 配置docker国内镜像
## 新版kubelet建议使用systemd
echo '{
 "exec-opts": ["native.cgroupdriver=systemd"],
 "registry-mirrors": ["https://s07f4mkl.mirror.aliyuncs.com"]
}' >> /etc/docker/daemon.json
systemctl restart docker
}


#ipvs相关
ipvs_config(){
yum install ipvsadm ipset sysstat conntrack libseccomp -y

cat > /etc/modules-load.d/ipvs.conf <<EOF
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
ip_vs_sh
nf_conntrack
ip_tables
ip_set
xt_set
ipt_set
ipt_rpfilter
ipt_REJECT
ipip
EOF

systemctl enable --now systemd-modules-load.service
lsmod | grep -e ip_vs -e nf_conntrack
}

#配置系统参数
sysctl_config(){
cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65000
#k8s
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
vm.overcommit_memory = 1
vm.panic_on_oom = 0
fs.inotify.max_user_watches = 89100
fs.may_detach_mounts = 1
fs.file-max = 52706963
fs.nr_open = 52706963
net.netfilter.nf_conntrack_max = 2310720
EOF
/sbin/sysctl -p
echo "sysctl set OK!!"
}

main(){
    yum_config
    iptables_config
    networkmanager_config
    selinux_config
    swap_config
    time_config
    ulimit_config
    #kernel_config
    docker_config
    ipvs_config
    sysctl_config
    
	
}
main
reboot
