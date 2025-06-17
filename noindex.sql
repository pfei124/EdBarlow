/* Procedure copyright(c) 1993-1995 by Simon Walker */

/************************************************************************\
|* Procedure Name: sp__find_missing_index
|*
|* Author: Simon Walker
|*
|* Description:
|*
|* Usage:       sp__find_missing_index
|*
|* Modification History:
|*
|* Date        Who    Version  What
|*             Tom Lu          adding "Lock Scheme" to distinguish DOL from Allpages tables
|* 12.11.2024         6.91
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = 'P'
           and    name = "sp__noindex")
begin
    drop procedure sp__noindex
end
go

create procedure sp__noindex ( @dont_format char(1) = null)
as
begin

    set nocount on

    select No_Indexes = convert(char(50),o.name),
           "Rows" = row_count(db_id(), o.id),
           Pages= data_pages(db_id(), o.id)
    from   sysobjects o, sysindexes i
    where  o.type = "U"
    and    o.id = i.id
    and    i.indid = 0
    and    o.id not in (select o.id
                        from   sysindexes i,
                               sysobjects o
                        where  o.id = i.id
                        and    o.type = "U"
                        and    i.indid > 0)
    order by Pages desc, row_count(db_id(), o.id) desc

    select No_Clustered_Index = convert(char(50),o.name),
           "Rows" = row_count(db_id(), o.id),
           Pages= data_pages(db_id(), o.id),
	   "Lock Scheme" = case when sysstat2 & 57344 = 16384 then "Datapages"
				when sysstat2 & 57344 = 32768 then "DataRows"
				else "Allpages"
				end
    from   sysindexes i,
           sysobjects o
    where  o.id = i.id
    and    o.type= "U"
    and    i.indid = 0
    and    o.id in (select o.id
                        from   sysindexes i,
                               sysobjects o
                        where  o.id = i.id
                        and    o.type = "U"
                        and    i.indid > 0)
      order by "Lock Scheme", Pages desc, row_count(db_id(), o.id) desc

end
go

grant execute on sp__noindex to public
go

