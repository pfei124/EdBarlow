/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revsegment
|*
|* Author:      
|*
|* Description:
|*
|* Usage:       sp__revsegment 
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

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revsegment")
begin
    drop procedure sp__revsegment
end
go

create procedure sp__revsegment( @dont_format char(1) = null)
as
begin
                /* syntax sp_addsegment segname,devname */
                select "exec sp_addsegment '"+s.name+"','"+d.name+"'"
                from master..sysdevices d, master..sysusages u,syssegments s
                where
       		 	d.vdevno=u.vdevno
                 and d.status & 2 = 2
                 and u.dbid=db_id()
                 and s.segment >2
                 and segmap & power(2,s.segment)  != 0

   return (0)
end
go

grant execute on sp__revsegment to public
go

