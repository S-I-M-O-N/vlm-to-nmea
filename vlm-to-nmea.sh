#!/bin/sh
#depends on jq

LC_ALL=C;

USERNAME="USER@DOMAIN.ORG";
USERPW='PASSWORD';
USERID=12345;
SERVER="https://v-l-m.org/ws/boatinfo.php?forcefmt=json&select_idu=$USERID";
HOST="127.0.0.1";
PORT="10110";

#exec 3<>/dev/udp/"$HOST""/""$PORT"

while true

do

#wget --user=$USERNAME --password=$USERPW $SERVER -O boatinfo.php.json;

LAT=$(jq ".LAT" boatinfo.php.json);
LON=$(jq ".LON" boatinfo.php.json);
SOG=$(jq ".BSP" boatinfo.php.json);
CMG=$(jq ".HDG" boatinfo.php.json);
NOW=$(jq ".NOW" boatinfo.php.json);
VAC=$(jq ".VAC" boatinfo.php.json);
VAC=10;
DOF=$(date -u --date=@$NOW +%d%m%y);
TOF=$(date -u --date=@$NOW +%H%M%S);

SOG=$(printf '%05.1f' $SOG);
CMG=$(echo $CMG | sed 's/"//g');
SOG=$(printf '%05.1f' $SOG);
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
LATMIN=$(printf '%05.2f' $LATMIN);
LATDEG=$(printf '%02.0f' $LATDEG);

LONDEG=$(echo $LON |sed 's/-//g' |cut -d "." -f1);
LONDEG=$(echo $LONDEG/1000 | bc);
LONABS=$(echo $LON |sed 's/-//g' );
LONDEGM=$(echo $LONDEG*1000 | bc);
LONMIN=$(echo $LONABS-$LONDEGM | bc );
LONMIN=$(echo $LONMIN*0.06 |bc );
LONMIN=$(printf '%05.2f' $LONMIN);
LONDEG=$(printf '%03.0f' $LONDEG);

CRC=62;

echo \$GPRMC,$TOF,A,$LATDEG$LATMIN,$NoS,$LONDEG$LONMIN,$EoW,$SOG,$CMG,$DOF,000.0,E*$CRC | nc -u -q2 $HOST $PORT;

sleep "$VAC""s";

done

return 0;
