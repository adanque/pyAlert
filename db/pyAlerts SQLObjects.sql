/*
	Author: Alan Danque
	Date:	20210331
	Purpose:pyAlerts Application Email Alert Configuration
*/

use master
go

-- Create pyAlerts Database
CREATE DATABASE [pyAlerts]
	 CONTAINMENT = NONE
	 ON  PRIMARY 
	( NAME = N'pyAlert', FILENAME = N'E:\SQL_DATA\pyAlert.mdf' , SIZE = 102400KB , FILEGROWTH = 65536KB )
	 LOG ON 
	( NAME = N'pyAlert_log', FILENAME = N'E:\SQL_LOGS\pyAlert_log.ldf' , SIZE = 51200KB , FILEGROWTH = 65536KB )
	GO
	ALTER DATABASE [pyAlerts] SET COMPATIBILITY_LEVEL = 140
	GO
	ALTER DATABASE [pyAlerts] SET ANSI_NULL_DEFAULT OFF 
	GO
	ALTER DATABASE [pyAlerts] SET ANSI_NULLS OFF 
	GO
	ALTER DATABASE [pyAlerts] SET ANSI_PADDING OFF 
	GO
	ALTER DATABASE [pyAlerts] SET ANSI_WARNINGS OFF 
	GO
	ALTER DATABASE [pyAlerts] SET ARITHABORT OFF 
	GO
	ALTER DATABASE [pyAlerts] SET AUTO_CLOSE OFF 
	GO
	ALTER DATABASE [pyAlerts] SET AUTO_SHRINK OFF 
	GO
	ALTER DATABASE [pyAlerts] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
	GO
	ALTER DATABASE [pyAlerts] SET AUTO_UPDATE_STATISTICS ON 
	GO
	ALTER DATABASE [pyAlerts] SET CURSOR_CLOSE_ON_COMMIT OFF 
	GO
	ALTER DATABASE [pyAlerts] SET CURSOR_DEFAULT  GLOBAL 
	GO
	ALTER DATABASE [pyAlerts] SET CONCAT_NULL_YIELDS_NULL OFF 
	GO
	ALTER DATABASE [pyAlerts] SET NUMERIC_ROUNDABORT OFF 
	GO
	ALTER DATABASE [pyAlerts] SET QUOTED_IDENTIFIER OFF 
	GO
	ALTER DATABASE [pyAlerts] SET RECURSIVE_TRIGGERS OFF 
	GO
	ALTER DATABASE [pyAlerts] SET  DISABLE_BROKER 
	GO
	ALTER DATABASE [pyAlerts] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
	GO
	ALTER DATABASE [pyAlerts] SET DATE_CORRELATION_OPTIMIZATION OFF 
	GO
	ALTER DATABASE [pyAlerts] SET PARAMETERIZATION SIMPLE 
	GO
	ALTER DATABASE [pyAlerts] SET READ_COMMITTED_SNAPSHOT OFF 
	GO
	ALTER DATABASE [pyAlerts] SET  READ_WRITE 
	GO
	ALTER DATABASE [pyAlerts] SET RECOVERY FULL 
	GO
	ALTER DATABASE [pyAlerts] SET  MULTI_USER 
	GO
	ALTER DATABASE [pyAlerts] SET PAGE_VERIFY CHECKSUM  
	GO
	ALTER DATABASE [pyAlerts] SET TARGET_RECOVERY_TIME = 60 SECONDS 
	GO
	ALTER DATABASE [pyAlerts] SET DELAYED_DURABILITY = DISABLED 
	GO
	USE [pyAlerts]
	GO
	ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
	GO
	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
	GO
	ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
	GO
	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
	GO
	ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
	GO
	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
	GO
	ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
	GO
	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
	GO
	USE [pyAlerts]
	GO
	IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [pyAlerts] MODIFY FILEGROUP [PRIMARY] DEFAULT
	GO


use pyAlerts
go

if object_id('pyEmailSequences') is not null drop table pyEmailSequences
create table pyEmailSequences (
	  seqid bigint
	 ,seqname varchar(100)
	 )
	insert into pyEmailSequences (seqid, seqname) select 0, 'pyEmailLog'
go

if object_id('uP_pyAlert_getNextID') is not null drop proc uP_pyAlert_getNextID
go
CREATE PROC [dbo].[uP_pyAlert_getNextID] 
	 @SEQNAME VARCHAR(100)
	,@OUTVAL BIGINT OUTPUT
AS
--AUTHOR: ALAN DANQUE
UPDATE pyAlerts..pyEmailSequences 
	SET @OUTVAL = SEQID = SEQID + 1
	WHERE SEQNAME=@SEQNAME--'SMTPEMAIL'
GO


