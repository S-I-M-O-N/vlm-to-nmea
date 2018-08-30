#!/bin/bash
#
# Bash script to feed postion information from Virtual Loup de Mer via NMEA to other applications via UDP.
#
# depends on jq bc
#
# by S-I-M-O-N
#
# See https://github.com/S-I-M-O-N/vlm-to-nmea for last version
# 
# LICENSE GPL3
#
# NMEA CRC Routine taken from 
# https://unix.stackexchange.com/questions/311765/way-to-eliminate-external-commands-from-scriptfor-generating-nmea-0183-xor-check 
#
# THANK YOU!
#

LC_ALL=C;

USERNAME="USER@DOMAIN.ORG";
USERPW='PASSWORD';
USERID=12345;
SERVER="https://v-l-m.org/ws/boatinfo.php?forcefmt=json&select_idu=$USERID";
HOST="127.0.0.1";
PORT="10110";
LOG="/dev/null"; #may be set to a filename for logging of wget output

echo "Script running - Terminate with CTRL-C";

while true

do
 wget --user=$USERNAME --password=$USERPW $SERVER -O boatinfo.php.json -o $LOG;

 LAT=$(jq ".LAT" boatinfo.php.json);
 LON=$(jq ".LON" boatinfo.php.json);
 SOG=$(jq ".BSP" boatinfo.php.json);
 CMG=$(jq ".HDG" boatinfo.php.json);
 LUP=$(jq ".LUP" boatinfo.php.json | sed 's/"//g');
 VAC=$(jq ".VAC" boatinfo.php.json);
 DOF=$(date -u --date=@$LUP +%d%m%y);
 TOF=$(date -u --date=@$LUP +%H%M%S);

 SOG=$(printf '%05.1f' $SOG);
 CMG=$(echo $CMG | sed 's/"//g');
 SOG=$(printf '%06.1f' $SOG);
 CMG=$(printf '%05.1f' $CMG);


 NoS=$(echo $LAT |cut -c1);

 if test "$NoS" = "-"
 then
	NoS=S;
 else
	NoS=N;
 fi

 EoW=$(echo $LON |cut -c1);

 if test "$EoW" = "-"
 then
	EoW=W;
 else
	EoW=E;
 fi

 LATDEG=$(echo $LAT |sed 's/-//g' |cut -d "." -f1);
 LATABS=$(echo $LAT |sed 's/-//g' );
 LATDEG=$(echo $LATDEG/1000 | bc );
 LATDEGM=$(echo $LATDEG*1000 | bc);
 LATMIN=$(echo $LATABS-$LATDEGM | bc );
 LATMIN=$(echo $LATMIN*0.06 |bc );
 LATMIN=$(printf '%06.3f' $LATMIN);
 LATDEG=$(printf '%02.0f' $LATDEG);

 LONDEG=$(echo $LON |sed 's/-//g' |cut -d "." -f1);
 LONDEG=$(echo $LONDEG/1000 | bc);
 LONABS=$(echo $LON |sed 's/-//g' );
 LONDEGM=$(echo $LONDEG*1000 | bc);
 LONMIN=$(echo $LONABS-$LONDEGM | bc );
 LONMIN=$(echo $LONMIN*0.06 |bc );
 LONMIN=$(printf '%06.3f' $LONMIN);
 LONDEG=$(printf '%03.0f' $LONDEG);

 SENTENCE="\$GPRMC,$TOF.000,A,$LATDEG$LATMIN,$NoS,$LONDEG$LONMIN,$EoW,$SOG,$CMG,$DOF,000.0,W*";
 TAIL="${SENTENCE##*$}"
 HEAD=${TAIL%\**}
 LEN=${#HEAD} 
 XOR=0
 for (( x=0; x<$LEN; x++ )); do
      (( XOR^=$(printf '%d' "'${HEAD:$x:1}'") ))
 done
 CRC=$(printf '%02X\n' "${XOR}");

 echo \$GPRMC,$TOF.000,A,$LATDEG$LATMIN,$NoS,$LONDEG$LONMIN,$EoW,$SOG,$CMG,$DOF,000.0,W*$CRC | nc -u -q1 $HOST $PORT;
 echo \$GPRMC,$TOF.000,A,$LATDEG$LATMIN,$NoS,$LONDEG$LONMIN,$EoW,$SOG,$CMG,$DOF,000.0,W*$CRC | nc -u -q1 $HOST $PORT;
 echo \$GPRMC,$TOF.000,A,$LATDEG$LATMIN,$NoS,$LONDEG$LONMIN,$EoW,$SOG,$CMG,$DOF,000.0,W*$CRC | nc -u -q1 $HOST $PORT;

 sleep "$VAC""s";

done

return 0;
