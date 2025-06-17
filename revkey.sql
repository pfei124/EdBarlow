
/************************************************************************\
|* Procedure Name:   sp__revkey
|*
|* Author: Chris Vilsack <cvilsack@btmna.com>
|*
|* Description:
|*
|* Usage:       sp__revkey
|*
|* Modification History:
|* Date        Version Who           What
|* dd.mm.yyyy  x.y     
|*                     
|*
\************************************************************************/

use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * 
	     FROM sysobjects
            WHERE name = "sp__revkey"
              AND type = "P")
   drop procedure sp__revkey
go

create procedure sp__revkey (
                             @tablename varchar(60)=NULL, 
                             @withgo varchar(1)=NULL
                            )
as
begin

if @tablename is null
begin

    SELECT char(10)+
    --  Create the exec statement
           ltrim(rtrim(isnull(substring("exec sp_primarykey ", charindex(b.name,
                  "primary"),char_length("exec sp_primarykey ")),"") +
                isnull(substring("exec sp_foreignkey ", charindex(b.name,
                  "foreign"),char_length("exec sp_foreignkey ")), "") +
                isnull(substring("exec sp_commonkey ", charindex(b.name,
                  "common"),char_length("exec sp_commonkey ")), ""))) + " " +
    --  Get the Databases involved
           ltrim(rtrim(isnull(substring("'" + object_name(a.id) + "'",
                charindex(b.name, "primary"),char_length("'" + object_name(a.id) + "'")),"") +
                isnull(substring(("'" + object_name(a.id) + "'" + ", " + "'" +
                object_name(a.depid) + "'"), charindex(b.name, "foreign"),
                char_length((select("'" + object_name(a.id) + "'" + ", " +
                "'" + object_name(a.depid) + "'")))),"") +
                isnull(substring(("'" + object_name(a.id) + "'" + ", " + "'" +
                object_name(a.depid) + "'"), charindex(b.name, "common"),
                char_length((select("'" + object_name(a.id) + "'" + ", " +
                "'" + object_name(a.depid) + "'")))),""))) + ", " +

    --  Get the Columns involved
        isnull(substring(
                            substring(col_name(a.id, key1) + ","
                                   + isnull(col_name(a.id, key2), "NULL") + ","
                                   + isnull(col_name(a.id, key3), "NULL") + ","
                                   + isnull(col_name(a.id, key4), "NULL") + ","
                                   + isnull(col_name(a.id, key5), "NULL") + ","
                                   + isnull(col_name(a.id, key6), "NULL") + ","
                                   + isnull(col_name(a.id, key7), "NULL") + ","
                                   + isnull(col_name(a.id, key8), "NULL") + ",NULL", 1,
                                charindex("NULL",(col_name(a.id, key1) + ","
                                   + isnull(col_name(a.id, key2), "NULL") + ","
                                   + isnull(col_name(a.id, key3), "NULL") + ","
                                   + isnull(col_name(a.id, key4), "NULL") + ","
                                   + isnull(col_name(a.id, key5), "NULL") + ","
                                   + isnull(col_name(a.id, key6), "NULL") + ","
                                   + isnull(col_name(a.id, key7), "NULL") + ","
                                   + isnull(col_name(a.id, key8), "NULL") + ",NULL"))-2)
                             +
                            substring("," + col_name(a.id, depkey1) + ","
                                   + isnull(col_name(a.id, depkey2), "NULL") + ","
                                   + isnull(col_name(a.id, depkey3), "NULL") + ","
                                   + isnull(col_name(a.id, depkey4), "NULL") + ","
                                   + isnull(col_name(a.id, depkey5), "NULL") + ","
                                   + isnull(col_name(a.id, depkey6), "NULL") + ","
                                   + isnull(col_name(a.id, depkey7), "NULL") + ","
                                   + isnull(col_name(a.id, depkey8), "NULL") + ",NULL", 1,
                                charindex("NULL",("," + col_name(a.id, depkey1) + ","
                                   + isnull(col_name(a.id, depkey2), "NULL") + ","
                                   + isnull(col_name(a.id, depkey3), "NULL") + ","
                                   + isnull(col_name(a.id, depkey4), "NULL") + ","
                                   + isnull(col_name(a.id, depkey5), "NULL") + ","
                                   + isnull(col_name(a.id, depkey6), "NULL") + ","
                                   + isnull(col_name(a.id, depkey7), "NULL") + ","
                                   + isnull(col_name(a.id, depkey8), "NULL") + ",NULL"))-2)

            , charindex(b.name, "common"),
              char_length(
                            substring(col_name(a.id, key1) + ","
                                   + isnull(col_name(a.id, key2), "NULL") + ","
                                   + isnull(col_name(a.id, key3), "NULL") + ","
                                   + isnull(col_name(a.id, key4), "NULL") + ","
                                   + isnull(col_name(a.id, key5), "NULL") + ","
                                   + isnull(col_name(a.id, key6), "NULL") + ","
                                   + isnull(col_name(a.id, key7), "NULL") + ","
                                   + isnull(col_name(a.id, key8), "NULL") + ",NULL", 1,
                                charindex("NULL",(col_name(a.id, key1) + ","
                                   + isnull(col_name(a.id, key2), "NULL") + ","
                                   + isnull(col_name(a.id, key3), "NULL") + ","
                                   + isnull(col_name(a.id, key4), "NULL") + ","
                                   + isnull(col_name(a.id, key5), "NULL") + ","
                                   + isnull(col_name(a.id, key6), "NULL") + ","
                                   + isnull(col_name(a.id, key7), "NULL") + ","
                                   + isnull(col_name(a.id, key8), "NULL") + ",NULL"))-2)
                             +
                            substring("," + col_name(a.id, depkey1) + ","
                                   + isnull(col_name(a.id, depkey2), "NULL") + ","
                                   + isnull(col_name(a.id, depkey3), "NULL") + ","
                                   + isnull(col_name(a.id, depkey4), "NULL") + ","
                                   + isnull(col_name(a.id, depkey5), "NULL") + ","
                                   + isnull(col_name(a.id, depkey6), "NULL") + ","
                                   + isnull(col_name(a.id, depkey7), "NULL") + ","
                                   + isnull(col_name(a.id, depkey8), "NULL") + ",NULL", 1,
                                charindex("NULL",("," + col_name(a.id, depkey1) + ","
                                   + isnull(col_name(a.id, depkey2), "NULL") + ","
                                   + isnull(col_name(a.id, depkey3), "NULL") + ","
                                   + isnull(col_name(a.id, depkey4), "NULL") + ","
                                   + isnull(col_name(a.id, depkey5), "NULL") + ","
                                   + isnull(col_name(a.id, depkey6), "NULL") + ","
                                   + isnull(col_name(a.id, depkey7), "NULL") + ","
                                   + isnull(col_name(a.id, depkey8), "NULL") + ",NULL"))-2)
            )),
                            substring(col_name(a.id, key1) + ","
                                   + isnull(col_name(a.id, key2), "NULL") + ","
                                   + isnull(col_name(a.id, key3), "NULL") + ","
                                   + isnull(col_name(a.id, key4), "NULL") + ","
                                   + isnull(col_name(a.id, key5), "NULL") + ","
                                   + isnull(col_name(a.id, key6), "NULL") + ","
                                   + isnull(col_name(a.id, key7), "NULL") + ","
                                   + isnull(col_name(a.id, key8), "NULL") + ",NULL", 1,
                                charindex("NULL",(col_name(a.id, key1) + ","
                                   + isnull(col_name(a.id, key2), "NULL") + ","
                                   + isnull(col_name(a.id, key3), "NULL") + ","
                                   + isnull(col_name(a.id, key4), "NULL") + ","
                                   + isnull(col_name(a.id, key5), "NULL") + ","
                                   + isnull(col_name(a.id, key6), "NULL") + ","
                                   + isnull(col_name(a.id, key7), "NULL") + ","
                                   + isnull(col_name(a.id, key8), "NULL") + ",NULL"))-2)
            )
    --  Append a Null
        + isnull(@withgo, char(10)+"go"+char(10))
      FROM  syskeys a, master..spt_values b, sysobjects c
      where a.type *= b.number
        and b.type = 'K'
        and a.id = c.id
        and c.type <> "S"
