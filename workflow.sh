# requirements: https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac
# Folder Action for macOS to wrap pkg to intunemac automaticly.
# Michael Rieder 2021 

# Get the directory path from filename
DIR="$(dirname "${1}")" ;
mkdir -p "${DIR}/intunemac"
mkdir -p "${DIR}/source_packages"
mkdir -p "${DIR}/source_failed"


OIFS="$IFS"
IFS=$'\n'
for PKGFILES in $(ls  ${DIR}/*.pkg)
	do
	echo "Convert file: ${PKGFILES}" >>/tmp/IntuneAppUtil.log
	FILETYPEDIAG=$(/usr/bin/file $PKGFILES)
	if [[ $FILETYPEDIAG == *"xar archive"* ]]; then
		echo "Start wrapper for package.."  >>/tmp/IntuneAppUtil.log

		# Start Wrapping tool and save output in the same directory as the source.
		/usr/local/bin/IntuneAppUtil -c "${PKGFILES}" -o "${DIR}/intunemac/" -v >>/tmp/IntuneAppUtil.log
		if [[ $? -eq 0 ]]; then
			mv "${PKGFILES}" "${DIR}/source_packages/"
		else
			echo "***** ERRROR on processing file $1" >>/tmp/IntuneAppUtil.log
			mv "${PKGFILES}" "${DIR}/source_failed/"
		fi

	else 
		echo "***** ERRROR unknown package format $PKGFILES" >>/tmp/IntuneAppUtil.log
	fi

done
IFS="$OIFS"