if object_id('pyEmailSendGroupMembersConfig') is not null drop table pyEmailSendGroupMembersConfig
if object_id('pyEmailLog') is not null drop table pyEmailLog
if object_id('pyEmailStatus') is not null drop table pyEmailStatus 
create table pyEmailStatus (
	 sid int primary key
	,statusname varchar(50)
	)
	insert into pyEmailStatus (sid, statusname) select 1, 'received'
	insert into pyEmailStatus (sid, statusname) select 2, 'pending'
	insert into pyEmailStatus (sid, statusname) select 3, 'sent'
	insert into pyEmailStatus (sid, statusname) select 4, 'error'

 
create table pyEmailLog (
	 mid bigint primary key
	,gid int 
	,daterec datetime default getdate()
	,datesent datetime 
	,sender varchar(2000)
	,recipients varchar(max)
	,subj varchar(max)
	,msg varchar(max)
	,sid int 
	,ret_msg varchar(max)
	,critical_type int
	,constraint fk_sid foreign key (sid) references pyEmailStatus (sid) 
	)

if object_id('pyEmailGroups') is not null drop table pyEmailGroups 
create table pyEmailGroups (
	 gid int primary key
	,groupname varchar(50)
	,active int default 1
	)

if object_id('pyEmailRecipients') is not null drop table pyEmailRecipients 
create table pyEmailRecipients (
	 rid int primary key
	,fullname varchar(256)
	,emailaddr varchar(750)
	,active int default 1
	)

if object_id('pyEmailCriticality') is not null drop table pyEmailCriticality 
create table pyEmailCriticality (
	 cid int primary key
	,criticality_name varchar(50)
	)
	insert into pyEmailCriticality (cid, criticality_name) select 4, 'SendAll'
	insert into pyEmailCriticality (cid, criticality_name) select 2, 'OnlyFailuresWarnings'
	insert into pyEmailCriticality (cid, criticality_name) select 1, 'OnlyFailures'

if object_id('pyEmailRequestingServers') is not null drop table pyEmailRequestingServers
create table pyEmailRequestingServers (
	 sid int primary key
	,pyservername varchar(255)
	,active int default 1
	)

if object_id('pyEmailApplications') is not null drop table pyEmailApplications 
create table pyEmailApplications (
	 aid int primary key
	,appname varchar(255)
	,active int default 1
	)


-- Establishes Application(s) Relevance to an email group
if object_id('pyEmailImportance') is not null drop table pyEmailImportance 
create table pyEmailImportance (
	 iid int primary key
	,gid int 
	,aids varchar(2000)
	)

if object_id('pyEmailSendField') is not null drop table pyEmailSendField
create table pyEmailSendField (
	 tid int primary key
	,typename varchar(25)
	)
	insert into pyEmailSendField (tid, typename) select 1, 'to:'
	insert into pyEmailSendField (tid, typename) select 2, 'cc:'
	insert into pyEmailSendField (tid, typename) select 3, 'bcc:'

create table pyEmailSendGroupMembersConfig (
	 scid int primary key
	,gid int not null unique
	,rids varchar(2000)
	,cids varchar(2000)
	,updatedt datetime default getdate()
	,notes varchar(255)
	,active int default 1
	,toccbcc varchar(2000)
	,constraint fk_gid foreign key (gid) references pyEmailGroups (gid) 
	)

go
USE pyAlerts
GO

SET QUOTED_IDENTIFIER OFF
GO

if object_id('dbo.fn_RetDelimValTbl') is not null drop function dbo.fn_RetDelimValTbl
go
create function [dbo].[fn_RetDelimValTbl]( @DELIMITERVAL char(1), @INPUTVALUE varchar(8000) ) 
returns @RETROWS TABLE 
	(
	 ROWID int identity(1, 1)
	,retVals VARCHAR(1000) 
	)
as
BEGIN
	--Author: Alan Danque
	--Date:   Sept 22, 2007
	--Purpose:Parse passed values using delimiter
	DECLARE  @ROWCNT INT
		,@CURROW INT
		,@LENINPUTVALUE INT		
		,@LASTVALPOSITION INT
		,@OPTIONVAL VARCHAR(100)
	SELECT @CURROW = 1
	SELECT @LENINPUTVALUE = LEN(@INPUTVALUE) 
	SELECT @LASTVALPOSITION = 0
	SELECT @CURROW = 1
	WHILE @CURROW <= @LENINPUTVALUE
	BEGIN
		IF (SELECT CHARINDEX(@DELIMITERVAL, @INPUTVALUE, @CURROW)) > 1
		BEGIN
			IF (SELECT SUBSTRING(@INPUTVALUE, @CURROW, 1) ) = @DELIMITERVAL
			BEGIN
				SELECT @OPTIONVAL = SUBSTRING(@INPUTVALUE, @LASTVALPOSITION+1, (@CURROW - @LASTVALPOSITION)-1 )
				INSERT @RETROWS (retVals) SELECT @OPTIONVAL
				SELECT @LASTVALPOSITION = @CURROW
			END
		END
		ELSE
			BEGIN
				SELECT @LASTVALPOSITION = @CURROW
			END
		SELECT @CURROW = @CURROW + 1
	END
	RETURN;
