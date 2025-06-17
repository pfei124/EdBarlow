
/************************************************************************\
|* Procedure Name: sp__helprole
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__helprole
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 10.01.2025  wp    x.xx     recovered
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select * from sysobjects
            where name = "sp__helprole"
              and type = "P")
   drop procedure sp__helprole
go

create procedure sp__helprole
as
SELECT  trole=convert(char(20), sr.name),
        LOGID=convert(char(11), l.name),
        tname=convert(char(25), l.fullname),
        ActAtLogn  = Case
                     when sr.name in ( 'navigator_role','sybase_ts_role',  'sa_role','oper_role', 'replication_role','sso_role' )
                      then 'Y'
                     when lr.status = 0
                      then 'N'
                     when lr.status = 1
                      then 'Y'
                     else '-'
                     end
        , PswdRqrd = Case
                     when datalength(sr.password) > 0
                      then 'Y'
                     else 'N'
                     end
        INTO #tmprole
        FROM master..sysloginroles lr,
             master..syssrvroles sr,
             master..syslogins l
        WHERE ( lr.suid *= l.suid )
          and ( lr.srid =* sr.srid )
update #tmprole set LOGID = '       ' , tname = 'Not assigned to a user'
        WHERE LOGID is null
select 'Role'=trole, LOGID, 'Name'=tname, ActAtLogn, PswdRqrd from #tmprole
        ORDER BY trole , LOGID
print ' '
select 'Roles granted to Roles' = 'grant role ' + role_name(object_info1) + ' to ' + role_name(object)
        FROM master..sysattributes,
             master..syssrvroles sr
        WHERE class = 8 and attribute = 2 and sr.srid = object_info1
go

grant execute on sp__helprole to public
go

