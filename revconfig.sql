/* Procedure copyright(c) 2006 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revconfigure
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__revconfigure
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
           and    name = "sp__revconfigure")
begin
    drop procedure sp__revconfigure
end
go

create procedure sp__revconfigure
as
begin

  select distinct "exec sp_configure '"+rtrim(x.comment)+"',"+isnull(c.value2,convert(char(10),c.value))
        from     master..sysconfigures x,              -- For the name
                 master..syscurconfigs c,              -- For the values
                 master..sysconfigures c2              -- parent
        where    c.config=x.config
        and      x.parent=c2.config
        and      x.comment != c2.name
        -- and x.comment != x.name
        and      x.parent!=19                          -- No Caching Messages
        and      c.config!=19
        and      x.config!=19
        and      c.value2 != c.defvalue                -- changed
        and c.config not in ( 114,153,158,132,104 )

end
go

grant exec on sp__revconfigure to public
go

