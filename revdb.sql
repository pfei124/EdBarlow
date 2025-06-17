/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revdb
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__revdb
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

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revdb")
begin
    drop procedure sp__revdb
end
go

create procedure sp__revdb ( @dbname varchar(30) = NULL , 
	                     @dont_format char(1) = NULL
                           )
as
DECLARE @numpgsmb       int             /* number of pages per Megabyte */
,       @curdbid        int
,       @olddbid        int
,       @msg            varchar(127)
,       @segdev         varchar(30)
,       @segsize        int
,       @oldsegdev      varchar(30)
,       @oldsegsize     int
,       @name           varchar(30)
,       @size           int
,       @count          int
,       @cnt            int
,       @oldcnt         int
,       @segmap         int
,       @lstart         int
,       @oldlstart      int
,       @oldsegmap      int
,       @rowcnt         int
,       @errtxt         varchar(255)

CREATE TABLE #tmp
( cnt    int
, dbid   int
, segmap int
, msg    varchar(127)
, device varchar(30)
, size   int
)

SET nocount ON

IF (@dbname IS NOT NULL) AND (db_id(@dbname) IS NULL)
BEGIN
   select @errtxt="No such database -- run sp_helpdb to list databases."
   print @errtxt
   RETURN -1
END

IF @dbname IN ("master", "tempdb", "model")
BEGIN
   SELECT @errtxt = "Cannot create DDL for "+@dbname+" database"
   PRINT @errtxt
   RETURN -1
END

SELECT @numpgsmb = (1048576 / v.low), @cnt=1
FROM master.dbo.spt_values v
WHERE v.number = 1 AND v.type = "E"

SELECT @curdbid = min(dbid)
FROM master.dbo.sysdatabases
WHERE ( name = @dbname or @dbname IS NULL)

SELECT  u.dbid,
        name = dv.name,
        size = u.size / @numpgsmb,
        u.lstart,
        segmap = u.segmap
into    #devlayout
FROM    master.dbo.sysusages u, master.dbo.sysdevices dv
WHERE   --dv.low <= size + vstart
--AND     dv.high >= size + vstart - 1
        u.vdevno=dv.vdevno
  AND   dv.status & 2 = 2
  AND   ( u.dbid = db_id(@dbname) OR @dbname IS NULL)
  AND   db_name(dbid) NOT IN ("master", "model", "tempdb")
ORDER BY u.dbid,u.lstart

WHILE @curdbid IS NOT NULL
BEGIN
   BEGIN
      SELECT @count=0
      SELECT @msg="XXX"
      SELECT @oldlstart=-1, @oldsegmap=2

      /* Data Space */
      WHILE @msg IS NOT NULL
      BEGIN
         SELECT @name=name, @size=size, @lstart=lstart, @segmap=segmap
         FROM   #devlayout
         WHERE  dbid=@curdbid
         AND    lstart = (
                SELECT MIN(lstart)
                FROM   #devlayout
                WHERE  dbid=@curdbid
                AND    lstart > @oldlstart
         )

         SELECT @rowcnt = @@rowcount

         IF @rowcnt > 0
         BEGIN
            IF (@segmap > 1) AND (@segmap & 2 <> @oldsegmap)
               SELECT @count = @count + 1

            IF @count=0
               SELECT @msg= "create database "+db_name(@curdbid)+CHAR(10)+"     on "
               ,      @segdev= rtrim(@name)
               ,      @segsize= @size
               ,      @count= 1
            ELSE IF @count=2
               SELECT @msg= "log on "
               ,      @segdev= rtrim(@name)
               ,      @segsize= @size
               ,      @count= 3
            ELSE IF @count=4
               SELECT @msg= " alter database "+db_name(@curdbid)+CHAR(10)+"     on "
               ,      @segdev= rtrim(@name)
               ,      @segsize= @size
               ,      @count= 1
            ELSE  /* @count IN (1,3) */
               SELECT @msg= "     ,"
               ,      @segdev= rtrim(@name)
               ,      @segsize= @size

            INSERT #tmp
            SELECT @cnt, @curdbid, @segmap, @msg, @segdev, @segsize

            SELECT @cnt=@cnt+1, @oldlstart=@lstart, @oldsegmap=@segmap & 2
         END
         ELSE
         BEGIN
            SELECT @msg=NULL
         END
      END
   END

   SELECT @curdbid = min(dbid)
   FROM   master.dbo.sysdatabases
   WHERE  dbid > @curdbid

   IF @@rowcount = 0    /* Seems to abort on the NULL @curdb not here??? */
   BEGIN
        break
   END
END

/*
** Consolidate segments of same type on same device if and only if segments are in sequence
*/
SELECT @msg="XXX",@oldcnt=0,@oldsegdev="",@oldsegsize=0,@olddbid=0,@oldsegmap=0

WHILE @msg IS NOT NULL
BEGIN
   SELECT @cnt=cnt,@curdbid=dbid,@segmap=segmap,@msg=msg,@segdev=device,@segsize=size
   FROM   #tmp
   WHERE  cnt = ( SELECT MIN(cnt)
                  FROM   #tmp
                  WHERE  cnt > @oldcnt
                )

   IF @@rowcount = 0
        break

   IF (@segdev=@oldsegdev AND @segmap=@oldsegmap AND @curdbid=@olddbid)
   BEGIN
        -- consolidate segments
        UPDATE #tmp
        SET    size=@segsize+@oldsegsize
        WHERE  cnt=@oldcnt

        DELETE #tmp
        WHERE  cnt=@cnt

        SELECT @oldsegsize=@segsize+@oldsegsize
   END
   ELSE
   BEGIN
        SELECT @oldsegsize=@segsize,@oldcnt=@cnt
   END

   SELECT @olddbid=@curdbid,@oldsegmap=@segmap,@oldsegdev=@segdev
END

SELECT convert(varchar(55),msg+" "+device+" = "+convert(varchar(12),size))
FROM   #tmp
ORDER BY cnt

DROP TABLE #tmp
RETURN (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__revdb to public
go