END
GO






if object_id('fn_RetEmailNHow') is not null drop function [dbo].[fn_RetEmailNHow]
go
set quoted_identifier off
go
create function [dbo].[fn_RetEmailNHow]( @email_group varchar(255), @critical_type int ) 
returns varchar(max)
	--TABLE 
	--(
	-- ROWID int identity(1, 1)
	--,retVals VARCHAR(1000) 
	--)
as
BEGIN
	--Author: Alan Danque
	--Date:   20210331
	--Purpose:pyAlerts String Modularizer
	declare @emails varchar(max), @sendcriticality varchar(max), @return varchar(max), @gid int --@email_group varchar(50) = 'ALAN_TEST'
		select @gid = gid from pyAlerts..pyEmailGroups where groupname = @email_group --'AL
		select @emails =
		stuff((
			select  ','+rtrim(h.typename)+d.emailaddr
			from pyAlerts..pyEmailGroups a 
				join pyAlerts..pyEmailSendGroupMembersConfig b -- 1/To, 2 /Cc, 3 /bcc
					on a.gid = b.gid
				cross apply pyAlerts.dbo.fn_RetDelimValTbl('~', b.rids) c
					join pyAlerts..pyEmailRecipients d on d.rid = c.retVals
				cross apply pyAlerts.dbo.fn_RetDelimValTbl('~', b.cids) e
					join pyAlerts..pyEmailCriticality f on f.cid = e.retVals and c.rowid = e.rowid
				cross apply pyAlerts.dbo.fn_RetDelimValTbl('~', b.toccbcc) g
					join pyAlerts..pyEmailSendField h on g.retVals = h.tid and c.rowid = g.rowid
				where d.active = 1
					and a.groupname = @email_group 
					and f.cid >= @critical_type
				order by c.rowid 
				FOR XML PATH('')
			), 1, 1, '')-- 
	
		select  @sendcriticality =
		stuff((
			select ','+f.criticality_name
			from pyAlerts..pyEmailGroups a 
				join pyAlerts..pyEmailSendGroupMembersConfig b 
					on a.gid = b.gid
				cross apply pyAlerts.dbo.fn_RetDelimValTbl('~', b.rids) c
					join pyAlerts..pyEmailRecipients d on d.rid = c.retVals
				cross apply pyAlerts.dbo.fn_RetDelimValTbl('~', b.cids) e
					join pyAlerts..pyEmailCriticality f on f.cid = e.retVals and c.rowid = e.rowid
				where d.active = 1
					and a.groupname = @email_group --'ALAN_TEST'
					and f.cid >= @critical_type
					order by c.rowid 
				FOR XML PATH('')
			), 1, 1, '')--
	
	select @return =rtrim(@emails)+"|"+rtrim(@sendcriticality)+"|"+rtrim(cast(@gid as varchar(255)))
	return @return;
END
go

--declare @EMAILGROUP varchar(255) = 'ALAN_TEST', @EMAILCFG varchar(max)
--select @EMAILCFG  = dbo.[fn_RetEmailNHow](@EMAILGROUP)

set quoted_identifier off
go
if object_id('uP_prepEmail') is not null drop proc uP_prepEmail
go
create procedure [dbo].[uP_prepEmail]
	 @EMAILGROUP varchar(255) 
	,@subj varchar(max)
	,@msg varchar(max)
	,@sender varchar(max)
	,@critical_type int
	,@OUTVAL varchar(max) OUTPUT
as
--Author: Alan Danque
--Date:   20210331
--Purpose:pyAlerts String Modularizer
set quoted_identifier off
set nocount on
declare @EMAILCFG varchar(max), @EMAIL_MID bigint, @gid int
select @EMAILCFG = dbo.[fn_RetEmailNHow](@EMAILGROUP, @critical_type)
select @gid = gid from pyAlerts..pyEmailGroups where groupname = @EMAILGROUP 
	EXEC pyAlerts..uP_pyAlert_getNextID @SEQNAME = 'pyEmailLog', @OUTVAL=@EMAIL_MID OUTPUT
	insert into pyAlerts..pyEmailLog (mid, gid, daterec, recipients, sid, sender, subj, msg, critical_type) select @EMAIL_MID, @gid, getdate(), rtrim(@EMAILCFG), 1, @sender, @subj, @msg, @critical_type
	select @OUTVAL =rtrim(@EMAILCFG)+"|"+rtrim(cast(@EMAIL_MID as varchar(255)))
	select @OUTVAL 
	return -- ; 
