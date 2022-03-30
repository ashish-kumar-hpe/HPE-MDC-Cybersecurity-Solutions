#!/bin/bash
#
# xGT pre-requisites setup
# 
# ****** Pre-requisites *********
# Create a "sdflex_trovares_POC.tgz" and make it available on a HPE public FTP account for Trovares POC customers.
# it should have following when it is untarred.
# $TROVARES_POC_HOME/hpefsw/hpe-foundation*.iso
# 

# Please update below variable before running this script in your setup.
# 
# Specify the directory name where you have extracted the sdflex_trovares_POC.tgz file
TROVARES_POC_HOME="/root/trovares_POC"
#
# Mention a mount point name for NVMe disks and it has to be in absolute path (full path) 
# NVMe disks will be mounted on /nvme_data0, /nvme_data1, /nvme_data2 and so on
NVME_MNT_DIR="/nvme_data"
NVME_DEVICE_NAME_PATTERN="/dev/nvme0n*"

# Update your organization NTP Server IP/hostname here
NTPSVR="server 0.pool.ntp.org"

# Update NVMe disks list here. Enter complete path. For example: /dev/nvme0n1 
NVME_DISK_LIST=(/dev/nvme0n1 /dev/nvme0n2 /dev/nvme0n3)

# HPE FOUNDATION SOFTWARE mount point
HPEFS_MNT_DIR="/hpefswmount"

# Below parameters are used by SAR function to collect network statistics 
NETWORK_INTERFACE=ens33
REPORT_DIR="/hpeSarReport"

function usage {
echo ""
echo 'Usage:'
echo "------"
echo '# ./setup_prereq.sh -[Option]'
echo ""
echo "Options:"
echo "-f: [Step 1] Installs HPE Foundation Software for HPE Superdome Flex, which is located at" 
echo "    $TROVARES_POC_HOME/hpefsw.(Requires RHEL OS yum repo configured & Foundation ISO shipped"
echo "    along with this script)"
echo "-m: [Step 2] Create filesystem on below NVME disks (defined inside the script),"
echo "    `echo "Currently selected NVMe Disks: "${NVME_DISK_LIST[@]}`," 
echo "    create mount points, update /etc/fstab, and mount them at "$NVME_MNT_DIR"0, "$NVME_MNT_DIR"1"
echo "    and so on. "
echo "-d: [Step 3] Tune NVMe disks:`echo ${NVME_DISK_LIST[@]}`"
echo "-s: [Step 4] Sets SELINUX to Permissive, setup limits.conf, tunes kernel params, disables Firewall"
echo "    sets maximum CPU frequency, disables HugePage."
echo "-n: [Step 5] Configure NTP Client (Update your NTP Server IP in the script before running this)."
echo "-j: [Step 6] Installs JAVA (Requires RHEL OS yum repo configured)."
echo "-p: [Step 7] Installs Python (Python-3.7.4.tar.xz Source file shipped along with this script)."
echo "-x: [Step 8] Installs xGT python packages."
echo "-z: [Step 9] Installs Jupyter."
echo "-r: Collect SAR Reports at $REPORT_DIR"
echo " "
echo "############################################################################################"
echo "NOTE: It is recommended to use above options step by step. For example:              "
echo "Execute first './setup_prereq.sh -f' and then './setup_prereq.sh -m', and so on"
echo "############################################################################################"
echo " "
}

