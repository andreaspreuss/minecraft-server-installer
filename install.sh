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
	installdir="/this/is/no/real/dir"	# installation-directory
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
	dir="$( cd -P "$( dirname "$0" )" && pwd )"
	installdir=""
	step=0
	until [ "$step" == 1 ] ; do
		conclear
		echo "Should the server be installed into this directory? ($dir) [y/n]"
		read ans
		dbgPrint "$ans"
		if [ "$ans" == "y" ] ; then
			installdir="$dir"
			step=1
		elif [ "$ans" == "n" ] ; then
			step=1
		else
			step=0
			continue
		fi
	done
	
	if [ "$installdir" == "" ] ; then
		step=0
		until [ "$step" == 1 ] ; do
			conclear
			echo "Please enter the directory to install the server into"
			read ans
			dbgPrint "$ans"
			if [ ! -d "$ans" ] ; then
				step1=0
				until [ "$step1" == 1 ] ; do
					echo "Do you want me to create the dir $ans? [y/n]"
					read ans1
					dbgPrint "$ans1"
					if [ "$ans1" == "y" ] ; then
						mkdir -p "$ans"
						step1=1
					elif [ "$ans1" == "n" ] ; then
						step1=1
					else
						step1=0
					fi
				done
				
				if [ -d "$ans" ] ; then
					installdir="$ans"
					step=1
				else
					step=0
				fi
			fi
		done
	fi
	
	
	# now we even have a directory to work with
	cd "$installdir"
	
	
	server=""
	
	if [ "$serverversion" == "bukkit" ] ; then
		# download the latest recommended version of bukkit
		wget -nv -O craftbukkit.jar http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-0.0.1-SNAPSHOT.jar
		server="java -Xmx1024M -Xms1024M -jar craftbukkit.jar"	
	else
		# download the lates vanilla minecraft-server
		wget -nv -O minecraft_server.jar https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar
		server="java -Xmx1024M -Xms1024M -jar minecraft_server.jar nogui";
	fi
	
	
	cat > server-watch.sh <<'SCRIPT'
#!/bin/bash
##################################################################################################
## ABOUT                                                                                        ##
##################################################################################################
## serverscript v1.0 by devvis                                                                  ##
##################################################################################################
## Be sure to edit the server-variable to contain the full path to your minecraft_server.jar if ##
## this script isn't running from the same working-dir as the server.                           ##
##################################################################################################

############
## CONFIG ##
############
SCRIPT

echo "server=\"$server\"" >> server-watch.sh

cat >> server-watch.sh <<'SCRIPT'
############################################################################
## DO NOT EDIT ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING ##
############################################################################
ver="1.0"


echo "serverscript v$ver by devvis started"
echo "Running on `uname -o`"

until $server; do
echo "Minecraft-server crasched with error-code $?. Restarting..." >&2
    sleep 1
done

SCRIPT

chmod +x server-watch.sh

	# if we're runnig this as root we better set our permissions straight
	
#	if [ "$root" == 1 ] ; then
#		step=0
#		until [ "$step" == 1 ] ; then
#			conclear
#			echo "Since we're running this script as root, which user and group should own the server-directory ($installdir)? [user:group]"
#			read ans
#			dbgPrint "$ans"
			
			## following here we should check if the user and group is correctly formatted
			## format will be checked against the default regexp; ^[a-z][-a-z0-9]*\$
			
			## furthermore we will perhaps check in /etc/passwd if that user and associated group actually exist,
			## just to prevent chown to spew errors in our face :(
			
	
	
	
	
	
	
	
	
	
	
fi # end of interactive mode