go


go
if object_id('uP_updtEmailLog') is not null drop proc uP_updtEmailLog
go
create procedure [dbo].[uP_updtEmailLog]
	 @EMAIL_MID bigint
	,@STATUS_ID int
	,@ret_msg varchar(max) = ''
as
--Author: Alan Danque
--Date:   20210331
--Purpose:pyAlerts Update Email Log after email sent.
update a set a.sid = @STATUS_ID, a.ret_msg = @ret_msg, a.datesent = getdate()
	from pyAlerts..pyEmailLog a where a.mid = @EMAIL_MID
go


------- Configuration Area and Examples

-- Insert sourced alert python server
insert into pyEmailRequestingServers (sid, pyservername) select 1, 'SVRNAMEAPP07'

-- Add related applications to email group
insert into pyEmailApplications (aid, appname) select 1, 'EnergyStar'
insert into pyEmailApplications (aid, appname) select 2, 'OtherTestApp'

-- Add recipients
insert into pyEmailRecipients (rid, fullname, emailaddr) select 1, 'Alan Danque', 'adanque@DomainNameHere.com'
insert into pyEmailRecipients (rid, fullname, emailaddr) select 2, 'Alan Danque', 'adanque@gmail.com'
insert into pyEmailRecipients (rid, fullname, emailaddr) select 3, 'Alan Danque', 'alandanque1@aol.com'


-- Add email groups
insert into pyEmailGroups (gid, groupname) select 1, 'ALAN_TEST'

-- Add email group associations (for reporting purposes)
insert into pyEmailImportance (iid, gid, aids) select 1, 1, '1~2~'
--insert into pyEmailImportance (iid, gid, aids) select 2, 1, '2~'

-- Add email recipient to group and desired type of criticality of email receipt
insert into pyEmailSendGroupMembersConfig (scid, gid, rids, cids, toccbcc, notes) 
		select 1, 1
			, '1~2~3~' --Recipient Emails				!!rids & cids are Order Dependent!!  IMPORTANT don't forget the trailing ~ tildas
			, '4~2~1~' --Desired Recipent Criticality !!rids & cids are Order Dependent!! 4 All / 2  fail&warn / 1 fail only
			, '1~2~3~'
			, 'test' --Notes
go

-- Validation
-- select * from pyEmailSendGroupMembersConfig
-- Test who receives email for the group depending on the criticality 
	select dbo.[fn_RetEmailNHow]('ALAN_TEST', 4)
	--adanque@DomainNameHere.com|SendAll|1

	select dbo.[fn_RetEmailNHow]('ALAN_TEST', 2)
	--adanque@DomainNameHere.com|SendAll|1

	select dbo.[fn_RetEmailNHow]('ALAN_TEST', 1)
	--adanque@DomainNameHere.com,adanque@gmail.com,alandanque1@aol.com|SendAll,OnlyFailuresWarnings,OnlyFailures|1

/*
	Workflow:
		1. Python application calls, "uP_prepEmail" to get email recipients using group name along with if the recipient wants to receive success / fail&warn / or just failures
		2. After python app sends email, it calls, "uP_updtEmailLog" to update the email log

*/
-- Example pyApplication Email Prep 
declare @OUTVAL varchar(max)
exec pyAlerts..[uP_prepEmail] @EMAILGROUP = 'ALAN_TEST'
	,@subj = 'test subject'
	,@msg = ' test message '
	,@sender = 'alan danque'
	,@critical_type = 4
	,@OUTVAL = @OUTVAL OUTPUT
select @OUTVAL 

adanque@DomainNameHere.com,adanque@gmail.com|SendAll,OnlyFailures|1|1

-- Review 
select * 
	from pyEmailLog a
		join pyEmailStatus b
			on a.sid = b.sid

-- Example pyApplication email log update
exec pyAlerts..uP_updtEmailLog
	 @EMAIL_MID = 1
	,@STATUS_ID = 3
	,@ret_msg = ' TEST WHERE THE ERROR CODE WILL BE STORED'

-- Review
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



select b.statusname, * from pyAlerts..pyEmailLog a 
	join pyAlerts..pyEmailStatus b on a.sid = b.sid
	order by mid desc

--declare @OUTVAL varchar(max) exec pyAlerts..[uP_prepEmail] @EMAILGROUP = 'ALAN_TEST',@subj = 'test from alan',@msg = 'msg text',@sender = 'adanque@DomainNameHere.com',@critical_type = 1,@OUTVAL = @OUTVAL OUTPUT select @OUTVAL 