/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helpproc
|*
|* Author:
|*
|* Description:
|*
|* Usage:       sp__helpproc
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* 12.11.2024        6.91
|*
\************************************************************************/


use sybsystemprocs
go

if exists (select * from sysobjects
            where  name = "sp__helpproc"
              and  type = "P")
   drop procedure sp__helpproc

go

create procedure sp__helpproc(
                              @objname varchar(92) = NULL,
                              @dont_format char(1) = NULL
                             )
as
begin

if exists (select * from sysobjects where name=@objname and type='P' )
          select Procedure_name = convert(char(35),name),
                 Owner          = convert(char(15),user_name(uid)),
                 Created_date   = convert(char(2),crdate,6)
                                  +substring(convert(char(9),crdate,6),4,3)
                                  +substring(convert(char(9),crdate,6),8,2)
            from sysobjects
           where name =@objname
             and type = "P"
           order by name
else if @objname is null
          select Procedure_name = convert(char(35),name),
                 Owner          = convert(char(15),user_name(uid)),
                 Created_date   = convert(char(2),crdate,6)
                                  +substring(convert(char(9),crdate,6),4,3)
                                  +substring(convert(char(9),crdate,6),8,2)
            from sysobjects
           where type = "P"
           order by name
else
          select Procedure_name = convert(char(35),name),
                 Owner          = convert(char(15),user_name(uid)),
                 Created_date   = convert(char(2),crdate,6)
                                  +substring(convert(char(9),crdate,6),4,3)
                                  +substring(convert(char(9),crdate,6),8,2)
            from sysobjects
           where name like "%"+@objname+"%"
             and type = "P"
           order by name

end
go

grant execute on sp__helpproc  to public
go

