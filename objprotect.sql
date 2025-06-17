/* Procedure copyright(c) 1997 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__objprotect
|*
|* Author:
|*
|* Description:      permissions by object vs sel/upd/ins/del
|*                   optionally can pass in user or group and it will filter
|*                   only works on full table info (not on column stuff)
|*
|* Usage:  sp__objprotect
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

if exists (select * from sysobjects
           where  name = "sp__objprotect"
           and    type = "P")
begin
   drop procedure sp__objprotect
end
go

create procedure sp__objprotect(
                @groupname char(30) = NULL
)
as
set nocount on

select uid,name
into   #good_uids
from   sysusers
where  (( uid=gid and @groupname is null ) or ( name = @groupname ))
and  uid not between 16380 and 16399
--and	name not like '%X_role' escape 'X'
--and	name not like 'dbX_%' escape 'X'
--and    name not in ( 'replication_role', 'navigator_role',
--'sybase_ts_role',
--'oper_role',
--'sso_role',
--'sa_role')

select o.name,id,type,grpname=g.name,permitted="       "
into   #objects
from   sysobjects o,#good_uids g
where  o.uid=1 and type not in ('D','R','S','TR')

update #objects set permitted=""

-- Add Selects
update  #objects
set     permitted="S"+permitted
from    sysprotects p, #good_uids g, #objects o
where   o.id=p.id
and     o.grpname = g.name
and     g.uid = p.uid
and     p.action=193
and     isnull(columns,0x01) = 0x01
and     protecttype<=1

-- Add Updates
update  #objects
set     permitted="U"+permitted
from    sysprotects p, #good_uids g, #objects o
where   o.id=p.id
and     o.grpname = g.name
and     g.uid = p.uid
and     p.action=197
and     isnull(columns,0x01) = 0x01
and     protecttype<=1

-- Add Deletes
update  #objects
set     permitted="D"+permitted
from    sysprotects p, #good_uids g, #objects o
where   o.id=p.id
and     o.grpname = g.name
and     g.uid = p.uid
and     p.action=196
and     isnull(columns,0x01) = 0x01
and     protecttype<=1

-- Add Inserts
update  #objects
set     permitted="I"+permitted
from    sysprotects p, #good_uids g, #objects o
where   o.id=p.id
and     o.grpname = g.name
and     g.uid = p.uid
and     p.action=195
and     isnull(columns,0x01) = 0x01
and     protecttype<=1

-- Add Executes
update  #objects
set     permitted="E"+permitted
from    sysprotects p, #good_uids g, #objects o
where   o.id=p.id
and     o.grpname = g.name
and     g.uid = p.uid
and     p.action=224
and     isnull(columns,0x01) = 0x01
and     protecttype<=1

--update #objects set r=( select count(*)
--from sysprotects p,  #good_uids g
--where o.id=p.id
--and isnull(columns,0x01) = 0x01
--and protecttype=2
--and g.uid = p.uid )
--from #objects o
--
--select name,type, sel=convert(char(6),s),upd=convert(char(6),u),del=convert(char(6),d),ins=convert(char(6),i),rev=convert(char(6),r),exe=convert(char(6),e)
--from #objects
--order by type,name

select 
convert(char(15),type) type,
convert(char(20),name) name,
convert(char(20),grpname) grpname,
convert(char(10),permitted),permitted
from #objects
order by type,name,grpname
return (0)
go

grant execute on sp__objprotect to public
go

