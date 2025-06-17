/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpuser
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
           and    name = "sp__helpuser")
begin
    drop procedure sp__helpuser
end
go

create procedure sp__helpuser(
        @usernm varchar(30)=NULL,
        @dont_format char(1) = null
        )
as
begin
        create table #tmp
        (
        Login_name char(17) null,
        User_name  char(17) null,
        Group_name char(22) null,
        Default_db char(17) null,
        Is_Alias   char(1)  null,
        uid               int     null,
			status smallint null
        )

        /* Get Regular Logins */
        insert #tmp
        select
                Login_name = m.name,
                User_name  = u.name,
                Group_name = g.name,
                Default_db = m.dbname,
                Is_Alias   = NULL,
                u.uid, m.status&7
        from    sysusers u, sysusers g, master.dbo.syslogins m
        where   u.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     u.suid not in ( select suid
                                from master..sysdatabases
                                where dbid=db_id() )

        /* Add Any Aliases */
        insert #tmp
        select
                Login_name = convert(char(17), m.name),
                User_name  = convert(char(17), u.name),
                Group_name = convert(char(22), g.name),
                Default_db = convert(char(17), m.dbname),
                Is_Alias   = convert(char(1),'Y'),
                u.uid, m.status&7
        from    sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
        where   a.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     a.altsuid=u.suid

        /* Add the actual db owner from sysdatabases */
        insert #tmp
        select
                Login_name = convert(char(17), l.name),
                User_name  = convert(char(17), "dbo"),
                Group_name = convert(char(22), "DB Creator"),
                Default_db = convert(char(17), l.dbname),
                Is_Alias   = convert(char(1),'X'),
                1, l.status
        from    master..sysdatabases d , master.dbo.syslogins l
        where d.dbid=db_id()
        and     d.suid=l.suid
   and   d.suid!=1

        if @usernm is not null
                delete #tmp where Login_name != @usernm or ( Login_name is null and User_name != @usernm)

		  update #tmp set Login_name=Login_name+"(locked)" where status&2=2
		  update #tmp set Login_name=Login_name+"(expired)" where status&4=4

        if @dont_format is null
                select
                        Login_name, User_name, "Alias"=isnull(Is_Alias,""),
                        Group_name, Default_db
                from #tmp
                order by Login_name
        else
                select
                        Login_name, User_name, "Alias"=isnull(Is_Alias,""),
                        Group_name, Default_db,db_name()
                from #tmp
                order by Login_name

        if @usernm is not null
                exec sp__helplogin @usernm

        drop table #tmp
    return (0)
end
go

grant execute on sp__helpuser to public
go
