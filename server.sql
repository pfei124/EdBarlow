/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__server
|*
|* Author:
|*
|* Description: calls procedures: sp__helpdb, sp__helpdbdev, sp__helpdevice, etc.
|*
|* Usage:
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2004
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__server")
begin
    drop procedure sp__server
end
go

create procedure sp__server    ( @dont_format char(1) = null)
as
begin
        print "******* SYBASE VERSION *******"
        print @@version

        print ""
        set nocount on
        exec sp__helpdb
        print ""
        set nocount on
        exec sp__helpdbdev PD

        print ""
        set nocount on
        exec sp__helpdevice

	if exists ( select * from master..sysdatabases where name='sybsystemprocs' )
	begin
        	print ""
        	set nocount on
        	exec sp__helpmirror
	end

        print ""
        set nocount on
        exec sp__vdevno

        print ""
        set nocount on
        exec sp__helpsegment

        print ""
        set nocount on
        exec sp__helplogin

    return (0)
end
go

grant execute on sp__server to public
go

