/* Procedure copyright(c) 1993-1995 by Simon Walker */

/************************************************************************\
|* Procedure Name: sp__trigger
|*
|* Author: Simon Walker
|*
|* Description:
|*
|* Usage:       sp__trigger
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
           and    name = "sp__trigger")
begin
    drop procedure sp__trigger
end
go

create procedure sp__trigger (
		              @table_name char(30) = NULL,
                              @dont_format char(1) = NULL
                             )
as
begin
    declare @deflt char(30)

    select @deflt = "...................."

if ( @dont_format is null )
    select "table name" = substring(name,1,30),
           "insert trigger" = substring(isnull(object_name(instrig),@deflt),1,18),
           "update trigger" = substring(isnull(object_name(updtrig),@deflt),1,18),
           "delete trigger" = substring(isnull(object_name(deltrig),@deflt),1,18)
    from   sysobjects
    where  type = "U"
    and    name = isnull(@table_name, name)
    order by name
else
    select "table name" = name,
           "insert trigger" = isnull(object_name(instrig),@deflt),
           "update trigger" = isnull(object_name(updtrig),@deflt),
           "delete trigger" = isnull(object_name(deltrig),@deflt)
    from   sysobjects
    where  type = "U"
    and    name = isnull(@table_name, name)
    order by name

    return (0)
end
go

grant execute on sp__trigger to public
go

