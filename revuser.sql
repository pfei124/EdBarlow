/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__revuser
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
\************************************************************************/

use sybsystemprocs 
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revuser")
begin
    drop procedure sp__revuser
end
go

create procedure sp__revuser( @dont_format char(1) = null)
as
begin
        /* Get Regular Users */
        select  "exec sp_adduser '"+m.name+"','"+u.name+"','"+g.name+"'"
        from    sysusers u, sysusers g, master.dbo.syslogins m
        where   u.suid = m.suid
        and     u.gid  = g.uid
			and     u.name not like '%_role'
        and     u.uid  != u.gid
        and       u.suid!=1
        and     u.uid not in ( select uid from model..sysusers )
	and     m.name!='probe'

    return (0)
end
go

grant execute on sp__revuser to public
go

