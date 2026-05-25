DO $$
DECLARE
    staging_count bigint;
    fact_count bigint;
BEGIN
    SELECT count(*) INTO staging_count FROM mock_data;
    SELECT count(*) INTO fact_count FROM fact_sales;

    IF staging_count <> 10000 THEN
        RAISE EXCEPTION 'Expected 10000 rows in mock_data, got %', staging_count;
    END IF;

    IF fact_count <> staging_count THEN
        RAISE EXCEPTION 'Expected fact_sales count to equal mock_data count %, got %', staging_count, fact_count;
    END IF;

    RAISE NOTICE 'Loaded % source rows and % fact rows', staging_count, fact_count;
END;
$$;
