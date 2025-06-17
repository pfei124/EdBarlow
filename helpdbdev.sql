/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpdbdev
|*
|* Author:         
|*
|* Description:
|*
|* Usage: sp__helpdbdev ND : device names   (ordered by DB)
|*        sp__helpdbdev PD : physical names (ordered by DB)
|*        sp__helpdbdev N  : devices names
|*        sp__helpdbdev P  : physical namews
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2024  wp    x.1      field length for "Physical Name"
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select *
                          from  sysobjects
                          where  type = "P"
                          and    name = "sp__helpdbdev")
begin
         drop procedure sp__helpdbdev
end
go

create procedure sp__helpdbdev (
        @fmt char(2)=NULL,
        @dbname char(30)=NULL ,
        @dont_format char(1) = null
        )
as

declare @msg            varchar(127)
declare @numpgsmb int           /* Number of Pages per Megabytes */

if @fmt is null
begin
        print "USAGE sp__helpdbdev "
        print "ND => device names ordered by database"
        print "PD => physical names ordered by database"
        print "N  => device names ordered by device"
        print "P  => physical names ordered by device"
        return 0
end

/* Check Existence */
if @dbname is not null
begin
        if not exists ( select * from master..sysdatabases
                                                where name=@dbname )
        begin
                select @msg="Unknown Database: "+@dbname
                print  @msg
                return
        end
end

select @numpgsmb = (1048576. / v.low)
from master.dbo.spt_values v
where v.number = 1 and v.type = "E"

set nocount on
if @fmt = "ND"
        select
                "Database Name"=substring(d.name,1,15),
                "Device Name" = substring(dv.name, 1,15),
                "Size" = round(size / @numpgsmb,2),
                "Usage" = convert(char(12),b.name)
        from  master..sysdatabases d, master..sysusages u,
                master..sysdevices dv, master..spt_values b
        where d.dbid = u.dbid
            --    and dv.low <= size + vstart
            --    and dv.high >= size + vstart - 1
            	and u.vdevno = dv.vdevno
                and dv.status & 2 = 2
                and b.type = "S"
                and u.segmap & 7 = b.number
                and isnull(@dbname,d.name)=d.name
        order by d.name,u.lstart
else if @fmt = "PD"
        select
                "Physical Name" = convert(char(50),dv.phyname),
                "Database Name" = convert(char(15),d.name),
                "Size" = round(size / @numpgsmb,2)
        from  master..sysdatabases d, master..sysusages u,
                        master..sysdevices dv, master..spt_values b
        where d.dbid = u.dbid
                --        and dv.low <= size + vstart
                --        and dv.high >= size + vstart - 1
                	and u.vdevno = dv.vdevno
                        and dv.status & 2 = 2
                        and b.type = "S"
                        and u.segmap & 7 = b.number
                        and isnull(@dbname,d.name)=d.name
        order by d.name,u.lstart
else if @fmt = "N"
        select
                "Database Name"=substring(d.name,1,15),
                "Device Name" = substring(dv.name, 1,15),
                "Size" = round(size / @numpgsmb,2),
                "Usage" = convert(char(12),b.name)
        from  master..sysdatabases d, master..sysusages u,
                        master..sysdevices dv, master..spt_values b
        where d.dbid = u.dbid
                --        and dv.low <= size + vstart
                --        and dv.high >= size + vstart - 1
                	and u.vdevno = dv.vdevno
                        and dv.status & 2 = 2
                        and b.type = "S"
                        and u.segmap & 7 = b.number
                        and isnull(@dbname,d.name)=d.name
        order by dv.name,u.lstart
else if @fmt = "P"
        select
                "Physical Name" = convert(char(50),dv.phyname),
                "Database Name" = convert(char(15),d.name),
                "Size" = round(size / @numpgsmb,2)
        from  master..sysdatabases d, master..sysusages u,
                        master..sysdevices dv, master..spt_values b
        where d.dbid = u.dbid
                  --      and dv.low <= size + vstart
                  --      and dv.high >= size + vstart - 1
                	and u.vdevno = dv.vdevno
                        and dv.status & 2 = 2
                        and b.type = "S"
                        and u.segmap & 7 = b.number
                        and isnull(@dbname,d.name)=d.name
        order by dv.phyname,u.lstart

return (0)
go

/* Give execute privilege to users. This can be removed if you only want
        the sa to have excute privilege on this stored proc */
grant exec on sp__helpdbdev to public
go

