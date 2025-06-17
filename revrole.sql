
/************************************************************************\
|* Procedure Name:   sp__revrole
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__revrole
|*
|* Modification History:
|* Date        Version Who           What
|* dd.mm.yyyy  x.y
|*
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select * from sysobjects
                where name = "sp__revrole" )
        drop procedure sp__revrole
go

create procedure sp__revrole
as
begin
set nocount on
select "exec sp_role 'grant', " +
                rtrim(r.name)+","+
                suser_name(lr.suid)
        from master..sysloginroles lr, master..syssrvroles r
        where r.srid = lr.srid
   and   suser_name(lr.suid) != 'sa'

return
end
go

grant execute on sp__revrole to public
go

