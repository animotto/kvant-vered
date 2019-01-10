format FORMAT_HELP = 
Kvant Version Editor

Usage:
    -f <file>           File Version
    -h                  This help
.

format FORMAT_TERM_HELP =
COMMAND        PARAMETERS                 DESCRIPTION
-------------  -------------------------  -----------

routes                                    Print routes
cos                                       Print classes of service
acos                                      Print advanced classes of service
stations       NUMBER|FROM-TO             Print stations
help                                      This help
exit                                      Exit
.

format FORMAT_ROUTE_HEADER =
                 [ROUTES]


ROUTE             CCT            DIRECTION
----------------  -------------  ---------

.

format FORMAT_ROUTE =
@<<<<<<<<<<<<<<<  @<<<<<<<<<<<<  @||||||||
$route,$cctdescr,$direction
.

format FORMAT_COS_HEADER =
                 [CLASSES OF SERVICE]


COS  TOL          FAR  OUTBOUND  SPECIAL  CID  TRANSFER
---  -----------  ---  --------  -------  ---  --------

.

format FORMAT_COS =
@<<  @<<<<<<<<<<  @||  @|||||||  @||||||  @||  @|||||||
$cos,$tol,$rfar,$rout,$rspec,$cid,$transfer
.

format FORMAT_ACOS_HEADER =
                     [ADVANCED CLASSES OF SERVICE]


COS  TOL          FAR  OUT  SPEC  CID  TRANS  FORWARD  FWDBUSY  FWDNOANS
---  -----------  ---  ---  ----  ---  -----  -------  -------  --------

.

format FORMAT_ACOS =
@<<  @<<<<<<<<<<  @||  @||  @|||  @||  @||||  @||||||  @||||||  @|||||||
$acos,$tol,$rfar,$rout,$rspec,$cid,$transfer,$forward,$forwbusy,$forwnoans
.

format FORMAT_STATIONS_HEADER =
				[STATIONS]


STATION  COS
-------  ---
.

format FORMAT_STATIONS =
@<<<<<<  @<<
$station,$cos
.

1;
