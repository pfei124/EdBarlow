/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__qspace
|*
|* Author:  
|*
|* Description:      Database/log space available/used/utilised
|*
|* Usage:  sp__iostat
|*
|* Modification History:
|* Date        Version Who      What
|* dd.mm.yyyy  x.y                              
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__qspace")
begin
   drop procedure sp__qspace
end
go

create procedure sp__qspace ( @dont_format char(1) = NULL )
as
begin

declare @log_pgs  float
declare @used_pgs float
declare @pct_used int
declare @log_pct_used int
declare @db_size  float,@log_size float
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

select @log_pgs = reserved_pages(db_id(), 8)

select @used_pgs = sum(reserved_pages(db_id(), id))
from sysobjects
where id != 8

/* Reset If Data & Log On Same Device */
if @log_size is null
        select @used_pgs = @used_pgs+@log_pgs,@log_pgs=0, @log_size=1

if @log_size = 0
        select @log_size = @log_size + 1

select @pct_used=(@used_pgs*100)/@db_size
select @log_pct_used=(@log_pgs*100)/@log_size

select  Name       = db_name(),
        Percent    = @pct_used,
        "Log Pct"  = @log_pct_used
end
go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have execute privilege on this stored proc */
grant exec on sp__qspace to public
go
