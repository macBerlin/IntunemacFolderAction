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
		PACKAGENAME=$(basename "${PKGFILES}") 
		if [[ -f "${DIR}/intunemac/${PACKAGENAME}.intunemac" ]]; then  
	            tstamp=$(date +%s)
			echo "***** Destiantion file exist $PACKAGENAME" >>/tmp/IntuneAppUtil.log
		    mv "${DIR}/intunemac/${PACKAGENAME}.intunemac" "${DIR}/intunemac/${PACKAGENAME}.intunemac.${tstamp}"
		fi	
		/usr/local/bin/IntuneAppUtil -c "${PKGFILES}" -o "${DIR}/intunemac" -v >>/tmp/IntuneAppUtil.log
		if [[ $? -eq 0 ]]; then
			mv "${PKGFILES}" "${DIR}/source_packages/"
		
			unzip "${DIR}/intunemac/${PACKAGENAME}.intunemac" -d /tmp/
			#cp /tmp/IntuneMacPackage/Metadata/Detection.xml /tmp/IntuneMacPackage/Metadata/Detection2.xml
			MACOSLOBAPP=$(cat /tmp/IntuneMacPackage/Metadata/Detection.xml | grep "MacOSLobApp")			PKGNAME=$(echo $MACOSLOBAPP | awk -F" " {'print $3'})
			BUNDLEID=$(echo $MACOSLOBAPP | awk -F" " {'print $4'})
			BUILDNUMBER=$(echo $MACOSLOBAPP | awk -F" " {'print $5'} | awk -F "\"" {'print $2'})

			MACOSLOBCHILD=$(cat /tmp/IntuneMacPackage/Metadata/Detection.xml |grep -i "MacOSLobChildApp" | grep -i "${BUNDLEID}")
			BUNDLEID_CHILD=$(echo $MACOSLOBCHILD | awk -F" " {'print $2'})
			BUILDNUMBER_CHILD=$(echo $MACOSLOBCHILD | awk -F" " {'print $3'} | awk -F "\"" {'print $2'})
			VERNUMBER_CHILD=$(echo $MACOSLOBCHILD | awk -F" " {'print $3'})

			
			if [ -z "$MACOSLOBCHILD" ]
			then
      			echo "**** The master BUNDLEID does not match the childs.. generate new child"  >>/tmp/IntuneAppUtil.log
				MACOSLOBCHILD=$(echo "<MacOSLobChildApp ${BUNDLEID} BuildNumber=\"${BUILDNUMBER}\" VersionNumber=\"${BUILDNUMBER}\"/>")
				print $MACOSLOBCHILD
			else
				## be sure build number match
				echo "MACOSLOBCHILD before AWK: $MACOSLOBCHILD"  >>/tmp/IntuneAppUtil.log
				MACOSLOBCHILD=$(echo ${MACOSLOBCHILD} | awk -v cuv1=${BUILDNUMBER_CHILD} -v cuv2=${BUILDNUMBER} '{gsub(cuv1,cuv2); print;}')
				echo "ELEMENT: MACOSLOBCHILD: $MACOSLOBCHILD"  >>/tmp/IntuneAppUtil.log	
			fi



			sed -i '' '/MacOSLobChildApp/d' /tmp/IntuneMacPackage/Metadata/Detection.xml			
			sleep 0.5
			sed -i '' "s|<\/MD5Hash>.*|<\/MD5Hash>\\r${MACOSLOBCHILD}|" /tmp/IntuneMacPackage/Metadata/Detection.xml
			sleep 0.5

			mv "${DIR}/intunemac/${PACKAGENAME}.intunemac" "${DIR}/intunemac/${PACKAGENAME}.intunemac.unprepared"
			cd /tmp/
			zip -q --symlinks -0 -r "${DIR}/intunemac/${PACKAGENAME}.intunemac" IntuneMacPackage
	
			#cleanup
			rm -rf /tmp/IntuneMacPackage

		else
			echo "***** ERRROR on processing file $1" >>/tmp/IntuneAppUtil.log
			mv "${PKGFILES}" "${DIR}/source_failed/"
		fi
		
	else 
		echo "***** ERRROR unknown package format $PKGFILES" >>/tmp/IntuneAppUtil.log
	fi

done
IFS="$OIFS"

