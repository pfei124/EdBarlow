
/************************************************************************\
|* Procedure Name:   sp__revbindings
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__revbindings
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

if exists ( select * from sysobjects where type = "P"
                and name = "sp__revbindings")
        drop procedure sp__revbindings
go

create procedure sp__revbindings
as
begin
create table #bindings
(
name char(30) null,
bindings char(255) null,
binding_object int null
)
--Get the bind default statement for user datatypes
insert #bindings
select name, "bindings" = substring("exec sp_bindefault",1,18)+" "+
        substring(object_name(tdefault),1,datalength(object_name(tdefault)))+
        "," + name, "binding_object" = tdefault
from systypes where usertype > 100

--Get the bind rule statement for user datatypes
insert #bindings
select name, "bindings" = substring("exec sp_bindrule",1,16)+" "+
        substring(object_name(domain),1,datalength(object_name(domain)))+
        "," + name, "binding_object" = domain
from systypes where usertype > 100

--Get the bind default statement for columns in tables
insert #bindings
select c.name, "bindings" = substring("exec sp_bindefault",1,18)+" "+
        substring(object_name(c.cdefault),1,datalength(object_name(c.cdefault)))+
        "," + "'"+ object_name(c.id)+"."+c.name +"'", "binding_object" = c.cdefault
from syscolumns c, syscomments com
where c.cdefault = com.id
and charindex('DEFAULT',text)  = 0

--Get the bind rule statement for columns in tables
insert #bindings
select c.name, "bindings" = substring("exec sp_bindrule",1,16)+" "+
        substring(object_name(c.domain),1,datalength(object_name(c.domain)))+
        "," + "'"+ object_name(c.id)+"."+c.name +"'", "binding_object" = c.domain
from syscolumns c, syscomments com
where c.domain = com.id
and charindex('CONSTRAINT',text)  = 0

select convert(char(78),bindings) from #bindings
where binding_object != 0
order by name

set nocount off
return
end
go

grant execute on sp__revbindings to public
go