if [ $# -eq 0 ]; then
    echo "No arguments provided. Check the syntax:"
	usage
    exit 1
fi

function setupFSWrepo {

rpm -qa | grep "hpe-foundation"
if [ $? -eq 0 ]; then
	echo "HPE Foundation Software is already installed !"
	exit 0
else	
	echo "HPE Foundation Software is not yet installed !"
fi

ls $TROVARES_POC_HOME/hpefsw/hpe-foundation*.iso >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Trying to install now, but could not find HPE Foundation Software ISO at $TROVARES_POC_HOME/hpefsw/. Please perform the following steps:"
	echo "1) Please download sdflex_trovares_POC.tgz file from ftp location mentioned in the Cookbook."
	echo "2) Untar it using 'tar xvzf sdflex_trovares_POC.tgz' as root user."
	echo "3) Update TROVARES_POC_HOME parameter in system_prereq.sh"
	echo "3) Finally re-run the script with '-f' option."
	echo " "
	exit 1
else	
	echo "Found `ls $TROVARES_POC_HOME/hpefsw/hpe-foundation*.iso`"
	echo "Creating directory $HPEFS_MNT_DIR, if it does not exist already"
	mkdir $HPEFS_MNT_DIR >/dev/null 2>&1  
	echo "Mounting `ls $TROVARES_POC_HOME/hpefsw/hpe-foundation*.iso` on $HPEFS_MNT_DIR"
	mount -t iso9660 -ro loop `ls $TROVARES_POC_HOME/hpefsw/hpe-foundation*.iso` $HPEFS_MNT_DIR
fi


echo "Creating HPE Foundation Software Repo.."
cat << EOF > /etc/yum.repos.d/hpefsw.repo
[hpefsw]
name=HPE Foundation Software - Trovares Setup
baseurl=file://`echo $HPEFS_MNT_DIR`/RPMS
enabled=1
gpgcheck=0
gpgkey=file://`echo $HPEFS_MNT_DIR`/RPM-GPG-KEY-hpe file://`echo $HPEFS_MNT_DIR`/RPM-GPG-KEY-sgi
EOF

# yum repolist 

}

function installFSW {

echo 'Installing HPE Foundation Software: yum groupinstall "HPE Foundation Software" -y'
yum groupinstall "HPE Foundation Software" -y
if [ $? -ne 0 ]; then
	echo ''
	echo "##################################################################################"
	echo 'WARNING: Installation failed'
	echo 'NOTE: yum groupinstall "HPE Foundation Software" failed. Please check manually.'
	echo 'NOTE: HPE Foundation software has dependency on many RPMs located in RHEL OS image.' 
	echo "Please configure yum repo for the RHEL OS and re-try."
	echo "###################################################################################"
	echo 'For example: Configure OS repo using ISO image as shown below and re-try.'
	echo 'Create ISO mount point   => # mkdir /rhelmnt'
	echo 'Mount the RHEL ISO image => # mount -t iso9660 -ro loop /root/RHEL-7.6-20181010.0-Server-x86_64-dvd1.iso /rhelmnt'
	echo ''
	echo 'Create repo file as shown below:'
	echo '# cat /etc/yum.repos.d/rhelmnt.repo'
	echo '[rheliso]'
	echo 'name=RHEL OS Image'
	echo 'baseurl=file:///rhelmnt'
	echo 'enabled=1'
	echo 'gpgcheck=0'
	echo ''
	exit 1
fi
systemctl status memlog

}

function createFilesytemOnNvmeDisk {

ls $NVME_DEVICE_NAME_PATTERN >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "NVMe disks not found"
	exit 1
fi
for disk in "${NVME_DISK_LIST[@]}"
do
	fdisk -l /dev/nvme0n3 | grep label
	partexist=`echo $?`
	file -sL $disk | grep filesystem
	if [ $? -eq 0 ]; then
		echo "INFO: Filesystem already exists on $disk. Not creating filesystem !"
	elif [ $partexist -eq 0 ]; then
		echo "WARNING: Partition found on the $disk. Please remove partition from $disk manually and re-run this command !"	
	else
		echo "INFO: Creating XFS filesystem on $disk .."
		mkfs.xfs $disk
	fi
done

}

function createMountPoints {

ls $NVME_DEVICE_NAME_PATTERN >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "NVMe disks not found."
	exit 1
fi

for disk in "${NVME_DISK_LIST[@]}"
do
# Finding NVMe disk number
dsknum=`echo $disk | cut -d"/" -f3 | cut -d"e" -f2 | cut -d"n" -f1`
mkdir /"$NVME_MNT_DIR"$dsknum
done

}

function mountNVMEdisks {

ls $NVME_DEVICE_NAME_PATTERN >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "NVMe disks not found."
	exit 1
fi

for disk in "${NVME_DISK_LIST[@]}"
do

	echo "Adding entry in fstab..."
	grep $disk /etc/fstab
	if [ $? -eq 0 ]; then
		echo "fstab entry already exists for $disk, skipping."
	else
		dsknum=`echo $disk | cut -d"/" -f3 | cut -d"e" -f2 | cut -d"n" -f1`
		echo "# Below entry added by Trovares POC setup script" >> /etc/fstab
		echo "$disk       "$NVME_MNT_DIR"$dsknum      xfs     noatime,nodiratime   0 0" >> /etc/fstab
		echo "Added fstab entry for $disk."
	fi
done

mount -a

}

function setReadAhead {

ls $NVME_DEVICE_NAME_PATTERN >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "This system does not have NVMe disks. Not setting tunables."
	exit 0
fi

for i in "${NVME_DISK_LIST[@]}"
do
   echo "Setting read ahead using blockdev on $i."
   blockdev --setra 8192 $i;
done;
	
}

function setDiskParam {
ls $NVME_DEVICE_NAME_PATTERN >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "This system does not have NVMe disks. Not setting tunables."
	exit 0
fi


for f in "${NVME_DISK_LIST[@]}";
do
   dsk=`echo $f | cut -d"/" -f3`
   val=$(cat /sys/block/$dsk/queue/rotational)
   if [[ "$val" -eq "0" ]]; then
        echo "Disk /sys/block/$dsk configured as NVME_SSD"
		echo "Setting $f/queue/read_ahead_kb to 4096 for $f"
        echo "echo 4096 > /sys/block/$dsk/queue/read_ahead_kb" >> /etc/rc.d/rc.local
		echo "Setting $f/queue/nr_requests to 32 for $f"
        echo "echo 32 > /sys/block/$dsk/queue/nr_requests"  >> /etc/rc.d/rc.local
		echo "Setting $f/queue/nomerges to 2 for $f"
        echo "echo 2 > /sys/block/$dsk/queue/nomerges"  >> /etc/rc.d/rc.local
		echo "Setting $f/queue/rq_affinity to 2 for $f"
        echo "echo 2 > /sys/block/$dsk/queue/rq_affinity"  >> /etc/rc.d/rc.local
		echo "========================================="
    fi
done

}

function setSelinuxHugepageSystectl {

echo "######################################"
echo "### Setting SELINUX=permissive #######"
echo "######################################"

sed -i -e 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

echo "Below change has been done in /etc/selinux/config"
grep ^SELINUX /etc/selinux/config
echo " "
echo "/etc/selinux/config file modified !"

echo "##########################################################################################"
echo "### Creating /etc/rc.d/rc.local and adding command to disable transparent_hugepage #######"
echo "###########################################################################################"

cat << EOF >> /etc/rc.d/rc.local
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
EOF

echo "Setting up I/O Schedular for NVMe disks in /etc/rc.d/rc.local"
for i in "${NVME_DISK_LIST[@]}"
do
	dsk=`echo $i | cut -d"/" -f3`
	echo "echo 'mq-deadline' > /sys/block/$dsk/queue/scheduler" >> /etc/rc.d/rc.local
done;

echo " "
echo "Setting up maximum frequency for the CPU"
echo " "
ls -l /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "##################################################################################################################"
	echo "WARNING: Unable to set CPU maximum frequency as /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies" 
	echo "could not be found !"
	echo "##################################################################################################################"
else
	max_freq=$(for c in $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies); do echo $c; done | sort -nr | head -1)
	for cpu_max_freq in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq
	do 
		echo "echo $max_freq > $cpu_max_freq" >> /etc/rc.d/rc.local
	done
fi

echo "Below is the modified content of /etc/rc.d/rc.local file"
cat /etc/rc.d/rc.local

chmod +x /etc/rc.d/rc.local

echo "######################################"
echo "### Updating sysctl.conf file #######"
echo "######################################"
echo ""

cp /etc/sysctl.conf /etc/sysctl.conf_HPEOLD
echo "Existing /etc/sysctl.conf has been backed up as /etc/sysctl.conf_HPEOLD. Creating a new /etc/sysctl.conf and applying it."
cat <<EOF > /etc/sysctl.conf
kernel.sem = 250 32000 100 128
kernel.shmall = 2097152
kernel.shmmax = 2147483648
fs.file-max = 65536
kernel.shmmni = 4096
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 1024 65000
net.core.rmem_default = 4194304
net.core.wmem_default = 2621444
net.core.rmem_max=4194304
net.core.wmem_max=262144
net.ipv4.tcp_rmem = 1048576 1048576 4194304
net.ipv4.tcp_wmem = 1048576 1048576 1048576
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.all.disable_ipv6 = 1
kernel.nmi_watchdog=0
vm.swappiness=1
EOF

echo "Here is the current sysctl configuration"
sysctl -p


echo "You must reboot the server now to activate the configuration done now."
}

