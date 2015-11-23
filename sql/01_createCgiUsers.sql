create table cgiUsers (
       UID varchar(8) primary key,
       Name varchar(20),
       Password text,
       LastLogin datetime,
       LastModified datetime
);
