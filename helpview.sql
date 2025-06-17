/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpview
|*
|* Author:
|*
|* Description:
|*
|* Usage:
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

if exists (SELECT * 
	     FROM sysobjects
            WHERE name = 'sp__helpview'
              AND type = 'P')
   drop procedure sp__helpview
go

create procedure sp__helpview ( 
                               @objname char(30) = NULL,
                               @dont_format char(1) = NULL
                              )
AS
begin
	declare @searchobj sysname
	if @objname is null
		select @searchobj='%'
	else
		select @searchobj='%'+@objname+'%'

	select view_name = o.name,
		o.uid,
		o.crdate,
		c.colid,
		value = c.text
--( select text from syscomments c where c.id=o.id and colid=1 )
	into   #helpview
	from   sysobjects o, syscomments c
	where  o.name like @searchobj
	and    o.type = 'V'
	and	 o.id=c.id
	order  by o.name

if exists (select * from sysobjects where name=@objname and type='V' )
     delete #helpview where view_name!= @objname

if not exists ( select * from #helpview )
begin
        if @objname is not null
                print 'View Not Found'
        else
                print 'No Views In Database'
        return
end

update #helpview
set    view_name = user_name(uid)+'.'+view_name
where  uid!=1

/* delete everything until first as */
/* get rid of newlines from definition */
update #helpview
set    value = lower(value)

while 1=1
begin
        update #helpview
        set    value=stuff(value,charindex(char(10),value),1,' ')
        where  charindex(char(10),value)!=0

        if @@rowcount = 0
        begin
                  update #helpview
                  set    value=stuff(value,charindex(char(14),value),1,' ')
                  where  charindex(char(14),value)!=0
                  if @@rowcount = 0 break
        end
end

/* the from clause should be ' from ' at this stage */
-- update #helpview
-- set    value = ""
-- where  patindex('% from %',value) = 0
--
-- update #helpview
-- set    value = substring(value,patindex('% from %',value)+6,120)
-- where 	patindex('% from %',value) != 0

-- update #helpview
-- set    value = substring(value,1,patindex('% where %',value))
-- where substring(value,1,patindex('% where %',value)) is not null
-- and 	patindex('% where %',value) != 0

if @dont_format='Y'
begin
select view_name     'View Name' ,
       convert(char(2),crdate,6)
       	+substring(convert(char(9),crdate,6),4,3)
         +substring(convert(char(9),crdate,6),8,2) 'Cr Date',
       value                 'Text'
from #helpview
order by view_name
end
else
begin
select substring(view_name,1,20)     'View Name' ,
       convert(char(2),crdate,6)
       	+substring(convert(char(9),crdate,6),4,3)
         +substring(convert(char(9),crdate,6),8,2) 'Cr Date',
       convert(char(45),value)                 'Text'
from #helpview
order by view_name
end

drop table #helpview
end
go

grant execute on sp__helpview  to public
go

