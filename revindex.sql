/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:   sp__revindex
|*
|* Author: Ed Barlow
|*
|* Description:
|*
|* Usage:       sp__revindex (<objectname>)
|*
|* Modification History:
|* Date        Version Who           What
|* March 2006  x.y     Ludek Svozil  Corrected "clustered" indexes for DOL tables
|*                     www.svozil-consulting.ch
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (SELECT * 
	     FROM sysobjects
	    WHERE name = "sp__revindex"
	      AND type = "P")
   drop procedure sp__revindex
go
create procedure sp__revindex (
                          @object char(30)=NULL,
                          @dont_format char(1) = null
                         )
as
begin

declare @type smallint	/* the object type */
declare @nl   char      /* RV added */

select @nl = char(10)   /* RV added */

select owner      = user_name(o.uid),
       name       = o.name,
       index_name = i.name,
       indexid    = i.indid,
	status     = status,
	status2    = status2,  /* RV added */
	createstmt = convert(varchar(255),"N.A."),
	keylist    = convert(varchar(255),"N.A."),
	endingstmt = convert(varchar(255),@nl + "go"),
	segment    = segment
into   #indexlist
from   sysobjects o, sysindexes i
where  i.id   = o.id
and    o.type = "U"
and      isnull(@object,o.name)=o.name
and      indid > 0
and      indid < 255  /* RV added */

if @@rowcount = 0
begin
	if @object is null
		select convert(varchar(255),"No Indexes found in Current Database")
	return
end

/* delete multiple rows */
delete #indexlist
from   #indexlist a, #indexlist b
where  a.indexid = 0
and    b.indexid != 0
and    a.name = b.name

/* RV added
 handle cases where indexes were created as 'real' indexes
 also handle cases where indexes were defined as constraints
*/

update #indexlist
set    createstmt='CREATE'
where  status2 & 2 = 0

update #indexlist
set    createstmt = 'ALTER TABLE ' + rtrim(owner) + '.' + rtrim(name) +
		    ' ADD CONSTRAINT ' + rtrim(index_name)
where  status2 & 2 = 2

update #indexlist
set    createstmt = rtrim(createstmt)+' UNIQUE'
where  status & 2 = 2
and    status & 2048 != 2048

update #indexlist
set    createstmt = rtrim(createstmt)+' PRIMARY KEY'
where  status & 2 = 2
and    status & 2048 = 2048

update #indexlist
set    createstmt = rtrim(createstmt)+' CLUSTERED'
where  indexid = 1 or status&16=16 or status2&512 = 512

update #indexlist
set    createstmt = rtrim(createstmt)+' NONCLUSTERED'
where  indexid > 1 and status&16 <> 16 and status2&512 <> 512

update #indexlist
set    createstmt = rtrim(createstmt)+ ' INDEX '+rtrim(index_name)
		    + " ON "+rtrim(owner)+"."+rtrim(name)+' ('
where  status2 & 2 = 0

update #indexlist
set    createstmt = rtrim(createstmt) + ' ('
where  status2 & 2 = 2

declare @count int
select  @count=1

while ( @count < 17 )   /* 16 appears to be the max number of index cols */
begin

	if @count=1
		update #indexlist
		set    keylist=index_col(owner+"."+name,indexid,@count)
		where  index_col(owner+"."+name,indexid,@count) is not null
   else
		update #indexlist
		set    keylist=rtrim(keylist)+","+index_col(owner+"."+name,indexid,@count)
		where  index_col(owner+"."+name,indexid,@count) is not null

	if @@rowcount=0 break

	select @count=@count+1
end

/* add on segment clause if other than default */
update #indexlist
set     i.endingstmt=" ON '"+rtrim(s.name)+"' "+rtrim(i.endingstmt)
from  #indexlist i,syssegments s
where s.segment = i.segment
and     s.name <> "default"

update #indexlist
set     endingstmt=" WITH IGNORE_DUP_KEY "+rtrim(endingstmt)
where status&1 = 1

update #indexlist
set     endingstmt=" WITH IGNORE_DUP_ROW "+rtrim(endingstmt)
where status&4 = 4

update #indexlist
set     endingstmt=" WITH ALLOW_DUP_ROW "+rtrim(endingstmt)
where status&64 = 64

insert #indexlist
select
	owner,
   name,
   index_name,
   indexid,
	status   ,
	status2  ,
 	createstmt = 'IF EXISTS ( SELECT * FROM sysindexes WHERE
			id=OBJECT_ID("'+ rtrim(name) + '") AND name= "' +
		 	 		rtrim(index_name) +
		 	 		'" ) DROP INDEX ' +
		 	 		rtrim(name) +
		  			'.' +
		 	 		rtrim(index_name)  +
		 	 		@nl +'go' ,
	keylist    ,
	endingstmt ,
	segment=-1
from #indexlist
where  status2 & 2 = 0

insert #indexlist
select
	owner,
   name,
   index_name,
   indexid,
	status   ,
	status2  ,
   createstmt = 'ALTER TABLE ' + rtrim(owner) + '.' + rtrim(name) +
		    ' DROP CONSTRAINT ' + rtrim(index_name) + @nl +'go' ,
	keylist    ,
	endingstmt ,
	segment=-1
from #indexlist
where  status2 & 2 = 2

update #indexlist
set keylist="", endingstmt=""
where segment = -1

update #indexlist
set segment=1, endingstmt=") "+rtrim(endingstmt)
where segment != -1

select convert(varchar(255),createstmt+keylist+endingstmt)
	as "-- DDL Code"
from #indexlist
order by segment,owner,name,indexid

return(0)

end

go

grant execute on sp__revindex to public
go
