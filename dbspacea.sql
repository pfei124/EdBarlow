/* Procedure copyright(c) 2005 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__dbspacea
|*
|* Author:
|*
|* Description: Database/log space available/used/utilised 
|*
|* Usage:  sp__dbspacea
|*
|* Modification History:
|*
|* Date        Who      What
|* 16.01.2025  pfei124  created - based on sp__dbspace
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__dbspacea")
begin
   drop procedure sp__dbspacea
end
go

create procedure sp__dbspacea ( @dont_format char(1) = null )
as
begin

declare @log_pgs  float
declare @used_pgs float
declare @pct_used float
declare @db_size  float
declare @log_size float
declare @scale  float /* for overflow */

set nocount on

select @db_size = sum(size), @log_size=0
        from master.dbo.sysusages u
                where u.dbid = db_id()
                and   u.segmap in (3,7)

/* Just log */
select @log_size = sum(size)
        from master.dbo.sysusages u
                where u.dbid = db_id()
                and   u.segmap = 4

select @log_pgs = reserved_pages(db_id(),8)

select @used_pgs = sum( reserved_pages(db_id(),id) )
from sysobjects
where id != 8

/* @scale is number way to convert from pages to K  */
/* for example -> normally 2K page size so @scale=2 and multipled results */
select  @scale=low/1024
from    master.dbo.spt_values
where   number = 1 and type = "E"

/* Reset If Data & Log On Same Device */
if @log_size is null
begin
        select @used_pgs = @used_pgs+@log_pgs,@log_pgs=0,@log_size=0
end

select @pct_used=(@used_pgs*100)/@db_size


if @dont_format is not null
begin
select  "ASEname"  = @@servername,
        "Name"     = db_name(),
        "Data MB"  = str((@db_size*@scale)/1024, 16, 1),
        "Used MB"  = str((@used_pgs*@scale)/1024,16, 1),
        "Percent"  = str(@pct_used, 7, 0),
        "Log MB"   = str((@log_size*@scale)/1024,12, 1),
        "Log Used" = str((@log_pgs*@scale)/1024, 12, 1),
        "Log Pct"  = str((@log_pgs*100)/(@log_size+1), 7, 0)
end
else
begin
select  "ASEname"  = convert(char(12),@@servername),
        "Name"     = convert(char(15),db_name()),
        "Data MB"  = str((@db_size*@scale)/1024, 10, 1),
        "Used MB"  = str((@used_pgs*@scale)/1024,10, 1),
        "Percent"  = str(@pct_used, 7, 0),
        "Log MB"   = str((@log_size*@scale)/1024,10, 1),
        "Log Used" = str((@log_pgs*@scale)/1024, 10, 1),
        "Log Pct"  = str((@log_pgs*100)/(@log_size+1), 7, 0)
end
end
go

grant exec on sp__dbspacea to public
go

