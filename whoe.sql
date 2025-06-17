
/************************************************************************\
|* Procedure Name: sp__whoe
|*
|* Author: Philippe Wathelet
|*
|* Description: This is a substitute for Sybase's standard sp_who stored procedure
|*              The output is clearer without line wrapping.
|*              Use it with isql -U<user> -S<server> -w150
|*              allowing a width of up to 150 characters per line for example
|*
|* Usage:       sp__whoe <loginname>
|*
|* Modification History:
|*
|* Date        Who   Version  What
|* xx.07.1998  pw    1.0 
|* 12.11.2024        6.91
|*
\************************************************************************/


use sybsystemprocs
go
-- dump tran master with no_log
-- go

if exists (select * from sysobjects where name = "sp__whoe" and type = "P")
    drop procedure sp__whoe
go
create procedure sp__whoe @loginame varchar(30) = NULL
as
declare @low      int,
        @high     int,
        @spidlow  int,
        @spidhigh int,
        @forlogin char(23),
        @msg0     char(145),
        @msg1     char(20),
        @msg2     char(4),
        @msg3     char(4),
        @msg4     char(4),
        @msg5     char(4),
        @msg6     char(4),
        @msg7     char(4),
        @runtime  char(144)

select @low = 0, @high = 32767, @spidlow = 0, @spidhigh = 32767

/* A specific login name can also be given to focus (and reduce) the information displayed */
if @loginame is not NULL
    begin
    select @low = suser_id(@loginame), @high = suser_id(@loginame), @forlogin = "  for '" + @loginame + "' only"
    if @low is NULL
        begin
        if @loginame like "[0-9]%"
            begin
            select @spidlow = convert(int, @loginame),
            @spidhigh       = convert(int, @loginame),
            @low            = 0,
            @high           = 32767
        end
    else
        begin
        print "No login exists with the supplied name."
        return (1)
        end
    end
end

select @runtime = "       " + @@servername + " processes as on " + convert(char(19), getdate()) + @forlogin
-- print  @runtime
print  " "

set nocount on

select convert(char(4), p.spid)                                       "SPID",
       convert(char(5), p.suid)                                       "SUID",
       convert(char(3), p.enginenum)                                  "ENG" ,
       convert(char(10),hostprocess)                                  "HOSTPID ",
       convert(char(14), p.hostname)                                  "HOST",
       convert(char(12), db_name(p.dbid))                             "DATABASE",
       convert(char(16), p.program_name)                              "PROGRAM",
       convert(char(10),suser_name(p.suid))                           "LOGIN",
       convert(varchar(12),p.cmd)                                     "COMMAND",
       right("   " + convert(char(3), p.blocked),3)                   "BLK",
       convert(char(11), p.status)                                    "STATUS",
       convert(char(7), p.memusage)                                   "MEM    ",    /* MEMUSAGE is the amount of memory allocated to the process */
