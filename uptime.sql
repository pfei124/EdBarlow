/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__uptime
|*
|* Author:
|*
|* Description:
|*
|* Usage:  sp__uptime
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

if exists (SELECT * 
	     FROM sysobjects
            WHERE name = 'sp__uptime'
              AND type = 'P')
   drop procedure sp__uptime
go

create procedure sp__uptime
AS
begin
   select @@SERVERNAME, crdate
   from master..sysdatabases 
   where dbid=db_id('tempdb')
end
go

grant execute on sp__uptime  to public
go

