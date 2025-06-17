/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__indexspace
|*
|* Author:
|*
|* Description:
|*
|* Usage:  sp__indexspace
|*
|* Modification History:
|* Date        Who      What
|* dd.mm.yyyy  pfei124  format
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * FROM sysobjects
            WHERE name = "sp__indexspace"
              AND type = "P")
   drop procedure sp__indexspace
go

create procedure sp__indexspace (
                                 @objname     varchar(92) = NULL ,
                                 @dont_format char(1) = NULL
                                )
AS
BEGIN

declare @pagesize int                   /* Bytes Per Page */

set nocount on

select  @pagesize = low
from    master..spt_values
where   number = 1
and     type = "E"

select name = o.name,
       idxname = i.name,
       owner_id = o.uid,
       row_cnt  = row_count(db_id(), i.id),
       reserved = reserved_pages(db_id(), i.id, i.indid),
       data 	= data_pages(db_id(), i.id, i.indid),
       index_size = data_pages(db_id(), i.id, i.indid),
       segname = s.name,
       indid
into   #indexspace
from   sysobjects o, sysindexes i, syssegments s
where  i.id = o.id
and    (o.type = "U" or o.name = "syslogs")
and    s.segment = i.segment
and    isnull(@objname,o.name)=o.name

update #indexspace
set    name=user_name(owner_id)+'.'+name
where  owner_id>1

update #indexspace
set    name=name+'.'+idxname
where  indid!=0

update #indexspace
set    row_cnt=-1
where  row_cnt>99999999

print ""
print "Data Level (Index Type 0 or 1)"
select
   convert(char(50),name)           "Name",
   convert(char(12),row_cnt)        "Rows",
   convert(char(16),rtrim(convert(char(30),((reserved/1024)*@pagesize)/1024))+"/"+
     rtrim(convert(char(30),((data/1024)*@pagesize)/1024))+"/"+
     rtrim(convert(char(30),((index_size/1024)*@pagesize)/1024)))       "Used/Data/Idx MB",
   str((row_cnt*1024)/(convert(float,data+index_size+1)*@pagesize),8,2) "Rows/KB",
   convert(char(12),segname)                                            "Segment"
from #indexspace
where indid<=1
order by name

print ""
print "Non Clustered Indexes"
select
   convert(char(50),name)           "Name",
   convert(char(12),row_cnt)        "Rows",
   convert(char(16),rtrim(convert(char(30),((reserved/1024)*@pagesize)/1024))+"/"+
     rtrim(convert(char(30),((data/1024)*@pagesize)/1024))+"/"+
     rtrim(convert(char(30),((index_size/1024)*@pagesize)/1024)))       "Used/Data/Idx MB",
   str((row_cnt*1024)/(convert(float,data+index_size+1)*@pagesize),8,2) "Rows/KB",
   convert(char(12),segname)                                            "Segment"
from #indexspace
where indid>1
order by name

drop table #indexspace
return(0)
END

go

grant execute on sp__indexspace to public
go

