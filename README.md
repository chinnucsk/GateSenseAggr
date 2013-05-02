GateSenseAggr
=============

Hacker Days

How to get started
------------------

After cloning the repo, run

    make deps
    make

(If you get a "cannot find pam_appl.h", install libpam0g-dev (for Ubuntu).)

To run the server:

    make rel
    make node-console

then access [http://localhost:8080/aggrsense]

Good luck! :-)

Code Map
--------

REST dispatcher::
     lib/aggrsense/src/aggrsense_appmod.erl


Bibliography
------------

CKAN API::
    [http://docs.ckan.org/en/latest/api.html]

COSM REST API::
    [http://cosm.com/docs/quickstart/curl.html]
