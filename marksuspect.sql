
/************************************************************************\
|* Procedure Name: sp__marksuspect
|*
|* Author: ?
|*
|* Description: stolen verbatim from the troubleshooting guide
|*              it's a useful procedure provided for the benefit of sybase users
|*              if someone at sybase objects - i will happily rewrite this so it does
|*              not use any sybase code - i hope nobody objects - it *is* a free package
|*
|*
|* Usage:       sp__marksuspect @dbname
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

if exists (SELECT *
           from   sysobjects
           where  type = "P"
           and    name = "sp__marksuspect")
begin
    drop procedure sp__marksuspect
end
go


create procedure sp__marksuspect @dbname varchar(30)
AS
BEGIN
   DECLARE @msg varchar(80)
   IF @@trancount > 0
     BEGIN
      PRINT "Can not run sp_marksuspect from within a transaction."
      RETURN (1)
     END
   IF suser_id() != 1
     BEGIN
      SELECT @msg = "You must be the System Administrator (SA)"
      SELECT @msg = @msg + 'to execute this procedure.'
      PRINT @msg
      RETURN (1)
     END
   IF (SELECT COUNT(*) FROM master..sysdatabases
      WHERE name = @dbname) != 1
     BEGIN
      SELECT @msg = 'Database ' + @dbname + ' does not exist!'
      PRINT @msg
      RETURN (1)
     END
   IF (SELECT COUNT(*) FROM master..sysdatabases
      WHERE name = @dbname and status & 320 = 320) = 1
     BEGIN
      SELECT @msg = "Database '" + @dbname + "' "
      SELECT @msg = @msg + 'is already marked suspect.'
      PRINT @msg
      RETURN (1)
     END
   BEGIN TRAN
     update master..sysdatabases set status = status|320
       WHERE name = @dbname
     IF @@error != 0 or @@rowcount != 1
       ROLLBACK TRAN
     ELSE
       BEGIN
        COMMIT TRAN
        SELECT @msg = "Database '" + @dbname + "' has been marked suspect!"
        PRINT @msg
        PRINT " "
        SELECT @msg = "NOTE: You may now drop this database"
        SELECT @msg = @msg + "via dbcc dbrepair (dbname, dropdb)."
        PRINT @msg
        PRINT " "
       END
END
go

