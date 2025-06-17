
/************************************************************************\
|* Procedure Name:   sp__revrule
|*
|* Author:      Chris Vilsack <cvilsack@btmna.com>
|*
|* Description:
|*
|* Usage:       sp__revrule
|*
|* Modification History:
|* Date        Version Who           What
|* dd.mm.yyyy  x.y
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * 
	     FROM sysobjects
            WHERE name = "sp__revrule"
              AND type = "P")
   drop procedure sp__revrule
go

create procedure sp__revrule @format char(1) = NULL
as
begin

declare @rownow int, @maxrow int

create table #temprules
(
    rownum numeric(18,0) IDENTITY,
    id  int
)

insert #temprules(id)
    select id
        from sysobjects where type = 'R'
        order by object_name(id)

select @maxrow = (select max (rownum) from #temprules), @rownow = 1

if @format is null
begin

    while (@rownow <= @maxrow)
    begin

        select char(10) + "exec sp_bindrule '" + object_name(a.id) + "', '" +
                object_name(b.id) + "." + col_name(b.id, b.colid) + "'" +
                char(10) + "go" + char(10)
            from #temprules a, syscolumns b, sysobjects c
            where a.id = b.domain
                and c.type ='U'
                and c.id = b.id
                and @rownow = a.rownum
            order by object_name(b.id), col_name(b.id, b.colid)

        select "exec sp_bindrule '" + object_name(a.id) + "', '" +
                b.name + "'"
            from #temprules a, systypes b
            where a.id = b.domain
                and @rownow = a.rownum
            order by b.name

        select @rownow = @rownow + 1
    end
end

else
begin

    while (@rownow <= @maxrow)
    begin

        select char(10) + "exec sp_bindrule '" + object_name(a.id) + "', '" +
                object_name(b.id) + "." + col_name(b.id, b.colid) + "'" +
                char(10) + "go" + char(10)
            from #temprules a, syscolumns b, sysobjects c
            where a.id = b.domain
                and c.type ='U'
                and c.id = b.id
                and @rownow = a.rownum
            order by object_name(b.id), col_name(b.id, b.colid)

        select char(10) + "exec sp_bindrule '" + object_name(a.id) + "', '" +
                b.name + "'" +
                char(10) + "go" + char(10)
            from #temprules a, systypes b
            where a.id = b.domain
                and @rownow = a.rownum
            order by b.name

        select @rownow = @rownow + 1
    end
end

drop table #temprules
end
go

grant execute on sp__revrule to public
go

