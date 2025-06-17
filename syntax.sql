/* Procedure copyright(c) 1996 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__syntax
|*
|* Author:
|*
|* Description: returns the parameter of a procedure
|*
|* Usage:
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2004  wp    x.1      char(4) for Length
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * 
	     FROM sysobjects
            WHERE name = "sp__syntax"
              AND type = "P")
   drop procedure sp__syntax
go

create procedure sp__syntax( @objname varchar(30)='%', @dont_format char(1) = NULL )
AS
BEGIN

set nocount on

if @objname is null
        select @objname="%"

select
        Proc_name = convert(char(40),o.name),
        Parameter_name = c.name,
        Type = t.name,
        Nulls = convert(bit,(c.status & 8)),
        Length = c.length,
        Prec = c.prec,
        Scale = c.scale,
        Param_order=c.colid,
        utype = t.usertype
into #collist
from syscolumns c, systypes t, sysobjects o
where c.usertype *= t.usertype
and     o.name like @objname
and     o.id = c.id
and     o.type = 'P'
order by o.name

/* Could it be in sybsystemprocs */
/* Ignore any calls to all */
if @objname != "%" and db_name() != "sybsystemprocs"
        insert #collist
        select
                Proc_name = convert(char(40),o.name),
                Parameter_name = c.name,
                Type = t.name,
                Nulls = convert(bit,(c.status & 8)),
                Length = c.length,
                Prec = c.prec,
                Scale = c.scale,
                Param_order=c.colid,
                utype = t.usertype
        from  sybsystemprocs..syscolumns c,
                        sybsystemprocs..systypes t,
                        sybsystemprocs..sysobjects o
        where c.usertype *= t.usertype
        and     o.name like @objname
        and     o.id = c.id
        and     o.type = 'P'
        order by o.name

if not exists ( select * from #collist )
begin
       print "Error: Object Does Not Exist"
       return
end

update #collist
set Type=Type+'('+rtrim(convert(char(4),Length))+')'
where Type='varchar'
or    Type='char'

update #collist
set Type=Type+'('+rtrim(convert(char(3),Prec))+')'
where Type='decimal'

update #collist
set Type=Type+'('+rtrim(convert(char(3),Prec))+')'
where Type='numeric'
and   Scale=0

update #collist
set Type=Type
        +'('
        +rtrim(convert(char(3),Prec))
        +','
        +rtrim(convert(char(3),Scale))
        +')'
where Type='numeric'
and   Scale>0

update #collist
set Type=Type+" NULL"
where Nulls = 1

update #collist
set Type=Type+" NOT NULL"
where Nulls != 1

if @dont_format is null
        select
                Proc_name,
                "Order" = Param_order,
                /* Parameter = substring(Parameter_name + " " + Type,1,30) */
                Parameter = convert(varchar(65),Parameter_name + " " + Type)
        from #collist
        order by Proc_name,Param_order
else
        select
                Proc_name,
                "Order" = Param_order,
                Parameter = Parameter_name + " " + Type
        from #collist
        order by Proc_name,Param_order

return(0)
END
go

grant execute on sp__syntax  to public
go

