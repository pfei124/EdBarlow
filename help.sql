/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__help
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__help
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
           and    name = "sp__help")
begin
    drop procedure sp__help
end
go

create procedure sp__help ( 
	                   @object varchar(92) = NULL,
                           @dont_format char(1) = null
                          )
as
begin

   declare @msg char(128),@x int
   set nocount on

   if @object is not null
   begin
      /* Not a table view or system proc */
      if not exists ( select * from sysobjects where name=@object
                      and type in ('U','V','S') )
        begin
          execute sp_help @object
          return
        end

/*      select
                       Name = o.name,
                       Owner = convert(char(17),user_name(uid)),
                       Object_type = convert(char(22), m.description + x.name)
             from sysobjects o, master.dbo.spt_values  v,
                       master.dbo.spt_values x, master.dbo.sysmessages m
             where o.sysstat & 2055 = v.number
                       and v.type = "O"
                       and v.msgnum = m.error
                       and m.error between 17100 and 17109
                       and o.name = @object
                       and x.type = "R"
                       and o.userstat &  -32768 = x.number
                       -- to separate proxy tables
                       and sysstat2&1024 = 1024
             order by Object_type desc, Name asc
*/
      if exists ( select * from sysobjects
                  where name=@object
                  and type in ('U','V','S') )
        begin
            /* Trigger Info */
            exec sp__trigger @object

            /* Column Information */
            exec sp__helpcolumn @object

            /* Basic Index Information (why not) */
            print ""
            print "**** Index Information ****"
            exec sp__helpindex @object=@object, @no_print='Y', @dont_format=@dont_format

               -- exec sp_helpconstraint @object
        end
   end
   else
   begin
       select  c.id,c.text
       into    #tmp
       from    sysobjects  o, syscomments c
       where   c.id=o.id
       and     o.type in ('D','R')
       and             o.name not like '%[0-9]'

       delete #tmp
       from #tmp t, sysconstraints c
       where c.constrid=t.id

       insert #tmp
       select c.id,text=c.name
                        from   syscolumns c
                        where  c.colid=1
                        and    c.name like '@%'

       select @x=2
       while ( @x < 16 )
       begin
          update #tmp
          set    text=text+", "+c.name
          from   syscolumns c,#tmp t
          where  c.id=t.id
          and    c.colid=@x

          if @@rowcount=0
             break

          select @x=@x+1
       end

       select
            Name        = convert(char(35),o.name),
            Owner       = convert(char(10),user_name(uid)),
            Object_type = convert(char(20), v.name),
            Notes       = convert(char(50),t.text)
       from sysobjects o, master.dbo.spt_values  v,#tmp t
       where o.sysstat & 2055 = v.number
       and   o.type!='S'
       and   ( o.name not like '%[0-9]' or o.type != 'D' )
       and   v.type = "O"
       and   t.id=*o.id
       order by Object_type desc, Name asc
   end
end
go

grant execute on sp__help to public
go

