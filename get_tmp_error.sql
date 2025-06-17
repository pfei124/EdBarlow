/* Procedure copyright(c) 1996 by Ed Barlow */
/* Forgive this one - I need it for other stuff */

/************************************************************************\
|* Procedure Name: sp__get_tmp_error
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__get_tmp_error
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
           and    name = "sp__get_tmp_error")
begin
    drop procedure sp__get_tmp_error
end
go

create table #error ( msg varchar(127) not NULL )
go

create procedure sp__get_tmp_error
as
        select msg from #error
go

grant execute on sp__get_tmp_error to public
go