function setLimits {

echo "###################################################"
echo "### Updating /etc/security/limits.conf file #######"
echo "###################################################"
echo ""

cp /etc/security/limits.conf /etc/security/limits.conf_HPEOLD
echo "Existing /etc/sysctl.conf has been backed up as /etc/security/limits.conf_HPEOLD. Creating a new /etc/security/limits.conf and applying it."
cat << EOF > /etc/security/limits.conf
*  soft nproc 65536
*  hard nproc 65536
*  soft nofile 262144
*  hard nofile 262144
EOF

echo "Below is the current /etc/security/limits.conf."
cat /etc/security/limits.conf
}

function stopStartServices {

echo "###################################################"
echo "### Disabling firewall, tuned-adm services  #######"
echo "###################################################"
echo ""

systemctl disable firewalld 
systemctl stop firewalld 
systemctl status firewalld

echo "Disabling tuned service. Ignore any error message. Error message may be reported if tuned was already disabled."
tuned-adm off
tuned-adm list
systemctl stop tuned
systemctl disable tuned

#echo "Starting rpcbind service"
#service rpcbind start
echo "#######################################################################"
echo "You must reboot the server now to activate the configuration done now."
echo "########################################################################"
 
}

function ntpClient {

echo "################################"
echo "### Setting up NTP Client#######"
echo "################################"
echo ""

rpm -qa | grep ntp-
if [ $? -eq 0 ]; then
	echo "`rpm -qa | grep ntp-` is already installed. "
else
	echo "Installing NTP using RHEL OS Repository"
	yum -y install ntp
	if [ $? -ne 0 ]; then
	echo "ntp installation failed. Please check RHEL OS yum repository configured or not."
	exit 1
	fi
fi

echo "Creating /etc/ntp.conf with dummy NTP server."

cat << EOF > /etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
server `echo $NTPSVR`
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF

echo "Staring ntpd daemon..."
systemctl enable ntpd.service
systemctl start ntpd.service
#sleeping for 3 seconds for the daemon to start fully
sleep 3
echo "Checking ntpstat..." 
ntpstat
echo "If above reports that ntp is unsynchronised, please check with server admin."

echo "NOTE: Below is the current configuration. Please replace $NTPSVR with" 
echo "      your NTP server name and restart NTP service"
cat /etc/ntp.conf
echo " "

echo "###########################################################################"
echo "NOTE: Manually update NTP Server information in /etc/ntp.conf."
echo "Ask your Server admin to provide NTP server IP or hostname for your setup"
echo "###########################################################################"
	   
}

