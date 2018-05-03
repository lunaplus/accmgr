alter table expenditures add column (
      freeze bit(1) not null default b'0',
      sorts int not null default 0
);
-- freeze : b'1'=>freezed, b'0'=>normal
