#!/bin/bash

dpath=($@)
echo ${#dpath[*]} 'is the size of the array'
num=${#dpath[*]}-1

prypath=$(pwd)
pwd

read -p 'Select your options for sorting? a or d'$'\n' useroption

while [[ "$useroption" != "a" ]] && [[ "$useroption" != "d" ]]
do {
	read -p 'You have selected the wrong option'$'\n''choose between a or d'$'\n' useroption
} 
done

for (( i=0; i<=num; i++)) {
	cd "$prypath/${dpath[$i]}";
	pwd;
	ls -$useroption;
	echo "ls -$useroption";
	if [ "$useroption" == "a" ]; then
		useroption="d"
	else [ "$useroption" == "d" ]
		useroption="a"
	fi
}

