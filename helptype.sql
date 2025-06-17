/* Procedure copyright(c) 1999 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helptype
|*
|* Author:
|*
|* Description: 
|*
|* Usage:       sp__helptype
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
           and    name = "sp__helptype")
begin
    drop procedure sp__helptype
end
go

create procedure sp__helptype ( @dont_format char(1)=NULL )
as
begin

-- GET USER DEFINED TYPES
select  username=user_name(t.uid),
        t.name,
        defname=object_name(t.tdefault),
        rulename=object_name(t.domain),
        t.allownulls,
        t.length,
        base_type=s.name
into    #tmp
from    systypes t , master..spt_values s
where   s.type='J'
and     s.low = t.type
--and   t.usertype>=100
order by usertype

update  #tmp
set     base_type=base_type+"("+convert(varchar,length)+")"
where   base_type='char' or base_type='varchar' or base_type='varbinary'

if @dont_format is null
        select  "TYPE"=convert(char(21),name),
                        "DEFAULT"=convert(char(13),defname),
                        "RULE"=convert(char(13),rulename),
                        "NULL"=allownulls,
                        "BASE TYPE"=convert(char(21),base_type)
from #tmp
		order by name
else
        select  "TYPE"=name,
                        "DEFAULT"=defname,
                        "RULE"=rulename,
                        "NULL"=allownulls,
                        "BASE TYPE"=base_type
from #tmp
order by name
end
go

grant execute on sp__helptype to public
go

