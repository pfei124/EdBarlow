
/************************************************************************\
|* Procedure Name: sp__helptext
|*
|* Author: Andrew Zanevsky, AZ Databases, Inc.
|*
|* Description: Works similar to standard system stored procedure sp_helptext.
|*              Correctly handles cases when a substring begins in one row of 
|*              syscomments table and continues in the next (no split lines!).
|*              Uses print command (not select) to generate the result for
|*              technical reasons.
|*
|* Parameters:  @objname - object name
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
         where  type = 'P'
         and    name = "sp__helptext")
begin
    drop procedure sp__helptext
end
go
create procedure sp__helptext ( @objname varchar(92), @dont_format char(1) = null)
as
declare @text_count int,
        @text       varchar(255),
		  @otext		varchar(255),
		  @Tcolid int,
		  @Tnumber int,
        @line       varchar(1024),
        @split      tinyint,
        @lf         char(1)
select  @lf = char(10)

/*
if @@trancount = 0
begin
        set transaction isolation level 1
        set chained off
end
*/

/***** Make sure the @objname is local to the current database. */
if @objname like "%.%.%" and
        substring(@objname, 1, charindex(".", @objname) - 1) != db_name()
begin
        print "Object must be in the current database."
        return (1)
end

/***** See if @objname exists. */
if (object_id(@objname) is NULL)
begin
        print "Object does not exist in this database."
        return (1)
end

select  text,colid,number
into    #text
from    syscomments
where   id = object_id(@objname)
order by number,colid

select  @text_count = @@rowcount

if @text_count = 0
begin
        print "Error - Object Does Not Exist"
        return
end

/***** Parse and print the text one line at a time. */
set rowcount 1
while @text_count > 0
begin
        select  @text_count = @text_count - 1,
					 @otext = text,
                @text  = text + space( ( 255 - datalength( text ) )
                                       * sign( @text_count ) ),
                @split = charindex( @lf, text ),
					 @Tcolid=colid,
					 @Tnumber=number
        from    #text

--print "FETCHLINE: %1!",@text
--print "FETCHLINEO: %1!",@otext
--print "SPLIT: %1!",@split
--print "DONEFETCH: TEXTCOUNT=%1!",@text_count

        delete  #text where colid=@Tcolid and number=@Tnumber

		  if @split = 0 					/* No line feeds on line */
		  begin
						select @text=@line+@text, @line=""
						print "%1!",@text
						select @text="", @line=""
		  end

        while   @split > 0
        begin
                select  @line  = @line + substring( @text, 1, @split - 1 ),
                        @text  = right( @text, datalength( @text ) - @split )
                print   "%1!",@line
					 --print "REMAINDER %1!",@text
                select  @split = charindex( @lf, @text ),
                        @line  = NULL
        end
                --print   "AFTER LINE %1!",@line
					 --print "AFTER REMAINDER %1!",@text

        if @text_count = 0
        begin
                if ascii(@text) = 0
                begin
                        select @text=substring(rtrim(@text),2,255)
                end

                print "%1!",@text
        end
        else
                select  @line = @text
end
set rowcount 0

print "go"

go
grant execute on sp__helptext to public
go

