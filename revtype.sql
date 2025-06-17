
/************************************************************************\
|* Procedure Name: sp__revtype 
|*
|* Author:         Ed Barlow
|*
|* Description:
|*
|* Usage:
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 19.09.2000  EMB   
|*
\************************************************************************/


use sybsystemprocs 
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revtype")
begin
    drop procedure sp__revtype
end
go

create procedure sp__revtype
as
begin


-- GET USER DEFINED TYPES
select  username=user_name(t.uid),
        t.name,
        defname=object_name(t.tdefault),
        rulename=object_name(t.domain),
        t.allownulls,
        t.length,
        t.prec,
        t.scale,
        t.ident,
        base_type=s.name
into    #tmp
from    systypes t , master..spt_values s
where   s.type='J'
and     s.low = t.type
and     t.usertype>=100

update  #tmp
set     base_type=base_type+"("+convert(varchar(3),length)+")"
where   (base_type='char' or base_type='varchar' or base_type='varbinary')

update  #tmp
set     base_type=base_type+"("+convert(varchar(3),prec)+")"
where   ( base_type='decimal' or base_type='numeric' )
and     scale=0

update  #tmp
set     base_type=base_type+"("+
                convert(varchar(3),prec)+
                ","+
                convert(varchar(3),scale)+
                ")"
where   ( base_type='decimal' or base_type='numeric' )
and     scale>0

select  convert(char(78),'exec sp_addtype ' +
        rtrim(name)+",'"+
        base_type+"'"+
        substring(',"identity"',1,20*ident)+
        isnull(substring(',"not null"',1,20-10*allownulls-10*ident),"")+
        substring(',"null"',1,20*allownulls))
from #tmp

end
go

grant execute on sp__revtype to public
go

