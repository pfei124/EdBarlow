/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpgroup
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__helpgroup
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
           and    name = "sp__helpgroup")
begin
    drop procedure sp__helpgroup
end
go

create procedure sp__helpgroup (
	                        @groupname char(30)=NULL,
                                @dont_format char(1) = null
                               )
as
begin
        create table #tmp
        (
        Login_name   char(14) null,
        User_name    char(14) null,
        Group_name   char(22) null,
        Default_db   char(14) null,
        Is_Alias     char(1) null
        )

        /* Get Regular Logins */
        insert #tmp
        select
        Login_name = m.name,
        User_name  = u.name,
        Group_name = g.name,
        Default_db = m.dbname,
        Is_Alias    = NULL
        from    sysusers u, sysusers g, master.dbo.syslogins m
        where   u.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     u.suid not between -16397 and -16383
	and     u.uid not between 16383 and 16397
        and     u.uid  != 0

        /* Add Any Aliases */
        insert #tmp
        select
        Login_name = convert(char(14), m.name),
        User_name  = convert(char(14), u.name),
        Group_name = convert(char(22), g.name),
        Default_db = convert(char(14), m.dbname),
        Is_Alias    = 'Y'
        from    sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
        where   a.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     a.altsuid=u.suid
        and     u.uid != 1

        /* Insert Groups w/o users */

        insert #tmp
        select "N.A.","N.A.",name,"N.A.","N.A."
        from  sysusers
        where   uid  = gid
        and     gid not in ( select gid from sysusers where uid  != gid )
        and     suid not between -16397 and -16383
	and     uid not between 16383 and 16397

        select Group_name,Login_name,"Alias"=isnull(Is_Alias,""),User_name,Default_db
        from #tmp
        where isnull(@groupname,Group_name)=Group_name
        order by Group_name,User_name

        drop table #tmp
   return (0)
end
go

grant execute on sp__helpgroup to public
go

