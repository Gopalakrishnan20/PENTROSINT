import time
import sys
import os
from url import urlinfo
from pdfanalysis import pdfinfo
from imagerecon import recon
from iplocator import iplocate
from TraceIP import read_multiple_ip
from webscrap import Links
from NameInfo import Nameinfo
from number import number
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
R = '\033[1;31;40m' 
G = '\033[1;32;40m'
C = '\033[1;36;40m'
Y = '\033[1;33;40m' 
def reconinput():
    inp=(input(bgG+R+"[PENTROSINT]"+G+"[Info] ==> "))
    if(inp == '1'):
        recon()
    elif (inp=='2'):
        iplocate()
    elif(inp=='3'):
        read_multiple_ip()
    elif(inp =='4'):
        urlinfo()
    elif (inp=='5'):
        pdfinfo()
    elif(inp=='6'):
        Links()
    elif (inp=='7'):
        Nameinfo()
    elif (inp=='8'):
        number()
    elif (inp=='9'):
    	print('Enter your target ID:')
    	Id=input(bgG+R+"Without @")
    	os.system("python3 main.py '%s'" %Id)
    elif(inp=='exit'):
        exit()
    elif(inp=='00'):
    	os.system('python3 PENTROSINT.py')
    elif(inp=='tools'):
        print(G+"""Tools available 
    
            1.Social media hunting using image
            2.Trace Single IP
            3.Heatmap
            4.URL redirection checker
            5.PDF meta data analysis
            6.URL lookup in webpages
            7.Information Gathering using Name
            8.Phonenumber verifier
            9.OSINT Instagram
            
            
            00.Go back to main page
            usage : type exit to stop
            """)
    else:
        print(R+"Enter an valid option")
    while True:
        reconinput()    
        
if __name__=="__main__":
   reconinput()
     
    
