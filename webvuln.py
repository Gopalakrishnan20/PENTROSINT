from clickjack import ClickJacking
from hostheader import HostHeader
from subdomain import fuzz
from reverseip import ReverseIP
import os
H='\033[30m'
R='\033[31m'
G='\033[32m'
B='\033[34m'
P='\033[35m'
C='\033[36m'
Y='\033[33m'
W='\033[97m'
bgH='\033[40m'
bgR='\033[41m'
bgG='\033[42m'
bgB='\033[44m'
bgP='\033[45m'
bgC='\033[46m'
bgY='\033[43m'
bgW='\033[107m'
BOLD='\033[1m'
RST='\033[0m'
cyan="\033[1;36;40m"
green="\033[1;32;40m"
red="\033[1;31;40m"
Y = '\033[1;33;40m' 
cyan="\033[1;36;40m"
green="\033[1;32;40m"
red="\033[1;31;40m"
Y = '\033[1;33;40m' 
def Webvuln():
    inp=(input(BOLD+R+"[PENTROSINT]"+BOLD+G+"[Vulnerability] ==> "))
    if(inp == '1'):
        ClickJacking()
    elif(inp=='2'):
    	HostHeader()
    elif(inp=='3'):
        fuzz()
    elif(inp=='4'):
        ReverseIP()
    elif(inp=='00'):
    	os.system('python3 PENTROSINT.py')
    elif(inp=='exit'):
    	exit()
    elif(inp=='help'):
        print(green+"""
               1.ClickJacking,
               2.Host header injection.
               3.Subdomain Enumeration.
               4.Reverse IP
               
               00.Main Page
               Enter 'exit' to Exit
               """)
    else:
        print(red+"Invalid choice")
    while True:
        Webvuln()

if __name__=="__main__":
    Webvuln()
