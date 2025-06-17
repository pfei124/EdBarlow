
/************************************************************************\
|* Procedure Name: sp_size 
|*
|* Author:         Michael A. van Stolk (?)
|*
|* Description:    This stored procedure prints out information regarding the size
|*                 of the specified stored procedure or all stored procedures if
|*                 none is specified.
|*
|* Usage:
|*
|* Modification History:
|*
|* Date        Who   Version  What
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if (select object_id("sp__size")) > 0
        drop procedure sp__size
go


create procedure sp__size (@objname varchar(40) = 'ALL')
as

declare @size   int,
        @lines  int,
        @pid    int,
        @msg    varchar(76)

select  name,
        id,
        size    = 0,
        lines   = 0
    into    #procs
    from    sysobjects
    where   type = 'P' and (@objname = 'ALL' or name = @objname)

if @@rowcount = 0
    begin
    select  @msg = 'Proc ' + @objname + ' not found in database ' + db_name()
    print @msg
    return 1
    end

select  @pid = min(id) from #procs
while (@pid is not null)
    begin
    select  @size = 255 * count(*) from sysprocedures
        where   id = @pid
    select  @lines = count(*) from syscomments
        where   id = @pid
    update #procs
        set size    = @size,
            lines   = @lines
        where   id = @pid
    select  @pid = min(id)
        from    #procs
        where   id > @pid
    end

select  Proc_name   = name,
        Size        = convert(char(5),size / 1000) + "KB",
        Avail_size  = 128 - (size / 1000),
        Lines       = lines,
        Avail_lines = 255 - lines
    from    #procs
    order by upper(name)

return 0
go

grant execute on sp__size to public
go

