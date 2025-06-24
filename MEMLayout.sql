use sybsystemprocs
go

if exists (select * from sysobjects where type = "P" and name = "sp__MEMLayout")
begin
   drop procedure sp__MEMLayout
end
go

create procedure sp__MEMLayout (@dont_format char(1) = null)
as
begin

  declare @pcache           bigint
  declare @engine_percent   int
  declare @max_engines      int
  declare @ELCperengine     numeric(19,0)
  declare @PCACHEcore       numeric(19,0)
  declare @StatementCacheMB numeric(19,0)

  create table #tmp
  (
   structure  char(30)      NULL,
   numpages   numeric(19,0) NULL,
   MB         numeric(19,0) NULL,
   GB         numeric(19,0) NULL
  )

  create table #tmp2
  (
   ord          int           NOT NULL,
   configparam  char(43)      NULL,
   value        int           NULL,
   unit         char(10)      NULL
  )

  set nocount on

  insert #tmp
  select "max memory" as "structure",
  convert(numeric(19,0),cc.value), 
  convert(numeric(19,0),cc.value/512), 
  convert(numeric(19,0),cc.value/512/1024)
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config 
  where c.name = "max memory"

  insert #tmp
  select "total physical memory" as "structure",
  convert(numeric(19,0),cc.value), 
  convert(numeric(19,0),cc.value/512), 
  convert(numeric(19,0),cc.value/512/1024)
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config 
  where c.name = "total physical memory"

  insert #tmp
  select "total logical memory" as "structure",
  convert(numeric(19,0),cc.value), 
  convert(numeric(19,0),cc.value/512), 
  convert(numeric(19,0),cc.value/512/1024)
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config 
  where c.name = "total logical memory"

  insert #tmp
  select "procedure cache size" as "structure",
  convert(numeric(19,0),cc.value), 
  convert(numeric(19,0),cc.value/512), 
  convert(numeric(19,0),cc.value/512/1024)
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config 
  where c.name = "procedure cache size"

  insert #tmp
  select cache_name,
  convert(numeric(19,0),run_size*512),
  convert(numeric(19,0),run_size),
  convert(numeric(19,0),run_size/1024.0)
  from master..syscacheinfo
  order by run_size desc

  select 
  convert(char(12),@@servername) "ASE",
  structure,
  numpages as "pages(2k)",
  MB,
  GB 
  from #tmp
  order by numpages desc

-- print "*******  procedure cache relevant settings  *******"

  insert #tmp2
  select 1,convert(char(40),c.name),cc.value,"percent"
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("engine local cache percent")

  insert #tmp2
  select 2,convert(char(40),c.name),cc.value,"num"
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("max online engines")

  select @pcache = cc.value 
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("procedure cache size")

  select @engine_percent = cc.value
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("engine local cache percent")

  select @max_engines = cc.value 
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("max online engines")

  select @ELCperengine = convert(numeric(19,0),(@pcache*@engine_percent/100/@max_engines/512))

  insert #tmp2
  select 4,"ELC per engine",@ELCperengine,"MB"

  insert #tmp2
  select 5,"   ",null,"  "

  insert #tmp2
  select 6,"pcache total (MB)",convert(numeric(19,0),t1.MB),"MB"
  from #tmp t1
  where t1.structure = "procedure cache size"

  insert #tmp2
  select 7,"ELC total",@ELCperengine*@max_engines,"MB"

  insert #tmp2
  select 3,convert(char(40),c.name),cc.value,"pages(2k)"
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("statement cache size")

  select @StatementCacheMB = convert(numeric(19,0),cc.value/512)
  from master..syscurconfigs cc inner join master..sysconfigures c on c.config = cc.config
  where c.name in ("statement cache size")

  insert #tmp2
  select 8,"statement cache (MB)",@StatementCacheMB,"MB"

  insert #tmp2
  select 9,"pcache core (MB)",convert(numeric(19,0),(t1.MB - @ELCperengine*@max_engines - @StatementCacheMB)),"MB"
  from #tmp t1
  where t1.structure = "procedure cache size"

  select
  configparam as "pcache relevant info",
  value,
  unit
  from #tmp2
  order by ord

  return
end
go

grant exec on sp__MEMLayout to public
go

