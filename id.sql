/* Procedure copyright(c) 1996 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__id
|*
|* Author:
|*
|* Description:
|*
|* Usage:  sp__id
|*
|* Modification History:
|* Date        Who      What
|* dd.mm.yyyy  pfei124  format
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select * from sysobjects
           where  name = "sp__id"
           and    type = "P")
   drop procedure sp__id

go

/*---------------------------------------------------------------------------*/

create procedure sp__id ( @dont_format char(1) = null )
AS
BEGIN

set nocount on

select
        "server"=convert(char(15),@@servername),
        "db"=convert(char(20),db_name()),
        "login"=convert(char(17),suser_name()),
        "suid"=convert(char(4),suser_id()),
        "user name"=convert(char(17),user_name())
return(0)
END

go

grant execute on sp__id  to public
go

