create table specifications (
       SID bigint auto_increment primary key,
       wpdate datetime,
       EID bigint,
       withdrawFrom bigint,
       paymentTo bigint,
       amount bigint,
       paymentMonth datetime
);
