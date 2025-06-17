/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpobject
|*
|* Author:
|*
|* Description: calls sp__helptable, sp__helpview, sp__helpproc,
|*                    sp__helpdefault, sp__helprule and sp__helptrigger
|*              for @objectname             
|*              
|* Usage:       sp__helpobject
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2024        6.91
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * FROM sysobjects
           WHERE  name = "sp__helpobject"
           AND    type = "P")
   drop procedure sp__helpobject
go

create procedure sp__helpobject(
                           @objectname    varchar(92) = NULL,
                           @dont_format   char(1) = NULL
                          )
AS
BEGIN

set nocount on

exec sp__helptable @objectname
print ""
exec sp__helpview @objectname
print ""
exec sp__helpproc @objectname
print ""
exec sp__helpdefault @objectname
print ""
exec sp__helprule @objectname
print ""
exec sp__helptrigger @objectname

set nocount off
END

go

grant execute on sp__helpobject  to public
go

