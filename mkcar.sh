#!/bin/bash


#    catalog["${f}"]="NAME(${filename}):SIZE(${filesize}):MIMETYPE(${filemtype}):${filehash}"


VERBOSE=

usage ()
{
    out=${2:-2}
    usage="usage:bash mkcar.sh  <archive.car> <file1, file2,... >"
    >&"${out}" printf "usage:\n\t%s\n" "${usage}"  
}

# don't automatically overwrite files
check_overwrite()
{
    read -p "overwrite existing file ${1} ? [Y]" do_overwrite

    do_overwrite="${do_overwrite:-yes}"

    do_overwrite="${do_overwrite,,}"    # tolower

    if [[ $do_overwrite =~ ^(yes|y)$ ]] ; then
        return 1
     else
        return 0
    fi
}

# generate a hash for the file
# ex:  MD5SUM(9873945249A45434)
fhash ()
{
    # CHOOSE ONE
    fcheck="md5sum -b" ; hash_type="MD5SUM"
#    fcheck="sha1sum -b" ; hash_type="SHA1SUM"
    #fcheck="cfv -C "    ; hash_type="CFV"

    f_hash=$( ${fcheck} "${1}" | cut -d ' ' -f1)    

    printf "%s(%s)" "${hash_type}" "${f_hash}" 
}



check_args ()
{
    #check for bad cmdlines
    ext="${1##*.}" 

    [[ "${1}" == "help"  ]]  &&  echo "mkcar help"                 &&  usage 1  && exit

    [[ "${ext}" != "car" ]]  &&  echo "extension needs to be .car" &&  usage 2  && exit

    [[ ${#} -lt 2        ]]  &&  echo "too few file arguments"     &&  usage 2  && exit

    [[  -f "${1}"        ]]  &&  ow=$(check_overwrite "${1}") && [[ ow -eq 0 ]] && exit

}




# start making a car and a catalog
# use ":" as a delimiter

declare -a catalog

carfile="${1}"

check_args "${@}"

shift

files=( "${@}" )                 

i=0

for f in "${files[@]}"
do

    if [ -f "${f}" ]; then

	cat "${f}" >> "${carfile}"  # append files 

	if [[ $VERBOSE ]] ; then  >&2 printf "%s ==> %s\n" "${f}" "${carfile}" ; fi

    fi
    
    # generate catalog info
    filename="${f}"

    filesize=$(stat  --format "%s"   "${f}" ) # name, size

    filemtype=$(file --brief -i "${f}" ) # mimetype

    filehash=$(fhash "${f}") # hash

    catalog[$i]="NAME(${filename}):SIZE(${filesize}):MIMETYPE(${filemtype}):${filehash}"

    if [[ $VERBOSE ]] ; then  >&2 printf "%s ::> [ %s ]\n" "${f}" "${catalog[$i]}" ; fi
    ((i++))
done




# creat catalog file in /tmp/tmp.<random>
tmp_catalog=$(mktemp)

for ((j=0; j < $i ; j++))
do
    echo "${catalog[$j]}" >> "${tmp_catalog}"
    if [[ $VERBOSE ]] ; then  >&2 printf "%s ==> %s\n" "${catalog[$j]}" "${tmp_catalog}"; fi
done


# attach catalog to car file
offset=$(stat  --format "%s"   "${tmp_catalog}" )

cat "${tmp_catalog}" >> "${carfile}"

echo "${offset}" >> "${carfile}"

if [[ $VERBOSE ]] ; then printf "catalog size %lu ==> %s\n" "${offset}" "${carfile}" >&2 ; fi

# end
