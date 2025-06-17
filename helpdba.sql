
/************************************************************************\
|* Procedure Name: sp__helpdba
|*
|* Author: Werner Pfeiffer
|*
|* Description: like sp__helpdb, but with servername
|*
|* Usage:       sp__helpdba
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 13.12.2024  wp    1.00     initial
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select * from sysobjects where type = "P" and name = "sp__helpdba")
begin
   drop procedure sp__helpdba
end
go

/* If @dbname=NoPrint no print statements will be run */
create procedure sp__helpdba (
                             @dbname char(30)=NULL, 
                             @dont_format char(1)=NULL 
                            )
as
   declare @msg char(128)
   declare @numpgsmb float

   select @numpgsmb = (1048576.0 / v.low)
   from master.dbo.spt_values v
   where v.number = 1 and v.type = "E"
   set nocount on
   if @dbname is not null and @dbname <> "NoPrint"
     begin
        /* Check Existence */
        if not exists ( select * from master..sysdatabases where name like @dbname )
          begin
             select @msg = "Unknown Database: " + @dbname
             if @dont_format is not null
             print @msg
             return
          end
        /* Print Some Database Information */
        select "servername"=@@servername,
               "database"  = convert(char(20),name),
               "data(MB)"  = str((select sum(u.size) from master..sysusages u where u.dbid=d.dbid and u.segmap in (3,7))/@numpgsmb,12,0),
               "log(MB)"   = str((select sum(u.size) from master..sysusages u where u.dbid=d.dbid and u.segmap=4)/@numpgsmb,12,0),
               "owner"     = suser_name(d.suid)
        from master..sysdatabases d
        where d.name like @dbname
        exec sp__helpdbdev @dbname
        return
     end
   select distinct name = convert(char(20),name),
         size_data=( select sum(u.size) from master..sysusages u where u.dbid=d.dbid and u.segmap in (3,7)),
         size_log =( select sum(u.size) from master..sysusages u where u.dbid=d.dbid and u.segmap=4 ),
         owner = suser_name(d.suid),
         dbid,
         status,
         status2,
         si = "  ",
         tl = "  ",
         cr = "  ",
         cl = "  ",
         ds = "  ",
         ro = "  ",
         do = "  ",
         su = "  ",
         an = "  ",
         nc = "  ",
         ab = "  ",
         nf = "  ",
         ai = "  "
     into   #dbd_tbl
     from   master..sysdatabases d
     group by d.dbid
     order by d.name

     update #dbd_tbl
     set    size_log=round((v.low * convert(float,size_log) / 1048576), 0)
     from   #dbd_tbl, master..spt_values v
     where  v.type = 'E'
     and    v.number = 1
     and    size_log is not null
     update #dbd_tbl
     set    size_data=round((v.low * convert(float,size_data) / 1048576), 0)
     from   #dbd_tbl, master..spt_values v
     where  v.type = 'E'
     and    v.number = 1
     update #dbd_tbl
     set    si = 'Y'
     where  status & 4 = 4
     update #dbd_tbl
     set    tl = 'Y'
     where  status & 8 = 8
     update #dbd_tbl
     set    cr = 'Y'
     where  status & 16 = 16
     update #dbd_tbl
     set    name =  rtrim(name) + " ("+convert(varchar,dbid)+")"
     update #dbd_tbl
     set    cl = 'Y'
     where  status & 32 = 32
     update #dbd_tbl
     set    ds = 'Y'
     where  status & 256 = 256
     update #dbd_tbl
     set    ro = 'Y'
     where  status & 1024 = 1024
     update #dbd_tbl
     set    do = 'Y'
     where  status & 2048 = 2048
     update #dbd_tbl
     set    su = 'Y'
     where  status & 4096 = 4096
     update #dbd_tbl
     set    nc = 'Y'
     where  status & 16384 = 16384
     update #dbd_tbl
     set    an = 'Y'
     where  status & 8192 = 8192
     update #dbd_tbl
     set    ab = 'Y'
     where  status2 & 1 = 1
     update #dbd_tbl
     set    nf = 'Y'
     where  status2 & 2 = 2
     update #dbd_tbl
     set    ai = 'Y'
     where  status2 & 4 = 4

     set nocount on
     if @dbname <> "NoPrint" and @dont_format is null
       begin
           print "key   description            key   description"
           print "---   -----------            ---   -----------"
           print "si    select into/bulkcopy    ro   read only"
           print "tl    trunc. log on chkpt     do   dbo use only"
           print "cr    no chkpt on recovery    su   single user"
           print "cl    crashed during load     ab   abort tran"
           print "ds    database suspect"
           print ""
           print "****** DATABASE CONFIGURATION *******"
       end
     if @dont_format is null
       begin
           select "servername"=@@servername,
                "database" = convert(char(20),name),
                "data(MB)" = str(size_data,12,0),
                "log(MB)"  = isnull(str(size_log,12,0),"N/A"),
                "owner"    = convert(char(12),owner),
                /* created,*/
                si = isnull(si, " "),
                tl = isnull(tl, " "),
                cr = isnull(cr, " "),
                cl = isnull(cl, " "),
                ds = isnull(ds, " "),
                ro = isnull(ro, " "),
                do = isnull(do, " "),
                su = isnull(su, " "),
                ab = isnull(ab, " ")
           from  #dbd_tbl
           order by name
       end
     else
       begin
           select "servername"=@@servername,
                "database" = convert(char(20),name),
                "data(MB)" = str(size_data,12,0),
                "log(MB)"  = isnull(str(size_log,12,0),"N/A"),
                "owner"    = convert(char(12),owner),
                /* created,*/
                si = isnull(si, " "),
                tl = isnull(tl, " "),
                cr = isnull(cr, " "),
                cl = isnull(cl, " "),
                ds = isnull(ds, " "),
                ro = isnull(ro, " "),
                do = isnull(do, " "),
                su = isnull(su, " "),
                ab = isnull(ab, " "),
                an = isnull(an, " "),
                nc = isnull(nc, " "),
                nf = isnull(nf, " "),
                ai = isnull(ai, " ")
           from #dbd_tbl
           order by name
       end
     if @dbname <> "NoPrint"
       begin
             set nocount on
             select "total space used"=str(sum(size_data+isnull(size_log,0)),16,0),
                    "total data"=str(sum(size_data),12,0),
                    "total log"=str(sum(isnull(size_log,0)),12,0)
             from #dbd_tbl
       end
   return (0)
go

grant exec on sp__helpdba to public
go

