/* Procedure copyright(c) 1993-1995 by Ed Barlow */
/* Copied from sp__whodo by simon walker */

/************************************************************************\
|* Procedure Name: sp__whodo
|*
|* Author:
|*
|* Description:
|*
|* Usage:
|*
|* Modification History:
|*
|* Date        Who   Version  What
|*
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
         from   sysobjects
         where  type = 'P'
         and    name = "sp__whodo")
begin
    drop procedure sp__whodo
end
go

create procedure sp__whodo (@parm varchar(30)=null, @dont_format char(1)=null)
as
begin
    declare @parmsuid int , @parmdbid int

    if @parm is not NULL
    begin
        select @parmsuid = suser_id(@parm)
        if @parmsuid is NULL
        begin
            select @parmdbid = db_id(@parm)
            if @parmdbid is null
            begin
               print "No login exists with the supplied name."
               return (1)
            end
        end

        select
            spid,
            loginame= substring(suser_name(suid), 1, 9),
            "cpu"   =       convert(char(5),cpu%10000),
            "io"    =       convert(char(5),physical_io%10000),
            "mem"   =       convert(char(5),memusage%10000),
            dbname  =       substring(db_name(dbid), 1, 10),
            status  =       convert(char(8), status),
            cmd,
            bk      =       convert(char(4), blocked%10000),
            bktime  =       convert(char(4),isnull(time_blocked,0)),
            xcpu    =       cpu,
            xio     =       physical_io,
            xmem    =       memusage,
            xblocked =  blocked
        into   #tmp_a
        from   master..sysprocesses
        where cmd != "AWAITING COMMAND"
             and      cmd != "DEADLOCK TUNE"
             and      cmd != "ASTC HANDLER"
             and      cmd not like "HK %"
             and          cmd != "NETWORK HANDLER"
             and          cmd != "MIRROR HANDLER"
             and          cmd != "AUDIT PROCESS"
             and          cmd != "CHECKPOINT SLEEP"
--                and   suid != 0
             and   isnull(@parmdbid,dbid) = dbid
             and     isnull(@parmsuid,suid) = suid

        if @dont_format is null
        begin
            update #tmp_a set cpu="HUGE" where xcpu>=10000
            update #tmp_a set io="HUGE" where xio>=10000
            update #tmp_a set mem="HUGE" where xmem>=10000
            update #tmp_a set bk="XX" where xblocked>=100

            update #tmp_a set spid=0
            from #tmp_a t where t.spid>999
        end

        select "pid" = convert(char(4),spid),
           loginame, cpu , io  , mem , dbname , status ,
           cmd, bk
                  from   #tmp_a
    end
    else
    begin

      /* NEED TEMP TABLE FOR OVERFLOW */
    select pid = convert(char(20), spid),
           loginame= suser_name(suid),
           cpu = convert(varchar(20),cpu),
           io  = convert(varchar(20),physical_io),
           mem = convert(varchar(20),memusage),
           dbname = db_name(dbid),
           --dbname = substring(db_name(dbid), 1, 10),
           status = convert(char(8), status),
           cmd,
           bk = convert(char(20), blocked),
           bktime=convert(char(20),isnull(time_blocked,0))
    into   #tmp
    from   master..sysprocesses
    where  cmd != "AWAITING COMMAND"
-- and suid!=0
/*
         and      cmd != "DEADLOCK TUNE"
         and      cmd != "ASTC HANDLER"
         and      cmd not like "HK %"
         and      cmd != "NETWORK HANDLER"
         and      cmd != "MIRROR HANDLER"
         and      cmd != "AUDIT PROCESS"
         and      cmd != "HOUSEKEEPER"
         and      cmd != "CHECKPOINT SLEEP"
*/

			delete #tmp where loginame is null

        if @dont_format is null
        begin
           update #tmp set pid = "****"  where char_length(rtrim(ltrim(pid))) > 4
           update #tmp set cpu = "HUGE" where char_length(rtrim(ltrim(cpu))) > 5
           update #tmp set io  = "HUGE" where char_length(rtrim(ltrim(io))) > 5
           update #tmp set mem = "HUGE" where char_length(rtrim(ltrim(mem))) > 5
           update #tmp set bk  = "****" where char_length(rtrim(ltrim(bk))) > 4
           update #tmp set bktime  = "****" where char_length(rtrim(ltrim(bktime))) > 4
        end

        if @dont_format is null
        select spid = substring(pid,1,4),
           "Login"=substring(loginame, 1, 9),
           "cpu/io/mem" = substring(cpu+"/"+io+"/"+mem,1,15),
           dbname = substring(dbname, 1, 10),
           status,
           cmd,
           bk = substring(bk,1,4),
           bktm=substring(bktime,1,4)
           from #tmp
        else
        select spid = pid,
           loginame,
           cpu,
           io,
           mem,
           dbname,
           status,
           cmd,
           bk , bktm=bktime
           from #tmp
        end
   return
end
go

grant execute on sp__whodo to public
go

