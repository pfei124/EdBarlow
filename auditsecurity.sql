/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__auditsecurity
|*
|* Author:
|*
|* Description:      server check security
|*
|*            Users With Paswords like %Id%
|*            Users With Null Passwords
|*            Users With Short (<=4 character) Passwords
|*            Users With Master,Model, or Tempdb Database As Default
|*            Allow Updates is set
|*            Checks stupid passwords
|*    Check db with bad statuses
|*              Logins with bad databases for startup
|*
|*
|* Usage:  sp__auditsecurity @print_only_errors
|*          (if @print_only_errors is not null then prints only errors)
|*
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
           and    name = "sp__auditsecurity")
begin
    drop procedure sp__auditsecurity
end
go

create procedure sp__auditsecurity (
        @print_only_errors int = NULL,
        @srvname char(30) = NULL,
        @hostname char(30) = NULL,
        @dont_format char(1) = null )
as
begin
        declare @c int
        declare @numpgsmb int

        --if @srvname is not null and @hostname is null
        --begin
                --print "MUST PASS BOTH SERVER AND HOST IF EITHER SPECIFIED"
                --return 200
        --end

        create table #audsec_errs
        ( error_no int not null, msg char(255) not null )

        set nocount on

        INSERT  #audsec_errs
        SELECT  31001,"User "+name+" Is Locked"
        from        master..syslogins
        where      status & 2 = 2

        if @@rowcount=0 and @print_only_errors is null
                insert #audsec_errs values (31000, "(No Users With Null Passwords)")

        -- not in 11.5...
        -- INSERT  #audsec_errs
        -- SELECT  31001,"User "+name+" Is Has "+convert(varchar,logincount)+" Failed Logins"
        -- from   master..syslogins
        -- where          logincount > 10

        INSERT  #audsec_errs
        SELECT  31002,"Login "+name+" Is Expired"
        from      master..syslogins
        where     status & 4 = 4

        if @@rowcount=0 and @print_only_errors is null
                insert #audsec_errs values (31000, "(No Users With Expired Passwords)")

        INSERT  #audsec_errs
        SELECT  31003,"User "+name+" Has Null/Short Password"
        from      master..syslogins
        where     password is null
        or                status & 1 = 1

        if @@rowcount=0 and @print_only_errors is null
                insert #audsec_errs values (31000, "(No Users With Invalid Passwords)")

        INSERT  #audsec_errs
        SELECT    31004,"User "+name+" Has "+dbname+" Database As Default"
        from        master..syslogins
        where      ( dbname in ("master","model","tempdb",'sybsystemdb')
        and          name != "sa"
        and          name != "probe" )
        or                    ( name = "sa" and dbname!="master" )

        if @@rowcount=0 and @print_only_errors is null
                insert #audsec_errs values (31000, "(No Users With Master/Model/Tempdb As Default)")

   -- STUFF THAT SHOULD BE DIFFERENT
        INSERT  #audsec_errs
   SELECT   31025,x.name+" Config Has Been Reset To "+c.value2+" (default="+c.defvalue+")"
   from    master..syscurconfigs c,master..sysconfigures x
   where   c.value2 != c.defvalue
   and     c.config = x.config
   and     c.config not in ( 102,103,114,259,158,161,160,153,134,
               105,138,106,132,131,122,116,114,126,127,135,402 )  -- DONT CARE
        and     c.config not in ( 139,137,104,103 )     -- REQUIRED DIFFERENT
        and     c.config not between 360 and 372
        and       c.config not in (
                        376,    -- sql batch capture
                        302,356,                -- mda stuff
                        317,                                    -- rep
                        335,                                    -- license
                        396,                                    -- max memory
                        156,                                    -- NETWORK LISTENERS
                        268,                                    -- MEMORY PER WORKER PROCESS
                        410,                                    -- HISTOGRAM STEPS
                        301,                                    -- LARGE IO BUFFERS
                        263,107,181,267,387,146,
                        170,113,                                -- Deadlock/Recovery Prints
                        374,402,245)

        -- Check Devices
        select  @c=count(*) from master..sysdevices
                        where status & 2 = 2
        INSERT  #audsec_errs
        SELECT  31006,"ERROR: Num Open Devices Parameter Set Too Low"
        from    master..syscurconfigs c
        where   c.value < @c
        and     c.config=116

        -- Check Databases
        select  @c=count(*) from master..sysdatabases
        INSERT  #audsec_errs
        SELECT  31007,"ERROR: Num Open Databases Parameter Set Too Low"
        from    master..syscurconfigs c
        where   c.value < @c
        and     c.config=105

        INSERT  #audsec_errs
        SELECT  31008,"Allow Updates is Set"
        from        master..syscurconfigs
        where      config=102 and value=1

        if @@rowcount=0
        begin
                INSERT   #audsec_errs
                SELECT  31010,"Allow Updates is Set"
                from       master..sysconfigures
                where      config=102 and value=1

                if @@rowcount=0 and @print_only_errors is null
                        insert #audsec_errs values (31000, "(Allow Updates is Not Set)")
        end

        INSERT          #audsec_errs
        SELECT  31012,"User sa is trusted from "+srvname
        from       master..sysremotelogins r, master..sysservers s
        where      r.remoteserverid = s.srvid
        and             r.suid=1
        and             r.status=1
        if @@rowcount=0 and @print_only_errors is null
                insert #audsec_errs values (31000, "(No Trusted Remote Logins)")

        INSERT  #audsec_errs
        SELECT    31013,"Database "+name+" Created For Load"
        FROM     master..sysdatabases
        WHERE      status & 32 = 32

        INSERT  #audsec_errs
        SELECT    31014,"Database "+name+" Suspect"
        FROM     master..sysdatabases
        WHERE      status & 256 = 256

        INSERT  #audsec_errs
        SELECT    31015,"Database "+name+" Offline"
        FROM     master..sysdatabases
        WHERE      status2 & 16 = 16

        INSERT  #audsec_errs
        SELECT    31016,"Database "+name+" Offline until recovery completes"
        FROM     master..sysdatabases
        WHERE      status2 & 32 = 32

        INSERT  #audsec_errs
        SELECT    31017,"Database "+name+" Is Being Recovered"
        FROM     master..sysdatabases
        WHERE      status2 & 64 = 64

        INSERT  #audsec_errs
        SELECT    31018,"Database "+name+" Has Suspect Pages"
        FROM     master..sysdatabases
        WHERE      status2 & 128 = 128

        INSERT  #audsec_errs
        SELECT    31019,"Database "+name+" Is Being Upgraded"
        FROM     master..sysdatabases
        WHERE      status2 & 512 = 512

        INSERT  #audsec_errs
        SELECT  distinct 31020,"Database "+name+" -> No Log Device and No TL on Chkpt"
        FROM    master..sysdatabases
        WHERE   status2 & 0x8000 = 0x8000
        and     name not in ('master','model','sybsystemprocs','tempdb','sybsystemdb' )
        and     status & 8 != 8

        INSERT   #audsec_errs
        select   31021,"ERROR: MIRROR BROKEN: "+name
        from            master..sysdevices where cntrltype=0
        and             ( status & 256 = 256 or status & 2048 = 2048 )

        INSERT   #audsec_errs
        select   31022,"ERROR: CHECK MIRRORING: "+name
        from       master..sysdevices where cntrltype=0
        and        ( status & 4096 = 4096 or status & 8192 = 8192 )

        INSERT          #audsec_errs
        select          31030,"ERROR: Login "+name+" Has an invalid default db ("+dbname+")"
        from            master..syslogins l
        where   l.dbname not in ( select name from master..sysdatabases )
        and       status & 4 != 4
        and       status & 2 != 2

  -- Check for unused sysusages rows
        INSERT    #audsec_errs
        select    31031,"Device "+rtrim(dev.name)+" Is Mapped But Unused (no segments). Size (MB) ="+ltrim(rtrim(str((usg.size/512.),10,0)))
        from master.dbo.sysusages usg,
        master.dbo.sysdevices dev
        where usg.vdevno  = dev.vdevno
                        and usg.segmap=0
                        and cntrltype = 0

        select @numpgsmb = (1048576. / v.low)
        from master.dbo.spt_values v
        where v.number = 1 and v.type = "E"

        select  @c =  sum(u.size) / @numpgsmb
        from        master..sysusages u
        where   u.dbid=db_id("sybsystemprocs")
        and          u.segmap!=4

        if @numpgsmb < 60
        begin
                INSERT  #audsec_errs
                select  31032,"ERROR: Sybsystemprocs should be > 60 MB ("+convert(varchar,@numpgsmb)+")"
        end

        select  @c =  sum(u.size) / @numpgsmb
        from        master..sysusages u
        where   u.dbid=db_id("tempdb")

        if @c < 100
        begin
                INSERT  #audsec_errs
                select  31033,"ERROR: tempdb should be >= 100 MB (currently "+convert(varchar,@c)+"MB)"
        end

        if @@SERVERNAME is null
                INSERT  #audsec_errs select  31039,"ERROR: @@SERVERNAME is null"

        if @srvname is null
        begin
                if @dont_format is null
                        select "Security Violations"=substring(msg,1,79)
                        from #audsec_errs
                else
                        select "Security Violations"=msg
                        from #audsec_errs
        end
        else if @hostname is null
        begin
                if @dont_format is null
                        select srvname=@srvname,db="master","Violation"=substring(msg,1,65)
                        from #audsec_errs
                else
                        select srvname=@srvname,db="master","Violation"=msg
                        from #audsec_errs
        end
        else
        begin
                if @dont_format is null
                        select hostname=@hostname,srvname=@srvname,error_no,db="master",type="a",day=getdate(),"Violation"=substring(msg,1,65)
                        from #audsec_errs
                else
                        select hostname=@hostname,srvname=@srvname,error_no,db="master",type="a",day=getdate(),"Violation"=msg
                        from #audsec_errs
        end

        drop table #audsec_errs
end
go
