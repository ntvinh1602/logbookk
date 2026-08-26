DROP TRIGGER IF EXISTS after_new_prices_ins ON dwd.daily_asset_close;

CREATE TRIGGER after_new_prices_ins
AFTER INSERT
ON dwd.daily_asset_close REFERENCING NEW table as new_rows
FOR EACH STATEMENT
 EXECUTE FUNCTION dws.trg_snapshots_prices();


DROP TRIGGER IF EXISTS after_new_prices_upd ON dwd.daily_asset_close;

CREATE TRIGGER after_new_prices_upd
AFTER UPDATE
ON dwd.daily_asset_close REFERENCING OLD table as old_rows NEW table as new_rows
FOR EACH STATEMENT
 EXECUTE FUNCTION dws.trg_snapshots_prices();

 DROP TRIGGER IF EXISTS after_new_fxrate_ins ON dwd.daily_fxrate_close;

CREATE TRIGGER after_new_fxrate_ins
AFTER INSERT
ON dwd.daily_fxrate_close REFERENCING NEW table as new_rows
FOR EACH STATEMENT
 EXECUTE FUNCTION dws.trg_snapshots_fxrate();


DROP TRIGGER IF EXISTS after_new_fxrate_upd ON dwd.daily_fxrate_close;

CREATE TRIGGER after_new_fxrate_upd
AFTER UPDATE
ON dwd.daily_fxrate_close REFERENCING OLD table as old_rows NEW table as new_rows
FOR EACH STATEMENT
 EXECUTE FUNCTION dws.trg_snapshots_fxrate();