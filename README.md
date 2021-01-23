# TV2MultiCast
Over the Air TV to MultiCast

LOCATION
- United States (ATSC OTA broadcast standard)

HARDWARE
- Hauppauge WinTV-dualHD (USB), or an ATSC TV tuner supported by the Linux Kernel
- 2 Computers - 1 to stream, 1 to watch/test
- Network Switch with IGMP Snooping

OS/SOFTWARE
- Streaming computer: Ubuntu Desktop/Server (all commands are terminal-based)
- Viewing computer: Any OS
- VLC



## Streaming Network Setup - Enable IGMP Snooping
Enable IGMP snooping on your network. Otherwise, the video will be streamed to every wired device on your network, causing slowdowns, excessive energy usage, and it's just plain rude. 

I have an Ubiquiti Unifi Switch:
Settings > Networks > (Network I'm multicasting on) > Enable IGMP snooping > Save.
If Multicasting does not work, ensure you have completely uninstalled Wireshark and Virtualbox, including the network adapters, reboot, then install the lastest versions of both and reboot.



## Streaming Computer Setup - Show multiple TV tuners for WinTV-dualHD in Ubuntu
https://hauppauge.com/pages/support/support_linux.html?#ubuntu

     ls /dev/dvb ## You should see "adapter0" ## This tells us we don't have the firmware or we'd see "adapter1" as well.
     sudo add-apt-repository ppa:b-rad/kernel+mediatree+hauppauge ## Install the PPA.
     sudo apt-get update ## Update our package database so it is aware of the new PPA.
     dpkg -l | grep linux-image-generic-hwe ## If a line is displayed beginning with "ii", then you are running the HWE version of Ubuntu. 
     sudo apt-get install linux-hwe-mediatree ## !ONLY IF YOU HAVE HWE version of Ubuntu!
     sudo apt-get install linux-mediatree ## !ONLY IF YOU DO NOT HAVE HWE version of Ubuntu!
     sudo shutdown -r now ## Reboot
     ls /dev/dvb ## You should see "adapter0" and "adapter1"
     
     

## Streaming Computer Setup - Get the OTA tv channels
Install all updates, and install needed applications:

    sudo apt-get update && sudo apt-get upgrade -y ## Make sure computer is fully up-to-date.
    sudo apt-get install dvb-apps dvblast w-scan -y
    
Create directory and initiate scanning for TV channels. This will take a while.
"US" can be replaced with your country code, but most countries around the world don't use ATSC for TV.

    mkdir ~/dvblast
    sudo w_scan -X -c US > ~/dvblast/channels.txt
    nano ~/dvblast/channels.txt

Take a screenshot or note each item. You'll create a config file for each one you want to multicast. Here's an example for KSPS-HD:

    "KSPS-HD:177000000:VSB_8:49:52:1"
    "KSPS-HD:177000000:VSB_8:49:52:2"
    "KSPS-HD:177000000:VSB_8:49:52:3"

You'll need the first (channel name), second (frequency) and last (subchannel) parts. In our example, there are multiple subchannels broadcasting on the same frequency.

Create the config file for DVBlast. DVBlast will use this to tune in to the TV channel and send the multicast stream out:

    nano ~/dvblast/KSPS-HD.cfg

We also need to know if the channels are broadcasting 24/7 or not. This tells DVBlast if it needs to reset the tuner if it stops getting a signal. I've just left it at 1 and haven't had any issues that I can tell.

Input the following: 

    ##MulticastIP:Port, 1=ChannelAlwaysBroadcasts/0=SometimesBroadcasts, SubChannel
    239.255.0.1:1234 1 1
    239.255.0.2:1234 1 2
    239.255.0.3:1234 1 3
    
If you have multiple IP addresses/adapters on the streaming computer and want to send the broadcast over a specific one, add "@ipaddress" of the adapter you want to send it on. For example, if you have 2 adapters and one is "192.168.1.10" and the second is "192.168.1.20":

    239.255.0.1:1234@192.168.1.20 1 1
  
Now for the fun part:

    sudo dvblast -a 0 -f 177000000 -b 6 -c ~/dvblast/KSPS-HD.cfg -m VSB_8 -e
    # -a 0 is the adapter number from the ls /dev/dvb command
    # -f 177000000 is the frequency of the station. For KLRU, the frequency is 521000000
    # -b 6 is the bandwidth of ATSC channels in the US
    # -c ~/dvblast/KSPS-HD.cfg is the configuration file for KLRU's channels created in a previous step
    # -m VSB_8 is the modulation used (8VSB doesn't work). This should also match the encoding found in: ~/dvblast/channels.txt
    # -e enables the electronic pass through guide (EPG), which provides information about the shows. (Doesn't seem to work for ATSC channels)
    
At this point, you can fire up VLC on your viewing computer and tune in:
VLC > Open Network Connection > 
    rtp://@239.255.0.1:1234

...but no one wants to manually type that in all the time - especially in a business or school. There's an answer for that:
SAP Announce! We'll cover that shortly right after we solve a different problem: Running multiple commands in the same terminal.

Let's cancel the stream (ctrl-c) on the Streaming computer. We're going to run in to scaling issues very quickly, so let's install screen so we can run multiple commands at the same time:



## Streaming Computer Setup - Screen your TV
    sudo apt-get install screen
    
Create a new screen called "tv0". 0 is the number of our TV Tuner adapter:

    screen -dm -S tv0
    screen -S tv0 -X stuff "sudo dvblast -a 0 -f 177000000 -b 6 -c ~/dvblast/KSPS-HD.cfg -m VSB_8 -e -W -Y\n"
    screen -r tv0

Now we can go back to our main terminal by pressing:

    [CTRL]-[A]
    [D]
    
To view the screens you have:

    screen -ls

To re-attach to your screen:
    
    screen -r tv0



## Streaming Computer Setup - SAP Announce
    sudo apt-get install minisapserver

    sudo nano /etc/sap.cfg

Input the following:

    [program]
    playlist_group=KSPS
    type=rtp
    name=KSPS-HD
    user=ProbablyNotUsedByVLC
    machine=ProbablyNotUsedByVLC
    site=ProbablyNotUsedByVLC
    address=239.255.2.1
    port=1234

    [program]
    playlist_group=KSPS
    type=rtp
    name=KKSPS Wo
    user=ProbablyNotUsedByVLC
    machine=ProbablyNotUsedByVLC
    site=ProbablyNotUsedByVLC
    address=239.255.0.2
    port=1234

    [program]
    playlist_group=KSPS
    type=rtp
    name=KKSPS Cr
    user=ProbablyNotUsedByVLC
    machine=ProbablyNotUsedByVLC
    site=ProbablyNotUsedByVLC
    address=239.255.0.3
    port=1234
    
Feel free to change "ProbablyNotUsedByVLC" to something as appropriate as possible. It'll help anyone looking at the detailed information figure out what computer is broadcasting this SAP information on the network - and that person might be you 3 years from now. Do yourself and everyone else a favor and fill it out. :)

"playlist_group=KSPS" Each channel can be part of a group. Not sure yet if multiple groups can be specified.

Start the SAP announce:

    screen -dm -S sap
    screen -S sap -X stuff "sapserver -c /etc/sap.cfg\n"
    screen -r sap
    [CTRL]-[A]
    [D]

On your VLC viewing computer, navigate to your playlist:

    VLC > [CTRL]-[L] > Network streams (SAP)
You should see your channels pop up there. Double-click them to check them out.

Now, if you're using a dual-tuner card, you'll realize we only have half of this setup working. We still have a whole other tuner we can use!


Create another config file for the second TV channel frequency you'd like to use. BE SURE to use unique multicast IP addresses! 
Then create a new screen called "tv1". 1 is the number of our TV Tuner adapter. 

    screen -dm -S tv1
    screen -S tv1 -X stuff "sudo dvblast -a 1 -f 479000000 -b 6 -c ~/dvblast/KHQ.cfg -m VSB_8 -e\n"
    screen -r tv1
    [CTRL]-[A]
    [D]

Be sure to upate the SAP announce and restart it:

    screen -r sap
    [CTRL]-[C] ##This stops the SAP server.
    sudo nano /etc/sap.cfg
    sapserver -c /etc/sap.cfg
    [CTRL]-[A]
    [D]
    
#### ALL DONE


# Docker

HARDWARE REQUIREMENTS
- Hauppauge WinTV-dualHD (USB), or an ATSC TV tuner supported by the Linux Kernel
- Network Switch with IGMP Snooping enabled

LOCATION REQUIREMENTS
- United States (ATSC is USA broadcast standard - this can be changed in a variable.)

### Docker Stack
    version: '2'
    
    services:
      tvstream_scan:
        image: fishscene/tv-multicast:latest
        container_name: tvstream_scan
        restart: "no"
        volumes:
          - tv-multicast:/config
        environment:
          - PERFORMSCAN=true
        network_mode: host
        devices:
          - /dev/dvb:/dev/dvb
    
      tvstream_0_593000000:
        image: fishscene/tv-multicast:latest
        container_name: tvstream_0_593000000
        restart: always
        depends_on:
          - "tvstream_scan"
        volumes:
          - tv-multicast:/config
        environment:
          - PERFORMSCAN=false
          - ADAPTERNUMBER=0
          - FREQUENCY=593000000
          - DELIVERY=ATSC
          - SITENAME=MYLOCATION
          - NAME=MYNAME
        network_mode: host
        devices:
          - /dev/dvb:/dev/dvb
          
      tvstream_1_509000000:
        image: fishscene/tv-multicast:latest
        container_name: tvstream_1_509000000
        restart: always
        depends_on:
          - "tvstream_scan"
        volumes:
          - tv-multicast:/config
        environment:
          - PERFORMSCAN=false
          - ADAPTERNUMBER=1
          - FREQUENCY=509000000
          - DELIVERY=ATSC
          - SITENAME=MYLOCATION
          - NAME=MYNAME
        network_mode: host
        devices:
          - /dev/dvb:/dev/dvb
          
      tvstream_sapserver:
        image: fishscene/tv-sap:latest
        container_name: tvstream_sapserver
        depends_on:
          - "tvstream_scan"
        restart: always
        volumes:
          - tv-multicast:/config
        network_mode: host
