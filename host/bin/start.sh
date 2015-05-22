#!/bin/bash

cpu=`uname -m`

if [ -z "$1" ]; then
	repo=area515
else
	repo=$1
fi;

installDirectory=/opt/cwh
#Its pretty hard to keep these updated, let me know when they get too old
if [ "${cpu}" = "armv6l" ]; then 
	javaURL="http://download.oracle.com/otn-pub/java/jdk/8u33-b05/jdk-8u33-linux-arm-vfp-hflt.tar.gz"
elif [ "${cpu}" = "i686" ]; then 
	javaURL="http://download.oracle.com/otn-pub/java/jdk/8u31-b13/jdk-8u31-linux-i586.tar.gz"
elif [ "${cpu}" = "x86_64" ]; then 
	javaURL="http://download.oracle.com/otn-pub/java/jdk/8u31-b13/jdk-8u31-linux-x64.tar.gz"
fi

if [ ! -f "/usr/lib/jni/librxtxSerial.so" ]; then
	echo Installing RxTx
	apt-get install --yes --force-yes librxtx-java
fi

#This application will always need to have the display set to the following
export DISPLAY=:0.0
xinitProcess=`ps -ef | grep grep -v | grep xinit`
if [ -z "${xinitProcess}" ]; then
    echo No X server running, starting and configuring one
    startx &
    xhost +x
fi

javaInstalled=`which java`
if [ "$javaInstalled" = "" ]; then
	javaMajorVersion=0
	javaMinorVersion=0
else
	javaMajorVersion=`java -version 2>&1 | grep "java version" | awk -F[\".] '{print "0"$2}'`
	javaMinorVersion=`java -version 2>&1 | grep "java version" | awk -F[\".] '{print "0"$3}'`
fi

if [ "$javaMinorVersion" -lt 8 -a "$javaMajorVersion" -le 1 ]; then
	downloadJavaFile=`echo ${javaURL} | awk -F/ '{print $(NF)}'`
	echo Either Java is not installed, or an incorrect version of Java is installed. Installing from this URL: ${javaURL}
	mkdir -p /usr/lib/jvm
	cd /usr/lib/jvm
	rm ${downloadJavaFile}
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "${javaURL}"
	
	firstSnapshot=`ls -1`
	echo Unzipping and installing Java now
	tar xzf ${downloadJavaFile}
	secondSnapshot=`ls -1`
	javaInstallFile=`echo "$firstSnapshot"$'\n'"$secondSnapshot" | sort | uniq -u`
	
	if [ -z "${javaInstallFile}" ]; then
		echo "A new version of Java is available, please update this script with the proper download URLS from: http://www.oracle.com/technetwork/java/javase/downloads/index.html"
		exit
	fi
	
	ln -sf /usr/lib/jvm/${javaInstallFile}/bin/java /usr/bin/java
	ln -sf /usr/lib/jvm/${javaInstallFile}/bin/javac /usr/bin/javac
	ln -sf /usr/lib/jvm/${javaInstallFile}/bin/keytool /usr/bin/keytool		
	rm ${downloadJavaFile}
fi

mkdir -p ${installDirectory}
cd ${installDirectory}
cp build.number networkbuildnumber
mv build.number currentbuildnumber
wget -t 2 -T 20 https://github.com/${repo}/Creation-Workshop-Host/raw/master/host/build.number
mv build.number networkbuildnumber

if [ -f currentbuildnumber ]; then
	currentBuildNumber=`grep build.number currentbuildnumber | awk -F= '{print $2}' | tr -d '\r\n'`
	(( currentBuildNumber-- ))
else
	currentBuildNumber=0
fi
networkBuildNumber=`grep build.number networkbuildnumber | awk -F= '{print $2}' | tr -d '\r\n'`

#Network build.number is always 1 greater than it the current version
(( networkBuildNumber-- ))

if [ "$networkBuildNumber" -gt "$currentBuildNumber" ]; then
	echo Installing latest version of cwh: ${networkBuildNumber}
	rm -r ${installDirectory}
	mkdir -p ${installDirectory}
	cd ${installDirectory}
	wget https://github.com/${repo}/Creation-Workshop-Host/raw/master/host/cwh-0.${networkBuildNumber}.zip
	unzip cwh-0.${networkBuildNumber}.zip
	chmod 777 *.sh
	rm cwh-0.${networkBuildNumber}.zip
else
	rm networkbuildnumber
	mv currentbuildnumber build.number
fi

echo Turning off screen saver and power saving
xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features
xset s noblank     # don't blank the video device 

if [ ! -f "/etc/init.d/cwhservice" ]; then
	echo Installing CWH as a service
	cp ${installDirectory}/cwhservice /etc/init.d/
	chmod 777 /etc/init.d/cwhservice
	update-rc.d cwhservice defaults
fi

echo Starting printer host server

if [ "$2" != "debug" ]
then
        java -Djava.library.path=/usr/lib/jni:os/Linux/${cpu} -cp lib/*:. org.area515.resinprinter.server.Main > log.out 2> log.err &
else
        java  -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=4000,suspend=n -Djava.library.path=/usr/lib/jni:os/Linux/${cpu} -cp lib/*:. org.area515.resinprinter.server.Main > log.out 2> log.err &
fi
