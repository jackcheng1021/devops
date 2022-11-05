# devops

1.基于基础云的devops平台包括
- 云平台即代码: saltstack, openstack脚本（openstack脚本详见liberty_openstack仓库：https://github.com/jackcheng1021/liberty_openstack）
- 系统配置即代码: saltstack
- 物理主机即代码: cobbler
- 代码托管与共享: 云主机, git, github
- 生产环境即代码: 云主机, docker
- 产品测试即代码: 云主机, serverspec
- 产品部署即代码: 云主机, docker, kubernetes
- 性能监控即代码: saltstack, zabbix
![image](https://github.com/jackcheng1021/devops/blob/master/img/devops-architecture-image.png)

2.安装和配置
- 环境准备
  - 三台安装CentOS7操作系统的虚拟机
  - 在同一网段
  - 三台主机名分别为: controller compute01 compute02
- 关闭三台主机的SELINUX模块
```
//分别在三台主机执行如下命令
sed -i 's#^SELINUX=.*#SELINUX=disabled#g' /etc/selinux/config
reboot
```
- 安装
  - 将该项目下载到 controller 节点的 root 目录下
  - 进入目录 `cd /root/devops/`
  - 下载 openstack 需要用的 tar 到 devops/liberty_openstack/ 目录
    - liberty安装包
    - 链接：https://pan.baidu.com/s/1ZkhNkJD4EC8y4pAvodEtDg 
    - 提取码：kn34 
```
//执行如下命令
chmod +x devops-platform-install.sh
./devops-platform-install.sh
```
