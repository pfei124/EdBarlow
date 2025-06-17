/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__colnull
|*
|* Author:
|*
|* Description:
|*
|* Usage:  sp__colnull
|*
|* Modification History:
|*
|* Date        Who      What
|* dd.mm.yyyy  pfei124  format
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * 
	     FROM sysobjects
            WHERE name = "sp__colnull"
              AND type = "P")
   drop procedure sp__colnull

go

create procedure sp__colnull ( 
                              @objname char(32) = NULL, 
			      @show_type char(1)=' ',
                              @dont_format char(1) = NULL
                             )
/* if @show_type = 'S' will show system tables */
AS

set nocount on

if not exists (select * from sysobjects where name=@objname and type='U')
        select @objname="%"+@objname+"%"

select distinct
                 column= c.name,
                 tname=  o.name,
                 type =  t.name,
                 length=c.length,
                 c.status,
                 Nulls="not null",
                 Ident = "identity",
                 c.prec,
                 c.scale
into   #colnull
from   syscolumns c, systypes t, sysobjects o
where  c.id = o.id         /* key */
and    o.name like @objname
and    c.number = 0
and    c.usertype = t.usertype
and    o.type in ('U', @show_type )

update #colnull
set type=type+'('+rtrim(convert(char(4),length))+')'
where type='varchar'
or    type='char'

update #colnull
set type=type+'('+rtrim(convert(char(4),prec))+')'
where type='decimal'
and   scale=0

update #colnull
set type=type+'('+rtrim(convert(char(4),prec))+','+convert(char(4),scale)+')'
where type='decimal'
and   scale>0

update #colnull
set type=type+'('+rtrim(convert(char(4),prec))+')'
where type='numeric'
and   scale=0

update #colnull
set type=type
        +'('
        +rtrim(convert(char(4),prec))
        +','
        +rtrim(convert(char(4),scale))
        +')'
where type='numeric'
and   scale>0

update #colnull
set  Nulls='null'
where status & 8 != 0

if @dont_format is null
select distinct "Column"=substring(t1.column,1,20),
                "Table"=substring(t1.tname,1,20),
                "Defn"=substring(t1.type,1,15),
                "Null"=t1.Nulls
from #colnull t1,#colnull t2
where t1.column=t2.column
and    t1.Nulls!=t2.Nulls
order by t1.column,t1.type,t1.Nulls
else
select distinct
                "Column"=t1.column,
                "Table"=t1.tname,
                "Defn"=t1.type,
                "Null"=t1.Nulls
from #colnull t1,#colnull t2
where t1.column=t2.column
and    t1.Nulls!=t2.Nulls
order by t1.column,t1.type,t1.Nulls

drop table #colnull
go

grant execute on sp__colnull  to public
go

