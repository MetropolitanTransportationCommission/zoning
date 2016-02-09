#$@ is the file name of the target of the rule. 
#example get from s3:aws s3 cp s3://landuse/zoning/match_fields_tables_zoning_2012_source.csv match_fields_tables_zoning_2012_source.csv
get = aws s3 cp s3://landuse/zoning/
get_zoning = aws s3 cp s3://zoning-sf-bay-area/
DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=mtc 
psql = PGPASSWORD=vagrant psql -p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME)
shp2pgsql = shp2pgsql -t 2D -s 26910 -I

#########################
#####need to review######
#########################

load_zoning_code_additions:
	$(psql) -f load/add_missing_codes.sql

fix_string_matching_in_zoning_table: match_fields_tables_zoning_2012_source.csv
	$(psql) -f load/zoning_codes_fix_string_matching.sql

###########################
####Join Parcels/Zoning####
###########################

zoning_parcels.csv: zoning_files \
					county10_ca.shp \
					city10_ba.shp \
					zoning_lookup.csv \
					parcels_sql_dump
#load postgis extensions
	$(psql) -f functions/zoning_functions.sql
	$(psql) -f functions/postgis_addons.sql
#load generic zoning assignment table
	$(psql) -f load/load-generic-zoning-code-table.sql
#load and assign adminstrative areas to parcels
	$(psql) -c "DROP SCHEMA if exists admin_staging CASCADE;"
	$(psql) -c "CREATE SCHEMA admin_staging;"
	$(shp2pgsql) city10_ba.shp admin_staging.city10_ba | $(psql)
	$(shp2pgsql) county10_ca.shp admin_staging.county10_ca | $(psql)
	$(psql) -f load/load-zoning-shapefile-metadata.sql
	$(psql) -f process/create_jurisdictional_table.sql
	$(psql) -f process/assign_city_name_by_county.sql
