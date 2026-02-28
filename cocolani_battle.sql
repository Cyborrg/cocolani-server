-- phpMyAdmin SQL Dump
-- version 4.2.7.1
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Feb 28, 2026 at 04:34 PM
-- Server version: 5.5.39
-- PHP Version: 5.4.31

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `cocolani_battle`
--

-- --------------------------------------------------------

--
-- Table structure for table `cc_bans`
--

CREATE TABLE IF NOT EXISTS `cc_bans` (
`id` int(11) NOT NULL,
  `ip` varchar(255) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `until` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `banned_by` varchar(255) NOT NULL DEFAULT '',
  `ban_type` varchar(16) NOT NULL DEFAULT 'name',
  `ban_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_battle_settings`
--

CREATE TABLE IF NOT EXISTS `cc_battle_settings` (
`id` int(11) NOT NULL,
  `room_id` varchar(8) NOT NULL DEFAULT '0',
  `startGameThreshold` int(11) NOT NULL DEFAULT '2'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `cc_battle_settings`
--

INSERT INTO `cc_battle_settings` (`id`, `room_id`, `startGameThreshold`) VALUES
(1, '0', 2),
(2, '1', 2);

-- --------------------------------------------------------

--
-- Table structure for table `cc_char_status`
--

CREATE TABLE IF NOT EXISTS `cc_char_status` (
  `is_min_level_home` varchar(255) NOT NULL,
  `display` varchar(255) NOT NULL,
`ID` int(255) NOT NULL,
  `is_email_confirm_level` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_chat`
--

CREATE TABLE IF NOT EXISTS `cc_chat` (
`id` int(11) NOT NULL,
  `Sender` varchar(255) NOT NULL DEFAULT '',
  `Room_ID` varchar(255) NOT NULL DEFAULT '',
  `Time` varchar(64) NOT NULL DEFAULT '',
  `Message` text NOT NULL,
  `Swear` varchar(8) NOT NULL DEFAULT 'False'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_def_lang`
--

CREATE TABLE IF NOT EXISTS `cc_def_lang` (
  `lang` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cc_def_lang`
--

INSERT INTO `cc_def_lang` (`lang`) VALUES
('0');

-- --------------------------------------------------------

--
-- Table structure for table `cc_def_settings`
--

CREATE TABLE IF NOT EXISTS `cc_def_settings` (
  `caption` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `init_purse_amount` varchar(255) NOT NULL,
  `one_email_per_registration` varchar(255) NOT NULL,
  `ban_period_days` varchar(255) NOT NULL,
`id` int(255) NOT NULL,
  `template_path` varchar(255) NOT NULL,
  `email_from` varchar(255) NOT NULL,
  `base_url` varchar(255) NOT NULL,
  `swf_url` varchar(255) NOT NULL,
  `reg_url` varchar(255) NOT NULL,
  `limit_one_connection` varchar(255) NOT NULL DEFAULT '0',
  `pagination_size` int(11) NOT NULL DEFAULT '10',
  `max_num_account_per_email` int(11) NOT NULL DEFAULT '100',
  `MOTD` varchar(255) DEFAULT 'Welcome to Cocolani!',
  `usertypes` varchar(255) DEFAULT '0',
  `logins_open` varchar(8) NOT NULL DEFAULT 'true'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `cc_def_settings`
--

INSERT INTO `cc_def_settings` (`caption`, `init_purse_amount`, `one_email_per_registration`, `ban_period_days`, `id`, `template_path`, `email_from`, `base_url`, `swf_url`, `reg_url`, `limit_one_connection`, `pagination_size`, `max_num_account_per_email`, `MOTD`, `usertypes`, `logins_open`) VALUES
('جزر كوكولاني | Cocolani Islands', '200', '1', '7', 1, '', '', 'http://localhost/cocolani', 'swf-5968/', 'http://localhost/cocolani/php/req/', '1', 10, 1, 'Welcome to Cocolani!', '0,Visitor|1,Banned|2,Unconfirmed|3,Explorer|7,Moderator|8,Super Moderator|4,Resident', 'true');

-- --------------------------------------------------------

--
-- Table structure for table `cc_email_templates`
--

CREATE TABLE IF NOT EXISTS `cc_email_templates` (
  `id` int(11) NOT NULL,
  `content` text NOT NULL,
  `subject` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cc_email_templates`
--

INSERT INTO `cc_email_templates` (`id`, `content`, `subject`) VALUES
(-13, 'Welcome %FIRST_NAME% %LAST_NAME%,Please confirm your registration: %CONFIRM%', 'Welcome to Cocolani');

-- --------------------------------------------------------

--
-- Table structure for table `cc_energy_prices`
--

CREATE TABLE IF NOT EXISTS `cc_energy_prices` (
  `tier_id` int(11) NOT NULL,
  `price` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `cc_energy_prices`
--

INSERT INTO `cc_energy_prices` (`tier_id`, `price`) VALUES
(1, 5),
(2, 10),
(3, 14);

-- --------------------------------------------------------

--
-- Table structure for table `cc_extra_langs`
--

CREATE TABLE IF NOT EXISTS `cc_extra_langs` (
`id` int(255) NOT NULL,
  `lang` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_games`
--

CREATE TABLE IF NOT EXISTS `cc_games` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cc_games`
--

INSERT INTO `cc_games` (`id`, `name`) VALUES
(1, 'Mahjonng'),
(2, 'Temple Run'),
(3, 'Temple Towers'),
(4, 'Lava crossing'),
(5, 'Lunch with a Mole'),
(7, 'Aerial Defense'),
(8, 'Gem Mining'),
(9, 'Cacti Sweeper'),
(10, 'Racer'),
(11, 'Cog Calamity'),
(12, 'Sheep Shelter'),
(13, 'Fishing'),
(14, 'Yeknom Temple Puzzle'),
(15, 'Jungle Gems'),
(16, 'Coconut Catch'),
(17, 'Lava Tubing'),
(18, 'Volcanic Gemtwist'),
(21, 'Marble Madness');

-- --------------------------------------------------------

--
-- Table structure for table `cc_game_config`
--

CREATE TABLE IF NOT EXISTS `cc_game_config` (
  `game_id` int(11) NOT NULL,
  `game_name` varchar(255) DEFAULT NULL,
  `bronze_min` int(11) NOT NULL,
  `silver_min` int(11) NOT NULL,
  `gold_min` int(11) NOT NULL,
  `money_min_score` int(11) NOT NULL,
  `money_max_score` int(11) NOT NULL,
  `money_divisor` int(11) NOT NULL,
  `money_limit` int(11) NOT NULL,
  `tribe_id` int(11) NOT NULL,
  `max_score` int(11) NOT NULL DEFAULT '60000'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `cc_game_config`
--

INSERT INTO `cc_game_config` (`game_id`, `game_name`, `bronze_min`, `silver_min`, `gold_min`, `money_min_score`, `money_max_score`, `money_divisor`, `money_limit`, `tribe_id`, `max_score`) VALUES
(1, 'Matching Cubes', 1000, 2000, 4000, 1, 7500, 251, 30, 0, 60000),
(2, 'Temple Run', 1500, 3000, 5000, 900, 22000, 734, 30, 0, 60000),
(3, 'Pyramid', 100, 400, 800, 300, 1000, 50, 20, 0, 60000),
(4, 'Save Turtle Eggs', 150, 300, 600, 100, 1750, 59, 30, 1, 60000),
(5, 'Hungry Platypus', 150, 300, 600, 150, 1800, 60, 30, 0, 60000),
(7, 'Aerial Defense', 2000, 10000, 15000, 1200, 30000, 1001, 30, 0, 60000),
(8, 'Rock Hunting', 1000, 3000, 6000, 1000, 22000, 734, 30, 1, 60000),
(9, 'Hidden Mines', 1000, 10000, 20000, 3000, 45000, 1501, 30, 1, 60000),
(10, 'Car Race', 10000, 15000, 22500, 4000, 40000, 1334, 30, 1, 60000),
(11, 'Confused Gear', 2000, 3500, 7000, 2000, 11000, 551, 20, 1, 60000),
(12, 'Save Sheep', 3, 7, 15, 1, 50, 1, 50, 1, 60000),
(13, 'Hunting Challenge', 150, 300, 700, 20, 2000, 67, 30, 0, 60000),
(14, 'Puzzle', 500, 3000, 5000, 0, 8000, 5, 500, 0, 60000),
(15, 'Jungle Gem', 5000, 9500, 20000, 800, 30000, 1001, 30, 0, 60000),
(16, 'Coconut', 1000, 3000, 6000, 300, 20000, 667, 30, 0, 60000),
(17, 'Energy Tube', 10000, 100000, 150000, 5000, 300000, 10001, 30, 1, 60000),
(18, 'Volcanic Gems', 5000, 9500, 20000, 1500, 40000, 1334, 30, 1, 60000),
(21, 'Crazy Balls', 4000, 8000, 12000, 500, 22000, 734, 30, 99, 60000);

-- --------------------------------------------------------

--
-- Table structure for table `cc_game_pzl_award`
--

CREATE TABLE IF NOT EXISTS `cc_game_pzl_award` (
  `pzl_id` int(11) NOT NULL,
  `required_gold_game_ids` varchar(255) NOT NULL COMMENT 'comma-separated game IDs all needing gold'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `cc_game_pzl_award`
--

INSERT INTO `cc_game_pzl_award` (`pzl_id`, `required_gold_game_ids`) VALUES
(7, '4,8,11,17');

-- --------------------------------------------------------

--
-- Table structure for table `cc_game_rewards`
--

CREATE TABLE IF NOT EXISTS `cc_game_rewards` (
`id` int(11) NOT NULL,
  `game_id` int(11) NOT NULL,
  `min_tier` int(11) NOT NULL DEFAULT '1' COMMENT '1=bronze 2=silver 3=gold',
  `reward_type` varchar(32) NOT NULL COMMENT 'item | pzl | invars | item_and_invars',
  `pzl_id` int(11) DEFAULT NULL,
  `item_obj_id` int(11) DEFAULT NULL,
  `invars_id` int(11) DEFAULT NULL,
  `once_check_field` varchar(64) DEFAULT NULL COMMENT 'user field to check e.g. pzl or invars',
  `once_check_value` varchar(64) DEFAULT NULL COMMENT 'value that means already awarded'
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `cc_game_rewards`
--

INSERT INTO `cc_game_rewards` (`id`, `game_id`, `min_tier`, `reward_type`, `pzl_id`, `item_obj_id`, `invars_id`, `once_check_field`, `once_check_value`) VALUES
(1, 16, 1, 'item_and_invars', NULL, 58, 66, 'invars', '66'),
(2, 14, 1, 'pzl', 18, NULL, NULL, 'pzl', '18');

-- --------------------------------------------------------

--
-- Table structure for table `cc_highscores`
--

CREATE TABLE IF NOT EXISTS `cc_highscores` (
`id` int(11) NOT NULL,
  `game_id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `score` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=46 ;

--
-- Dumping data for table `cc_highscores`
--

INSERT INTO `cc_highscores` (`id`, `game_id`, `username`, `score`, `created_at`) VALUES
(1, 11, 'xvv', 7032, '2026-02-17 05:20:12'),
(2, 8, 'xvv', 17663, '2026-02-17 05:31:51'),
(3, 17, 'xvv', 168700, '2026-02-17 05:35:00'),
(4, 4, 'xvv', 642, '2026-02-17 05:36:51'),
(5, 13, 'xvv', 715, '2026-02-17 05:52:35'),
(6, 3, 'clue', 695, '2026-02-24 08:38:28'),
(7, 3, 'clue', 384, '2026-02-24 08:40:57'),
(8, 14, 'clue', 160, '2026-02-24 08:45:10'),
(9, 14, 'clue3', 3330, '2026-02-26 03:56:20'),
(10, 7, 'clue3', 1000, '2026-02-26 04:00:03'),
(11, 7, 'clue3', 2350, '2026-02-26 04:00:34'),
(12, 16, 'clue3', 3400, '2026-02-26 06:26:04'),
(13, 12, 'clue3', 13, '2026-02-26 07:22:01'),
(14, 18, 'clue3', 7880, '2026-02-26 07:24:47'),
(15, 11, 'clue3', 5511, '2026-02-26 07:28:38'),
(16, 11, 'clue3', 7137, '2026-02-26 07:30:57'),
(17, 8, 'clue3', 18283, '2026-02-26 07:38:40'),
(18, 17, 'clue3', 221300, '2026-02-26 09:21:31'),
(19, 4, 'clue3', 532, '2026-02-26 09:23:41'),
(20, 4, 'clue3', 682, '2026-02-26 09:24:54'),
(21, 4, 'clue3', 114, '2026-02-26 09:49:17'),
(22, 4, 'clue3', 1404, '2026-02-26 09:51:02'),
(23, 4, 'clue3', 150, '2026-02-26 09:54:00'),
(24, 4, 'clue3', 999, '2026-02-26 09:56:01'),
(25, 4, 'clue3', 999, '2026-02-26 09:56:07'),
(26, 4, 'clue3', 999, '2026-02-26 09:56:09'),
(27, 4, 'clue3', 999, '2026-02-26 09:56:11'),
(28, 4, 'clue3', 999, '2026-02-26 09:56:12'),
(29, 4, 'clue3', 999, '2026-02-26 09:56:13'),
(30, 4, 'clue3', 999, '2026-02-26 09:56:14'),
(31, 4, 'clue3', 999, '2026-02-26 09:56:16'),
(32, 4, 'clue3', 99999, '2026-02-26 10:02:56'),
(33, 4, 'clue3', 9999, '2026-02-26 10:08:06'),
(34, 8, 'clue3', 928, '2026-02-26 10:09:38'),
(35, 8, 'clue3', 92899, '2026-02-26 10:11:26'),
(36, 18, 'clue3', 1680, '2026-02-26 10:16:52'),
(37, 4, 'clue3', 150, '2026-02-26 10:29:07'),
(38, 4, 'clue3', 150, '2026-02-26 10:32:09'),
(39, 4, 'clue3', 900, '2026-02-26 10:33:36'),
(40, 4, 'xvv', 270, '2026-02-27 05:51:42'),
(41, 3, 'nnn', 356, '2026-02-28 05:10:38'),
(42, 3, 'nnn', 540, '2026-02-28 05:12:48'),
(43, 14, 'nnn', 6660, '2026-02-28 05:14:32'),
(44, 16, 'nnn', 2700, '2026-02-28 05:32:09'),
(45, 12, 'nnn', 6, '2026-02-28 05:36:36');

-- --------------------------------------------------------

--
-- Table structure for table `cc_homes`
--

CREATE TABLE IF NOT EXISTS `cc_homes` (
  `user_id` int(255) NOT NULL,
  `street_num` varchar(255) NOT NULL DEFAULT '1',
  `tribe_ID` int(255) NOT NULL,
  `created` varchar(255) NOT NULL,
  `door_state` varchar(255) NOT NULL DEFAULT '0',
  `expiry_date` varchar(255) NOT NULL,
  `max_street` varchar(255) NOT NULL DEFAULT '1',
`ID` int(255) NOT NULL,
  `home_rental_period_days` int(255) NOT NULL DEFAULT '30',
  `slot` int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_homes_furniture`
--

CREATE TABLE IF NOT EXISTS `cc_homes_furniture` (
`id` int(11) NOT NULL,
  `home_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `x_pos` float NOT NULL,
  `y_pos` float NOT NULL,
  `rotation` int(11) NOT NULL DEFAULT '1',
  `is_wall` int(11) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_inv`
--

CREATE TABLE IF NOT EXISTS `cc_inv` (
  `active` varchar(255) NOT NULL,
  `user_id` int(255) NOT NULL,
`ID` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_invlist`
--

CREATE TABLE IF NOT EXISTS `cc_invlist` (
  `objID` int(11) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `description` varchar(255) CHARACTER SET utf8 NOT NULL,
  `swfID` int(11) NOT NULL DEFAULT '0',
  `price` int(11) NOT NULL DEFAULT '0',
  `kind` int(11) DEFAULT '0',
  `exchange` int(11) DEFAULT '0',
  `lvl` varchar(255) DEFAULT '1',
  `type` int(11) DEFAULT '0',
  `LastNumber` int(11) DEFAULT '0',
  `H_ClothStore` varchar(10) DEFAULT '0',
  `Y_ClothStore` varchar(10) DEFAULT '0',
  `H_FurnStore` varchar(10) DEFAULT '0',
  `Y_FurnStore` varchar(10) DEFAULT '0',
  `weaponStore` varchar(10) DEFAULT '0',
  `pzl_id` int(11) DEFAULT NULL,
  `tutStore` int(11) NOT NULL DEFAULT '0',
  `Y_BallonStore` int(11) NOT NULL DEFAULT '0',
  `H_BallonStore` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cc_invlist`
--

INSERT INTO `cc_invlist` (`objID`, `name`, `description`, `swfID`, `price`, `kind`, `exchange`, `lvl`, `type`, `LastNumber`, `H_ClothStore`, `Y_ClothStore`, `H_FurnStore`, `Y_FurnStore`, `weaponStore`, `pzl_id`, `tutStore`, `Y_BallonStore`, `H_BallonStore`) VALUES
(1, 'Leaf', 'Leaf 1', 1, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(2, 'Leaf', 'Leaf 2', 1, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(3, 'Coconut', 'Coconut', 2, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(4, 'Banana peel', 'Banana peel', 3, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(5, 'green gem', 'green gem', 4, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(6, 'Berry', 'Berry', 5, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(7, 'Feather', 'Feather', 6, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(8, 'Flower', 'Flower', 7, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(9, 'Nail', 'Rusty Nail', 8, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(10, 'Nail', 'Nail', 9, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(11, 'Wheel', 'Cart Wheel', 10, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(12, 'Drill Bit', 'Drill Bit', 11, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(13, 'Wrench', 'Wrench', 12, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(14, 'Bolt', 'Bolt', 13, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(15, 'Glue', 'Glue', 14, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(16, 'Steel Bar', 'Steel Bar', 15, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(17, 'Fury Rock', 'Fury Rock', 16, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 8, 0, 0, 0),
(18, 'Angry Rock', 'Angry Rock', 17, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 9, 0, 0, 0),
(19, 'Cooker Rock', 'Cooker Rock', 18, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 10, 0, 0, 0),
(20, 'Dreadlocks', 'Dreadlocks', 200, 150, 0, 0, '0', 1, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(21, 'Flame Hair', 'Flame Hair', 203, 120, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(22, 'Butterfly ears', 'Butterfly ears', 303, 80, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(23, 'Stick ears', 'Stick ears', 304, 120, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(24, 'Bolt ears', 'Bolt ears', 305, 120, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(25, 'Tiara', 'Tiara', 403, 150, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(26, 'Grass hat', 'Grass hat', 404, 110, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(27, 'Diamond ears', 'Diamond ears', 300, 300, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(28, 'Hole ears', 'Hole ears', 301, 140, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(29, 'Phantom ears', 'Phantom ears', 302, 90, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(30, 'Horned hat', 'Horned hat', 400, 110, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(31, 'Boat hat', 'Boat hat', 406, 110, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(32, 'Pilot hat', 'Pilot hat', 407, 200, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(33, 'Gremlin ears', 'Gremlin ears', 408, 170, 0, 0, '0', 3, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(35, 'Captain hat', 'Captain hat', 19, 700, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(36, 'Golden horn', 'Golden horn', 20, 0, 0, 1, '0', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(37, 'Fish', 'Fish', 21, 0, 0, 1, '0', 0, 0, '0', '0', '0', '0', '0', NULL, 36, 0, 0),
(38, 'Palm Frond', 'Palm Frond', 22, 0, 0, 1, '0', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(39, 'Chest key', 'Rusty chest key', 23, 0, 0, 1, '0', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(40, 'Scrap wood', 'Scrap wood', 24, 50, 0, 1, '0', 0, 0, '0', '0', '0', '0', '0', NULL, 36, 0, 0),
(41, 'Vine stem', 'Vine stem', 25, 0, 0, 0, '0', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(42, 'Rock fragment', 'Rock fragment', 26, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(43, 'Rock fragment', 'Rock fragment', 27, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(44, 'Rock fragment', 'Rock fragment', 28, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(45, 'Rock fragment', 'Rock fragment', 29, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(46, 'Rock fragment', 'Rock fragment', 30, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(47, 'Rock fragment', 'Rock fragment', 31, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(48, 'Wooden stick', 'Wooden stick', 32, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(49, 'Rope', 'Rope', 33, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(50, 'Cloth', 'Cloth', 34, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(51, 'Fuel', 'Fuel', 35, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(52, 'Banana', 'Banana', 36, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 13, 0, 0, 0),
(53, 'Banana', 'Banana', 36, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 14, 0, 0, 0),
(54, 'Banana', 'Banana', 36, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 15, 0, 0, 0),
(55, 'Banana', 'Banana', 36, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 16, 0, 0, 0),
(56, 'Banana', 'Banana', 36, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', 17, 0, 0, 0),
(57, 'Bag of berries', 'Bag of berries', 37, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(58, 'Coconuts', 'Coconuts', 38, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(59, 'Green monkey gem', 'Green monkey gem', 39, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(60, 'Lever', 'Lever', 41, 10, 0, 0, '1', 0, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(70, 'Soldier Helmet', 'Soldier Helmet', 412, 140, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(71, 'Bakers Hat', 'Bakers Hat', 413, 130, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(72, 'Lava Splash', 'Lava Splash', 414, 170, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(73, 'Peacock Hat', 'Peacock Hat', 415, 380, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(74, 'Frond Hat', 'Frond Hat', 416, 300, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(76, 'Tarboosh', 'Tarboosh', 417, 300, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(77, 'Yellow Butterfly', 'Yellow Butterfly', 420, 270, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(78, 'Bull Horns', 'Bull Horns', 421, 220, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(79, 'Blue Turban', 'Blue Turban', 422, 230, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(80, 'Bell Turban', 'Bell Turban', 423, 150, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(81, 'Gem Hat', 'Gem Hat', 424, 300, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(82, 'Helmet Hat', 'Helmet Hat', 425, 200, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(83, 'Crab Hat', 'Crab Hat', 448, 250, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(84, 'Skull Hat', 'Skull Hat', 427, 200, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(85, 'Leaf Hat', 'Leaf Hat', 428, 180, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(86, 'Sun Crown', 'Sun Crown', 429, 280, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(87, 'Silk Hat', 'Silk Hat', 430, 190, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(88, 'Butterfly Hat', 'Butterfly Hat', 431, 270, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(89, 'Jewel Crown', 'Jewel Crown', 432, 320, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(90, 'Hornbells', 'Hornbells', 433, 200, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(91, 'Red Emperor', 'Red Emperor', 434, 280, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(92, 'Cloth Hat', 'Cloth Hat', 435, 110, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(93, 'Conetop Hat', 'Conetop Hat', 436, 300, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(94, 'Big Eye Hat', 'Big Eye Hat', 437, 200, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(95, 'Red Horns', 'Red Horns', 418, 250, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(96, 'Ladybug Hat', 'Ladybug Hat', 419, 250, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(97, 'Straw Hat', 'Straw Hat', 438, 80, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(98, 'Flower Hat', 'Flower Hat', 439, 205, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(99, 'Monkey Hat', 'Monkey Hat', 426, 300, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(100, 'Jewel Crown', 'Jewel Crown', 440, 320, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(101, 'Emperor Hat', 'Emperor Hat', 441, 280, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(102, 'Blue Cloth Hat', 'Blue Cloth Hat', 442, 110, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(103, 'Straw Hat', 'Straw Hat', 443, 90, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(104, 'Red Silk Hat', 'Red Silk Hat', 444, 190, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(105, 'Bell Turban', 'Bell Turban', 445, 150, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(106, 'Green Turban', 'Green Turban', 446, 230, 0, 0, '0', 2, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(107, 'Big Eye Hat', 'Big Eye Hat', 447, 200, 0, 0, '0', 2, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(409, 'Helmet', 'Helmet', 409, 0, 0, 1, '0', 2, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(410, 'Celebration Hat', 'Celebration Yeknom Hat', 410, 0, 0, 1, '0', 2, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(411, 'Celebration Hat', 'Celebration Huhu Hat', 411, 0, 0, 1, '0', 2, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(499, 'Nancy Hair', 'Nancy Hair', 511, 300, 0, 0, '0', 1, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(500, 'Fakiri Hair', 'Fakiri Hair', 510, 300, 0, 0, '0', 1, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(510, 'Pank Hair', 'Pank Hair', 500, 260, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(511, 'Roll Hair', 'Roll Hair', 501, 230, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(512, 'Pineapple Hair', 'Pineapple Hair', 502, 150, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(513, 'Pigtails', 'Pigtails', 503, 220, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(514, 'Black Hair', 'Black Hair', 504, 190, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(515, 'Spike Hair', 'Spike Hair', 505, 200, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(516, 'Braid Hair', 'Braid Hair', 506, 210, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(517, 'Red Hair', 'Red Hair', 507, 190, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(518, 'Blonde Hair', 'Blonde Hair', 508, 230, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(519, 'Dreadlocks', 'Dreadlocks', 509, 200, 0, 0, '0', 1, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(700, 'Heart wand', 'Heart wand', 700, 70, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(701, 'Torch', 'Torch', 701, 0, 0, 1, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(702, 'Paddle', 'Paddle', 702, 0, 0, 1, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(703, 'Yeknom Comb', 'Yeknom Comb', 703, 70, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(704, 'Huhu Comb', 'Huhu Comb', 704, 70, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(705, 'Summer Camp Beach Ball', 'Summer Camp Beach Ball', 705, 0, 0, 1, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(706, 'fishing net', 'fishing net', 706, 60, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(707, 'Yeknom Pompom', 'Yeknom Pompom', 707, 70, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(708, 'Pompom', 'Pompom', 708, 75, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(709, 'Heart wand', 'Heart wand', 709, 70, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(710, 'Flyswatter', 'Flyswatter', 710, 50, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(711, 'Football', 'Football', 711, 110, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(712, 'Yeknom Shield', 'Yeknom Shield', 712, 120, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(713, 'Huhuloa Shield', 'Huhuloa Shield', 713, 100, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(741, 'Branch', 'Branch', 741, 50, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(742, 'Paintbrush', 'Paintbrush', 742, 110, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(748, 'Cocolani Balloon', 'Cocolani Balloon', 748, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 1, 1),
(749, 'Cocolani Balloon', 'Cocolani Balloon', 749, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 1, 1),
(750, 'Yellow Balloon', 'Yellow Balloon', 750, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 1, 0),
(751, 'Blue Balloon', 'Blue Balloon', 751, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 1, 0),
(752, 'Green Balloon', 'Green Balloon', 752, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 1, 0),
(753, 'Pink Balloon', 'Pink Balloon', 753, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 1),
(754, 'Red Balloon', 'Red Balloon', 754, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 1),
(755, 'Purple Balloon', 'Purple Balloon', 755, 100, 0, 0, '0', 4, 0, '0', '0', '', '0', '0', NULL, 0, 0, 0),
(756, 'Eish Safari Balloon', 'Eish Balloon', 756, 100, 0, 0, '0', 4, 0, '0', '0', '0', '0', '0', NULL, 0, 0, 0),
(757, 'Green Bag', 'Green Bag', 757, 150, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(758, 'Leaf Bag', 'Leaf Bag', 758, 120, 0, 0, '0', 4, 0, '0', '8', '0', '0', '0', NULL, 0, 0, 0),
(759, 'Magma Bag', 'Magma Bag', 759, 150, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(760, 'Lizard Bag', 'Lizard Bag', 760, 120, 0, 0, '0', 4, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1000, 'Ball', 'This battle ball is capable of rolling and has an extended time limit.', 2000, 120, 7, 0, '1:3:5', 7, 0, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1001, 'Cherry Bomb', 'Lob these at enemies for a devastating explosion.', 2001, 180, 7, 0, '2:5:10', 7, 0, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1002, 'Boomerang', 'Quick to use, if this comes back to your player, you&amp;#039;re entitled to another go.', 2002, 220, 7, 0, '3:7:9', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1003, 'Frisbee', 'Quick and devastating, mow down your opposition in one sweep.', 2003, 220, 7, 0, '1:5:8', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1004, 'Shield', 'Protection in your vicinity.', 2004, 200, 7, 0, '5:8', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1005, 'Health', 'Give health in the vicinity', 2005, 220, 7, 0, '2:6', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1006, 'Attractor', 'Attract weapons to the object', 2006, 250, 7, 0, '9', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1007, 'Repulser', 'Repell weapons from the object', 2007, 250, 7, 0, '8', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1008, 'Spear', 'Spear', 2008, 50, 7, 0, '1:4:7', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1009, 'Stiletto', 'Heels for throwing at enemies. Good bounce for those hard to reach areas.', 2009, 200, 7, 0, '1:3', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1010, 'Makeup Kit', 'Works as a medical kit and heals players in the vicinity', 2010, 230, 7, 0, '2:4:8', 7, 3, '0', '0', '0', '0', '-1', NULL, 0, 0, 0),
(1011, 'Old style TV', 'Old style TV', 1011, 250, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1012, 'Triple Couch', 'Triple Couch', 1012, 180, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1013, 'Triple Couch', 'Triple Couch', 1013, 200, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1014, 'Vase', 'Vase', 1014, 30, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1015, 'Vase', 'Vase', 1015, 40, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1016, 'Table', 'Table', 1016, 150, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1017, 'Table', 'Table', 1017, 200, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1018, 'Fishtank', 'Fishtank', 1018, 220, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1019, 'Fishtank', 'Fishtank', 1019, 180, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1020, 'Bookshelf', 'Bookshelf', 1020, 110, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1021, 'Bookshelf', 'Bookshelf', 1021, 110, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1022, 'Drawers', 'Drawers', 1022, 90, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1023, 'Drawers', 'Drawers', 1023, 90, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1024, 'Bookshelf', 'Bookshelf', 1024, 110, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1025, 'Bookshelf', 'Bookshelf', 1025, 110, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1026, 'Candle', 'Candle', 1026, 70, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1027, 'Candle', 'Candle', 1027, 70, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1028, 'Chair', 'Chair', 1028, 100, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1029, 'Chair', 'Chair', 1029, 100, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1030, 'Drawers', 'Drawers', 1030, 90, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1031, 'Drawers', 'Drawers', 1031, 90, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1032, 'Couch', 'Couch', 1032, 190, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1033, 'Couch', 'Couch', 1033, 190, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1034, 'Rock tank', 'Rock tank', 1034, 200, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1035, 'Fishtank', 'Fishtank', 1035, 200, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1036, 'Plant', 'Plant', 1036, 30, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1037, 'Plant', 'Plant', 1037, 40, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1038, 'Rug', 'Rug', 1038, 65, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1039, 'Rug', 'Rug', 1039, 50, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1040, 'Table', 'Table', 1040, 130, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1041, 'Table', 'Table', 1041, 145, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1042, 'Torch', 'Torch', 1042, 75, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1043, 'Wide TV', 'Wide TV', 1043, 650, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1044, 'Old style TV', 'Old style TV', 1044, 230, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1045, 'Slender vase', 'Slender vase', 1045, 40, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1046, 'Maroon vase', 'Maroon vase', 1046, 50, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1047, 'Rug', 'Rug', 1047, 40, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1048, 'Cabinet', 'Cabinet', 1048, 130, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1049, 'Rug', 'Rug', 1049, 50, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1050, 'Vine torch', 'Vine torch', 1050, 40, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1058, 'Goat Statue', 'Goat Statue', 1058, 120, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1059, 'Monkey Statue', 'Monkey Statue', 1059, 120, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1060, 'Gem Statue', 'Gem Statue', 1060, 175, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1061, 'Turtle Statue', 'Turtle Statue', 1061, 150, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1062, 'Turtle Statue', 'Turtle Statue', 1062, 150, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1063, 'Dragon Statue', 'Dragon Statue', 1063, 175, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1064, 'Dragon Statue', 'Dragon Statue', 1064, 175, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1065, 'Antelope Statue', 'Antelope Statue', 1065, 120, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1066, 'Wave Couch', 'Wave Couch', 1066, 275, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1067, 'Wave Couch', 'Wave Couch', 1067, 275, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1068, 'Stone Couch', 'Stone Couch', 1068, 275, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1069, 'Fern Couch', 'Fern Couch', 1069, 275, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1070, 'Spike Couch ', 'Spike Couch ', 1070, 250, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1071, 'Spike Couch', 'Spike Couch', 1071, 250, 0, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1072, 'Flower Couch', 'Flower Couch', 1072, 250, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1073, 'Flower Couch', 'Flower Couch', 1073, 250, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1200, 'Stick Ears', 'Stick Ears', 306, 140, 0, 0, '0', 3, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1201, 'Bolt Ears', 'Bolt Ears', 307, 170, 0, 0, '0', 3, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1202, 'Diamond Ears', 'Diamond Ears', 308, 140, 0, 0, '0', 3, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1203, 'Hole Ears', 'Hole Ears', 309, 120, 0, 0, '0', 3, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1204, 'Phantom Ears', 'Phantom Ears', 310, 120, 0, 0, '0', 3, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1205, 'Butterfly Ears', 'Butterfly Ears', 311, 80, 0, 0, '0', 3, 0, '15', '0', '0', '0', '0', NULL, 0, 0, 0),
(1501, 'Crab Painting', 'Crab Painting', 1501, 140, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1502, 'Toucan Painting', 'Toucan Painting', 1502, 130, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1503, 'Bone Painting', 'Bone Painting', 1503, 200, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1504, 'Flower Painting', 'Flower Painting', 1504, 160, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1505, 'Regal Drapes', 'Regal Drapes', 1505, 250, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1506, 'Regal Drapes', 'Regal Drapes', 1506, 250, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1507, 'Blue Drapes', 'Blue Drapes', 1507, 180, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1508, 'Vine Drapes', 'Vine Drapes', 1508, 180, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1509, 'Branch Drapes', 'Branch Drapes', 1509, 150, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1510, 'Rainbow Drapes', 'Rainbow Drapes', 1510, 175, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1511, 'Bone Drapes', 'Bone Drapes', 1511, 150, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1512, 'Bull Horn Drapes', 'Bull Horn Drapes', 1512, 175, 1, 0, '0', 6, 0, '0', '0', '35', '0', '0', NULL, 0, 0, 0),
(1531, 'Chair', 'Chair', 1001, 80, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1538, 'Single Chair', 'Single Chair', 1008, 100, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1539, 'Single Chair', 'Single Chair', 1009, 150, 0, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1540, 'Widescreen TV', 'Widescreen TV', 1010, 800, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0),
(1607, 'Plant', 'Plant', 1007, 40, 1, 0, '0', 6, 0, '0', '0', '0', '9', '0', NULL, 0, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `cc_item_upgrades`
--

CREATE TABLE IF NOT EXISTS `cc_item_upgrades` (
`id` int(10) unsigned NOT NULL,
  `objID` int(10) unsigned NOT NULL,
  `from_lvl` int(10) unsigned NOT NULL,
  `to_lvl` int(10) unsigned NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=16 ;

--
-- Dumping data for table `cc_item_upgrades`
--

INSERT INTO `cc_item_upgrades` (`id`, `objID`, `from_lvl`, `to_lvl`) VALUES
(1, 1000, 1, 3),
(2, 1000, 3, 5),
(3, 1001, 2, 5),
(4, 1001, 5, 10),
(5, 1004, 5, 8),
(6, 1002, 3, 7),
(7, 1002, 7, 9),
(8, 1003, 1, 5),
(9, 1003, 5, 8),
(10, 1005, 2, 6),
(11, 1008, 1, 4),
(12, 1008, 4, 7),
(13, 1009, 1, 3),
(14, 1010, 2, 4),
(15, 1010, 4, 8);

-- --------------------------------------------------------

--
-- Table structure for table `cc_keywords`
--

CREATE TABLE IF NOT EXISTS `cc_keywords` (
`id` int(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `enabled` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_mail`
--

CREATE TABLE IF NOT EXISTS `cc_mail` (
`id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `subject` varchar(255) DEFAULT 'No Subject',
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_mod_news`
--

CREATE TABLE IF NOT EXISTS `cc_mod_news` (
  `enabled` varchar(255) NOT NULL,
  `news_date` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `cc_mod_news_keywords`
--

CREATE TABLE IF NOT EXISTS `cc_mod_news_keywords` (
  `news_id` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `cc_mod_news_settings`
--

CREATE TABLE IF NOT EXISTS `cc_mod_news_settings` (
`id` int(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `date_format` varchar(255) NOT NULL,
  `news_date` varchar(255) NOT NULL,
  `news_date1` varchar(255) NOT NULL,
  `content` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_monkey_rooms`
--

CREATE TABLE IF NOT EXISTS `cc_monkey_rooms` (
  `room_name` varchar(100) NOT NULL,
  `pzl_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cc_monkey_rooms`
--

INSERT INTO `cc_monkey_rooms` (`room_name`, `pzl_id`) VALUES
('Jungle', 13),
('Jungle Centre', 15),
('Jungle Pathway 2', 14),
('Jungle Pathway 3', 16),
('Jungle Room 2', 17);

-- --------------------------------------------------------

--
-- Table structure for table `cc_page`
--

CREATE TABLE IF NOT EXISTS `cc_page` (
`id` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_permissions`
--

CREATE TABLE IF NOT EXISTS `cc_permissions` (
  `user_id` int(255) NOT NULL,
  `char_status_id` int(255) NOT NULL,
`id` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_puzzle_bots`
--

CREATE TABLE IF NOT EXISTS `cc_puzzle_bots` (
  `bot_id` int(11) NOT NULL,
  `bot_type` varchar(20) NOT NULL,
  `money_reward` int(11) NOT NULL DEFAULT '0',
  `prize_obj_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `cc_puzzle_bots`
--

INSERT INTO `cc_puzzle_bots` (`bot_id`, `bot_type`, `money_reward`, `prize_obj_id`) VALUES
(1, 'complex', 25, 57),
(2, 'complex', 0, 409),
(3, 'simple', 25, NULL),
(4, 'complex', 0, 701),
(5, 'simple', 25, NULL),
(6, 'complex', 0, 39);

-- --------------------------------------------------------

--
-- Table structure for table `cc_puzzle_bot_items`
--

CREATE TABLE IF NOT EXISTS `cc_puzzle_bot_items` (
`id` int(11) NOT NULL,
  `bot_id` int(11) NOT NULL,
  `item_obj_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=22 ;

--
-- Dumping data for table `cc_puzzle_bot_items`
--

INSERT INTO `cc_puzzle_bot_items` (`id`, `bot_id`, `item_obj_id`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 1, 3),
(4, 1, 4),
(5, 1, 6),
(6, 1, 7),
(7, 1, 8),
(8, 2, 9),
(9, 2, 10),
(10, 2, 11),
(11, 2, 12),
(12, 2, 13),
(13, 2, 14),
(14, 2, 15),
(15, 3, 57),
(16, 4, 48),
(17, 4, 49),
(18, 4, 50),
(19, 4, 51),
(20, 5, 58),
(21, 6, 37);

-- --------------------------------------------------------

--
-- Table structure for table `cc_puzzle_config`
--

CREATE TABLE IF NOT EXISTS `cc_puzzle_config` (
  `config_key` varchar(50) NOT NULL,
  `config_value` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `cc_puzzle_config`
--

INSERT INTO `cc_puzzle_config` (`config_key`, `config_value`) VALUES
('bribe_price', '50');

-- --------------------------------------------------------

--
-- Table structure for table `cc_puzzle_rewards`
--

CREATE TABLE IF NOT EXISTS `cc_puzzle_rewards` (
`id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `choice_id` varchar(10) DEFAULT NULL,
  `reward_type` varchar(20) NOT NULL,
  `money_amount` int(11) NOT NULL DEFAULT '0',
  `pzl_id` int(11) NOT NULL,
  `remove_item_obj_id` int(11) DEFAULT NULL,
  `add_invars_id` int(11) DEFAULT NULL,
  `item_obj_id` int(11) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=14 ;

--
-- Dumping data for table `cc_puzzle_rewards`
--

INSERT INTO `cc_puzzle_rewards` (`id`, `room_id`, `choice_id`, `reward_type`, `money_amount`, `pzl_id`, `remove_item_obj_id`, `add_invars_id`, `item_obj_id`) VALUES
(1, 23, '1', 'money', 25, 2, NULL, NULL, NULL),
(2, 23, '2', 'money', 50, 3, NULL, NULL, NULL),
(3, 23, '11', 'money', 100, 11, NULL, NULL, NULL),
(4, 33, '1', 'money', 25, 2, NULL, NULL, NULL),
(5, 33, '2', 'money', 50, 3, NULL, NULL, NULL),
(6, 33, '11', 'money', 100, 11, NULL, NULL, NULL),
(7, 8, '1', 'item', 0, 20, NULL, NULL, 410),
(8, 8, '2', 'money', 250, 20, NULL, NULL, NULL),
(9, 15, '1', 'item', 0, 21, NULL, NULL, 411),
(10, 15, '2', 'money', 250, 21, NULL, NULL, NULL),
(11, 37, NULL, 'both', 300, 22, NULL, NULL, 705),
(12, 49, NULL, 'special_gem', 250, 19, 59, 59, NULL),
(13, 36, NULL, 'item', 0, 36, 36, 36, 40);

-- --------------------------------------------------------

--
-- Table structure for table `cc_security_log`
--

CREATE TABLE IF NOT EXISTS `cc_security_log` (
`id` int(11) NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `reason` varchar(64) NOT NULL DEFAULT '',
  `detail` varchar(255) NOT NULL DEFAULT '',
  `ts` bigint(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_servers`
--

CREATE TABLE IF NOT EXISTS `cc_servers` (
  `server_id` int(255) NOT NULL,
`id` int(255) NOT NULL,
  `lang_id` int(255) NOT NULL,
  `enabled` varchar(255) NOT NULL,
  `logins_active` varchar(255) NOT NULL,
  `zone_name` varchar(255) NOT NULL,
  `ip` varchar(255) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `cc_servers`
--

INSERT INTO `cc_servers` (`server_id`, `id`, `lang_id`, `enabled`, `logins_active`, `zone_name`, `ip`) VALUES
(0, 1, 0, '1', '1', 'cocolani', '127.0.0.1');

-- --------------------------------------------------------

--
-- Table structure for table `cc_sessions`
--

CREATE TABLE IF NOT EXISTS `cc_sessions` (
  `username` varchar(255) NOT NULL,
  `session_start` datetime NOT NULL,
  `session_end` datetime NOT NULL,
  `IP` varchar(255) NOT NULL,
`id` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_stat`
--

CREATE TABLE IF NOT EXISTS `cc_stat` (
  `ip` varchar(255) NOT NULL,
  `time_diff` varchar(255) NOT NULL,
  `page` varchar(255) NOT NULL,
  `browser` varchar(255) NOT NULL,
  `os` varchar(255) NOT NULL,
  `host` varchar(255) NOT NULL,
  `referer` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `cc_swear_words`
--

CREATE TABLE IF NOT EXISTS `cc_swear_words` (
  `name` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `add_Error` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `cc_translations`
--

CREATE TABLE IF NOT EXISTS `cc_translations` (
  `caption` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cc_translations`
--

INSERT INTO `cc_translations` (`caption`, `name`) VALUES
('REGFORM_PROBLEM', 'There was a problem with the registration form.'),
('MAX_NUM_REGISTRATION_REACHED', 'Maximum number of registrations reached for this email.'),
('USERNAME_IN_USE', 'This username is already taken.'),
('DUPLICATED_EMAIL', 'This email is already registered.'),
('REGISTER_LATER', 'Please wait a while before registering again.'),
('SITE_NAME', 'جزر كوكولاني | Cocolani Island');

-- --------------------------------------------------------

--
-- Table structure for table `cc_translations_system`
--

CREATE TABLE IF NOT EXISTS `cc_translations_system` (
  `friendly_name` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `cc_tribes`
--

CREATE TABLE IF NOT EXISTS `cc_tribes` (
`ID` int(255) NOT NULL,
  `newstr` varchar(255) NOT NULL,
  `init_purse_amount` varchar(255) NOT NULL,
  `active` varchar(255) NOT NULL,
  `total_population` varchar(255) NOT NULL,
  `tribe_id` int(255) NOT NULL,
  `population` varchar(255) NOT NULL,
  `battles_won` varchar(255) NOT NULL,
  `chief_id` int(255) NOT NULL,
  `name` varchar(255) DEFAULT ''
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `cc_tribes`
--

INSERT INTO `cc_tribes` (`ID`, `newstr`, `init_purse_amount`, `active`, `total_population`, `tribe_id`, `population`, `battles_won`, `chief_id`, `name`) VALUES
(1, '', '200', '1', '0', 1, '0', '1', 8, 'Yeknom'),
(2, '', '200', '1', '0', 2, '0', '0', 10, 'Huhuhola');

-- --------------------------------------------------------

--
-- Table structure for table `cc_tuberide_prices`
--

CREATE TABLE IF NOT EXISTS `cc_tuberide_prices` (
  `tier_id` int(11) NOT NULL,
  `price` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `cc_tuberide_prices`
--

INSERT INTO `cc_tuberide_prices` (`tier_id`, `price`) VALUES
(1, 10),
(2, 15),
(3, 25);

-- --------------------------------------------------------

--
-- Table structure for table `cc_user`
--

CREATE TABLE IF NOT EXISTS `cc_user` (
`ID` int(255) NOT NULL,
  `username` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `email` varchar(255) NOT NULL,
  `birth_date` date NOT NULL,
  `first_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `last_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `sex` varchar(255) NOT NULL,
  `about` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `mask` varchar(255) NOT NULL,
  `mask_colors` varchar(255) NOT NULL,
  `clothing` varchar(255) NOT NULL,
  `tribe_id` int(255) NOT NULL,
  `money` varchar(32) NOT NULL,
  `happyness` varchar(255) NOT NULL,
  `rank_ID` int(255) NOT NULL,
  `status_ID` int(255) NOT NULL,
  `lang_id` int(255) NOT NULL,
  `register_date` date NOT NULL,
  `uniqid` int(255) NOT NULL,
  `permission_id` int(255) NOT NULL,
  `primary_id` int(255) NOT NULL,
  `registered_num_emails` varchar(255) NOT NULL,
  `social_id` int(255) NOT NULL,
  `adr_1` varchar(255) NOT NULL,
  `adr_2` varchar(255) NOT NULL,
  `mobile` varchar(255) NOT NULL,
  `usercount` varchar(255) NOT NULL,
  `landline` varchar(255) NOT NULL,
  `registration_confirmed` varchar(255) NOT NULL,
  `won` varchar(45) NOT NULL,
  `loss` varchar(45) NOT NULL,
  `medals` varchar(255) NOT NULL,
  `lvl` varchar(255) NOT NULL,
  `IP` varchar(45) DEFAULT NULL,
  `lastZone` varchar(255) DEFAULT '',
  `seisson_start` varchar(255) DEFAULT '',
  `seisson_end` varchar(255) DEFAULT '',
  `skill` varchar(255) DEFAULT '0,0',
  `btl` varchar(255) DEFAULT '0;0',
  `home_ID` varchar(255) DEFAULT '-1',
  `homeAddr` varchar(255) DEFAULT '-1',
  `lastRoom` varchar(255) DEFAULT '0',
  `previousTribe` varchar(255) DEFAULT '0',
  `invars` text NOT NULL,
  `inventory` text CHARACTER SET utf8mb4 NOT NULL,
  `pzl` varchar(255) DEFAULT '',
  `level` varchar(255) DEFAULT '1',
  `dotutorial` varchar(255) DEFAULT '0',
  `prefs` text,
  `mgam` varchar(255) DEFAULT '0',
  `gam` varchar(255) DEFAULT '0',
  `swear` varchar(255) DEFAULT '0',
  `lastSwear` varchar(255) DEFAULT '',
  `hacks` varchar(255) DEFAULT 'False'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_userreginfo`
--

CREATE TABLE IF NOT EXISTS `cc_userreginfo` (
`ID` int(255) NOT NULL,
  `user_id` int(255) NOT NULL,
  `register_IP` varchar(255) NOT NULL,
  `register_date` date NOT NULL,
  `last_update` date NOT NULL,
  `IP` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_user_actions_history`
--

CREATE TABLE IF NOT EXISTS `cc_user_actions_history` (
  `user_id` int(255) NOT NULL,
  `subject` int(255) NOT NULL,
  `subject_id` int(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `when` varchar(255) NOT NULL,
  `deleted_value` varchar(255) NOT NULL,
  `subject_field` varchar(255) NOT NULL,
  `old_value` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `cc_user_parent`
--

CREATE TABLE IF NOT EXISTS `cc_user_parent` (
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
`id` int(255) NOT NULL,
  `email` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cc_zones`
--

CREATE TABLE IF NOT EXISTS `cc_zones` (
  `zone_name` varchar(255) NOT NULL,
  `friendly_name` varchar(255) NOT NULL,
  `port` varchar(255) NOT NULL,
  `activity_ratio` varchar(255) NOT NULL,
  `safe_chat` varchar(255) NOT NULL,
`id` int(255) NOT NULL,
  `server_id` int(255) NOT NULL,
  `ip` varchar(255) NOT NULL,
  `lang_id` int(255) NOT NULL,
  `enabled` varchar(255) NOT NULL,
  `logins_active` varchar(255) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `cc_zones`
--

INSERT INTO `cc_zones` (`zone_name`, `friendly_name`, `port`, `activity_ratio`, `safe_chat`, `id`, `server_id`, `ip`, `lang_id`, `enabled`, `logins_active`) VALUES
('cocolani', 'Cocolani', '9339', '0', '0', 1, 1, '127.0.0.1', 0, '1', '1');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cc_bans`
--
ALTER TABLE `cc_bans`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_battle_settings`
--
ALTER TABLE `cc_battle_settings`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `uq_room_id` (`room_id`);

--
-- Indexes for table `cc_char_status`
--
ALTER TABLE `cc_char_status`
 ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `cc_chat`
--
ALTER TABLE `cc_chat`
 ADD PRIMARY KEY (`id`), ADD KEY `idx_swear` (`Swear`);

--
-- Indexes for table `cc_def_settings`
--
ALTER TABLE `cc_def_settings`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_email_templates`
--
ALTER TABLE `cc_email_templates`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_extra_langs`
--
ALTER TABLE `cc_extra_langs`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_games`
--
ALTER TABLE `cc_games`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_game_config`
--
ALTER TABLE `cc_game_config`
 ADD PRIMARY KEY (`game_id`);

--
-- Indexes for table `cc_game_pzl_award`
--
ALTER TABLE `cc_game_pzl_award`
 ADD PRIMARY KEY (`pzl_id`);

--
-- Indexes for table `cc_game_rewards`
--
ALTER TABLE `cc_game_rewards`
 ADD PRIMARY KEY (`id`), ADD KEY `idx_game_id` (`game_id`);

--
-- Indexes for table `cc_highscores`
--
ALTER TABLE `cc_highscores`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_homes`
--
ALTER TABLE `cc_homes`
 ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `cc_homes_furniture`
--
ALTER TABLE `cc_homes_furniture`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_inv`
--
ALTER TABLE `cc_inv`
 ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `cc_invlist`
--
ALTER TABLE `cc_invlist`
 ADD PRIMARY KEY (`objID`);

--
-- Indexes for table `cc_item_upgrades`
--
ALTER TABLE `cc_item_upgrades`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_keywords`
--
ALTER TABLE `cc_keywords`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_mail`
--
ALTER TABLE `cc_mail`
 ADD PRIMARY KEY (`id`), ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `cc_mod_news_settings`
--
ALTER TABLE `cc_mod_news_settings`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_monkey_rooms`
--
ALTER TABLE `cc_monkey_rooms`
 ADD PRIMARY KEY (`room_name`);

--
-- Indexes for table `cc_page`
--
ALTER TABLE `cc_page`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_permissions`
--
ALTER TABLE `cc_permissions`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_puzzle_bots`
--
ALTER TABLE `cc_puzzle_bots`
 ADD PRIMARY KEY (`bot_id`);

--
-- Indexes for table `cc_puzzle_bot_items`
--
ALTER TABLE `cc_puzzle_bot_items`
 ADD PRIMARY KEY (`id`), ADD KEY `bot_id` (`bot_id`);

--
-- Indexes for table `cc_puzzle_config`
--
ALTER TABLE `cc_puzzle_config`
 ADD PRIMARY KEY (`config_key`);

--
-- Indexes for table `cc_puzzle_rewards`
--
ALTER TABLE `cc_puzzle_rewards`
 ADD PRIMARY KEY (`id`), ADD KEY `room_id` (`room_id`);

--
-- Indexes for table `cc_security_log`
--
ALTER TABLE `cc_security_log`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_servers`
--
ALTER TABLE `cc_servers`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_sessions`
--
ALTER TABLE `cc_sessions`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_tribes`
--
ALTER TABLE `cc_tribes`
 ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `cc_user`
--
ALTER TABLE `cc_user`
 ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `cc_userreginfo`
--
ALTER TABLE `cc_userreginfo`
 ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `cc_user_parent`
--
ALTER TABLE `cc_user_parent`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cc_zones`
--
ALTER TABLE `cc_zones`
 ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `cc_bans`
--
ALTER TABLE `cc_bans`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_battle_settings`
--
ALTER TABLE `cc_battle_settings`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `cc_char_status`
--
ALTER TABLE `cc_char_status`
MODIFY `ID` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_chat`
--
ALTER TABLE `cc_chat`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_def_settings`
--
ALTER TABLE `cc_def_settings`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `cc_extra_langs`
--
ALTER TABLE `cc_extra_langs`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_game_rewards`
--
ALTER TABLE `cc_game_rewards`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `cc_highscores`
--
ALTER TABLE `cc_highscores`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=46;
--
-- AUTO_INCREMENT for table `cc_homes`
--
ALTER TABLE `cc_homes`
MODIFY `ID` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_homes_furniture`
--
ALTER TABLE `cc_homes_furniture`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_inv`
--
ALTER TABLE `cc_inv`
MODIFY `ID` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_item_upgrades`
--
ALTER TABLE `cc_item_upgrades`
MODIFY `id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=16;
--
-- AUTO_INCREMENT for table `cc_keywords`
--
ALTER TABLE `cc_keywords`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_mail`
--
ALTER TABLE `cc_mail`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_mod_news_settings`
--
ALTER TABLE `cc_mod_news_settings`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_page`
--
ALTER TABLE `cc_page`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_permissions`
--
ALTER TABLE `cc_permissions`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_puzzle_bot_items`
--
ALTER TABLE `cc_puzzle_bot_items`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=22;
--
-- AUTO_INCREMENT for table `cc_puzzle_rewards`
--
ALTER TABLE `cc_puzzle_rewards`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
--
-- AUTO_INCREMENT for table `cc_security_log`
--
ALTER TABLE `cc_security_log`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_servers`
--
ALTER TABLE `cc_servers`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `cc_sessions`
--
ALTER TABLE `cc_sessions`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_tribes`
--
ALTER TABLE `cc_tribes`
MODIFY `ID` int(255) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `cc_user`
--
ALTER TABLE `cc_user`
MODIFY `ID` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_userreginfo`
--
ALTER TABLE `cc_userreginfo`
MODIFY `ID` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_user_parent`
--
ALTER TABLE `cc_user_parent`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cc_zones`
--
ALTER TABLE `cc_zones`
MODIFY `id` int(255) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
