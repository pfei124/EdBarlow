/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revalias
|*
|* Author:
|*
|* Description:
|*
|* Usage:
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
           and    name = "sp__revalias")
begin
    drop procedure sp__revalias
end
go

create procedure sp__revalias ( @dont_format char(1) = null)
as
begin
         select  "exec sp_addalias '"+m.name+"','"+u.name+"'"
         from    sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
         where   a.suid = m.suid
         and     u.gid  = g.uid
         and     u.uid  != u.gid
         and     a.altsuid=u.suid
         and     a.altsuid not in ( select altsuid from model..sysalternates )

    return (0)
end
go

grant execute on sp__revalias to public
go

