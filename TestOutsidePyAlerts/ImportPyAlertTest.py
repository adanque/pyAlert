"""
Author:     Alan Danque
Purpose:    Import pyAlert Test and Send
Date:       20210331
"""
from sys import path
import sys
from os.path import dirname, abspath
pyAlertPath= "E:\\pyAlerts" 
path.append(pyAlertPath)
curpath = sys.path[0]
basepath = dirname(curpath)
import pyAlert

# TEST EMAIL SENDING
subj="SENDING TEST EMAIL SUBJ"
msg="SENDING TEST EMAIL MSG"
sender="adanque@eqr.com"
emailgroup="ALAN_TEST"
send = pyAlert.sendmail(subj, msg, sender, emailgroup)
 