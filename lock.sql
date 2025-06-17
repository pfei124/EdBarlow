/* Procedure copyright(c) 1996 by Edward Barlow */

/************************************************************************\
|* Procedure Name:   sp__lock
|*
|* Author:
|*
|* Description:
|*
|* Usage:  sp__lock
|*
|* Modification History:
|* Date        Who      What
|* dd.mm.yyyy  pfei124  format
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
      from   sysobjects
      where  type = 'P'
      and    name = "sp__lock")
begin
    drop procedure sp__lock
end
go

create procedure sp__lock(
        @dbname char(30)=null,
        @spid smallint=null,
        @dont_format char(1) = null
)
as
begin

declare @dbid smallint
if @dbname is not null
   select @dbid=db_id(@dbname)

if (charindex("sa_role", show_role()) > 0)
begin
   if @dont_format is null
        select
         "Type"  = substring(v.name,1,11),
         "User"  = substring(suser_name(p.suid)+" (pid="+rtrim(convert(varchar,l.spid))+")",1,18),
         "Table" = substring(db_name(l.dbid)+".."+convert(char(30),object_name(l.id,l.dbid)),1,30),
         "Page"  = substring(convert(varchar,l.page),1,8),
         "Cmd"   = convert(char(16),p.cmd)
         from    master..syslocks l,
                 master..sysprocesses p,
                 master..spt_values v
         where       p.spid=l.spid
              and      l.type = v.number
              and      v.type = "L"
              and      p.dbid=isnull(@dbid,p.dbid)
              and      p.spid=isnull(@spid,p.spid)
              and      l.dbid=isnull(@dbid,l.dbid)
              and      l.spid=isnull(@spid,l.spid)
         order by l.dbid, l.id, v.name
   else
        select
         "Type"  =v.name,
         "User"  =suser_name(p.suid)+" (pid="+rtrim(convert(char(4),l.spid))+")",
         "Table" =db_name(l.dbid)+".."+object_name(l.id,l.dbid),
         "Page"  =l.page,
         "Cmd"   =p.cmd
         from    master..syslocks l,
                 master..sysprocesses p,
                 master..spt_values v
         where       p.spid=l.spid
              and      l.type = v.number
              and      v.type = "L"
              and      p.dbid=isnull(@dbid,p.dbid)
              and      p.spid=isnull(@spid,p.spid)
              and      l.dbid=isnull(@dbid,l.dbid)
              and      l.spid=isnull(@spid,l.spid)
         order by l.dbid, l.id, v.name

           return
end

   select
      "Type"=v.name,
      "Usernm"=convert(varchar(60),suser_name(p.suid)+" (pid="+rtrim(convert(char(4),l.spid))+")"),
      "TableNm"=convert(varchar(60),db_name(l.dbid)+".."),
      "Page"=l.page,
      "Cmd"=p.cmd,
            l.id,
            l.dbid
   into    #locks
   from     master..syslocks l,
            master..sysprocesses p,
            master..spt_values v
   where    p.spid=l.spid
      and   l.type = v.number
      and   v.type = "L"
      and        l.dbid=isnull(@dbid,l.dbid)
      and        l.spid=isnull(@spid,l.spid)
      and        p.dbid=isnull(@dbid,p.dbid)
      and        p.spid=isnull(@spid,p.spid)

   update #locks
   set     TableNm=TableNm+object_name(id,dbid)
   where dbid=db_id() or dbid=1 or dbid=2

   update #locks
   set   TableNm=TableNm+convert(varchar,id)
   where dbid<>db_id() and dbid>2

   delete #locks
   where TableNm like "tempdb..#locks%"

   if @dont_format is null
      select substring(Type, 1,11),
         "User"=substring(Usernm, 1,18),
         "Table"=convert(char(21),TableNm),
         "Page"=substring(convert(varchar,Page),1,8),
         "Cmd"=substring(Cmd,1,11)
      from #locks
      order by dbid, id, Type
   else
      select Type, "User"=Usernm, "Table"=TableNm, Page, Cmd
      from #locks
      order by dbid, id, Type

   return 0
end
go

grant execute on sp__lock to public
go

