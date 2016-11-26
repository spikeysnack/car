#!/bin/bash
# get source includes
DIR="${BASH_SOURCE%/*}"

if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

. "$DIR/readcar.sh" # carfile



extract_file ()
{
    carfile="${1}"
    outfile="${2}"
    offset="${3}"
    size="${4}"
    
    printf "%s %s ..." "unchunking" "${carfile}"
    result=$( ./chunker "${carfile}" "${outfile}" "${offset}" "${size}" )
    if [ $? -eq 0 ] ; then 
	printf "OK\n"
    else
	printf "CHUNKER ERROR [%s]\n" "${result}"
    fi
}



# strip parens
in_parens ()
{
    str=${1#*\(}
    str=${str%%\)*}
    printf "%s" "${str}"
}




main ()
{
    OFS=20
    carfile="${1}"
    out_dir="${2}"

    declare -a catalog
    declare -a catentry
    declare -a offsets
    declare -A CAR_DATA

    read_car_catalog "${carfile}"  catalog

    let "i=0"
    offsets[$i]=0 # first offset

    for entry in "${catalog[@]}"
    do
	OLDIFS=$IFS ; IFS=$':'

	catentry=( ${entry} ) # split on :
	
	for D in ${catentry[@]}
	do

	    [[ "${D}" =~ "NAME(" ]]     &&       CAR_DATA["name"]=$(in_parens "${D}" "NAME") 
	    [[ "${D}" =~ "SIZE(" ]]     &&       CAR_DATA["size"]=$(in_parens "${D}" "SIZE") 
	    [[ "${D}" =~ "MIMETYPE(" ]] &&       CAR_DATA["mimetype"]=$(in_parens "${D}" "MIMETYPE") 
	    [[ "${D}" =~ "MD5SUM(" ]]   &&       CAR_DATA["md5sum"]=$(in_parens "${D}" "MD5SUM")

	done # for D

	    offset=$(( ${CAR_DATA["size"]} ))
	    ((i++))
	    offsets[$i]=$(( offsets[$i-1] + offset )) 
	    CAR_DATA["offset"]=${offsets[$i-1]}


	if [[ ${CAR_DATA["name"]} ]] ; then 
	    printf "%s:\t%s\n" "name"     ${CAR_DATA["name"]}
	    printf "%s:\t%s\n" "size"     ${CAR_DATA["size"]}
	    printf "%s:\t%s\n" "mimetype" ${CAR_DATA["mimetype"]}
	    printf "%s:\t%s\n" "offset"   ${CAR_DATA["offset"]}
	    printf "\n"

	    if [[ ${CAR_DATA["name"]} && ${CAR_DATA["offset"]} && ${CAR_DATA["size"]} ]]; then

		extract_file "${carfile}" ${CAR_DATA["name"]} "${CAR_DATA["offset"]}"  ${CAR_DATA["size"]}
	    fi

	  else

	    printf "entry:\t %s \n" "${entry}"

	fi
	
	if [[ ${out_dir} ]] ; then
	    mkdir -p "${out_dir}"
	    mv "${CAR_DATA["name"]}" "${out_dir}"
	fi


    done #for entry
} # main



if [ "${0}" == "uncar.sh" ]; then main "${@}"; fi


#END
