/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helplogin
|*
|* Author:
|*
|* Description: this proc will list suid, login, defaultdb, remote
|*
|* Usage:       sp__helplogin
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
           and    name = "sp__helplogin")
begin
    drop procedure sp__helplogin
end
go

/* The parameter here is for programatic usage...  If anything */
/* is passed, it will not show password or print anything               */
/* otherwise we need worry if it works on system 10 or not              */
create procedure sp__helplogin (
                                @loginname char(30)=null,
                                @filter char(1)=null,
                                @db    char(1)=null,
                                @dont_format char(1)=NULL )
as
begin
        /* Parameters as i can figure them out: status&0x2=>locked, 4=>expired */
        /* Filters L=>Locked E=>Expired A=>Any Special */

        if @dont_format is null
                print "****** SERVER LOGINS *******"

        select  suid,
            Login_name = name,
            Default_db = dbname,
                                S= (status&1),
                                L= (status&2),
                                E= (status&4),
                                Sht= convert(char(3),' '),
                                Lck= convert(char(3),' '),
                                Exp= convert(char(3),' '),
                                Remote=' ',
                                sa = ' ', sso=' ', oper=' '
        into  #tmp
        from  master.dbo.syslogins
        where name = isnull(@loginname,name)

        if @filter is not null
        begin
                if @filter = 'L'
                        delete #tmp where L!=2
                if @filter = 'E'
                        delete #tmp where E!=4
        end

        update #tmp set Sht='Y' where S=1
        update #tmp set Lck='Y' where L=2
        update #tmp set Exp='Y' where E=4

        update #tmp
                set Remote='Y'
                from #tmp l, master..sysremotelogins s
                where l.suid = s.suid

        update #tmp
                set  sso='Y'
                from #tmp l, master..sysloginroles s
                where l.suid = s.suid
                and     srid=1

        update #tmp
                set  oper='Y'
                from #tmp l, master..sysloginroles s
                where l.suid = s.suid
                and     srid=2

        update #tmp
                set  sa='Y'
                from #tmp l, master..sysloginroles s
                where l.suid = s.suid
                and     srid=0

        if @filter = "A"
                delete #tmp
                where sa = ' ' and sso=' '
                               and oper=' ' and Remote=' ' and Sht=' '
                               and Lck=' ' and Exp=' '

	if @db is not null
	begin
		update #tmp set Exp="Y" from #tmp t, sysusers u  where t.suid=u.suid
		update #tmp set Sht="Y" from #tmp t, sysalternates u  where t.suid=u.suid and altsuid<=1

		update #tmp set suid= -1 * gid
		 from #tmp t, sysusers u
		 where t.suid=u.suid

		select
        	        Login_name,
                	Default_db,
                        SA=sa,
                        SSO=sso,
                        Oper=oper,
                        Is_Dbo=Sht,
                        Has_DbAccess=Exp,
                        Grp=g.name
	        from    #tmp t, sysusers g
	        where  t.suid *= -1 * g.uid
	        order by Login_name

	end
        else if @dont_format is null
        select
                Id=convert(char(4),suid),
                Login_name = convert(char(14), Login_name),
                Default_db = convert(char(14), Default_db),
                Sht,Lck,Exp,
                SA=sa,SSO=sso,Oper=oper,
                Remote
        from    #tmp t
        order by Login_name
        else
        select
                Id=suid,
                Login_name,
                Default_db,
                Sht,Lck,Exp,
                SA=sa,SSO=sso,Oper=oper,
                Remote
        from    #tmp t
        order by Login_name

        if @loginname is not null
        begin
           exec sp_displaylogin @loginname
        end

   return (0)
end
go

grant execute on sp__helplogin to public
go

