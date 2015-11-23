create table Accounts (
       AID bigint auto_increment primary key,
       name varchar(20),
       isCard bit(1) not null default b'0',
       UID varchar(8),
       balance bigint,
       adddate datetime,
       editdate datetime
);
