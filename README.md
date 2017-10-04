# netsuite-utils
Utility scripts for [Netsuite](http://www.netsuite.com/).

Requirements:
* libxml2-utils
* curl

## validate-bundle
Validates all files in a bundle against a local repository. Used for verifying bundled files are latest in versioned repository (such as git) before deployment.

## check-pdf-invoice-billto
Checks that an invoice's billto info hasn't been pushed onto the second page.
