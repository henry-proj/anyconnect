# anyconnect
## describe
This script is to solve the problem that the Cisco anyconnect client cannot remember the password. You need to enter the password every time you start the client.

## Instructions
1. Make sure the Cisco anyconnect client is installed on the system
2. Edit the script to modify the value of the CONN_INFO array
   The format is `"VPN_ADDRESS USERNAME PASSWORD"`, one per line, there is a space between the address and the username, there is a space between the username and the password, be careful not to forget the double quotes ("")
   ```shell
   ...
CONN_INFO=(
"VPN_ADDRESS USERNAME PASSWORD"
"vpn.github.com:8843 zhangsan 123456"
)
...
   ```
Save and exit the script after the modification is complete
4. Use bash ./connect-vpn.sh
