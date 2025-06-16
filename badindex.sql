/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__badindex
|*
|* Author:
|*
|* Description: list bad indexes
|*              - indexes that contain NULL values
|*              - over 90 char indexes
|*              - ...
|*
|* Usage:       sp__badindex
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

if exists (SELECT * FROM sysobjects
           WHERE  name = "sp__badindex"
           AND    type = "P")
   drop procedure sp__badindex

go

create procedure sp__badindex (
                               @objname char(32) = NULL,
                               @dont_format char(1)=NULL
                              )
AS
begin

set nocount on

if not exists (select * from sysobjects where name=@objname and type='U')
    select @objname="%"+@objname+"%"

select name,id
  into #objects
  from sysobjects
 where name like @objname
   and type != "S"

select id = i.id,
       index_name = name,
       indid,
       key_name=name
  into #indexkeys
  from sysindexes i
 where 1=2


/* Column by column make a table of columns in database */
declare @count int
select  @count=1
while ( @count < 17 )   /* 16 appears to be the max number of indexes */
begin
   insert #indexkeys
   select id = i.id,
          index_name = i.name,
          indid,
          key_name=index_col(o.name,i.indid,@count)
     from sysindexes i, #objects o
    where  o.id=i.id
      and      indid > 0
      and      index_col(o.name,i.indid,@count) is not null
   if  @@rowcount=0   break
   select @count=@count+1
end

select distinct
          column = substring(c.name, 1, 20),
          tname =  substring(o.name,1,20),
          id=o.id,
          type =substring(t.name,1,15),
          length=c.length,
          status=c.status,
          variable,
          c.usertype
  into #collist
  from syscolumns c, systypes t, #objects o
 where c.id = o.id
   and c.number = 0
   and c.usertype = t.usertype

update #collist
set    type=type+'('+rtrim(convert(varchar,length))+')'
where  type='varchar'
or     type='char'

create table #badindexes (
        name char(60) null,
        descr char(40) null,
        problem char(40) null
)

/* Make a list of all null, vbl lth, text, or image columns*/
insert #badindexes
select convert(char(35),b.tname+'.'+i.index_name),
                 substring(i.key_name,1,20) + " " + b.type,
                 "Allows Null"
from   #indexkeys i, #collist b
where  b.id = i.id
and    b.column = i.key_name
and      convert(bit,(status & 8))=1

insert #badindexes
select convert(char(35),b.tname+'.'+i.index_name),
                 substring(i.key_name,1,20) + " " + b.type,
                 "Text / Image"
from   #indexkeys i, #collist b
where  b.id = i.id
and    b.column = i.key_name
and      usertype in (19,20)

insert #badindexes
select convert(char(35),b.tname+'.'+i.index_name),
                 substring(i.key_name,1,20) + " " + b.type,
                 "Variable Length"
from   #indexkeys i, #collist b
where  b.id = i.id
and    b.column = i.key_name
and    variable=1

select
         i.id,i.indid,
         name=convert(char(35),o.name+'.'+i.name),
         rowcnt=row_count(db_id(),i.id),
         pgcnt= reserved_pages(db_id(), i.id, i.indid),
         distribution,
         index_length=0
into     #indexes
from     sysindexes i, #objects o
where  i.id= o.id
group by i.id
having i.id= o.id

/* Set index length */
update #indexes
set index_length = isnull(( select sum(length)
                from  #indexkeys k,#collist b
                where  b.id = k.id
                and    b.column = k.key_name
                and      i.id = k.id
                and      i.indid = k.indid ),0)
from  #indexes i

/* Over 90 character indexes */
insert #badindexes
select
        name,
        "Length = "+rtrim(convert(char(12),index_length)),
         ">90 Byte Index"
from #indexes
where index_length > 90

/* Get all indexes that have bad distribution count */
/*
insert #badindexes
select name,
                 "Rows="+rtrim(convert(char(12),rowcnt)),
                 "Need Update Stats"
from   #indexes
where  rowcnt>0
and      distribution = 0
and    indid>0
*/

/*Notice non clustered indexes on small tables (under 10 pages) */
insert #badindexes
select name,
                 "Rows="+rtrim(convert(char(12),rowcnt)),
                 "NC Index on Small Table"
from   #indexes
where  indid>1
and    pgcnt<= 20
and    rowcnt>0

drop table #indexes

if @dont_format is null
  select "Table/Index Name" = substring(name,1,40),
         "Description"=substring(descr,1,40) ,
         "Problem Found"=left(problem ,30)
    from #badindexes
  order by name
else
  select "Table/Index Name" = name,
         "Description"=descr ,
         "Problem Found"=problem
  from #badindexes
  order by name
end
go

grant execute on sp__badindex  to public
go
