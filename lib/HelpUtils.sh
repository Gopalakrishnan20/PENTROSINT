#!/usr/bin/env bash

fluxion_help(){
  echo " WIFIPOT(1)                       User Manuals                       WIFIPOT(1)



  NAME
         PENTROSINT  -  wifipot  is  a  security  auditing  and  social-engineering
         research tool from PENTROSINT

  SYNOPSIS
         wifipot [-debug] [-l language ] attack ...

  DESCRIPTION
         wifipot is a security auditing and  social-engineering  research  tool.
         It  is  a remake of linset by vk496 with (hopefully) less bugs and more
         functionality. The script attempts to retrieve the WPA/WPA2 key from  a
         target  access point by means of a social engineering (phising) attack.
         It's compatible with the latest release of  Kali  (rolling).  wifipot's
         attacks'  setup  is  mostly  manual, but experimental auto-mode handles
         some of the attacks' setup parameters.

  OPTIONS
         -v     Print version number.

         --help Print help page and exit with 0.

         -m     Run wifipot in manual mode instead of auto mode.

         -k     Kill wireless connection if it is connected.

         -d     Run wifipot in debug mode.

         -x     Try to run wifipot with xterm terminals instead of tmux.

         -r     Reload driver.

         -l <language>
                Define a certain language.

         -e <essid>
                Select the target network based on the ESSID.

         -c <channel>
                Indicate the channel(s) to listen to.

         -a <attack>
                Define a certain attack.

         --ratio <ratio>
                Define the windows size. Bigger ratio ->  smaller  window  size.
                Default is 4.

         -b <bssid>
                Select the target network based on the access point MAC address.

         -j <jamming interface>
                Define a certain jamming interface.

         -a <access point interface>
                Define a certain access point interface.

  FILES
         /tmp/fluxspace/
                The system wide tmp directory.
         $PENT/attacks/
                Folder where handshakes and passwords are stored in.

  ENVIRONMENT
         FLUXIONAuto
                Automatically run fluxion in auto mode if exported.

         FLUXIONDebug
                Automatically run fluxion in debug mode if exported.

         FLUXIONWIKillProcesses
                Automatically kill any interfering process(es).

  DIAGNOSTICS
         Please checkout the other log files or use the debug mode.


  AUTHOR
         gopalakrishnan20, ShanmugaPrasath, Daniel
  SEE ALSO
         aircrack-ng(8),


  Linux                             APRIL 2022                        PENTROSINT(1)"

}
