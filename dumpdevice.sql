/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__dumpdevice
|*
|* Author:
|*
|* Description:
|*
|* Usage:
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2024
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__dumpdevice")
begin
    drop procedure sp__dumpdevice
end
go

create procedure sp__dumpdevice (@devname char(30)=NULL, @dont_format char(1)=null )
as
set nocount on

        if @dont_format is not null
                print "********* BACKUP DEVICES *********"

        select  "Device Name"=substring(d.name, 1,20),
                "Physical Name"= substring(d.phyname,1,40)
        from master.dbo.sysdevices d
        where d.status & 2 != 2
        and   isnull(@devname,name) = name

return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__dumpdevice to public
go

exit

