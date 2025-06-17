/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpdefault
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__helpdefault
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

if exists (select * from sysobjects
           where  name = "sp__helpdefault"
           and    type = "P")
   drop procedure sp__helpdefault
go

create procedure sp__helpdefault (
                                  @objname       varchar(92) = NULL,
                                  @dont_format   char(1) = NULL
                                 )
as
begin

select  default_name = name,
        uid,
        o.id,
        times_used = ( select count(*) from syscolumns
                       where cdefault=o.id ),
        value = ( select text from syscomments c
                  where c.id=o.id and colid=1)
into    #dflts
from    sysobjects o
where   name like "%"+@objname+"%"
and     type = "D"
order  by name

if exists (select * from sysobjects where name=@objname and type='D' )
      delete #dflts
      where default_name!= @objname

if not exists ( select * from #dflts )
begin
        if @objname is not null
             print "Default Not Found"
        else
             print "No Defaults In Database"
        return
end

update #dflts
set      default_name = user_name(uid)+'.'+default_name
where  uid!=1

/* get rid of newlines from definition */
while 1=1
begin
        update #dflts
        set    value=stuff(value,charindex(char(10),value),1,' ')
        where  charindex(char(10),value)!=0

        if @@rowcount = 0
        begin
              update #dflts
              set    value=stuff(value,charindex(char(14),value),1,' ')
              where  charindex(char(14),value)!=0
              if @@rowcount = 0 break
        end
end

/* delete word default */
update #dflts
set    value = substring(value,7,255)
where  value like "DEFAULT%"

/* delete everything until first as */
/* there should be a string ' as ' at this stage */
update #dflts
set    value = substring(value,patindex('% as %',value)+4,120)

select substring(default_name,1,20)            "Default Name" ,
                 convert(char(10),times_used)  "Times Used",
                 object_name(c.id)+"."+c.name  "Column Name",
                 convert(char(46),value)       "Definition"
from #dflts d, syscolumns c
where c.cdefault = d.id
order by default_name

drop table #dflts
END
go

grant execute on sp__helpdefault  to public
go

