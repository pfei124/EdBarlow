/* Procedure copyright(c) 1993-1995 by Simon Walker */

/************************************************************************\
|* Procedure Name:   sp__who
|*
|* Author:
|*
|* Description:      
|*
|* Usage:  sp__who
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
         where  type = 'P'
         and    name = "sp__who")
begin
    drop procedure sp__who
end
go

create procedure sp__who (
	                  @parm varchar(30) = null, 
			  @dont_format char(1) = null
		         )
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
               print "No login or database exist with the supplied name."
               return (1)
            end
        end

        select spid= convert(varchar(4), spid),
               Login= convert(varchar(12),suser_name(suid)),
               hostInfo=convert(varchar(35),rtrim(hostname)+" "+rtrim(program_name)+" "+rtrim(hostprocess)),
               dbname=convert(varchar(12),db_name(dbid)),
               Status=convert(varchar(10), status),
               cmd=convert(varchar(16), cmd),
               bk = convert(varchar(4), blocked)
        from  master..sysprocesses
        where isnull(@parmdbid,dbid) = dbid
        and   isnull(@parmsuid,suid) = suid
    end
    else

	if @dont_format is not null
	begin
           select spid = spid,
                  Login= suser_name(suid),
                  HostInfo= case
			when hostname != "" and program_name != ""
   			then substring(rtrim(hostname)+ "("+rtrim(program_name)+")",1,35)
			when hostname != ""
   			then substring(rtrim(hostname),1,35)
			else ""
			end,
                  dbname = db_name(dbid),
                  Status = status,
                  cmd,
                  bk = blocked
                  /* ,bktm=time_blocked */
           from   master..sysprocesses
	   where suid!=0
	end
	else
	begin
           select spid = convert(char(4), spid),
                  Login= convert(varchar(12),suser_name(suid)),
                  HostInfo= case
                            when hostname != "" and program_name != ""
                            then convert(varchar(35),rtrim(hostname)+"("+rtrim(program_name)+")")
                            when hostname != ""
                            then convert(varchar(35),rtrim(hostname))
                            else ""
                            end,
                  DBname = convert(varchar(12),db_name(dbid)),
                  Status = convert(varchar(10), status),
                  cmd=convert(varchar(16), cmd),
                  bk = convert(varchar(4), blocked)
           from   master..sysprocesses
	   where suid!=0
	end

    return
end
go

grant execute on sp__who to public
go

