"""
Author:     Alan Danque
Purpose:     Py Email Alert Sender
Date:        20210331
"""
import os
import smtplib
import email
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import sys
import time
from datetime import date, datetime, timedelta
import yaml
from yaml import load, dump
from pathlib import Path
import pyodbc 
import contextlib

#if __name__ == '__main__':

def send(sender, to, server, subject='None', body='None'):
    errors={}
    error_out={}
    err = 0
    torecipients = []
    ccrecipients = []
    bccrecipients = []
    errors['starttime'] = str(datetime.now())
    message = email.message.Message()
    loopEmlist = to.split(",")
    for e in loopEmlist:
        emout = ""
        if "to:" in e:
            emout = e.replace('to:','')
            torecipients.append(emout)
        if "cc:" in e and "bcc:" not in e:
            emout = e.replace('cc:','')
            ccrecipients.append(emout)
        if "bcc:" in e:
            emout = e.replace('bcc:','')
            bccrecipients.append(emout)
    torecipients_str = ",".join(torecipients)
    ccrecipients_str = ",".join(ccrecipients)
    bccrecipients_str = ",".join(bccrecipients)
    print("torecipients_str")
    print(torecipients_str)
    print("ccrecipients_str")
    print(ccrecipients_str)
    print("bccrecipients_str")
    print(bccrecipients_str)
    
    message['To'] = torecipients_str
    message['Cc'] = ccrecipients_str
    message['Bcc'] = bccrecipients_str
    message['From'] = sender
    message['Subject'] = subject
    message.set_payload(body)
    #server = smtplib.SMTP(server)
    try:
        server = smtplib.SMTP(server)
        server.sendmail(sender, to, message.as_string())
    except Exception as e:
        errval = "Email Send: Exception!  Err: "+str(e)
        errors['ExecutionStatus'] = errval
        print(e)
        print(errval)            
        #server.quit() 
        return errors  # Email Error 
    else:
        #server.quit() 
        return 3  # Email Success

def executeSQL(sqlserver, sqldatabase, emailgroup, critical_type, subj, msg, sender, RetSQLAlertCode, email_mid="", status_id="", ret_msg="", sqlcmd_type=""):
    start_time = time.time()
    errors={}
    error_out={}
    err = 0
    errors['starttime'] = str(datetime.now())
    if sqlcmd_type == "uP_prepEmail":
        sqlcmd = "declare @OUTVAL varchar(max) exec pyAlerts..[uP_prepEmail] @EMAILGROUP = '{}',@subj = '{}',@msg = '{}',@sender = '{}',@critical_type = {},@OUTVAL = @OUTVAL OUTPUT select @OUTVAL ".format(emailgroup, subj, msg, sender, critical_type)
    elif sqlcmd_type == "uP_updtEmailLog":
        sqlcmd = " exec pyAlerts..uP_updtEmailLog @EMAIL_MID = {}, @STATUS_ID = {}, @ret_msg = '{}'".format(email_mid, status_id, ret_msg)
    else: 
        print("Invalid sqlcmd_type")
    # Test Connection Before Execution.
    try:
        contextlib.closing(pyodbc.connect(
                        'Driver={SQL Server};'
                        'Server='+ sqlserver + ';'
                        'Database=' + sqldatabase + ';'
                        'Trusted_Connection=yes;'
                    )) 
    except Exception as e:
        err+=1
        ts = str(datetime.now())
        errval = "Cmd: ODBC Connection Test Failed!  Err: "+str(e)
        errors['ExecutionStatus'] = errval
        print(e)
        print(errval)

    else:
        with contextlib.closing(pyodbc.connect(
                'Driver={SQL Server};'
                'Server='+ sqlserver + ';'
                'Database=' + sqldatabase + ';'
                'Trusted_Connection=yes;'
            )) as conn1:
            with contextlib.closing(conn1.cursor()) as cursor:
                #print(sqlcmd.format(table_name, dst_path))
                conn1.timeout = 500
                """
                if refresh == 1:
                    try:
                        cursor.execute(sqlcmd)
                        RetSQLAlertCode = cursor.fetchone()[0]
                    except Exception as e:
                        err+=1
                        ts = str(datetime.now())
                        errval = "Cmd: "+ sqlcmd +" Err: "+str(e)
                        errors['ExecutionStatus'] = errval
                """

                try:
                    cursor.execute(sqlcmd)
                    RetSQLAlertCode = cursor.fetchval() 

                except Exception as e:
                    err+=1
                    ts = str(datetime.now())
                    errval = "Cmd: "+ sqlcmd +" Err: "+str(e)
                    errors['ExecutionStatus'] = errval
                else:
                    ts = str(datetime.now())
                    rowsaffected = cursor.rowcount
                    errval ="Rows Loaded: " + str(rowsaffected)
                    print(errval)
                    errors['ExecutionStatus'] = errval
                #RetSQLAlertCode = cursor.fetchall() #RetSQLAlertCode = cursor.fetchone()[0]
                #print("1st RetSQLAlertCode")
                #print(RetSQLAlertCode)

            conn1.commit()
    if err > 0:
        # Execution Logging
        error_out = errors
        ts = str(datetime.now())
        error_out['status'] = "Exception! Duration: %s seconds ---" % (time.time() - start_time) + " Completed at: "+ ts
        error_out['sql_server'] = sqlserver
        error_out['sql_database'] = sqldatabase
        error_out['sql_cmd'] = sqlcmd
        error_out['endtime'] = str(datetime.now())
        print(error_out)
        return(error_out)
    else:
        ts = str(datetime.now())
        error_out = errors
        error_out['status'] = "Success! Duration: %s seconds ---" % (time.time() - start_time) + " Completed at: "+ ts
        return(RetSQLAlertCode)

