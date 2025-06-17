/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revgroup 
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__revgroup 
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
           and    name = "sp__revgroup")
begin
    drop procedure sp__revgroup
end
go

create procedure sp__revgroup( @dont_format char(1) = null )
as
begin
        /* Get Regular Users */
        select  "exec sp_addgroup '"+name+"'"
        from    sysusers u
        where   u.uid  = u.gid
			and     name not like '%_role'
        and      uid!=0
        and   uid not in ( select uid from model..sysusers )

    return (0)
end
go

grant execute on sp__revgroup to public
go