end
else
  begin

    SELECT char(10)+
    --  Create the exec statement
           ltrim(rtrim(isnull(substring("exec sp_primarykey ", charindex(b.name, "primary"),char_length("exec sp_primarykey ")),"") +
                isnull(substring("exec sp_foreignkey ", charindex(b.name, "foreign"),char_length("exec sp_foreignkey ")), "") +
                isnull(substring("exec sp_commonkey ", charindex(b.name, "common"),char_length("exec sp_commonkey ")), ""))) + " " +
    --  Get the Databases involved
           ltrim(rtrim(isnull(substring("'" + object_name(a.id) + "'",
           charindex(b.name, "primary"),char_length("'" + object_name(a.id) + "'")),"") +
                isnull(substring(("'" + object_name(a.id) + "'" + ", " + "'" +
                object_name(a.depid) + "'"), charindex(b.name, "foreign"),
           char_length((select("'" + object_name(a.id) + "'" + ", " + "'" + object_name(a.depid) + "'")))),"") +
                isnull(substring(("'" + object_name(a.id) + "'" + ", " + "'" +
                object_name(a.depid) + "'"), charindex(b.name, "common"),
           char_length((select("'" + object_name(a.id) + "'" + ", " + "'" + object_name(a.depid) + "'")))),""))) + ", " +

    --  Get the Columns involved
        isnull(substring(
                  substring(col_name(a.id, key1) + ","
                         + isnull(col_name(a.id, key2), "NULL") + ","
                         + isnull(col_name(a.id, key3), "NULL") + ","
                         + isnull(col_name(a.id, key4), "NULL") + ","
                         + isnull(col_name(a.id, key5), "NULL") + ","
                         + isnull(col_name(a.id, key6), "NULL") + ","
                         + isnull(col_name(a.id, key7), "NULL") + ","
                         + isnull(col_name(a.id, key8), "NULL") + ",NULL", 1,
                      charindex("NULL",(col_name(a.id, key1) + ","
                         + isnull(col_name(a.id, key2), "NULL") + ","
                         + isnull(col_name(a.id, key3), "NULL") + ","
                         + isnull(col_name(a.id, key4), "NULL") + ","
                         + isnull(col_name(a.id, key5), "NULL") + ","
                         + isnull(col_name(a.id, key6), "NULL") + ","
                         + isnull(col_name(a.id, key7), "NULL") + ","
                         + isnull(col_name(a.id, key8), "NULL") + ",NULL"))-2)
                   +
                  substring("," + col_name(a.id, depkey1) + ","
                         + isnull(col_name(a.id, depkey2), "NULL") + ","
                         + isnull(col_name(a.id, depkey3), "NULL") + ","
                         + isnull(col_name(a.id, depkey4), "NULL") + ","
                         + isnull(col_name(a.id, depkey5), "NULL") + ","
                         + isnull(col_name(a.id, depkey6), "NULL") + ","
                         + isnull(col_name(a.id, depkey7), "NULL") + ","
                         + isnull(col_name(a.id, depkey8), "NULL") + ",NULL", 1,
                      charindex("NULL",("," + col_name(a.id, depkey1) + ","
                         + isnull(col_name(a.id, depkey2), "NULL") + ","
                         + isnull(col_name(a.id, depkey3), "NULL") + ","
                         + isnull(col_name(a.id, depkey4), "NULL") + ","
                         + isnull(col_name(a.id, depkey5), "NULL") + ","
                         + isnull(col_name(a.id, depkey6), "NULL") + ","
                         + isnull(col_name(a.id, depkey7), "NULL") + ","
                         + isnull(col_name(a.id, depkey8), "NULL") + ",NULL"))-2)
            , charindex(b.name, "common"),
              char_length(
                  substring(col_name(a.id, key1) + ","
                         + isnull(col_name(a.id, key2), "NULL") + ","
                         + isnull(col_name(a.id, key3), "NULL") + ","
                         + isnull(col_name(a.id, key4), "NULL") + ","
                         + isnull(col_name(a.id, key5), "NULL") + ","
                         + isnull(col_name(a.id, key6), "NULL") + ","
                         + isnull(col_name(a.id, key7), "NULL") + ","
                         + isnull(col_name(a.id, key8), "NULL") + ",NULL", 1,
                      charindex("NULL",(col_name(a.id, key1) + ","
                         + isnull(col_name(a.id, key2), "NULL") + ","
                         + isnull(col_name(a.id, key3), "NULL") + ","
                         + isnull(col_name(a.id, key4), "NULL") + ","
                         + isnull(col_name(a.id, key5), "NULL") + ","
                         + isnull(col_name(a.id, key6), "NULL") + ","
                         + isnull(col_name(a.id, key7), "NULL") + ","
                         + isnull(col_name(a.id, key8), "NULL") + ",NULL"))-2)
                   +
                  substring("," + col_name(a.id, depkey1) + ","
                         + isnull(col_name(a.id, depkey2), "NULL") + ","
                         + isnull(col_name(a.id, depkey3), "NULL") + ","
                         + isnull(col_name(a.id, depkey4), "NULL") + ","
                         + isnull(col_name(a.id, depkey5), "NULL") + ","
                         + isnull(col_name(a.id, depkey6), "NULL") + ","
                         + isnull(col_name(a.id, depkey7), "NULL") + ","
                         + isnull(col_name(a.id, depkey8), "NULL") + ",NULL", 1,
                      charindex("NULL",("," + col_name(a.id, depkey1) + ","
                         + isnull(col_name(a.id, depkey2), "NULL") + ","
                         + isnull(col_name(a.id, depkey3), "NULL") + ","
                         + isnull(col_name(a.id, depkey4), "NULL") + ","
                         + isnull(col_name(a.id, depkey5), "NULL") + ","
                         + isnull(col_name(a.id, depkey6), "NULL") + ","
                         + isnull(col_name(a.id, depkey7), "NULL") + ","
                         + isnull(col_name(a.id, depkey8), "NULL") + ",NULL"))-2))),
                  substring(col_name(a.id, key1) + ","
                         + isnull(col_name(a.id, key2), "NULL") + ","
                         + isnull(col_name(a.id, key3), "NULL") + ","
                         + isnull(col_name(a.id, key4), "NULL") + ","
                         + isnull(col_name(a.id, key5), "NULL") + ","
                         + isnull(col_name(a.id, key6), "NULL") + ","
                         + isnull(col_name(a.id, key7), "NULL") + ","
                         + isnull(col_name(a.id, key8), "NULL") + ",NULL", 1,
                      charindex("NULL",(col_name(a.id, key1) + ","
                         + isnull(col_name(a.id, key2), "NULL") + ","
                         + isnull(col_name(a.id, key3), "NULL") + ","
                         + isnull(col_name(a.id, key4), "NULL") + ","
                         + isnull(col_name(a.id, key5), "NULL") + ","
                         + isnull(col_name(a.id, key6), "NULL") + ","
                         + isnull(col_name(a.id, key7), "NULL") + ","
                         + isnull(col_name(a.id, key8), "NULL") + ",NULL"))-2)
            )
    --  Append a Null
        + isnull(@withgo, char(10)+"go"+char(10))
      FROM  syskeys a, master..spt_values b, sysobjects c
      WHERE a.type *= b.number
        AND b.type = 'K'
        AND a.id = c.id
        AND c.type <> "S"
        AND a.id = object_id(@tablename)

  end

end
go

grant execute on sp__revkey to public
go

