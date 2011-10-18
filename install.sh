#!/bin/bash
# This scripts attempts to autoinstall a minecraft server, also setting up the firewall to allow incoming connections on the default port.
# Works only for debian/ubuntu

# v1.0 - by devvis


#####################
## CONFIG
#####################
# Should the script be interactive or will you define all variables below?
interactive=true
if [ "$interactive" != true ] ; then	# if we're not going to go with interactive, set all variables below
	serverversion="vanilla"				# vanilla or bukkit
fi
#####################
## END OF CONFIG
#####################

# Private config-area-shit
javainstall="apt-get install -y -qq sun-java6-jre"
debug=true


## Private functions
function conclear {
# Clears the console if debug isn't enabled
	if [ "$debug" != true ] ; then
		clear
	fi
}

function dbgPrint {
	if [ "$debug" == true ] ; then
		echo "$1"
	fi
}

conclear

# are we root?
if [[ $EUID -ne 0 ]] ; then
	root=0
else
	root=1
fi

if [ "$interactive" == true ] ; then

	step=0
	until [ "$step" == 1 ] ; do
		conclear
		echo "Do you want to use the vanilla mincraft-server or do you want to use bukkit? [vanilla/bukkit]"
		read serverversion
		dbgPrint "$serverversion"
		if [ "$serverversion" == "vanilla" ] || [ "$serverversion" == "bukkit" ] ; then
			step=1
		fi
	done
	step=0
	
	java=`dpkg --get-selections | awk '/\sun-java6-jre/{print $1}'`
	
	if [ "$java" != "sun-java6-jre" ] ; then
		java=`which java`
		if [ "$java" == "" ] ; then
			step=0
			until [ "$step" == 1 ] ; do
				conclear
				ans="n"
				echo "It seems that Java 6 isn't installed, should I attempt to install it automatically? [y/n]"
				read ans
				dbgPrint "$ans"
				
				if [ "$ans" == "y" ] ; then
					if [ "$root" == 0 ] ; then
						sudo $javainstall
					else
						$javainstall
					fi
					java=`which java`
					if [ "$java" == "" ] ; then
						echo "It seems like I was unable to install java. Please go to this URL and download the package manually."
						echo "http://www.java.com/en/download/manual.jsp"
						echo "Restart me when the installation is complete."
						exit 1
					else
						step=0
					fi
				elif [ "$ans" == "n" ] ; then
					echo "Please install java by either using apt (apt-get install sun-java6-jre) or go to this website and download it from there."
					echo "http://www.java.com/en/download/manual.jsp"
					echo "Restart me when the installation is complete."
					exit 1
				else
					step=0
				fi
			done
		else
			java=`dpkg --get-selections | awk '/\openjdk-6-jre/{print $1}'`
			if [ "$java" == "openjdk-6-jre" ] ; then
				step=0
				ans="y"
				until [ "$step" == 1 ] ; do
				conclear
					echo "Notice: It seems that you have Open JDK installed. Minecraft is known to have issues with this version of Java, proceed at your own risk."
					echo "You could remove Open JDK by exiting this installer and then run it again to install Oracle (Sun) Java 6 JRE."
					echo "Do you want to continue the installation of the minecraft-server with Open JDK? [y/n]"
					read ans
					dbgPrint "$ans"
					if [ "$ans" == "y" ] ; then
						step=1
					elif [ "$ans" == "n" ] ; then
						exit 1
					else
						step=0
					fi
				done
			else
				echo "I cannot determine which version of Java that you're using, other than that I know you have Java installed."
				echo "This will most probably work allright for you so we're just going to proceed with the installation."
			fi
		fi
	fi	
	
	# now we have java installed, and hopefully working.
	# lets move on to installing the actual server.
		
		
		
		
		
		
		
	
fi
