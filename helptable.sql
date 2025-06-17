/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helptable
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

if exists (select * from sysobjects
	   where  name = "sp__helptable"
	   and    type = "P")
   drop procedure sp__helptable

go

/* If @do_system_tables = 'S' also show system stuff */
create procedure sp__helptable ( 
	                        @objname varchar(92) = NULL, 
				@do_system_tables char(1)=' ', 
				@dont_format char(1)=null, 
				@min_size int=null
			       )
AS
BEGIN

declare @pgsz int
select  @pgsz = low/1024 from master..spt_values
where   number=1 and type='E'


/* If you want to see a specific system objects */
/* if @objname is not null and @do_system_tables is null
	select @do_system_tables=type from sysobjects where name=@objname */

if @do_system_tables != ' ' or @objname is not null
	select @do_system_tables='S'

if @objname is null
	select @objname='%'
else
	select @objname=@objname+'%'

select name = convert(char(60),rtrim(o.name)),
       owner_id = o.uid,
       --indid,
       o.crdate,
       row_cnt  = row_count(db_id(),o.id),
       reserved = reserved_pages(db_id(),o.id) * @pgsz,
       data     = data_pages(db_id(),o.id) * @pgsz,
       used     = used_pages(db_id(),o.id) * @pgsz,
       o.sysstat2,
       rowsper=convert(int,0),
       str_row_cnt="        ",
       str_reserved="      ",
       str_used="      "
into   #sum_info
from   sysobjects o
where  (o.type in ("U",@do_system_tables) or o.name = "syslogs" or o.name like "sysaudit%" )
and      o.name like @objname

update #sum_info
set    name=user_name(owner_id)+'.'+name
where  owner_id>1

-- correct bugs in the server
update #sum_info
set row_cnt=0  where row_cnt>1000000000
and   data<3000

if @min_size is not null
	delete #sum_info
	where  reserved<@min_size

update #sum_info
set  rowsper=(row_cnt/convert(float,data))*100
where data > 0

if @dont_format is null
begin
	/* OK - HANDLE *HUGE* TABLES NOW */
	update #sum_info
			set
				str_row_cnt=  case
						when row_cnt>9999999999 then  convert(varchar,convert(int, row_cnt/1000000000)) + 'G'
						when row_cnt>9999999    then  convert(varchar,convert(int, row_cnt/1000000)) + 'M'
						else convert(varchar,row_cnt) 
						end,
				str_reserved= case			
						when reserved>99999999 then convert(varchar,reserved/1000000) + 'G'
						when reserved>99999    then convert(varchar,reserved/1000) +'M'
						else convert(varchar,reserved) 
						end,
				str_used=     case			
						when (data)>99999999 then convert(varchar,(data)/1000000) + "G"
						when (data)>99999    then convert(varchar,(data)/1000) +"M"
						else convert(varchar,(data)) 
						end
						
        select
         convert(char(45),name) "Table Name",
         str_row_cnt            "Rows",
         str_reserved           "Res KB",
         str_used               "Usd KB",
         str(convert(float,rowsper)/100.0,6,2) "Rows/KB",
-- convert(char(13),segname) "Segment",
         convert(char(10),crdate,104) "CrDate",
         LockType=case 
                   when sysstat2 &  8192 != 0 then 'allpages'
                   when sysstat2 & 16384 != 0 then 'datapages'
                   when sysstat2 & 32768 != 0 then 'datarows'
                  else convert(varchar(15),sysstat2) 
                  end
        from #sum_info
        order by name
end
else
        select
         name "Table Name",
         row_cnt "Rows",
         reserved "Reserved KB",
         data "Used KB",
         str(convert(float,rowsper)/100.0,6,2) "Rows/KB",
-- convert(char(2),crdate,6)
-- +substring(convert(char(9),crdate,6),4,3)
-- +substring(convert(char(9),crdate,6),8,2) "Create Date"
         locktype=case 
                   when sysstat2 &  8192 != 0 then 'allpages'
                   when sysstat2 & 16384 != 0 then 'datapages'
                   when sysstat2 & 32768 != 0 then 'datarows'
                  else '?' 
                  end
        from #sum_info
        order by name

drop table #sum_info
--drop table #tableinfo

return(0)
END
go

grant execute on sp__helptable  to public
go

