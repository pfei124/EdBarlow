/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__auditdb
|*
|* Author: Ed Barlow
|*
|* Description:   Checks Common Database Problems
|*         - Lists users in group public
|*         - List users aliased to another non dbo user
|*         - list users without logins
|*         - list aliases without logins
|*         - list objects owned by a non - dbo
|*         - find any objects with syslogins in it
|*         - find any objects with public access
|*         - database has not been tran dumped in over a day???
|*         - Object with no text in syscomments
|*         - text in syscomments with no object
|*           num tables without ever having update stats run on them
|*
|*
|* Usage:  sp__auditdb
|*
|* Modification History:
|* Date        Version Who      What
|* dd.mm.yyyy  x.y
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT *
           from   sysobjects
           where  type = "P"
           and    name = "sp__auditdb")
begin
    drop procedure sp__auditdb
end
go

/* If servrname is set, select srvname,getdate,errors */
create procedure sp__auditdb( @srvname char(30) = null,
                              @hostname char(30) = null,
                              @dont_format char(1) = null,
                              @stats_check_days int = 14
                            )
as
begin
   --if @srvname is not null and @hostname is null
   --begin
      --print "MUST PASS BOTH SERVER AND HOST IF EITHER SPECIFIED"
      --return 200
   --end

   create table #error
   (  error_no int not null,
      msg char(74) not null
   )

   set nocount on

/*   - List users aliased to another non dbo user         */
   INSERT   #error
   SELECT   32100,"Login "+convert(char(14),m.name)+" is aliased to "+convert(char(14),u.name)
   from      sysusers u, master.dbo.syslogins m,sysalternates a
   where      a.suid = m.suid
   and        u.uid  != u.gid
   and      a.altsuid=u.suid
   and      a.altsuid>1

/*   - list aliases without logins               */
   INSERT #error
   select  32007,"suid "+rtrim(convert(char(10),a.suid))+" lacks login and is aliased to "+u.name
   from   sysusers u,sysalternates a
   where   u.uid!=u.gid and a.altsuid=u.suid and u.suid>=0
   and      suser_name(a.suid) is null

/*   - list users without logins               */
   INSERT #error
   select  32008,"user "+u.name+" can use db but lacks login suid="+rtrim(convert(char(10),suid))
   from    sysusers u
   where   u.uid!=u.gid and u.suid>=0
   and     suser_name(suid) is null

/*   - list objects owned by a non - dbo            */
   INSERT   #error
   SELECT distinct 32101,"User "+user_name(uid)+" Has "+convert(char(6),count(*))+" Objects"
   from   sysobjects where uid!=1
   group by uid

   if( db_name() != "sybsystemprocs" )
   begin
      /* proc exists with same name as system proc */
       INSERT   #error
      SELECT 32102,"Object "+name+" exists in "+db_name()+" and in sybsystemprocs - This is a possible Trojan Horse"
      from    sysobjects
      where name in ( select name from sybsystemprocs..sysobjects )
      and name not in ( select name from master..sysobjects )
      and    type='P'
      and    name like "sp_%"
                and    name != 'sp_thresholdaction'
   end

   if( db_name() != "master" and db_name() != "sybsystemprocs" )
   begin
         /* proc exists with same name as system proc */
         INSERT   #error
         SELECT 32102,"Object "+name+" in master - Possible Trojan Horse"
         from    sysobjects
         where name in ( select name from master..sysobjects )
         and   name not in ( select name from model..sysobjects )
         and    type='P'

/*   - find any objects with syslogins in it            */

/* Check if any groups exist - if not print message */
         if not exists (
            SELECT *
            from sysusers
            where uid=gid
                                and     name not like '%_role'
            and   uid!=0
            and   uid not in ( select uid from model..sysusers )
         )
         begin
            INSERT   #error
            SELECT  32104,"No Groups Exist In Database "+db_name()
            where db_name() not in
               ('tempdb','master','sybsystemprocs','sybsecurity','model')
         end
         else
         begin
/*   - Lists users in group public               */
            INSERT   #error
            SELECT   32105,"User "+n1.name+" is a member of group public"
            from     sysusers n1
            where    gid=0
                                and             name not like '%_role'
            and      uid!=gid
            and      uid>1

            INSERT   #error
            SELECT    distinct 32106,"Group Public "+rtrim(v.name)+" access to "+convert(char,count(*))+" objects"
            from    sysobjects o,sysprotects p,master..spt_values v
            where   o.type!='S'
            and   v.type   ='T'
            and   v.number = p.action
            and     o.id     = p.id
            and     p.protecttype!=206
            and     p.uid    =  0
            and   p.action in (193,195,196,197,224)
            group by v.name
         end
   end

