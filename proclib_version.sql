/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__proclib_version
|*
|* Author:
|*
|* Description: returns the version of Extended Stored Procedure Library
|*
|* Usage:
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
           where  type = "P"
           and    name = "sp__proclib_version")
begin
    drop procedure sp__proclib_version
end
go

/* If @dbname=NoPrint no print statements will be run */
create procedure sp__proclib_version ( @dont_format char(1) = null)
as

select 6.91

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__proclib_version to public
go

