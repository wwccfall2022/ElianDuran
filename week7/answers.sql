-- Create your tables, views, functions and procedures here!
CREATE SCHEMA destruction;
USE destruction;

CREATE TABLE players (
	player_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	email VARCHAR(50) NOT NULL
);

CREATE TABLE characters (
	character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    player_id INT UNSIGNED,
    name VARCHAR(30) NOT NULL,
    level INT UNSIGNED,
    CONSTRAINT characters_fk_players
        FOREIGN KEY (player_id)
        REFERENCES players (player_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE winners (
	character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    CONSTRAINT winners_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE character_stats (
	character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    health INT UNSIGNED,
    armor INT UNSIGNED,
    CONSTRAINT charstats_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE teams (
	team_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name VARCHAR(30)
);

CREATE TABLE team_members (
	team_member_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    team_id INT UNSIGNED,
    character_id INT UNSIGNED,
    CONSTRAINT teammember_fk_teams
        FOREIGN KEY (team_id)
        REFERENCES teams (team_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT teammemberchar_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE items (
	item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name VARCHAR(30),
    armor INT UNSIGNED,
    damage INT UNSIGNED
);

CREATE TABLE inventory (
	inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    character_id INT UNSIGNED,
    item_id INT UNSIGNED,
    CONSTRAINT inventorychar_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT inventoryitem_fk_items
        FOREIGN KEY (item_id)
        REFERENCES items (item_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE equipped (
	equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    character_id INT UNSIGNED,
    item_id INT UNSIGNED,
    CONSTRAINT equippedchar_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT equippeditem_fk_items
        FOREIGN KEY (item_id)
        REFERENCES items (item_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


CREATE OR REPLACE VIEW character_items AS 
	SELECT
		c.character_id,
		c.name AS character_name,	
		i.name AS item_name,
		i.armor,
		i.damage
	FROM characters c
		INNER JOIN inventory inv
			ON c.character_id = inv.character_id
		INNER JOIN items i
			ON inv.item_id = i.item_id
	UNION
	SELECT 
		c.character_id,
		c.name AS character_name,	
		i.name AS item_name,
		i.armor,
		i.damage
	FROM characters c
		INNER JOIN equipped eq
			ON c.character_id = eq.character_id
		INNER JOIN items i
			ON eq.item_id = i.item_id
	ORDER BY character_id ASC, item_name ASC;


CREATE OR REPLACE VIEW team_items AS
	SELECT
		t.team_id,
		t.name AS team_name,
		i.name AS item_name,
		i.armor,
		i.damage
	FROM teams t
		INNER JOIN team_members tm
			ON t.team_id = tm.team_id
		INNER JOIN inventory inv 
			ON tm.character_id = inv.character_id
		INNER JOIN items i
			ON inv.item_id = i.item_id
UNION 
	SELECT
		t.team_id,
		t.name AS team_name,
		i.name AS item_name,
		i.armor,
		i.damage
	FROM teams t
		INNER JOIN team_members tm
			ON t.team_id = tm.team_id
		INNER JOIN equipped eq
			ON tm.character_id = eq.character_id
		INNER JOIN items i
			ON eq.item_id = i.item_id
		ORDER BY team_id, item_name;
