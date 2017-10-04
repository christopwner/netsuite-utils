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

blank="This page is intentionally left blank"

for f in $1/*.pdf; do
    text=$(ps2ascii $f | sed 's/[\x0\f]//g' -)
    text=${text##*Page 1 of 3}
    text=${text%%Page 2 of 3*}
    text=$(echo $text | tr -d '\n')
    if [ "$text" != "$blank" ]; then
        echo $f
    fi
done
