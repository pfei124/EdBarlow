
use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__ASEspace")
begin
   drop procedure sp__ASEspace
end
go

create procedure sp__ASEspace ( @dont_format char(1) = null )
as

begin
   declare @numratio numeric(19,0)
   declare @pgsratio int
   declare @mempgsMB int 

   select @mempgsMB  = 512

   set nocount on
   select @pgsratio = low/2048 -- @@maxpagesize/@@pagesize
     from master.dbo.spt_values
    where number = 1 and type = "E"

   select @numratio = convert(numeric(19,0),512/@pgsratio)

   select 
     name = substring(d.name, 1, 20), d.dbid,
     datasize = (select sum(convert(numeric(19,0),u.size))/@numratio 
                 from master..sysusages u where u.dbid=d.dbid and u.segmap in (3,7)),
     usedsize = (select sum(convert(numeric(19,0),u.size)-convert(numeric(19,0),isnull(curunreservedpgs(u.dbid,u.lstart,0),unreservedpgs)))/@numratio
                 from master..sysusages u where u.dbid=d.dbid and u.segmap in (3,7)),
     logsize  = (select sum(convert(numeric(19,0),u.size))/@numratio
                 from master..sysusages u where u.dbid=d.dbid and u.segmap in (4))
     into #db_list
     from master..sysdatabases d
   order by d.dbid

   select 
   "ASEname" = @@servername, 
   "total space alloc (GB)"=str(sum(isnull(datasize,0)/1024+isnull((logsize)/1024,0)),22,0),
   "total data used (GB)"=str(sum(isnull(usedsize,0)/1024),20,0)
   from #db_list

end
go

grant exec on sp__ASEspace to public
go

