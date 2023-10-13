HOW TO RUN THE SCRIPTS

HOW TO USE THIS FILE:

Follow each step and do not skip any. Note that where there is a $ symbol before a text know that it is a command and you should run it.



STEP 1: you must be in a major directory either downloads, documents or music

$ cd Documents


STEP 2: creating a new directory that holds scripts

$ mkdir vms


STEP 3: copy the command.sh and vagrant.sh script into the vms directory

you can do this in 2 ways:
 1 - copying the msfinal.sh file after downloading into the vms directory using your file manager
 2 - copying the file through git bash


STEP 4: making sure the scripts are executable

$ chmod +x msfinal.sh


STEP 5: running the script

you only need to run 1 of the script which is the vagrant.sh once that runs it will automatically run the command.sh script once done:

$ ./vagrant.sh

STEP 6: wait until everything runs till the end

NOTE: make sure you have a very strong internet connection 


STEP 7: login to the master 

the command can only work when you are in the exact same directory where the command.sh, vagrant.sh and vagrantfile is present:

$ vagrant ssh master 

once the script is done running login to the master and there are 3 things you need to check to be present

    1) altschool user - 

    $ sudo su - altschool

    2) running process - a file named running_processes is to be present in the home directory:

    $ ls -al 

    3) altschool key - a file names altschool key is also needed to be present in the home directory and should contain the public key of the altschool user:

    $ ls -al

once this runs come back to step 7 and check if all the important things are present


STEP 8: login to the slave

the command can only work when you are in the exact same directory where the msfinal.sh and vagrantfile is present:

if you are still in the master machine you will need to exit:

$ exit

login to slave:

$ vagrant ssh slave

now that you are in slave machine there are 3 things you will need to check for to be present:

    1) altschool user ssh-key - there should be an ssh-key ending with altschool@master in the output of:

    $ cat ~/.ssh/authorized_keys

    2) vagrant user ssh-key - there should also be an ssh-key ending with root@master in the output of this command:

    $ cat ~/.ssh/authorized_keys

    3) mnt file - there should be a file named mnt in the home directory of the slave this file should have a sub directory:

    $ ls -al


STEP 9: making sure LAMP stack is present

we need to make sure the whole lamp stack was installed so you can do that by running:

    1) APACHE: there are different ways to check if apache is present use any that suits you:

    - your ip address: you can just take your ip address and paste it in your browser

    - $ systemctl status apache2 

    - $ apache2 --version

    2) PHP: you can run the command below to be sure php is installed

    - $ php --version

    3) MYSQL: you can run the command below to check if mysql is installed

    - $ systemctl status mysql

    you should see a running status