def sendmail(subj, msg, sender, emailgroup):
    start_time = time.time()
    mypath = "E://pyAlerts"
    #mypath = sys.path[0] #"E://pyAlerts"
    base_dir = Path(mypath)
    config_dir = base_dir.joinpath("Config")     
    filename = 'config.yaml'
    ymlfile = config_dir.joinpath(filename)    
    # Read YAML Config
    with open(ymlfile, 'r') as stream:
        try: 
            cfg = yaml.safe_load(stream)
            venvpath = cfg["pyAlertsCfg"].get("venvpath") 
            ca_certs = cfg["pyAlertsCfg"].get("ca_certs") 
            SMTPSERVER = cfg["pyAlertsCfg"].get("smtpserver") 
            sqlserver = cfg["pyAlertsCfg"].get("sqlserver") 
            sqldatabase = cfg["pyAlertsCfg"].get("sqldatabase") 
            sender = cfg["pyAlertsCfg"].get("sender") 
            warntext = cfg["pyAlertsCfg"].get("warntext") 
            errortext = cfg["pyAlertsCfg"].get("errortext") 
            defaultexceptionnotifier = cfg["pyAlertsCfg"].get("defaultexceptionnotifier") 
            pyserver = cfg["pyAlertsCfg"].get("pyserver") 
        except yaml.YAMLError as exc:
            print(exc)
    server = SMTPSERVER            

    #subj = sys.argv[1]
    #msg = sys.argv[2]
    #sender = sys.argv[3]
    #emailgroup = sys.argv[4]
    RetSQLAlertCode = ""

    #EVALUATE MESSAGE FOR CRITICALITY
    errortext = errortext.split("~")
    warntext= warntext.split("~")
    #CHECK SUBJECT STRING
    ERRSUBJCHECK = [t for t in errortext if(t in subj.lower())]
    ERRSUBJCHK = len(ERRSUBJCHECK)
    WARNSUBJCHECK = [t for t in warntext if(t in subj.lower())]
    WARNSUBJCHK = len(WARNSUBJCHECK)
    #CHECK MESSAGE STRING
    ERRMSGCHECK = [t for t in errortext if(t in msg.lower())]
    ERRMSGCHK = len(ERRMSGCHECK)
    WARNMSGCHECK = [t for t in warntext if(t in msg.lower())]
    WARNMSGCHK = len(WARNMSGCHECK)
    critical_type = 0
    if ERRSUBJCHK != 0 or ERRMSGCHK != 0:
        critical_type = 1
    elif (WARNSUBJCHK != 0 or WARNMSGCHK != 0) and ERRSUBJCHK == 0 and ERRMSGCHK == 0:
        critical_type = 2
    else: 
        critical_type = 4

    # Prepare Email Log Record
    sqlcmd_type = 'uP_prepEmail'
    email_mid=""
    status_id=""
    ret_msg=""
    email_recipient_cfg = executeSQL(sqlserver, sqldatabase, emailgroup, critical_type, subj, msg, sender, RetSQLAlertCode, email_mid, status_id, ret_msg, sqlcmd_type)
    print("uP_prepEmail Status:")
    # Verify the uP_prepEmail log entry had issues. Attempt to send email if there are issues
    checkexception = "Exception! Duration"
    if email_recipient_cfg in checkexception:
        print("Having issues connecting to SQL! Attempt to email alert")
        subj = "pyAlert is having issues connecting to SQL while attempting to email alert"
        message = "Please review pyAlert Framework Config on server:"+ pyserver
        attemptemail = send(sender, defaultexceptionnotifier, server=server, subject=subj, body=message)
    else:
        print("Obtained recipient config: " + email_recipient_cfg)
    print("Email Prep Complete: --- %s seconds ---" % (time.time() - start_time) )    

    # Parse email recipients
    parserestext = email_recipient_cfg.split("|")
    emailaddr = parserestext[0]
    sendtypesbyrecipient = parserestext[1]
    msgid = parserestext[3]
    to = emailaddr.replace('|',',') 
    message = """\
    From: %s
    To: %s
    Subject: %s
    
    %s
    """ % (sender, to, subj, msg)
    attemptemail = send(sender, to, server=server, subject=subj, body=message)
    print(attemptemail)
    if attemptemail == 3:
        print("Email Sent with Success!")    
        ret_msg="Email Relay Sent Duration: %s secs " % (time.time() - start_time)
    else:
        print("Email Failed to Send!")    
        ret_msg=str(attemptemail).replace("'","") 
        print(ret_msg)    
        attemptemail = 4
    print("Email Send Attempt Complete: --- %s seconds ---" % (time.time() - start_time) )

    # Update Email Log History with success or any email issues
    sqlcmd_type = 'uP_updtEmailLog'
    email_mid=msgid
    status_id=attemptemail
    logupdate = executeSQL(sqlserver, sqldatabase, emailgroup, critical_type, subj, msg, sender, RetSQLAlertCode, email_mid, status_id, ret_msg, sqlcmd_type)    
    print("uP_updtEmailLog Status:")
    print(logupdate)

    print("Update Complete: --- %s seconds passed ---" % (time.time() - start_time) )
