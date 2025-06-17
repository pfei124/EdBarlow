/* Procedure copyright(c) 2007 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__show_tempdb
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__show_tempdb
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2024        6.91
|*
\************************************************************************/

use sybsystemprocs
go

if exists (SELECT *
           from   sysobjects
           where  type = "P"
           and    name = "sp__show_tempdb")
begin
    drop procedure sp__show_tempdb
end
go

/* If servrname is set, select srvname,getdate,errors */
create procedure sp__show_tempdb
as
begin
select name = convert(varchar(30),rtrim(o.name)),
       row_cnt = rowcnt(i.doampg),
       reserved = (reserved_pgs(i.id, i.doampg) + reserved_pgs(i.id, i.ioampg)),
       owner_spid = substring(right(o.name,17), 3, 5),
       nestlevel  = substring(right(o.name,17), 1, 2),
       s.spid
from   sysobjects o, sysindexes i, master..sysprocesses s
where  i.id = o.id
and    o.type="U"
and    o.name like '#%'
and    convert(int,substring(right(o.name,17), 3, 5))=s.spid
and    rowcnt(i.doampg)>1000

end
go

grant execute on sp__show_tempdb to public
go

