#!/bin/bash

# strip parens
in_parens ()
{
    str=${1#*\(}
    str=${str%%\)*}

    printf "%s" "${str}"

}


f=$(in_parens "This is a [(dog)] in parens and nothing else.")

printf "%s\n" "${f}"
