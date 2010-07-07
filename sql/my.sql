CREATE TABLE entry (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    body TEXT NOT NULL,
    body_html TEXT DEFAULT NULL, -- cache
    ctime INT UNSIGNED NOT NULL,
    mtime INT UNSIGNED NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;
-- ALTER TABLE entry ADD body_html TEXT DEFAULT NULL AFTER body;

CREATE TABLE entry_index (
    entry_id INT UNSIGNED NOT NULL,
    body TEXT NOT NULL,
    PRIMARY KEY (entry_id),
    FULLTEXT (body) WITH PARSER bigram
) ENGINE=MyISAM;

CREATE TABLE entry_history (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entry_id INT UNSIGNED NOT NULL,
    body TEXT NOT NULL,
    ctime INT UNSIGNED NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE search_history (
    word VARCHAR(255) BINARY NOT NULL,
    atime INT UNSIGNED NOT NULL,
    PRIMARY KEY (word),
    INDEX (atime)
) ENGINE=InnoDB;

DELIMITER |
    CREATE TRIGGER before_insert_entry BEFORE INSERT ON entry FOR EACH ROW BEGIN
        SET NEW.ctime = UNIX_TIMESTAMP(NOW());
        SET NEW.mtime = NEW.ctime;
    END
|

DELIMITER |
    CREATE TRIGGER after_insert_entry AFTER INSERT ON entry FOR EACH ROW BEGIN
        INSERT INTO entry_index (entry_id, body) VALUES (NEW.id, NEW.body);
    END
|

DELIMITER |
    CREATE TRIGGER before_update_entry BEFORE UPDATE ON entry FOR EACH ROW BEGIN
        INSERT INTO entry_history (entry_id, body, ctime) VALUES (OLD.id, OLD.body, UNIX_TIMESTAMP(NOW()));
        SET NEW.mtime = UNIX_TIMESTAMP(NOW());
        SET NEW.body_html = NULL;
    END
|

DELIMITER |
    CREATE TRIGGER before_insert_search_history BEFORE INSERT ON search_history FOR EACH ROW BEGIN
        SET NEW.atime = UNIX_TIMESTAMP(NOW());
    END
|

