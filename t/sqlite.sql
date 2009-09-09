-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Sep  7 18:35:02 2009
-- 


BEGIN TRANSACTION;

--
-- Table: findordefault
--
CREATE TABLE findordefault (
  id INTEGER PRIMARY KEY NOT NULL,
  name character varying NOT NULL DEFAULT 'myname',
  password character varying NOT NULL DEFAULT 'mypassw0rd'
);

--
-- Table: skip_end
--
CREATE TABLE skip_end (
  id INTEGER PRIMARY KEY NOT NULL,
  name character varying NOT NULL,
  password character varying NOT NULL
);

--
-- Table: user
--
CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name character varying NOT NULL,
  password character varying NOT NULL
);

COMMIT;