/*   - Time since last dump               */
      INSERT #error
      select  32009,"database "+db_name()+" has not been tran dumped in "
            +convert(varchar,datediff(hh,dumptrdate,getdate()))
            +" hours"
      from    master..sysdatabases
      where   dbid=db_id()
      and     datediff(hh,dumptrdate,getdate())>24
      and     dbid not in (
                           select distinct usg.dbid
                           from master.dbo.sysusages usg
                           where usg.segmap != 4
                           and   usg.segmap&4 = 4
                          )
      and status & 8 = 0

      INSERT    #error
      select    32010,convert(varchar,count(*))+" Objects Have No Comments"
      from      sysobjects
      where     id not in (select id from syscomments)
      and       type in ('V','D','TR','R','P')

      /*
      INSERT    #error
      select     32011,"Comments for id "+rtrim(convert(char(20),id))+" have no object"
      from       syscomments
      where    object_name(id) is null
      */

        -- INSERT  #error
        -- select  32012,convert(char(6),count(*))+" Tables Have rows but have never had update statistics run"
        -- from    sysindexes i, sysobjects o
        -- where   distribution=0
        -- and     rowcnt(doampg) > 0
        -- and     used_pgs(i.id, doampg,ioampg) > 10
        -- and     o.id = i.id
        -- and     o.type != 'S'

        -- CREATE OBJECT PERMISSIONS GRANTED TO PEOPLE
        INSERT  #error
        select  32013, v.name + " Permission granted to  "+ u.name
        from sysprotects p, sysusers u,         master.dbo.spt_values v
        where action  in(203,207,222,233,236,198)
        and p.protecttype!=2
        and u.uid=p.uid
        and v.type='T'
        and v.number = action

        INSERT  #error
        select  32014,"Table "+object_name(id)+" Index "+ name +" is suspect"
        from    sysindexes i
        where   status & 32768 = 32768

        if db_name() != 'sybsystemprocs'
        INSERT #error
        select 32119,"proc "+name+" found in db "+db_name()
        from sysobjects
        where name like 'spX_X_%' escape 'X'


        -- STATISTICS STUFF
        INSERT  #error
        select  distinct 32016,"Object: "+object_name(s1.id)+" Has Statistics From "+convert(varchar,s1.moddate,0)+" and "+convert(varchar,s2.moddate,0)
--      ,s1.formatid,s1.usedcount,s1.colidarray
from sysstatistics s1, sysstatistics s2
where s1.id=s2.id
and   abs(datediff(dd,s1.moddate,s2.moddate)) > 1
and   s1.moddate>s2.moddate
and   ( s1.statid!=s2.statid
        or isnull(s1.colidarray,0x0)!=isnull(s2.colidarray ,0x0)
        or s1.formatid!=s2.formatid
        or s1.sequence!=s2.sequence )
order by object_name(s1.id)

if @@ROWCOUNT > 10
begin
        delete #error where error_no=32016
        INSERT  #error
        select  distinct 32016,"Many Objects in "+db_name()+" Have Statistics Created On Multiple Dates"
end


        INSERT  #error
        select  distinct 32017,"Object: "+object_name(s1.id)+" Has OLD Statistics From "+convert(varchar,s1.moddate,0)
from sysstatistics s1
where datediff(dd,s1.moddate,getdate()) > @stats_check_days
and object_name(s1.id) not like "sys%s"
order by object_name(s1.id)

if @@ROWCOUNT > 10
begin
        delete #error where error_no=32017
        INSERT  #error
        select  distinct 32017,"Many Objects in "+db_name()+" Have Outdated Statistics"
end

--X      INSERT    #error
--X     select    32015,"Device "+rtrim(dev.name)+" Is Mapped But Unused (no segments). Size (MB) ="+ltrim(rtrim(str((usg.size/512.),10,0)))
--X             from master.dbo.sysusages usg,
--X             master.dbo.sysdevices dev
--X             where vstart between low and high
--X                     and usg.segmap=0
--X                     and cntrltype = 0
--X                     and usg.dbid=11

-- Permissions on system objects granted
if db_name() != 'master' and db_name() != 'msdb'
insert #error
select 32018, name + " permissions granted to public on "+object_name(id) from sysprotects , master.dbo.spt_values c
where uid=0 and action!=193 and id<1000
and   action = number
and       type='T'
and       protecttype != 2
and     object_name(id) is not null

      DELETE    #error
      where     substring(msg,1,1) = "0"

   if @srvname is null
      select Error=msg from #error
   else if @hostname is null
      select srvname=@srvname,db=db_name(),msg from #error
   else
      select host=@hostname,srvname=@srvname,error_no,db=db_name(),type="a",day=getdate(),msg from #error

   drop table #error
end
go
