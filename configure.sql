/* Procedure copyright(c) 1999 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__configure
|*
|* Author:
|*
|* Description:
|*
|* Usage: 
|*
|* Modification History:
|*
|* Date        Who     Version What
|* 
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__configure")
begin
    drop procedure sp__configure
end
go

create procedure sp__configure ( @dont_format char(1) = null, @doall char(1) = null )
as
begin

	if @doall is not null
	begin
        select distinct Category  =c2.name, Parameter=x.comment, Value=c.value, CharValue=c.value2, DefValue=c.defvalue
        from     master..sysconfigures x,               -- For the name
                 master..syscurconfigs c,               -- For the values
                 master..sysconfigures c2               -- parent
        where    c.config=x.config
        and      x.parent=c2.config
        and      x.comment != c2.name

	  	  return
	end

        select distinct
                Category    = c2.name     ,
                Parameter   = x.comment   ,
                Value       = c.value     ,
                CharValue   = c.value2    ,
                DefValue    = c.defvalue
        into     #tmp
        from     master..sysconfigures x,         -- For the name
                 master..syscurconfigs c,         -- For the values
                 master..sysconfigures c2         -- parent
        where     c.config=x.config
        and       x.parent=c2.config
        and       x.comment != c2.name
        --        and       x.comment != x.name
        and       x.parent!=19    -- No Caching Messages
        and       c.config!=19
        and       x.config!=19
        and       (  c.value2 != c.defvalue        -- changed
        or        c.config in (103,104,137,138,139,126,122,123,124,106,107,116))
        -- commonly need to be changed

        if @dont_format is not null
                select   "Category"    = Category,
                         "Option Name" = Parameter,
                         "Value"       = isnull(CharValue,convert(char(10),Value)),
                         "Default"     = DefValue
                from #tmp
                order by Parameter
        else
                select   "Category"    = convert(char(32),Category),
                         "Option Name" = convert(char(32),Parameter),
                         "Value"       = convert(char(16),isnull(CharValue,convert(char(16),Value))),
                         "Default"     = convert(char(16),DefValue)
                from #tmp
                order by Parameter

        drop table #tmp

end
go

grant exec on sp__configure to public
go

