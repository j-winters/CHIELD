#!/bin/bash
# Compile the database from the Github repository and deploy
# to a location on the server (set in deploy_config.sh)
# This will probably need to run with sudo access
# Options:
# --nocompile   Don't run the R script that compiles the SQL database
# --nodelete    Don't delete the 
# --nolocalcoyping  Don't copy files to the local directory.  
#                   This means that the local git repository won't be changed


# Default path to python (overwritten in deploy_config.sh)
path_to_python="python"

source deploy_config.sh


# Set parameters
compile=true
remove_public_files_first=true
copy_local_files=true

while test $# -gt 0
do
	case "$1" in 
		--nocompile) compile=false
	;;
		--nodelete) remove_public_files_first=false
	;;
	    --nolocalcoyping) copy_local_files=false
esac
shift
done

if [ -z "$server_public_folder" ]
then
	echo "Required variables were not set. Check deploy_config.sh."
	exit 1
fi

# Re-create the database from the tree structure

if [ "$compile" = true ]
then
	#echo "Skipping database compilation ..."
	cd processing
	R -f TreeToDatabase.R
	cd ..
fi

# Copy the sqlite database and downloadable csv files to the local app:
cp -R data/db/* app/data/db/

echo "Zipping publicly downloadable files ..."
# Zip the downloadable csv files to the downloads folder
# in the public folder of the local app:
zip app/Site/downloads/CHIELD_csv.zip data/db/*.csv

# Zip the sqlite database and add to downloads
zip app/Site/downloads/CHIELD.zip data/db/CHIELD.sqlite

if [ "${remove_public_files_first}" = true ]
then
	echo "Deleting existing public files ..."
	rm -R ${server_public_folder}*
fi

if [ "$copy_local_files" = true ]
then
	echo "Copying local files to server folder ..."
	# Copy the local app public folder to the server public folder:
	cp -R app/Site/* $server_public_folder

	# Copy the local app private folder to the server private folder:
	cp -R app/data/* $server_private_folder

	# Set the right permissions
	chown _www ${server_private_folder}newRecords
	chown _www ${server_private_folder}processedRecords

	# sudo chmod 755 *.php
fi

# Need to update the python path for php to work
sed -i "" -e "s#path_to_python#${path_to_python}#g" ${server_public_folder}php/sendNewRecord.php