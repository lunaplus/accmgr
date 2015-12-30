create table specifications (
       SID bigint auto_increment primary key,
       wpdate datetime, -- withdraw or payment
       EID bigint,
       withdrawFrom bigint,
       paymentTo bigint,
       amount bigint,
       paymentMonth int
);