function installJava {

yum install -y java-1.8.0-openjdk*

echo "##################################################################################################"
echo "Setting up JAVA path in $HOME/.bash_profile:"
echo "This script assumes that java-1.8.0-openjdk-1.8.0.181-7.b13.el7.x86_64 was installed in the system"
echo "and the home directory is /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-7.b13.el7.x86_64."
echo "If you have installed different Java version, please update JAVA_HOME in $HOME/.bash_profile"
echo "##################################################################################################"

echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-7.b13.el7.x86_64" >> $HOME/.bash_profile
echo "export PATH=$PATH:$JAVA_HOME/bin" >> $HOME/.bash_profile

echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-7.b13.el7.x86_64"
echo "export PATH=$PATH:$JAVA_HOME/bin"

echo "Checking Java installation.."
java -version
if [ $? -ne 0 ]; then
	echo "java -version command failed. Please check the path and try again."
	echo 'Check this command "/usr/sbin/alternatives --config java" and choose the desired Java installation.' 
	exit 1
fi

}

function installPythonVirtualenv {

yum install gcc openssl-devel bzip2-devel libffi-devel sqlite-devel zlib-devel -y
cp $TROVARES_POC_HOME/python/Python-3.7.4.tar.xz /root
# wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tar.xz
cd /root
tar xvf Python-3.7.4.tar.xz
cd Python-3.7.4
./configure --enable-optimizations
make altinstall
echo "Installing virtualenv from $TROVARES_POC_HOME/virtualenv"
python3.7 -m pip install $TROVARES_POC_HOME/virtualenv/virtualenv-16.7.9-py2*
cd /root
virtualenv --extra-search-dir=$TROVARES_POC_HOME/virtualenv --never-download -p python3.7 Python_3_7
echo "#############################################################################"
echo 'Execute "source /root/Python_3_7/bin/activate" to activate virtual environment'
echo 'Execute "deactivate" to come out of virtual environment'
echo "#############################################################################"
echo "source /root/Python_3_7/bin/activate" >> $HOME/.bash_profile
}

