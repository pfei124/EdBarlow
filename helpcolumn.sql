/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpcolumn
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__helpcolumn
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
            WHERE name = "sp__helpcolumn"
              AND type = "P")
   drop procedure sp__helpcolumn
go

create procedure sp__helpcolumn (
		                 @objname varchar(30)=NULL,
                                 @colname varchar(30)=NULL,
                                 @dont_format char(1) = NULL 
			        )
AS
BEGIN

set nocount on
if @objname is not null and @colname is null
begin
  if object_id(	@objname ) is null
    begin
       select @colname=@objname
       select @objname=null
    end
end

create table #column_info
(
   Table_name char(30),
   uid smallint,
   Column_name char(30),
   Type varchar(30),
   Length int,
   Nulls bit,
   Nulls2 char(3),
   Default_name char(30) null,
   Rule_name char(30) null,
   rtype tinyint null,
   utype smallint null,
   Ident bit,
   colid smallint,
   prec tinyint null,
   scale tinyint null
)

if @objname is null and @colname is null
begin
 insert  #column_info
 select
        Table_name=o.name,
        o.uid,
        Column_name = c.name,
        Type =  t.name,
        Length = c.length,
        Nulls = convert(bit, (c.status & 8)),
        Nulls2= "No",
        Default_name = object_name(c.cdefault),
        Rule_name = object_name(c.domain),
        rtype = t.type, utype = t.usertype,
        Ident =  convert(bit, (c.status & 0x80)),
        colid, c.prec, c.scale
 from  syscolumns c, systypes t, sysobjects o
 where c.usertype *= t.usertype
 and   c.id = o.id
 and   o.type in ('U',@dont_format)
end
else if @colname is null
 begin

  if not exists ( select * from sysobjects where name=@objname and type in ('U','V','S') )
  begin
        declare @msg char(127)
        select  @msg="sp__helpcolumn: unknown object "+@objname
        print   @msg
        return
  end

  insert  #column_info
  select
        @objname,
        1,
   	  Column_name = c.name,
        Type =  t.name,
        Length = c.length,
        Nulls = convert(bit, (c.status & 8)),
        Nulls2= "No",
        Default_name = object_name(c.cdefault),
        Rule_name = object_name(c.domain),
        rtype = t.type,
        utype = t.usertype,
        Ident =  convert(bit, (c.status & 0x80)),
        colid,
        c.prec,
        c.scale
  from  syscolumns c, systypes t
  where c.id = object_id(@objname)
  and    c.usertype *= t.usertype
 end
else
 begin
  insert  #column_info
  select
        o.name,
        1,
   	  Column_name = c.name,
        Type =  t.name,
        Length = c.length,
        Nulls = convert(bit, (c.status & 8)),
        Nulls2= "No",
        Default_name = object_name(c.cdefault),
        Rule_name = object_name(c.domain),
        rtype = t.type, utype = t.usertype,
        Ident =  convert(bit, (c.status & 0x80)),
        colid, c.prec, c.scale
  from  syscolumns c, systypes t, sysobjects o
  where c.usertype *= t.usertype
  and   c.id = o.id
  and   o.type in ('U',@dont_format)
  and   c.name = @colname
  and   o.name = isnull(@objname,o.name)
 end

update #column_info
set Nulls2="Yes"
where Nulls=1

/* Handle National Characters */
 -- update #column_info
        -- set Length = Length / @@ncharsize
        -- where (rtype = 47 and utype = 24)
        -- or        (rtype = 39 and utype = 25)

 update #column_info
 set     Type=Type+"("+ltrim(convert(varchar(4),Length))+")"
 where   Type="char" or Type="varchar"

-- DECIMAL
update #column_info
set Type=Type+'('+rtrim(convert(varchar(4),prec))
where Type='decimal'

update #column_info
set Type=rtrim(Type)+","+convert(varchar(4),scale)
where substring(Type,1,7)='decimal' and scale>0

update #column_info
set Type=rtrim(Type)+")"
where substring(Type,1,7)='decimal'

update #column_info
set Type=Type+'('+rtrim(convert(varchar(4),prec))+')'
where Type='numeric'
and   scale=0

update #column_info
set Type=Type
        +'('
        +rtrim(convert(varchar(4),prec))
        +','
        +rtrim(convert(varchar(4),scale))
        +')'
where substring(Type,1,7)='numeric'
and   scale>0

update #column_info
set    Table_name=user_name(uid)+"."+Table_name
where   uid > 1

if @dont_format is not null and @objname is null
begin
 select
         "Column name" = Column_name,
         "Type" = Type,
         Ident,
         "Null"=Nulls2,
         Default_name "Default",
         Rule_name "Rule",
         Table_name "Table",
         "Num"=colid
 from #column_info
 order by Column_name,Table_name
end
else if @dont_format is not null and @objname is not null
begin
 select
         "Column name" = Column_name,
         "Type" = Type,
         Ident,
         "Null"=Nulls2,
         Default_name "Default",
         Rule_name "Rule",
         Table_name "Table",
         "Num"=colid
 from #column_info
 order by colid,Table_name
end
else if @objname is null
 select distinct
         "Column name" = convert(char(20), Column_name),
         "Type" = convert(char(13), Type),
         "I"=Ident,
         "Null"=Nulls2,
         convert(char(4), isnull(Default_name,"")) "Dflt",
         convert(char(4), isnull(Rule_name,"")) "Rule",
         convert(char(20),Table_name) "Table",
         "Num"=colid
 from #column_info
 order by Column_name,Table_name
else
 select distinct
         "Column name" = convert(char(20), Column_name),
         "Type" = convert(char(13), Type),
         "I"=Ident,
         "Null"=Nulls2,
         convert(char(4), isnull(Default_name,"")) "Dflt",
         convert(char(4), isnull(Rule_name,"")) "Rule",
         convert(char(20),Table_name) "Table",
         "Num"=colid
 from #column_info
 order by colid,Table_name

 drop table #column_info

return(0)
END
go

grant execute on sp__helpcolumn  to public
go

