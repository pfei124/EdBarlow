/* Procedure copyright(c) 2005 by Ed Barlow */

/************************************************************************\
|* Procedure Name: sp__vdevno
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__vdevno
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2024        6.91
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = 'P'
           and    name = "sp__vdevno")
begin
    drop procedure sp__vdevno
end
go

create procedure sp__vdevno (
	                     @dont_format char(1)=NULL, 
	                     @no_freedev char(1)=NULL 
		            )
as
begin
    select vdevno, name from master..sysdevices
    where status&2=2
    order by vdevno

    return (0)
end
go

grant execute on sp__vdevno to public
go

