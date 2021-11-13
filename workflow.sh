FILETYPEDIAG=$(/usr/bin/file $1)


## We run only if the the file contains a xar archive

if [[ $FILETYPEDIAG == *"xar archive"* ]]; then
	
	# Get the directory path from filename
	DIR="$(dirname "${1}")" ;
	
	# Start Wrapping tool and save output in the same directory as the source.
	/usr/local/bin/IntuneAppUtil -c "${1}"  -o "${DIR}" -v >>/tmp/IntuneAppUtil.log
	
	# If the exit code is equal 0 the process is complete. 
	if [[ $? -eq 0 ]]; then
		mv "${1}" "${DIR}/Archive/"
	else
		echo "***** ERRROR on processing file $1" >>/tmp/IntuneAppUtil.log
	fi

else 
	echo "***** ERRROR unknown package format $1" >>/tmp/IntuneAppUtil.log
fi







