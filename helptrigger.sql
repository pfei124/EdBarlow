/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name: sp__helptrigger
|*
|* Author:
|*
|* Description:
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

if exists (select * from sysobjects
           where  name = 'sp__helptrigger'
           and    type = 'P')
   drop procedure sp__helptrigger
go

create procedure sp__helptrigger (
                                  @objname varchar(92) = NULL,
                                  @dont_format char(1) = null
                                 )
AS
BEGIN

if @objname is null
	select @objname=''

select
         name,
         id,
         uid,
         owner = convert(char(15),user_name(uid)),
         crdate,
         ins_cnt = convert(char(7),'       '),
         del_cnt = convert(char(7),'       '),
         upd_cnt = convert(char(7),'       ')
into   #trigs
from   sysobjects o
where  name like '%'+@objname+'%'
and    type = 'TR'

if exists (select * from sysobjects where name=@objname and type='D' )
                  delete #trigs
                  where name!= @objname

if not exists ( select * from #trigs )
begin
        if @objname is not null
                print 'Trigger Not Found'
        else
                print 'No Triggers In Database'
        return
end

update #trigs
set    del_cnt=( select convert(char(7), count(*) )
			from   sysobjects o where  o.deltrig = #trigs.id),
       upd_cnt=( select convert(char(7), count(*) )
			from   sysobjects o where  o.updtrig = #trigs.id),
       ins_cnt=( select convert(char(7), count(*) )
			from   sysobjects o where  o.instrig = #trigs.id)

update #trigs
set      name = user_name(uid)+'.'+name
where  uid!=1

select
         name   'Trigger Name',
         convert(char(2),crdate,6)
                +substring(convert(char(9),crdate,6),4,3)
                +substring(convert(char(9),crdate,6),8,2) 'Cr Date',
         ins_cnt 'Ins Cnt',
         del_cnt 'Del Cnt',
         upd_cnt 'Upd Cnt'
from #trigs
order  by name
END
go

grant execute on sp__helptrigger  to public
go

