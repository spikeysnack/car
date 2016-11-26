#!/bin/bash

# readcar.sh

# this file can be included in other scripts
# but runs main if called from the cmdline

OFS=20  # constant 

# these are required 
# and better be around 
# or your box is broken.

STAT=$(which stat) # get file info
OD=$(which od)     # octal dump outputs bin data in char form 
DD=$(which dd)     # data dump  reads, writes bin files

#catalog is global array
declare -a catalog


# reads the catalog from a car file
read_car_catalog ()
{
    local carfile="${1}"
    local -i carstat
    local -i seekpoint
    local   catsize
    local   tmpfile

    carstat=$(${STAT} --format %s  "${carfile}") # size in bytes
    seekpoint=$((carstat - OFS))

    # od outputs '\n' as 'nl'
    catsize=$( ${OD} -An -a --skip-bytes=$((seekpoint)) --read-bytes=$((OFS))  "${carfile}" )
    catsize=${catsize%nl*}   
    catsize=${catsize#*nl}
    catsize=${catsize//[[:blank:]]/}

    seekpoint=$((carstat - (catsize + ${#catsize}) ))

    #   printf "%lu\n" $seekpoint
    #   printf "%lu\n" $catsize
    printf -v catsize "%lu\n" $catsize

    tmpfile=$(mktemp)

    #   printf "%s\n" $tmpfile

    # extract catalog to tmp file in /tmp/tmp.{random}
    ddresult=$( ${DD} if=${carfile} of=${tmpfile} ibs=1 skip=${seekpoint} count=${catsize} 2>&1 )

    [[ $DEBUG_DD ]] && printf "DEBUG_DD:\ %s\n" "${dderesult}" >&2 
 
    # import catalog into array by line from tmpfile
    OLDIFS=${IFS}; IFS=$'\n' 
    mapfile -t catalog < "${tmpfile}"
    IFS=$OLDIFS
}



#
main ()
{
    carfile="${1}"
    read_car_catalog "${carfile}" ${catalog}
    for entry in "${catalog[@]}"
    do
	printf "entry:\t%s\n" "${entry}"
    done
}


# if called as a program 
if [ "${0}" == "readcar.sh" ] ; then
    main "${1}"    
fi

#end

























