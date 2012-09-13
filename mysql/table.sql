use dixi;

/*
 *  alter table categories add site_id tinyint unsigned default 1 after name;
 *  alter table categories add sname varchar(128) default '底细真相站点'  after site_id;
 */
CREATE TABLE IF NOT EXISTS `categories` (
  `cid` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8_general_ci NOT NULL,
  `site_id` tinyint(3) unsigned NOT NULL,
  `sname` varchar(128) DEFAULT NULL,
  `curl` varchar(255) COLLATE utf8_general_ci DEFAULT NULL,
  `active` enum('Y','N') COLLATE utf8_general_ci DEFAULT 'Y',
  `weight` smallint(5) unsigned DEFAULT '1',
  `frequency` smallint(5) unsigned DEFAULT '6',
  `tag` varchar(255) COLLATE utf8_general_ci DEFAULT NULL,  
  `description` text COLLATE utf8_general_ci,
  `createdby` varchar(50) COLLATE utf8_general_ci DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` varchar(50) COLLATE utf8_general_ci DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `category` (`name`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci AUTO_INCREMENT=1 ;


CREATE TABLE IF NOT EXISTS `items` (
  `iid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8_general_ci NOT NULL,
  `cid` tinyint(3) unsigned NOT NULL,
  `cname` varchar(128) COLLATE utf8_general_ci NOT NULL,
  `iurl` varchar(255) COLLATE utf8_general_ci DEFAULT NULL,
  `active` enum('Y','N') COLLATE utf8_general_ci DEFAULT 'Y',
  `weight` smallint(5) unsigned DEFAULT '1',
  `frequency` smallint(5) unsigned DEFAULT '0',
  `tag` varchar(255) COLLATE utf8_general_ci DEFAULT NULL,
  `description` text COLLATE utf8_general_ci,
  `createdby` varchar(50) COLLATE utf8_general_ci DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` varchar(50) COLLATE utf8_general_ci DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`iid`),
  UNIQUE KEY `item` (`name`),
  KEY `FK_item_category` (`cid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci AUTO_INCREMENT=1 ;

-- 英语版.
CREATE TABLE IF NOT EXISTS `foods` (
  `fid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `google_keywords` varchar(128) NOT NULL,
  `meta_description` varchar(255) NOT NULL,
  `meta_keywords` varchar(255),
  `title` varchar(255),
  `url` varchar(255),
  `summary` varchar(255),
  `detail` text,
  `fdate`  date,
 `cate_id` tinyint(3) unsigned DEFAULT '3',
  `item_id` int(11) unsigned,
  `weight` tinyint(3) unsigned DEFAULT '0',
  PRIMARY KEY (`fid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

update foods set title=concat(google_keywords,',',url) where title is NULL;


-------http://www.baidu.com/search/rss.html-------------
CREATE TABLE IF NOT EXISTS `baidu_rss` (
  `bid` smallint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `url` varchar(255) NOT NULL,
  `category` varchar(128),
  primary key (`bid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-------------------------
drop table if exists tbl_lookup;
CREATE TABLE tbl_lookup
(
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) NOT NULL,
	code INTEGER NOT NULL,
	type VARCHAR(128) NOT NULL,
	position INTEGER NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

drop table if exists tbl_user;
CREATE TABLE tbl_user
(
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(128) NOT NULL,
	password VARCHAR(128) NOT NULL,
	salt VARCHAR(128) NOT NULL,
	email VARCHAR(128) NOT NULL,
	profile TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

drop table if exists tbl_post;
CREATE TABLE tbl_post
(
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(128) NOT NULL,
	content TEXT NOT NULL,
	tags TEXT,
	status INTEGER NOT NULL,
	create_time INTEGER,
	update_time INTEGER,
	author_id INTEGER NOT NULL,
	CONSTRAINT FK_post_author FOREIGN KEY (author_id)
		REFERENCES tbl_user (id) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

drop table if exists tbl_comment;
CREATE TABLE tbl_comment
(
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	content TEXT NOT NULL,
	status INTEGER NOT NULL,
	create_time INTEGER,
	author VARCHAR(128) NOT NULL,
	email VARCHAR(128) NOT NULL,
	url VARCHAR(128),
	post_id INTEGER NOT NULL,
	CONSTRAINT FK_comment_post FOREIGN KEY (post_id)
		REFERENCES tbl_post (id) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

drop table if exists tbl_tag;
CREATE TABLE tbl_tag
(
	id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(128) NOT NULL,
	frequency INTEGER DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

INSERT INTO tbl_lookup (name, type, code, position) VALUES ('Draft', 'PostStatus', 1, 1);
INSERT INTO tbl_lookup (name, type, code, position) VALUES ('Published', 'PostStatus', 2, 2);
INSERT INTO tbl_lookup (name, type, code, position) VALUES ('Archived', 'PostStatus', 3, 3);
INSERT INTO tbl_lookup (name, type, code, position) VALUES ('Pending Approval', 'CommentStatus', 1, 1);
INSERT INTO tbl_lookup (name, type, code, position) VALUES ('Approved', 'CommentStatus', 2, 2);

INSERT INTO tbl_user (username, password, salt, email) VALUES ('demo','2e5c7db760a33498023813489cfadc0b','28b206548469ce62182048fd9cf91760','webmaster@example.com');
INSERT INTO tbl_post (title, content, status, create_time, update_time, author_id, tags) VALUES ('Welcome!','This blog system is developed using Yii. It is meant to demonstrate how to use Yii to build a complete real-world application. Complete source code may be found in the Yii releases.

Feel free to try this system by writing new posts and posting comments.',2,1230952187,1230952187,1,'yii, blog');
INSERT INTO tbl_post (title, content, status, create_time, update_time, author_id, tags) VALUES ('A Test Post', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 2,1230952187,1230952187,1,'test');

INSERT INTO tbl_comment (content, status, create_time, author, email, post_id) VALUES ('This is a test comment.', 2, 1230952187, 'Tester', 'tester@example.com', 2);

INSERT INTO tbl_tag (name) VALUES ('yii');
INSERT INTO tbl_tag (name) VALUES ('blog');
INSERT INTO tbl_tag (name) VALUES ('test');

--
-- Table structure for table `contents`
-- 2012-09-12: 删除 site_id, sname, mname, mid, 添加:clicks, source, weight, updatedby, updated
-- 从rss来的数据包括author, source,两者相同,但还是存一份.
-- 现有的不要删除, 只是`notes` text, 不再用到,改为url, author, source替代.
-- pubdate 不是datetime, 而是varchar, 百度风云榜用字符而不是日期.
-- 加关注，喜欢，等。


-- 在使用了百度RSS之后,对表的修改.
-- source放百度RSS, author放original resource, createdby放perl的页面抓取程序名称, 

CREATE TABLE IF NOT EXISTS `contexts` (
  `cid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `linkname` varchar(255) NOT NULL,
  `url` varchar(255) DEFAULT NULL,
  `pubdate` varchar(30) DEFAULT NULL,
  `author` varchar(255) NOT NULL,
  `source` varchar(255) DEFAULT NULL,
  `clicks` int(10) unsigned NOT NULL DEFAULT '0',
  `content` text NOT NULL,
  `category` varchar(128) DEFAULT NULL,
  `cate_id` tinyint(3) unsigned DEFAULT NULL,
  `item` varchar(128) DEFAULT NULL,
  `iid` int(11) DEFAULT '0',
  `language` varchar(10) DEFAULT '中文',
  `tags` text,
  `likes` int(10) unsigned DEFAULT '0',
  `active` enum('Y','N') DEFAULT 'Y',
  `createdby` varchar(50) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `linkname_iid` (`linkname`,`iid`),
  KEY `linkname` (`linkname`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

