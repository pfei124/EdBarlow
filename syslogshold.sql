
/************************************************************************\
|* Procedure Name: sp__syslogshold
|*
|* Author:      ?
|*
|* Description:
|*
|* Usage:       sp__syslogshold
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 10.01.2025  wp    x.xx     recovered
|*
\************************************************************************/


use sybsystemprocs
go

if exists (select * from sysobjects
            where name = "sp__syslogshold"
              and type = "P")
   drop procedure sp__syslogshold
go

create procedure sp__syslogshold as
select P.hostname, P.hostprocess, H.dbid, User_name = L.name, P.suid, 
       P.spid, P.program_name, H.starttime, P.cmd, H.name 
  into #result_syslogshold 
  from master.dbo.sysprocesses P, master.dbo.syslogshold H, master.dbo.syslogins L
 where P.spid = H.spid and P.suid = L.suid
exec sp_autoformat @fulltabname = #result_syslogshold
declare c cursor for select spid from  #result_syslogshold
declare @spid int
open c
fetch c into @spid
while @@sqlstatus=0
begin
   print "sqltext '%1!'", @spid
   dbcc traceon(3604)
   dbcc sqltext(@spid)
   dbcc traceoff(3604)
   fetch c into @spid
end
close c
deallocate cursor c
drop table #result_syslogshold
go

grant execute on sp__syslogshold to public
go

