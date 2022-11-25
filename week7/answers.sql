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


DELIMITER ;;

CREATE FUNCTION armor_total(char_id INT UNSIGNED)
RETURNS INT UNSIGNED
DETERMINISTIC
BEGIN
	DECLARE armor_points_equipped INT UNSIGNED;
    DECLARE armor_points_cs INT UNSIGNED;
    
    SELECT SUM(i.armor) INTO armor_points_equipped
		FROM characters c
			INNER JOIN character_stats cs
				ON c.character_id = cs.character_id
			INNER JOIN equipped eq
				ON c.character_id = eq.character_id
			INNER JOIN items i
				ON eq.item_id = i.item_id
	WHERE c.character_id = char_id;
    
	SELECT cs.armor INTO armor_points_cs
		FROM characters c
			INNER JOIN character_stats cs
				ON c.character_id = cs.character_id
	WHERE c.character_id = char_id;
        
	return armor_points_equipped + armor_points_cs;
END;;
DELIMITER ;

DELIMITER ;;
CREATE PROCEDURE attack(IN char_attacked_id INT UNSIGNED, IN id_item_equipped INT UNSIGNED)
BEGIN
    	DECLARE char_armor INT SIGNED;
    DECLARE char_health INT;
	DECLARE attack_damage INT SIGNED;
    DECLARE difference INT;
    DECLARE new_char_health INT;
    
	-- character armor 
    SELECT armor_total(char_attacked_id) INTO char_armor;
    
    -- character_health
    SELECT health FROM character_stats WHERE character_id = char_attacked_id INTO char_health;
    
    
    -- item damage and attack damage - character armor
    SELECT i.damage
        FROM equipped eq
	    INNER JOIN items i
		ON eq.item_id = i.item_id
    WHERE eq.equipped_id = id_item_equipped INTO attack_damage;

    SET difference = attack_damage - char_armor;
    SET new_char_health = char_health - difference;
    
    -- check what happens with item damage
    IF difference > 0 THEN
	    UPDATE character_stats SET health=new_char_health WHERE character_id = char_attacked_id;
    ELSEIF difference >= char_health THEN
	    DELETE FROM characters WHERE character_id = char_attacked_id;
    END IF;
    
END;;
DELIMITER ;

DELIMITER ;;
CREATE PROCEDURE equip(IN item_inventory_id INT UNSIGNED)
BEGIN
	DECLARE char_id INT UNSIGNED;
    DECLARE inventory_item INT UNSIGNED;
    DECLARE char_equip INT UNSIGNED;
    DECLARE item_equip INT UNSIGNED;
    
    SELECT character_id INTO char_id FROM inventory WHERE inventory_id = item_inventory_id;
    
    SELECT item_id INTO inventory_item FROM inventory WHERE inventory_id = item_inventory_id;
 
    SELECT character_id INTO char_equip FROM characters WHERE character_id = char_id;
 
    SELECT item_id INTO item_equip FROM items WHERE item_id = inventory_item;
    
    DELETE FROM inventory WHERE inventory_id = item_inventory_id;
    
    INSERT INTO equipped (character_id, item_id) VALUES (char_equip, item_equip);
END;;
DELIMITER ;
