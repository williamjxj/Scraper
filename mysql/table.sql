use dixi;

/*
 *  alter table categories add site_id tinyint unsigned default 1 after name;
 *  alter table categories add sname varchar(128) default '底细真相站点'  after site_id;
 */
CREATE TABLE IF NOT EXISTS `categories` (
  `cid` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `site_id` tinyint(3) unsigned NOT NULL,
  `sname` varchar(128) DEFAULT NULL,
  `curl` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `active` enum('Y','N') COLLATE utf8_unicode_ci DEFAULT 'Y',
  `weight` smallint(5) unsigned DEFAULT '1',
  `frequency` smallint(5) unsigned DEFAULT '6',
  `tag` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,  
  `description` text COLLATE utf8_unicode_ci,
  `createdby` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `category` (`name`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;


CREATE TABLE IF NOT EXISTS `items` (
  `iid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `cid` tinyint(3) unsigned NOT NULL,
  `cname` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `iurl` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `active` enum('Y','N') COLLATE utf8_unicode_ci DEFAULT 'Y',
  `weight` smallint(5) unsigned DEFAULT '1',
  `frequency` smallint(5) unsigned DEFAULT '0',
  `tag` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `createdby` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`iid`),
  UNIQUE KEY `item` (`name`),
  KEY `FK_item_category` (`cid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

/*
 *  alter table channels add cid tinyint unsigned default 1 after name;
 *  alter table channels add cname varchar(128) default '食品'  after cid;
 *  alter table channels add iid int unsigned after name;
 *  alter table channels add iname varchar(128)  after iid;
 * 
 */
CREATE TABLE IF NOT EXISTS `channels` (
  `mid` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `cid` tinyint(3) unsigned NOT NULL,
  `cname` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `iid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `iname` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `url` varchar(255) NOT NULL,
  `weight` tinyint(3) unsigned DEFAULT '1',
  `groups` tinyint(3) unsigned DEFAULT '1',
  `description` text,
  `active` enum('Y','N') DEFAULT 'Y',
  `createdby` varchar(50) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` varchar(50) DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`mid`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;


CREATE TABLE IF NOT EXISTS `contexts` (
  `cid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `notes` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `cate_id` tinyint(3) unsigned DEFAULT '3',
  `item_id` int(11) unsigned,
  `chan_id` int unsigned NOT NULL,
  `chan_name` varchar(255),
  `weight` tinyint(3) unsigned DEFAULT '0',
  `active` enum('Y','N') DEFAULT 'Y',
  `createdby` varchar(50) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` varchar(50) DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `title_mid` (`name`,`chan_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `foods` (
  `fid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `google_keywords` varchar(128) NOT NULL,
  `meta_description` varchar(255) NOT NULL,
  `meta_keywords` varchar(255),
  `title` varchar(255),
  `url` varchar(255),
  `phone` varchar(20),
  `fax` varchar(20),
  `email` varchar(50),
  `zip` varchar(6),
  `summary` text,
  `fdate`  date,
 `cate_id` tinyint(3) unsigned DEFAULT '3',
  `item_id` int(11) unsigned,
  `weight` tinyint(3) unsigned DEFAULT '0',
  PRIMARY KEY (`fid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