--   right("  " + rtrim(convert(char(5), p.memusage)), 5)          "MEM  ",    /* MEMUSAGE is the amount of memory allocated to the process */
       right("       " + rtrim(convert(char(12), p.physical_io)), 8)  "PHYS I/O",
       right("00" + rtrim(convert(char(2), datediff(hh, h.starttime, getdate()))), 2) + ":" +
       right("00" + rtrim(convert(char(2), datediff(mi, h.starttime, getdate()) - (datediff(hh, h.starttime, getdate())) * 60)), 2)
                                                                      "HH:MM",   /* HH:MM is the duration of an active transaction over 1 min */
       convert(varchar(12),
          /* 1. A LOG FULL condition is clearly highlighted as being important */
          substring(" LOG IS FULL", 1, (1 - abs(sign(ascii(substring(p.cmd, 3, 1)) - 71))) * 11 + 1) +
          /* 2. All blocked processes are clearly marked and can be further investigated using: sp__whoe "<process number>" */
          substring(" -BLOCKED-  ", 1, sign(p.blocked) * 11 + 1) +
          /* 3. The time taken by the longest uncommitted (open) transaction if any */
          substring(" OVER " + rtrim(convert(char(4), datediff(mi, h.starttime, getdate()))) + "'  ", 1, sign(datediff(mi, h.starttime, getdate()) / 2) * 11 + 1) +
          /* 4. An infected process should be extremely rare and rather than being killed should preferably be cleared by a server reboot instead */
          substring(" *REBOOT!*  ", 1, (1 - abs(sign(ascii(substring(p.status, 3, 1)) - 102))) * 11 + 1) +
          /* 5. Indicating which is your own session's process */
          substring(" <-- YOU    ", 1, (1 - abs(sign(p.spid - @@spid))) * 11 + 1) +
          /* 6. The suppression of all spid's over 6 removes the Housekeeper process (and all other system processes) from the displayed report */
          substring(" ACTIVE     ", 1, (1 - abs(sign(ascii(substring(p.status, 2, 1)) - 117))) * (1 - sign(6 / p.spid)) * 11 + 1) +
          /* 7. All the processes accounting for more than 1000 i/o's are highlighted if they are not active already */
          substring(" BACKUP     ", 1, (1 - abs(sign(difference(p.hostname, "SYB_BACKUP") - 4))) * 11 + 1) +
          /* 8. A process having accumulated over 1000 physical i/o is considered of significance and worth bringing to the attention */
          substring(" >i/o       ", 1, (1 - sign(20000/(p.physical_io + 1))) * (1 - sign(14/p.spid)) * 11 + 1))  "WARNINGS   "
from   master..sysprocesses p, master..syslogshold h
where  p.suid between @low and @high
and    p.spid between @spidlow and @spidhigh
and    p.spid *= h.spid
order by 15, p.spid

/* Calculate the Processes Running and Runnable as close as possible from the display to reduce the chance of changes occurring between queries */

/* Number of processes running */
select @msg6 = rtrim(convert(char(4), count(*)))
from   master..sysprocesses p
where  p.suid between @low and @high
and    substring(suser_name(p.suid), 1, 4) != "NULL"
and    status = "running"

/* Number of processes runnable */
select @msg7 = rtrim(convert(char(4), count(*)))
from   master..sysprocesses p
where  p.suid between @low and @high
and    substring(suser_name(p.suid), 1, 4) != "NULL"
and    status = "runnable"

/* Number of processes */
select @msg1 = " " + rtrim(convert(char(4), count(suid)))
from   master..sysprocesses p
where  p.suid between @low and @high
and    p.spid between @spidlow and @spidhigh
order by spid

/* Number of hosts */
select @msg2 = rtrim(convert(char(4), count(distinct hostname)))
from   master..sysprocesses p
where  hostname != ""
and    p.suid between @low and @high
and    p.spid between @spidlow and @spidhigh

/* Number of databases */
select @msg3 = rtrim(convert(char(4), count(distinct dbid)))
from   master..sysprocesses p
where  p.suid between @low and @high
and    p.spid between @spidlow and @spidhigh

/* Number of users (logins) */
select @msg4 = rtrim(convert(char(4), count(distinct suid) + sign(abs(count(distinct suid) - 1))))
from   master..sysprocesses
where  substring(suser_name(suid), 1, 4) != "NULL"
and    @loginame is null

/* Total memory used for processes */
select @msg5 = rtrim(convert(char(7), sum(memusage)))
from   master..sysprocesses p
where  p.suid between @low and @high
and    p.spid between @spidlow and @spidhigh

/* Display the results */
select @msg0 = "  PROCESSES: " + rtrim(@msg1) 
             + "  HOSTS: " + rtrim(@msg2) 
	     + "  DATABASES: " + rtrim(@msg3) 
	     + "  LOGINS: " + rtrim(@msg4) 
	     + "  MEMORY USAGE: " + rtrim(@msg5) 
	     + "  RUNNING USER PROCESSES: " + rtrim(@msg6) 
	     + "  RUNNABLE USER PROCESSES: " + rtrim(@msg7)

print ""
print @msg0

return (0)
go

grant execute on sp__whoe to public
go

