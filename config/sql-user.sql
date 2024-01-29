-- SQL User Creation

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

--
-- User Creation: `doogle`
--
CREATE USER IF NOT EXISTS 'doogle'@'%' IDENTIFIED BY 'dzl1Z8T5IxsutKNNnmZB';
GRANT SELECT, INSERT, UPDATE ON `doogle`.* TO 'doogle'@'%';