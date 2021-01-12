#!/bin/bash
####tvstream_dockerExec.sh

#### Remove sap config file
printf "\nCurrent Task: Removing sap config file.\n"
rm -rf /config/sap.cfg

#### Create SAP config file.
printf "\nCurrent Task: Create /config/sap.cfg\n"
for f in "/config/$FREQUENCY.cfg"; do
  while IFS="# :" read -r multicastAddress port KeepAlive subChannel channelName channelNamePart2
  do
	#printf " $multicastAddress:$port\t$channelName $channelNamePart2\n"
	printf '[program]\n' >> /config/sap.cfg
	printf "type=rtp\n" >> /config/sap.cfg
	printf "name=$channelName $channelNamePart2\n" >> /config/sap.cfg
	printf "user=$NAME\n" >> /config/sap.cfg
	printf "machine=$(hostname)\n" >> /config/sap.cfg
	printf "site=$SITENAME\n" >> /config/sap.cfg
	printf "address=$multicastAddress\n" >> /config/sap.cfg
	printf "port=$port\n\n\n" >> /config/sap.cfg
  done < /config/$FREQUENCY.cfg
done

#### Run sapserver
printf "\nCurrent Task: Run sapserver\n"
screen -dm -S sap
screen -S sap -X stuff "sapserver -c /config/sap.cfg\n"
##############
##############
printf "\nCurrent Task: Starting multicast streams.\n"
#command="dvblast -a $ADAPTERNUMBER -f $FREQUENCY -b 6 -c /config/$FREQUENCY.cfg -m VSB_8 -e --delsys ATSC"
#$command
dvblast -a $ADAPTERNUMBER -f $FREQUENCY -b 6 -c /config/$FREQUENCY.cfg -m VSB_8 -e --delsys $DELIVERY
##############
