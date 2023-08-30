#!/bin/bash

#declare variable to accept file directory as input
#dpath=$1
dpath=($@)
echo ${#dpath[*]} #to know the size of the array
num=${#dpath[*]}-1
#echo $dpath

prypath=$(pwd)
echo $prypath

#option=(a d)
#read -p "Sorting option: a or d"$'\n' useroption
#index=0
#for i in "${!option[@]}"; do
#	[[ "${option[$i]}" = "${useroption}" ]]
#       	echo $i
#	break
#done
#echo $option
#	if ("${option[$i]}"="${useroption}")
#	then
#		index=$i
#		break
#	fi
#done
#echo $index
#for (i=1; i<=num; i++);

#echo Do you want options for sorting? a or d
read -p 'Do you want options for sorting? a or d'$'\n' useroption

for (( i=0; i<=num; i++)) {
	cd "$prypath/${dpath[$i]}";
	pwd;
	ls -$useroption;
	echo "ls -$useroption";
	if [ "$useroption" == "a" ]; then
		useroption="d"
	elif [ "$useroption" == "d" ]; then
		useroption="a"
	else [[ "$useropton" != 'a' ]] && [[ "$useroption" != 'd' ]]
		echo "You have selected the wrong option"
	fi
}
