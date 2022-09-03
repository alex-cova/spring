# CREATE SCHEMA spring;
# use spring;

create table country
(
    uuid varchar(36)  not null
        primary key,
    name varchar(120) not null
);

create table developer
(
    uuid        varchar(36)  not null
        primary key,
    name        varchar(255) not null,
    age         int          not null,
    gender      tinyint(1)   not null,
    phoneNumber varchar(13)  null,
    countryId   int          null,
    discordId   varchar(120) null,
    proLang     json         null
);