#load zoning source data shapefiles from 2012
	$(psql) -c "DROP SCHEMA IF EXISTS zoning_2012_staging CASCADE"
	$(psql) -c "CREATE SCHEMA zoning_2012_staging"
	ls jurisdictional/*.shp | cut -d "/" -f2 | sed 's/.shp//' |
		xargs -I {} $(shp2pgsql) jurisdictional/{} zoning_2012_staging.{} | $(psql)
#FIX for Napa
	$(psql) -c "CREATE TABLE zoning_2012_staging.napacozoning_temp AS SELECT zoning, geom from zoning_2012_staging.napacozoning;"
	$(psql) -c "DROP TABLE zoning_2012_staging.napacozoning;"
	$(psql) -c "CREATE TABLE zoning_2012_staging.napacozoning AS SELECT * from zoning_2012_staging.napacozoning_temp;"
	$(psql) -c "DROP TABLE zoning_2012_staging.napacozoning_temp;"
#FIX for Solano
	$(psql) -c "CREATE TABLE zoning_2012_staging.solcogeneral_plan_unincorporated_temp AS SELECT full_name, geom from zoning_2012_staging.solcogeneral_plan_unincorporated;"
	$(psql) -c "DROP TABLE zoning_2012_staging.solcogeneral_plan_unincorporated;"
	$(psql) -c "CREATE TABLE zoning_2012_staging.solcogeneral_plan_unincorporated AS SELECT * from zoning_2012_staging.solcogeneral_plan_unincorporated_temp;"
	$(psql) -c "DROP TABLE zoning_2012_staging.solcogeneral_plan_unincorporated_temp;"
#do 2012 assignment by city
	$(psql) -c "SELECT fix_2012_geoms(TRUE);"
	$(psql) -c "DROP SCHEMA IF EXISTS zoning_2012_parcel_overlaps CASCADE;"
	$(psql) -c "CREATE SCHEMA zoning_2012_parcel_overlaps;"
	$(psql) -c "SELECT overlap_2012(TRUE);"
#assign the 2012 zoning data to parcels
	$(psql) -f process/assign_2012_zoning_to_parcels.sql
#load zoning source data shapefile from 2006
	$(psql) -c "DROP TABLE IF EXISTS zoning.plu06_may2015estimate;"
	$(shp2pgsql) data/plu06_may2015estimate.shp zoning.plu06_may2015estimate | $(psql)
	$(psql) -f load/add-plu-2006.sql
#clean and homogenize geometries
	$(psql) -f process/clean_plu06_geoms.sql
#intersection with 2006:
	$(psql) -f process/create_intersection_table_plu06.sql
	$(psql) -f process/overlaps_plu06_missing_parcels.sql
	$(psql) -f process/assign_plu06_to_parcels.sql
#output 		
	$(psql) -f output/summarize.sql
	python output/fix_zoning_missing_id.py
	$(psql) mtc -f output/summarize.sql
	bash output/backup_db.sh
	bash output/write_db_to_s3.sh
	$(psql) -c "\COPY zoning.parcel to 'zoning_parcels_no_dev_as_zero.csv' DELIMITER ',' CSV HEADER;"
##############
##############
####FILES!####
##############
##############

##############
###PARCELS!###
##############

parcels_sql_dump:

##############
###ZONING!####
##############

legacy_tablenames := $(shell cat zoning_source_metadata.csv | cut -d ',' -f2 | tr '\n' ' ')
zip_targets = $(addprefix jurisdictional/, $(addsuffix .shp.zip, $(legacy_tablenames)))
shp_targets = $(addprefix jurisdictional/, $(addsuffix .shp, $(legacy_tablenames)))

zoning_files: zoning_files_2012 zoning_file_2006

zoning_files_2012: $(shp_targets) 

zoning_file_2006: data/plu06_may2015estimate.shp

data/plu06_may2015estimate.shp: data/plu06_may2015estimate.zip
	unzip -o $<
	touch $@

$(shp_targets): $(zip_targets)
	unzip -d jurisdictional -o $@.zip
	touch $@

$(zip_targets):
	$(get_zoning)$(@F) \
	$@.download
	mv $@.download $@

########################
####ADMINISTRATIVE!#####
########################

county10_ca.shp: county10_ca.zip
	unzip -o $<
	touch $@

city10_ba.shp: city10_ba.zip
	unzip -o $<

zoning_lookup.csv:
	curl -k -o $@.download https://raw.githubusercontent.com/MetropolitanTransportationCommission/bayarea_urbansim/master/data/zoning_lookup.csv?token=AAGCjC_Z9YDWbVUtwzTkKBHJgYdXwJqtks5WDHVUwA%3D%3D 
	mv $@.download $@

city10_ba.zip:
	$(get)city10_ba.zip \
	$@.download
	mv $@.download $@

county10_ca.zip:
	$(get)county10_ca.zip \
	$@.download
	mv $@.download $@

match_fields_tables_zoning_2012_source.csv:
	$(get)match_fields_tables_zoning_2012_source.csv \
	$@.download
	mv $@.download $@

data/plu06_may2015estimate.zip:
	$(get)plu06_may2015estimate.zip \
	$@.download
	mv $@.download $@

##################################
#############EXTRAS###############
##################################
##everything down here is not#####
#part of the main target creation#
##################################

load_pda: pda.shp
	$(shp2pgsql) pda.shp admin.pda | $(psql)

update_after_change_in_zoning_ids: \
	intersect \
	assign \
	backup_db

pda.shp.zip: 
	$(get)$@ \
	$@.download
	mv $@.download $@

City_Santa_Clara_GP_LU_02.zip: 
	$(get)$@ \
	$@.download
	mv $@.download $@

ba8parcels.sql:
	$(get)ba8parcels.sql \
	$@.download
	mv $@.download $@

parcels_spandex.sql:
	$(get)parcels_spandex.sql \
	$@.download
	mv $@.download $@

####################
######NO DEV########
####################

no_dev1_geo_only.csv:
	$(get)$@ \
	$@.download
	mv $@.download $@

no_dev:
	load_no_dev \
	apply_no_dev \

load_no_dev: no_dev1_geo_only.csv
	$(psql) -f load/no_dev.sql

apply_no_dev:
	$(psql) -f process/apply_no_dev.sql

no_dev1.txt:
	$(get)$@ \
	$@.download
	mv $@.download $@
	touch $@

###################
######Output#######
###################

sql_dump:
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel_withdetails.sql \
	vagrant
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel.sql \
	vagrant

write_db_to_s3:
	bash output/write_db_to_s3.sh

###################

clean_zoning_data: 
	$(psql) -c "DROP SCHEMA zoning CASCADE;"
	$(psql) -c "DROP SCHEMA zoning_2012_staging CASCADE;"

clean_db:
	sudo bash load/clean_db.sh
	
clean_intersection_tables:
	$(psql)	-f load/drop_intersection_tables.sql

clean_parcel_generation:
	$(psql)	-f load/drop_parcel_generation_tables.sql

clean_shapefiles:
	rm -rf jurisdictional

remove_source_data:
	rm ba8parcels.* 
	rm city10_ba.* 
	rm county10_ca.* 
	rm match_fields_tables_zoning_2012_source.* 
	rm parcels_spandex.* 
	rm Parcels2010_Update9.* 
	rm jurisdictional/*.* 
	rm PLU2008_Updated.*
	rm PlannedLandUsePhase*

reload_plu06: load_plu06 clean_plu06_geoms plu_06

#########################
###Join Parcels/PDAs#####
#########################
parcels_pdas.csv: 
	load_pda \
	$(psql) -f process/get_pda_for_parcels.sql


##################################################
###following may be useful later, not used now####
####for loading/checks against census source #####
##################################################

load_census_city_boundaries: gz_2010_06_160_00_500k.shp
	$(psql) -c "DROP TABLE IF EXISTS admin_staging.gz_2010_06_160_00_500k"
	shp2pgsql -W "LATIN1" -t 2D -s 4269 -I gz_2010_06_160_00_500k.shp admin_staging.gz_2010_06_160_00_500k | $(psql)

gz_2010_06_160_00_500k.shp: gz_2010_06_160_00_500k.zip
	unzip -o gz_2010_06_160_00_500k.zip

gz_2010_06_160_00_500k.zip:
	curl -k -o $@.download http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_06_160_00_500k.zip
	mv $@.download $@

load_census_county_boundaries: gz_2010_us_050_00_5m.shp
	$(psql) -c "DROP TABLE IF EXISTS admin_staging.gz_2010_us_050_00_5m"
	shp2pgsql -W "LATIN1" -t 2D -s 4269 -I gz_2010_us_050_00_5m.shp admin_staging.gz_2010_us_050_00_5m | $(psql)

gz_2010_us_050_00_5m.shp: gz_2010_us_050_00_5m.zip
	unzip -o $<

gz_2010_us_050_00_5m.zip:
	curl -k -o $@.download http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_us_050_00_5m.zip
	mv $@.download $@

##################################################
##################END CENSUS IMPORT###############
####for loading/checks against census source #####
##################################################

pda.shp: pda.shp.zip
	unzip -o $<
	touch $@

gdb_table_list:
	ls jurisdictional/*.shp | cut -d "/" -f2 | \
	sed 's/.shp//' | tr '[A-Z]' '[a-z]'| sort > gdb_table_list

zip_up_shapefiles:
	ls *.shp | sed 's/.shp//' | \
	xargs -I {} zip -r {}.zip . -i {}.shp.*
