/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__collist
|*
|* Author:
|*
|* Description:  list distinct columns in current databases
|*
|* Usage:  sp__collist
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
	    WHERE name = "sp__collist"
	      AND type = "P")
   drop procedure sp__collist
go

create procedure sp__collist (
                              @objname char(32) = NULL,
                              @colname char(30) = NULL,
                              @show_type char(1)=' ',
                              @dont_format char(1)=NULL 
                             )
/* if @show_type = 'S' will show system tables */
AS
set nocount on

if @objname is not null and @colname is null
begin
	if object_id(	@objname ) is null
	begin
		select @colname=@objname
		select @objname=null
	end
end

select column= substring(c.name, 1, 20),
		 tname=  substring(c.name,1,20),
		 type =substring(t.name,1,15),
		 length=c.length,
		 c.status,
		 Nulls="not null",
		 Ident = "identity",
		 c.prec,
		 c.scale,
		 c.colid
into   #collist
from   syscolumns c, systypes t
where  1=2

insert #collist
select distinct
		 column= substring(c.name, 1, 20),
		 tname=  substring(o.name,1,20),
		 type =substring(t.name,1,15),
		 length=c.length,
		 c.status,
		 Nulls="not null",
		 Ident = "identity",
		 c.prec,
		 c.scale,
		 c.colid
from   syscolumns c, systypes t, sysobjects o
where  c.id = o.id	 /* key */
and    o.name = isnull(@objname,o.name)
and    c.name = isnull(@colname,c.name)
and    c.number = 0
and    c.type = t.type
and    o.type in ('U', @show_type )

update #collist
set type=type+'('+rtrim(convert(char(4),length))+')'
where type='varchar'
or    type='char'

update #collist
set type=type+'('+rtrim(convert(char(4),prec))+')'
where type='decimal'
and   scale=0

update #collist
set type=type+'('+rtrim(convert(char(4),prec))+','+convert(char(4),scale)+')'
where type='decimal'
and   scale>0

update #collist
set type=type+'('+rtrim(convert(char(4),prec))+')'
where type='numeric'
and   scale=0

update #collist
set type=type
	+'('
	+rtrim(convert(char(4),prec))
	+','
	+rtrim(convert(char(4),scale))
	+')'
where type='numeric'
and   scale>0

update #collist
set  Nulls='null'
where status & 8 != 0

update #collist
set  Ident=''
where status & 0x80 = 0

if @objname is null and @colname is null
begin
	-- we have a big listing
	select distinct
			column,
			type,
			Nulls,
			Ident,
			"Num Tables"="/* "+convert(char(4),count(*))+" Tables */"
	from #collist
	group by column,type,Nulls
	order by column,type
end
else
	select distinct
		table_nm=tname,
		column,
		type,
		Nulls,
		Ident
	from #collist
	order by colid

drop table #collist

return
go

grant execute on sp__collist  to public
go