function installxGTRPMs {

source /root/Python_3_7/bin/activate
echo "Installing xGT python packages from $TROVARES_POC_HOME/xgt"
python3.7 -m pip install $TROVARES_POC_HOME/xgt/*
}

function installJupyter {

source /root/Python_3_7/bin/activate
echo "Installing Jupyter.."
python3.7 -m pip install $TROVARES_POC_HOME/jupyter/*
jupyter notebook --generate-config
ipaddr=`ip a | grep global | awk '{print $2}' | cut -d"/" -f1`
#sed -i -e "s/^#c.NotebookApp.ip.*/c.NotebookApp.ip=$ipaddr/g" /root/.jupyter/jupyter_notebook_config.py

echo "#############################################################################"
echo "You may start Jupyter notebook server using below commands:"
echo "source /root/Python_3_7/bin/activate"
echo "jupyter notebook --ip $ipaddr --allow-root"
echo "#############################################################################"

}

function hpeSarReport {

mkdir $REPORT_DIR  >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "NOTE: $REPORT_DIR already exists. Proceeding with report collection."
fi

dt=`date | sed -e "s/ /_/g"`
mkdir $REPORT_DIR/$dt
if [ $? -ne 0 ]; then
	echo "mkdir $REPORT_DIR/$dt failed. Please check directory permission and run again."
	exit 1
fi

sample_interval=1 
number_of_samples=10

export LC_TIME="POSIX"
echo "Storing SAR reports under $REPORT_DIR/$dt"
echo "Collecting $number_of_samples samples at every $sample_interval second(s) interval.."

# CPU
sar -u $sample_interval $number_of_samples | grep -v -E "CPU|Average|^$" > $REPORT_DIR/$dt/cpu.dat &
# CPU DETAILED CSV FORMAT
sar -P ALL $sample_interval $number_of_samples | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4","$5","$6","$7","$8","$9; }  }' >$REPORT_DIR/$dt/CPU.csv &

