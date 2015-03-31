
----- Load legacy code to generic type and information lookup table

CREATE TABLE zoning.codes_base2012 (
	id integer,
	juris integer, 
	city text, 
	name text, 
	min_far numeric(10,3), 
	max_far numeric(10,3), 
	max_height numeric(20,3),
	min_front_setback numeric(20,5),
	max_front_setback numeric(20,5),
	side_setback numeric(20,5),
	rear_setback numeric(20,5),
	min_dua numeric(10,3),
	max_dua numeric(10,3),
	coverage numeric(40,5),
	max_du_per_parcel numeric(40,3),
	min_lot_size numeric(40,4),
	HS text,
	HT text, 
	HM text, 
	of text, 
	HO text, 
	SC text, 
	IL text, 
	IW text, 
	IH text, 
	RS text, 
	RB text, 
	MR text, 
	MT text, 
	ME text 
);

COPY zoning.codes_base2012 FROM '/zoning_data/zoning_codes_base2012.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

UPDATE zoning.codes_base2012 SET HS = case when HS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET HT = case when HT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET HM = case when HM = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET of = case when of = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET HO = case when HO = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET SC = case when SC = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET IL = case when IL = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET IW = case when IW = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET IH = case when IH = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET RS = case when RS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET RB = case when RB = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET MR = case when MR = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET MT = case when MT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET ME = case when ME = 'x' then 'TRUE' else 'FALSE' end;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HS TYPE BOOLEAN USING HS::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HT TYPE BOOLEAN USING HT::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HM TYPE BOOLEAN USING HM::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN of TYPE BOOLEAN USING of::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HO TYPE BOOLEAN USING HO::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN SC TYPE BOOLEAN USING SC::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IL TYPE BOOLEAN USING IL::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IW TYPE BOOLEAN USING IW::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IH TYPE BOOLEAN USING IH::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN RS TYPE BOOLEAN USING RS::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN RB TYPE BOOLEAN USING RB::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN MR TYPE BOOLEAN USING MR::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN MT TYPE BOOLEAN USING MT::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN ME TYPE BOOLEAN USING ME::BOOLEAN;

ALTER TABLE zoning.codes_base2012 ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;


CREATE TABLE zoning.source_field_name (
	juris integer, 
	matchfield text, 
	tablename text, 
	city_name text 
);

COPY zoning.source_field_name FROM '/zoning_data/match_fields_tables_zoning_2012_source.csv' WITH (FORMAT csv, HEADER TRUE);

ALTER TABLE zoning.source_field_name ALTER COLUMN juris SET NOT NULL;
ALTER TABLE zoning.source_field_name ADD PRIMARY KEY (juris);