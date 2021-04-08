# pyAlert

## Pythonic Alerts Framework

Author: Alan Danque

Date:	20210331

Purpose:Allows for logging, reporting and email group subscription with sender/reciever configuration of SendAll, SendOnlyFail&War, or SendOnlyFail Email Alerts
Status: Under construction


## Abstract:

Under construction: The intention for this is to log, track and configure email alerts from Python applications. With the email subscription model and a configuration area for if a recipient wants to receive all emails ie successful/fail/warn or fail/warn or just fail notifications.

Note: This is a stand alone capable solution architected to be modular, elastic and fluid and thus able to be migrated easily regardless of cloud platform. With a dependency on a relational database engine and python 3.9 or higher.

## Python Libraries


## Relation DB Objects
### Tables:
| Table Name | Purpose |
| ----- | ------ | 
| pyEmailSequences | Sequence management |
| pyEmailStatus | Status id lookup | 
| pyEmailLog | Email Historical Log | 
| pyEmailGroups | Email Group | 
| pyEmailRecipients | Email addresses | 
| pyEmailCriticality | Criticality id lookup | 
| pyEmailRequestingServers | Python server names | 
| pyEmailApplications | Application names | 
| pyEmailImportance | Group and application relationship management | 
| pyEmailSendGroupMembersConfig	| Manages send / no-send based on criticality per group and email recipient | 

### Stored Procedures:
| Object Name | Purpose |
| ----- | ------ | 
| uP_pyAlert_getNextID | Sequence Management | 
| uP_prepEmail | Starts Email Log and obtains intended email recipients based on group | 
| uP_updtEmailLog | Updates Email Log status after alert execution |

### Functions:
| Object Name | Purpose |
| ----- | ------ | 
| fn_RetEmailNHow | Obtains list of intended email addresses by group |

### Workflow:

- 1. Python application calls, "uP_prepEmail" to get email recipients using group name along with if the recipient wants to receive success / fail&warn / or just failures

- 2. After python app sends email, it calls, "uP_updtEmailLog" to update the email log

- Server: DEVSQL08 (currently)

### Example pyApplication Email Prep 
declare @OUTVAL varchar(max)
exec pyAlerts..[uP_prepEmail] 
	 @EMAILGROUP = 'ALAN_TEST'
	,@subj = 'test subject'
	,@msg = ' test message '
	,@sender = 'alan danque'
	,@OUTVAL = @OUTVAL OUTPUT
select @OUTVAL 

### Review 
select * 
	from pyEmailLog a
		join pyEmailStatus b
			on a.sid = b.sid

### Example pyApplication email log update
### Example pyApplication email log update
exec pyAlerts..uP_updtEmailLog
	 @EMAIL_MID = 1
	,@STATUS_ID = 3
	,@ret_msg = ' TEST WHERE THE ERROR CODE WILL BE STORED'

### Review Queries
```
select distinct a.mid MessageID, a.daterec, a.datesent, a.sender, a.recipients, a.subj, a.msg, b.statusname, a.ret_msg, c.groupname
		-- Add if would like to see associated applications
		-- , f.appname
	from pyEmailLog a
		join pyEmailStatus b
			on a.sid = b.sid
		join pyEmailGroups c
			on a.gid = c.gid
		join pyEmailImportance d
			on a.gid = d.gid
		-- Allows for email groups to be associated with applications
		cross apply pyAlerts.dbo.fn_RetDelimValTbl('~', d.aids) e
			join pyAlerts..pyEmailApplications f on e.retVals = f.aid --and c.rowid = e.rowid
		-- Add where clause as needed
```

## Python
- Server: 
Under construction



## Project files
| Type | File name | Description |
| ----- | ------ | ------ |
| SQL | pyAlerts.sql | pyAlerts DB Objects |

