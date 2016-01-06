create table statistics (
       iyear int,
       imonth int,
       owner varchar(9),
       AID varchar(20),
       EID varchar(20),
       amount bigint,
       primary key(iyear, imonth, owner, AID, EID)
);
-- owner : UID(8) + 'ALLOWNERS'
-- AID : (bigint).to_s + 'ALLACCOUNTS'
-- EID : (bigint).to_s + 'INALL','OUTALL'
-- max(bigint unsigned)=18446744073709551615 // len(max(bigint unsigned))=20
