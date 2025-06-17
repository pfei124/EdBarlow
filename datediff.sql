/* Copyright (c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__datediff
|*
|* Author: Ed Barlow
|*
|* Description:
|*
|* Usage:  sp__datediff 
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

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__datediff")
begin
    drop procedure sp__datediff
end
go

create procedure sp__datediff (
                               @startdate datetime,
                               @scale char(1), 
                               @outp float output
                              )
as

if      @scale='h'
begin
        select @outp= convert(float,datediff(mi,@startdate,getdate()))/60
end
else    if @scale='d'
begin
        select @outp= convert(float,datediff(hh,@startdate,getdate()))/24
end
else    if @scale='m'
begin
        select @outp= convert(float,datediff(ss,@startdate,getdate()))/60
end
else    if @scale='s'
begin
        select @outp= convert(float,datediff(ss,@startdate,getdate()))
end
return  0
go

grant execute on sp__datediff to public
go

