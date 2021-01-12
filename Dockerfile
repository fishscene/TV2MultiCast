FROM ubuntu:20.04
run apt-get update
run apt-get install software-properties-common -y
run add-apt-repository ppa:b-rad/kernel+mediatree+hauppauge -y
run apt-get update
run apt-get install linux-mediatree -y

run apt-get install screen -y
run apt-get install minisapserver -y

run apt-get install dvb-apps dvblast -y

run mkdir /config
run mkdir /tvstream
ADD tvstream_dockerExec.sh /tvstream
run chmod +x /tvstream/tvstream_dockerExec.sh
CMD ["/tvstream/tvstream_dockerExec.sh"]
