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

# Utility script for validating bundled files are same as local repository.

url="https://webservices.sandbox.netsuite.com/services/NetSuitePort_2017_1"
wsdl="https://webservices.netsuite.com/wsdl/v2017_1_0/netsuite.wsdl"

app=
email=
password=
account=
role=

repo=
dir=/tmp/netsuite

# check bundle id given
if [ $# -ne 1 ]; then
    echo "Usage: $0 <bundle>"; exit 1;
fi

# setup envelope for soap requests
envelop() {
    envelope='
    <soap:Envelope 
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
        xmlns:platformCore="urn:core_2017_1.platform.webservices.netsuite.com"
        xmlns:platformMsgs="urn:messages_2017_1.platform.webservices.netsuite.com"
        xmlns:platformCommon="urn:common_2017_1.platform.webservices.netsuite.com">
        <soap:Header>
            <applicationInfo>
                  <applicationId>'${app}'</applicationId>
             </applicationInfo>
            <passport xsi:type="platformCore:Passport">
                <email>'${email}'</email>
                <password>'${password}'</password>
                <account>'${account}'</account>
                <role internalId="'${role}'"/>
            </passport>
        </soap:Header>
        '${body}'
    </soap:Envelope>
    '
}

# search for folder by bundle id
body='
<soap:Body xmlns:docFileCab="urn:filecabinet_2017_1.documents.webservices.netsuite.com">
    <platformMsgs:search>
        <searchRecord xsi:type="docFileCab:FolderSearch">
            <basic xsi:type="platformCommon:FolderSearchBasic">
                <name operator="contains" xsi:type="platformCore:SearchStringField">
                    <platformCore:searchValue>Bundle '$1'</platformCore:searchValue>
                </name>
            </basic>
        </searchRecord>
    </platformMsgs:search>
</soap:Body>
'
response=$(envelop && curl -s -H "Content-Type: text/xml;charset=UTF-8" -H "SOAPAction:search" -d "$envelope" $url)

# validate count is exactly 1
count=$(echo $response | xmllint --xpath "string(//*[local-name()='totalRecords'])" -)
if [ $count -eq 0 ]; then
    echo "No bundle found!"; exit 1;
fi
if [ $count -ne 1 ]; then
    echo "Found more than one bundle!"; exit 1;
fi

mkdir -p ${dir}/$1

# extract internal id of folder and search for files within
id=$(echo $response | xmllint --xpath "string(//*[local-name()='record']/@internalId)" -)
body='
<soap:Body xmlns:docFileCab="urn:filecabinet_2017_1.documents.webservices.netsuite.com">
    <platformMsgs:search>
        <searchRecord xsi:type="docFileCab:FileSearch">
            <basic xsi:type="platformCommon:FileSearchBasic">
                <folder operator="anyOf" xsi:type="platformCore:SearchMultiSelectField">
                    <platformCore:searchValue internalId="'${id}'"/>
                </folder>
            </basic>
        </searchRecord>
    </platformMsgs:search>
</soap:Body>
'
files=${dir}/$1/files.xml
envelop && curl -o "${files}" -s -H "Content-Type: text/xml;charset=UTF-8" -H "SOAPAction:search" -d "$envelope" $url

# validate count is greater than or equal to 1
count=$(xmllint --xpath "string(//*[local-name()='totalRecords'])" $files)
if [ $count -lt 1 ]; then
    echo "No files found in bundle folder!"; exit 1;
fi

# iterate over files
for (( i = 1; i <= $count; i++)); do
    name=$(xmllint --xpath "string(//*[local-name()='record'][$i]/*[local-name()='name'])" $files)
    url=$(echo $response | xmllint --xpath "string(//*[local-name()='record'][$i]/*[local-name()='url'])" $files)
    curl -s -o "${dir}/$1/$name" "$url"
    sum=$(md5sum ${dir}/$1/$name | sed 's/ .*//')
    echo $sum ${repo}/${name} | md5sum -c -
done
