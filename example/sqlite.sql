-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Jan 14 11:03:25 2011
-- 

BEGIN TRANSACTION;

--
-- Table: user
--
CREATE TABLE user (
  id character(10) NOT NULL,
  created_on timestamp with time zone NOT NULL,
  updated_on timestamp with time zone NOT NULL,
  email  NOT NULL,
  first  NOT NULL,
  last  NOT NULL,
  PRIMARY KEY (id)
);

COMMIT;
