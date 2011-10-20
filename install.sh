#!/bin/bash
# This scripts attempts to autoinstall a minecraft server, also setting up the firewall to allow incoming connections on the default port.
# Works only for debian/ubuntu

# v1.0 - by devvis

## TODO
# * Check if we have write-permission to the dir, if not, try sudo for changing it within the script
# * If the script is running as root, correct the permissions for all the dirs
# * Add more distros (for java-installation since apt doesnt run very well on systems like fbsd










#####################
## CONFIG
#####################
# Should the script be interactive or will you define all variables below?
interactive=true
if [ "$interactive" != true ] ; then	# if we're not going to go with interactive, set all variables below
	serverversion="vanilla"				# vanilla or bukkit
	installdir="/this/is/no/real/dir"	# installation-directory
	installjava=true					# will try to install java if it isn't found on the system
	
	allownether=true					# should the nether be enabled on the server?
	viewdistance=10						# what view-distance should be used? (10 is default and is recommended, reduce if you experience lag)
	spawnmonsters=true					# should monsters spawn?
	onlinemode=true						# should the users authenticate against the minecraft-servers? set to false if minecraft.net is down
	spawnanimals=true					# should animals spawn?
	maxplayers=20						# the maximum amount of players that can be online at the same time
	serverip=""							# if you have more than one interface and want to bind to only one ip
	pvp=true							# should pvp (player vs. player combat) be enabled?
	levelseed=""						# do you want some special, fancy seed? enter it here
	serverport=25565					# what port should the server bind to, 25565 is default
	whitelist=false						# should the server use a white list to only allow certain people to connect? (edit white-list.txt)
	allowflight=false					# should the users be able to fly if they have such client modification installed? (considered a hack by most people)
	gamemode=0							# 0 for survival, 1 for creative
	difficulty=1						# 0 for peaceful, 1 for easy, 2 for normal and 3 for hard. spawnmonsters=0 sets this to 0 as well
	motd="Welcome to my minecraft-server!"	# what message should be displayed for newly connected players?
	
	
	
fi
#####################
## END OF CONFIG
#####################

## Private config area, the only thing you might want to touch here
## would be setting debug=true, nothing else.
debug=true
javainstall="apt-get install -y -qq sun-java6-jre"


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

if [[ "$debug" == true ]] ; then
	set -v
fi
conclear

# are we root?
if [[ $EUID -ne 0 ]] ; then
	root=0
else
	root=1
fi

