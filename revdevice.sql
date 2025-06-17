/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revdevice
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__revdevice
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
           and    name = "sp__revdevice")
begin
    drop procedure sp__revdevice
end
go

create procedure sp__revdevice ( @dont_format char(1) = null)
as

set nocount on

create table #tmp
(
        txt     varchar(127),
        grp   int
)

create table #dev_tbl
(
        name            char(30) not null,
        phyname         varchar(127),
        disk_size       int      null,
        status          int      null,
        vdevno          int      null
)

insert  #dev_tbl
select  name=d.name,
        phyname = d.phyname,
        disk_size = 1. + (d.high - d.low),
        status=d.status,
        vdevno =  d.vdevno
from master.dbo.sysdevices d,
           master..spt_values v
    where  v.type = "E"
    and    v.number = 3

insert #tmp values("/********* BACKUP DEVICES *********/",1)

insert #tmp
select  "exec sp_addumpdevice 'tape','"+ltrim(rtrim(d.name))+"','"+ltrim(rtrim(d.phyname))+"',2",2
from #dev_tbl d
where d.status & 2 != 2
and   d.name not in ("diskdump","tapedump1","tapedump2")
and 	d.status & 16 = 16

insert #tmp
select  "exec sp_addumpdevice 'disk','"+ltrim(rtrim(d.name))+"','"+ltrim(rtrim(d.phyname))+"',2",2
from #dev_tbl d
where d.status & 2 != 2
and   d.name not in ("diskdump","tapedump1","tapedump2")
and 	d.status & 16 != 16

insert #tmp values("",3)
insert #tmp values("/****** PHYSICAL DISK DEVICES ******/",4)

insert #tmp
select  "disk init name='"+ltrim(rtrim(name))+"',"+
        "physname='"+ltrim(rtrim(phyname))+"',"+
        "vdevno="+convert(char(6),vdevno)+","+
        "size="+convert(char(20),disk_size),5
from  #dev_tbl
where status & 2 = 2
and   vdevno!=0

select txt from #tmp order by grp
return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__revdevice to public
go

