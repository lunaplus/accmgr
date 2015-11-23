create table expenditures (
       EID bigint auto_increment primary key,
       name varchar(20),
       classify	bit(1)
);
-- classify : b'1'=>in, b'0'=>out, null=>move
