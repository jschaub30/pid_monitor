#!/bin/bash
[[ $# -ne 1 ]] && echo Usage: $0 [CSV_FN] && exit -1

CSV_FN=$1

echo "<table>"
cat $CSV_FN | \
    sed -e 's/^/<tr><td>/' -e 's/,/<\/td><td>/g' -e 's/$/<\/td><\/tr>/'
echo "</table>"