if [ "$interactive" == true ] ; then
	
	# trying to determine the suitable amount of ram that the server should use
	totram="$($_CMD free -mto | grep Mem: | awk '{ print $2 }')"
	freeram="$($_CMD free -mto | grep Mem: | awk '{ print $4 }')"
	
	if [ "$totram" -lt 1024 ] ; then
		step=0
		until [ "$step" == 1 ] ; do
			conclear
			echo "NOTICE: It seems that you got less than 1024 MB of RAM on your server."
			echo "This will usually lead to a bad server performance, and you'll be very limited in the number of simultaneous players."
			echo "I strongly suggest that you add more RAM before continuing with the installation."
			echo "Do you want to continue anyway? [y/n]"
			read ans
			dbgPrint ans
			if [ "$ans" == "y" ] ; then
				step=1
			elif [ "$ans" == "n" ] ; then
				exit 1
			else
				step=0
			fi
		done
		ram="1024"
	else 
		if [ "$freeram" -gt 1024 ] && [ "$totram" -gt 2048 ] && [ "$totram" -lt 3072 ] ; then
			ram="1536"
		elif [ "$freeram" -gt 1024 ] && [ "$totram" -gt 2560 ] && [ "$totram" -lt 3584 ] ; then
			ram="2048"
		elif [ "$freeram" -gt 1024 ] && [ "$totram" -gt 3584 ] ; then
			ram="2560"
		else
			ram="1024"
			fi
	fi
	
	echo "$ram"
	
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

	# Lets ask the user some questions about what kind of server they want
	

	conclear
	echo "Now it's time for some questions about the settings of your server."
	echo "Please note that all of these will be written into server.properties and can be easily changed afterwards, just open up the file and change the value from there!"
	read ans
	
	step=0
	ans=""
	until [ "$step" == 1 ] ; do
		conclear
		echo "Should the nether be allowed on the server? [y/n]"
		read ans
		dbgPrint "$ans"
		if [ "$ans" == "y" ] ; then
			allownether=true
			step1=1
		elif [ "$ans" == "n" ] ; then
			allownether=false
			step1=1
		else
			step1=0
		fi
	done

	step=0
	ans=""
	until [ "$step" == 1 ] ; do
		conclear
		echo "What view-distance should the server use? (default is 10, reduce if you're on a low-performing server) [num]"
		read ans
		dbgPrint "$ans"
		if [ "$ans" == [0-9]* ] ; then
			viewdistance="$ans"
			step1=1
		else
			step1=0
		fi
	done

	step=0
	ans=""
	until [ "$step" == 1 ] ; do
		conclear
		echo "Should there be spawning monsters on the server? [y/n]"
		read ans
		dbgPrint "$ans"
		if [ "$ans" == "y" ] ; then
			spawnmonsters=true
			step1=1
		elif [ "$ans" == "n" ] ; then
			spawnmonsters=false
			step1=1
		else
			step1=0
		fi
	done

	step=0
	ans=""
	until [ "$step" == 1 ] ; do
		conclear
		echo "Should there be spawning animals on the server? [y/n]"
		read ans
		dbgPrint "$ans"
		if [ "$ans" == "y" ] ; then
			spawnanimals=true
			step1=1
		elif [ "$ans" == "n" ] ; then
			spawnanimals=false
			step1=1
		else
			step1=0
		fi
	done

	step=0
	ans=""
	until [ "$step" == 1 ] ; do
		conclear
		echo "Should the server verify users logging in against the minecraft.net-servers? (normally you want to say yes here) [y/n]"
		read ans
		dbgPrint "$ans"
		if [ "$ans" == "y" ] ; then
			onlinemode=true
			step1=1
		elif [ "$ans" == "n" ] ; then
			onlinemode=false
			step1=1
		else
			step1=0
		fi
	done

	# here we're going to estimate the number of users suitable for the server, of course you can change this by yourself
	bc=`which bc`
	if [ -a "$bc" ] ; then
		maxusers=`echo "(($totram * 0.75) / 100)" | bc`
	else
		maxusers="unknown"
	fi

	step=0
	ans=""
		until [ "$step" == 1 ] ; do
			conclear
			echo "How many concurrent players should be allowed on the server (recommendation based on system performance: $maxusers)"
			read ans
			dbgPrint "$ans"
			if [ "$ans" == [0-9]* ] ; then
				maxplayers="$ans"
				step1=1
			else
				step1=0
			fi
		done
	
	
	
	server=""
	
	# Adding server.properties manually so that we can predefine some values,
	# also fetches the server-version

	
	
	if [ "$serverversion" == "bukkit" ] ; then
		# download the latest recommended version of bukkit
		wget -nv -O craftbukkit.jar http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-0.0.1-SNAPSHOT.jar
		server="java -Xmx1024M -Xms1024M -jar craftbukkit.jar"
cat > server.properties <<PROPS
#Minecraft server properties
#Wed Sep 14 14:33:18 CEST 2011
#Created with minecraft-installer, by devvis
level-name=world
allow-nether=$allownether
view-distance=$viewdistance
spawn-monsters=$spawnmonsters
online-mode=$onlinemode
difficulty=$difficulty
gamemode=$gamemode
spawn-animals=$spawnanimals
max-players=$maxplayers
server-ip=$serverip
pvp=$pvp
level-seed=$levelseed
server-port=$serverport
allow-flight=$allowflight
white-list=$whitelist
motd=$motd
PROPS

	else
		# download the lates vanilla minecraft-server
		wget -nv -O minecraft_server.jar https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar
		server="java -Xmx1024M -Xms1024M -jar minecraft_server.jar nogui";
	fi
	
cat > server-watch.sh <<SCRIPT
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

server="$server"

############################################################################
## DO NOT EDIT ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING ##
############################################################################
ver="1.0"


echo "serverscript v$ver by devvis started"
echo "Running on \`uname -o\`"

until \$server; do
echo "Minecraft-server crasched with error-code \$?. Restarting..." >&2
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
