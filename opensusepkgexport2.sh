#!/bin/sh
###############################################
#  Derek Demuro - OpenSUSE Packages Export    #
###############################################

# Absolute path to de zypper repositories lists.
readonly reposPath='/etc/zypp/repos.d/'

echo 'Welcome to Package Automation V1.1'

echo 'Enter 1 to do a full package export with package details'
echo 'Enter 2 to do a exportable package export, to install in another system'
echo 'Enter 3 to install a exported package list in another system'
echo 'Enter 4 to export your repos'
echo 'Enter 5 to import your repos'
echo 'Enter 6 to differ two sources files'
echo 'Enter 7 to quit'

PS3='Please enter your choice: '
options=("1" "2" "3" "4" "5" "6" "7")
select opt in "${options[@]}"
do
    case $opt in
        "1")
		echo "You chose 1, we'll do a full package export with description"
		echo 'What name would you like us to use to save the output?'
		read fname
		#Package name: Version : Release : Version Installed
		#Package Ej: yast2-trans-zh_CN:2.22.0:8.7.1:1346256812:YaST2 - Simplified Chinese Translations
		rpm -qa --qf '%{NAME}:%{VERSION}:%{RELEASE}:%{INSTALLTID}:%{SUMMARY}\n' | sort >> $fname
            ;;
        "2")
		echo "You chose 2, we'll do an installable version"
		echo 'What name would you like us to use to save the output?'
		read name
		#For installable version
		rpm -qa --qf '%{NAME}\n' | sort >> $name
            ;;
        "3")
		echo "You chose 3, we'll install all the packages in the file."
		echo 'Select 0 to install everything without confirmation, 1 for confirmation'

		read conf

		if [ $conf -eq 0 ]
		then
			conf=0
		else
			conf=1
		fi

		#Do you want to update your repository list
		echo "If you want to update your package list press 1"
		read update
		if [ $update -eq 1 ]
		then
			zypper ref
		fi

		echo 'Please type the name of the file that contains the package list'
		read FILENAME
		
		rpm -qa --qf '%{NAME}\n' | sort > old.txt
		
		diff -Naur old.txt $FILENAME | grep '^+' | sed s/+//g | tail -n +2 > differencesToInstall.txt
		
		FILENAME=differencesToInstall.txt
		
			#Loop untill file provided is okay.
			until [  -f $FILENAME ]; do
				if [ -f $FILENAME ]
				then
					echo 'File seems to be fine'
				else
					echo 'Whoops file doesnt seem to exists, please introduce it again'
					echo 'Please type the name of the file that contains the package list'
					read FILENAME
				fi
			done

		count=0
		#Count how many lines, and start installing
		cat $FILENAME | while read LINE
		do
			let count++
			echo "$count $LINE"
			#Zypper -With no output
			if [ $conf = 0 ]
			then
				#NO CONFIRMATION OR MESSAGES				
				zypper --non-interactive install $LINE
			else
				#NORMAL INSTALL
				zypper install $LINE
			fi
		done

		echo -e "\nTotal $count Lines read"
		rm $FILENAME;
            ;;
        "4")
		echo "You chose 4, we'll backup your sources list located at /etc/zypp/repos.d/."
		echo 'Input the full path of the folder where you want them copied'
		read dirtree
		cp /etc/zypp/repos.d/* $dirtree
		
		repoammount=`ls /etc/zypp/repos.d | wc -w`
		copiedamm=`ls $dirtree | wc -w`
		echo 'You had: ' $repoammount 'sources, and we copied: ' $copiedamm
		if [ $repoammount -eq $copiedamm ]
		then
			echo 'Everything seems to be copied'
		else
			echo 'Whoops, seems something is missing'
		fi
	;;
	
	"5")    
	    ########################################################################################
	    # IMPORT THE SOURCES LIST                                                              #
	    ########################################################################################
	    cpCount=0
	
	    echo 'Enter the absolute path to the directory containing the .repo files you wish to import.'
	    read srcDir
	    
	    # Make sure there isn't a trailing slash on the path variable.
	    echo $srcDir | egrep '.+\/$' >/dev/null
	    
	    if [ $? -eq 0 ]
	    then
		# Remove the trailing slash.
	    srcDir=`echo "${srcDir%/}"`
	    fi

	    srcFilesCount=`ls "$srcDir"/*.repo | wc -w`
	    srcFilesList=`echo "$srcDir"/*.repo`
	    
	    for i in $srcFilesList
	    do
		cp $i $reposPath
		if [ $? -ne 0 ]
		then
		    echo "Something went wrong while copying the following file: $i :("
		    break
		fi
		$(( $cpCount++ ))
	    done        
	
	    echo "We had $srcFilesCount files to copy, and we were able to copy $cpCount files."        
	    ;;
	"6")
	    ########################################################################################
	    # COMPRARE TWO SOURCES FILES                                                           #
	    ########################################################################################
	    echo 'Type sources file 1'
	    read sources1
	    echo 'Type sources file 2'
	    read sources2
	    echo 'Type output file name'
	    read filename
	    # diff -u $sources1 $sources2 > $filename
	    diff -Naur $sources1 $sources2 | grep '^+' | sed s/+//g | tail -n +2 > $filename
	    ;;
	        
        "7")
            break
            ;;
        *)
            echo 'Invalid option.'
            ;;
    esac
done
