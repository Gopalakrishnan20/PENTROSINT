import os
from playsound import playsound
from socialrecon import reconinput
from gtts import gTTS  

from webvuln import Webvuln
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
def Main(a):
    if(a==1):
        reconinput()
    elif(a==2):
        Webvuln()
    elif(a==3):
    	os.system("sudo bash WiJAMMER.sh")
    elif(a==4):
    	os.system("sudo bash wifipot.sh")
        

if __name__=="__main__": 
    print("""
██████╗ ███████╗███╗   ██╗████████╗██████╗  ██████╗ ███████╗██╗███╗   ██╗████████╗
██╔══██╗██╔════╝████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██╔════╝██║████╗  ██║╚══██╔══╝
██████╔╝█████╗  ██╔██╗ ██║   ██║   ██████╔╝██║   ██║███████╗██║██╔██╗ ██║   ██║   
██╔═══╝ ██╔══╝  ██║╚██╗██║   ██║   ██╔══██╗██║   ██║╚════██║██║██║╚██╗██║   ██║   
██║     ███████╗██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████║██║██║ ╚████║   ██║   
╚═╝     ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝      
                                                                         
    """)
 
    print(green+"""
                Available Modules 
           
           1.Information gathering,
           2.Web vulnerability scanning,
           3.WiFi-Deauthentication
           4.Wifipot
    """) 
    language = 'en'
    text="Welcome     Please enter a valid option"
    aud=gTTS(text=text,lang=language,slow=False)
    aud.save("valid.mp3")
    playsound("valid.mp3")
    print(Y+"Note : In Information gathering type 'tools' to find tools.")
    print(Y+"Note : In Web vulnerability scanning type 'help' to find tools.")
    a=int(input(bgG+"[PENTROSINT]"+Y+" Module =>"))

    Main(a)
    
