### **k8s_init.sh脚本说明：**
```bash
1.yum_config: 配置阿里云base/epel源及安装基础工具
2.yum_k8s_config: 配置阿里云k8s源
3.iptables_config: 关闭系统自带firewalld,安装iptables
4.selinux_config: 关闭selinx
5.ulimit_config: 修改系统打开文件数
6.time_config: 配置时间同步
7.sysctl_config: 配置k8s相关系统参数
8.swap_config: 关闭swap
9.kernel_config: 升级内核版本
10.docker_config: 安装docker，配置docker cgroup driver为systemd
11.ipvs_config: 配置ipvs模块，k8s默认使用iptables
```
