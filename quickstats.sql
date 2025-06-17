/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__quickstats
|*
|* Author:
|*
|* Description:      prints quick statistics from server.  Useful for monitoring
|*
|* Usage:  sp__quickstats
|*
|* Modification History:
|* Date        Version Who      What
|* dd.mm.yyyy  x.y
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__quickstats")
begin
    drop procedure sp__quickstats
end
go

create procedure sp__quickstats( @starttime datetime=NULL, @noconvert int=NULL ,
        @dont_format char(1) = null
        )
as

declare @conn int, @blk int, @locks int, @tlock int, @runnable int, @time1 datetime, @datestmp float, @mirror_status char(6), @usr_pct int

-- max number of users
select @usr_pct=value from master..syscurconfigs where config=103

set nocount on

select @time1=getdate()
select @conn=count(*)   from master..sysprocesses where suid>1
select @usr_pct=(count(*)*100)/@usr_pct   from master..sysprocesses
select @blk=count(*)    from master..sysprocesses where blocked!=0
select @locks=count(*)  from master..syslocks
select @runnable=count(*)  from master..sysprocesses where cmd!="AWAITING COMMAND" and suid>1
select @tlock=count(*) from master..syslocks where type=1

if exists (select * from master.dbo.sysdevices where status & 64 != 64)
        select @mirror_status='None'
else if exists (select * from master.dbo.sysdevices
                where cntrltype=0
                and status & 64  = 64
                and status & 256 = 256 )
begin
         select @mirror_status='Broken'
end
else if exists (select * from master.dbo.sysdevices
                where cntrltype=0
                and status & 64 = 64
                and status & 512 != 512)
begin
         select @mirror_status='Broken'
end
else select @mirror_status='Ok'

declare @lc float, @li float, @lidle float
select  @lc = busy, @li =io, @lidle =idle
from    sybsystemprocs..record
where   description="quickstats"

declare @ms_per_tick float
select @ms_per_tick = convert(int,@@timeticks/1000)

/* numbers here are scaled to give percents  */
select
        @lc     = ( @@cpu_busy * @ms_per_tick) / 1000 - @lc,
        @li     = ( @@io_busy * @ms_per_tick) / 1000 - @li,
        @lidle  = ( @@idle * @ms_per_tick) / 1000 - @lidle

declare @sumtimes float
select  @sumtimes =   @lc + @li +@lidle

if @starttime is not null
     exec   sp__datediff @starttime,'m',@datestmp output
else select @datestmp=@sumtimes/60.0

if @sumtimes is null or @sumtimes=0
begin
        select @sumtimes=1,@lc=1,@li=0,@lidle=0
end


-- INSERT VALUE INTO RECORD AS APPROPRIATE
DELETE sybsystemprocs.dbo.record where  description="quickstats"
if @@error != 0
begin
	print "CANT DELETE sybsystemprocs..record"
	return
end

INSERT  sybsystemprocs.dbo.record
      select
            getdate(),
            ( @@cpu_busy * @ms_per_tick) / 1000,
				( @@io_busy * @ms_per_tick) / 1000,
				( @@idle * @ms_per_tick) / 1000,
            @@connections,
				@@pack_received,
				@@pack_sent,
				@@total_read,
				@@total_write,
				@@total_errors,
            "quickstats"
if @@error != 0
begin
	print "CANT INSERT sybsystemprocs..record"
	return
end

declare @tmptext varchar(255)
if not exists ( select * from sybsystemprocs.dbo.record )
begin
		print "No History Found - Initiating History Saving"
      select
            getdate(),
            ( @@cpu_busy * @ms_per_tick) / 1000,
				( @@io_busy * @ms_per_tick) / 1000,
				( @@idle * @ms_per_tick) / 1000,
            @@connections,
				@@pack_received,
				@@pack_sent,
				@@total_read,
				@@total_write,
				@@total_errors,
            "quickstats"
	return
end

if @noconvert is not null
begin
    select
       blocks=@blk,
       conn=convert(varchar(7),@conn),
       ctime=datediff(ms,@time1,getdate()),
       locks=@locks,
       run=@runnable,
       tlock=@tlock,
       str(convert(float,(100*@lc))/@sumtimes,5,2) "%busy",
       str(convert(float,(100*@li))/@sumtimes,5,2)  "%io ",
       str(convert(float,(100*@lidle))/@sumtimes,5,2) "%idle",
       mins=@datestmp,
       "mirror"=@mirror_status,
       conn_pct=convert(varchar(3),@usr_pct)+"%"
end
else
begin
    select
       blks=convert(char(4),@blk),
       conn=convert(varchar(7),@conn),
       ctime=convert(char(6),datediff(ms,@time1,getdate())),
       locks=convert(char(5),@locks),
       run=convert(char(4),@runnable),
       tlock=convert(char(5),@tlock),
       "%cpu"=str(convert(float,(100*@lc))/@sumtimes,5,2),
       "%io"=str(convert(float,(100*@li))/@sumtimes,5,2) ,
       "%idle"=str(convert(float,(100*@lidle))/@sumtimes,5,2),
       minutes=ltrim(str(@datestmp,10,1)),
       "mirror"=@mirror_status,
       conn_pct=convert(varchar(3),@usr_pct)+"%"
end

go
grant execute on sp__quickstats to public
go