# RAM 
sar -r $sample_interval $number_of_samples | grep -v -E "[a-zA-Z]|^$" > $REPORT_DIR/$dt/ram.dat &
#RAM DETAILED CSV FORMAT
sar -r $sample_interval $number_of_samples | grep -v -E "Linux|Average" | awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12; }}'  >$REPORT_DIR/$dt/RAM.csv &

# Swap
sar -S $sample_interval $number_of_samples | grep -v -E "[a-zA-Z]|^$" > $REPORT_DIR/$dt/swap.dat &
# Swap DETAILED CSV FORMAT
sar -S $sample_interval $number_of_samples | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4","$5","$6","$7; }  }' > $REPORT_DIR/$dt/swap.csv &

# Load average and tasks
sar -q $sample_interval $number_of_samples | grep -v -E "[a-zA-Z]|^$" > $REPORT_DIR/$dt/loadaverage.dat &
# Load average and tasks DETAILED CSV FORMAT
sar -q $sample_interval $number_of_samples | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4","$5","$6","$7","$8; }  }' > $REPORT_DIR/$dt/loadaverage.csv &

# IO transfer
sar -b $sample_interval $number_of_samples | grep -v -E "[a-zA-Z]|^$" > $REPORT_DIR/$dt/iotransfer.dat &
# IO transfer DETAILED CSV FORMAT
sar -b $sample_interval $number_of_samples | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4","$5","$6","$7; }  }' > $REPORT_DIR/$dt/iotransfer.csv &

# Process/context switches
sar -w $sample_interval $number_of_samples | grep -v -E "[a-zA-Z]|^$" > $REPORT_DIR/$dt/proc.dat &
# Process/context switches DETAILED CSV FORMAT
sar -w $sample_interval $number_of_samples | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4; }  }' > $REPORT_DIR/$dt/proc.csv &

# Network Interface
sar -n DEV $sample_interval $number_of_samples | grep $NETWORK_INTERFACE | grep -v "Average" > $REPORT_DIR/$dt/netinterface.dat &
# Network Interface DETAILED CSV FORMAT
sar -n DEV $sample_interval $number_of_samples | grep $NETWORK_INTERFACE | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) \
{ print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10; }  }' > $REPORT_DIR/$dt/netinterface.csv &

# Sockets
sar -n SOCK $sample_interval $number_of_samples | grep -v -E "[a-zA-Z]|^$" > $REPORT_DIR/$dt/sockets.dat &
# Sockets DETAILED CSV FORMAT
sar -n SOCK $sample_interval $number_of_samples | grep -v -E "Linux|Average"| awk '{if ($0 ~ /[0-9]/) { print $1","$2","$3","$4","$5","$6","$7","$8; }  }' > $REPORT_DIR/$dt/sockets.csv &

echo "Collecting reports in the background. Check the reports at $REPORT_DIR/$dt."
echo "Sleeping for $(($sample_interval * $number_of_samples)) seconds"
sleep $(($sample_interval * $number_of_samples))
}

while getopts ":fmdsnjpxzr" o; do
    case "${o}" in
        f)	#f=${OPTARG}
			setupFSWrepo
			installFSW
            ;;
        m)  #m=${OPTARG}
			createFilesytemOnNvmeDisk
			createMountPoints
			mountNVMEdisks
            ;;
        d)  #d=${OPTARG}
			setReadAhead
			setDiskParam
            ;;	
        s)  #s=${OPTARG}
			setSelinuxHugepageSystectl
			setLimits
			stopStartServices
            ;;	
        n)  #n=${OPTARG}
			ntpClient 
            ;;
        j)  #j=${OPTARG}
			installJava
            ;;
        p)  #p=${OPTARG}
			installPythonVirtualenv
            ;;
        x)
            #x=${OPTARG}
			installxGTRPMs
            ;;
        z)  #z=${OPTARG}
			installJupyter
            ;;
        r)  #r=${OPTARG}
			hpeSarReport
            ;;				
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

