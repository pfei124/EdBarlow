/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__ls
|*
|* Author:
|*
|* Description:
|*
|* Usage:  sp__ls
|*
|* Modification History:
|*
|* Date        Who      What
|* dd.mm.yyyy  pfei124  format
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select * from sysobjects
           where  name = "sp__ls"
           and    type = "P")
   drop procedure sp__ls
go
create procedure sp__ls(
        @objname varchar(30) = '%',
        @objtype varchar(2) = '%',
        @dont_format char(1) = null
        )
AS
BEGIN

if @objname in ('D','P','TR','U','V','S','R')
begin
      select Object_name  = name,
             Type         = type,
             Owner        = convert(char(15),user_name(uid)),
             Created_date = convert(char(20),crdate)
      from   sysobjects
      where  type = @objname
      order  by name
end
/* do a simple ls */
else if exists (select * from sysobjects where name like '%'+@objname+'%')
      select Object_name  = name,
             Type         = type,
             Owner        = convert(char(15),user_name(uid)),
             Created_date = convert(char(20),crdate)
      from   sysobjects
      where  name like '%' + @objname + '%'
      and   type!='S'
		and   type like @objtype
      order  by name
else if exists (select * from sysobjects where lower(name) like '%'+lower(@objname)+'%')
      select Object_name  = name,
             Type         = type,
             Owner        = convert(char(15),user_name(uid)),
             Created_date = convert(char(20),crdate)
      from   sysobjects
      where lower(name) like '%'+lower(@objname)+'%'
      and   type!='S'
		and   type like @objtype
      order  by name
else     print "No Object Found"

return(0)
END
go

grant execute on sp__ls  to public
go

