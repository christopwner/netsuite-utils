#!/bin/bash

# Copyright (C) 2017 Christopher Towner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Utility script for verifying invoices (pdf) billto info isn't pushed into second page.

# check dir given
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dir>"; exit 1;
fi

pattern="^\s*This page is intentionally left blank*"

for f in $1/*.pdf; do
    pdfseparate -f 2 -l 2 "${f}" /tmp/partial-invoice.pdf 2>/dev/null || continue
    if ! [[ $(ps2ascii /tmp/partial-invoice.pdf) =~ ${pattern} ]]; then
        echo $f
    else
        echo -n .
    fi
    
done
