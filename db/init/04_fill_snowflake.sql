INSERT INTO dim_country (country_name)
SELECT DISTINCT country_name
FROM (
    SELECT customer_country AS country_name FROM v_mock_data_clean
    UNION
    SELECT seller_country FROM v_mock_data_clean
    UNION
    SELECT store_country FROM v_mock_data_clean
    UNION
    SELECT supplier_country FROM v_mock_data_clean
) countries
WHERE country_name IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

WITH locations AS (
    SELECT DISTINCT
        customer_location_hash AS location_hash,
        NULL::text AS address,
        NULL::text AS city,
        NULL::text AS state,
        customer_postal_code AS postal_code,
        customer_country AS country_name
    FROM v_mock_data_clean
    UNION
    SELECT DISTINCT
        seller_location_hash,
        NULL::text,
        NULL::text,
        NULL::text,
        seller_postal_code,
        seller_country
    FROM v_mock_data_clean
    UNION
    SELECT DISTINCT
        store_location_hash,
        store_location,
        store_city,
        store_state,
        NULL::text,
        store_country
    FROM v_mock_data_clean
    UNION
    SELECT DISTINCT
        supplier_location_hash,
        supplier_address,
        supplier_city,
        NULL::text,
        NULL::text,
        supplier_country
    FROM v_mock_data_clean
)
INSERT INTO dim_location (
    location_hash,
    country_key,
    address,
    city,
    state,
    postal_code
)
SELECT
    locations.location_hash,
    dim_country.country_key,
    locations.address,
    locations.city,
    locations.state,
    locations.postal_code
FROM locations
LEFT JOIN dim_country
    ON dim_country.country_name = locations.country_name
WHERE COALESCE(
    locations.address,
    locations.city,
    locations.state,
    locations.postal_code,
    locations.country_name
) IS NOT NULL
ON CONFLICT (location_hash) DO NOTHING;

INSERT INTO dim_product_category (category_name)
SELECT DISTINCT product_category
FROM v_mock_data_clean
WHERE product_category IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO dim_pet_category (category_name)
SELECT DISTINCT pet_category
FROM v_mock_data_clean
WHERE pet_category IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO dim_brand (brand_name)
SELECT DISTINCT product_brand
FROM v_mock_data_clean
WHERE product_brand IS NOT NULL
ON CONFLICT (brand_name) DO NOTHING;

INSERT INTO dim_material (material_name)
SELECT DISTINCT product_material
FROM v_mock_data_clean
WHERE product_material IS NOT NULL
ON CONFLICT (material_name) DO NOTHING;

INSERT INTO dim_color (color_name)
SELECT DISTINCT product_color
FROM v_mock_data_clean
WHERE product_color IS NOT NULL
ON CONFLICT (color_name) DO NOTHING;

INSERT INTO dim_size (size_name)
SELECT DISTINCT product_size
FROM v_mock_data_clean
WHERE product_size IS NOT NULL
ON CONFLICT (size_name) DO NOTHING;

INSERT INTO dim_date (
    date_key,
    year,
    quarter,
    month,
    day_of_month,
    day_of_week,
    week_of_year
)
SELECT DISTINCT
    sale_date,
    EXTRACT(YEAR FROM sale_date)::smallint,
    EXTRACT(QUARTER FROM sale_date)::smallint,
    EXTRACT(MONTH FROM sale_date)::smallint,
    EXTRACT(DAY FROM sale_date)::smallint,
    EXTRACT(ISODOW FROM sale_date)::smallint,
    EXTRACT(WEEK FROM sale_date)::smallint
FROM v_mock_data_clean
WHERE sale_date IS NOT NULL
ON CONFLICT (date_key) DO NOTHING;

INSERT INTO dim_customer (
    customer_hash,
    source_customer_id,
    first_name,
    last_name,
    age,
    email,
    location_key
)
SELECT DISTINCT
    source.customer_hash,
    source.source_customer_id,
    source.customer_first_name,
    source.customer_last_name,
    source.customer_age,
    source.customer_email,
    dim_location.location_key
FROM v_mock_data_clean source
LEFT JOIN dim_location
    ON dim_location.location_hash = source.customer_location_hash
ON CONFLICT (customer_hash) DO NOTHING;

INSERT INTO dim_pet (
    pet_hash,
    customer_key,
    pet_type,
    pet_name,
    pet_breed
)
SELECT DISTINCT
    source.pet_hash,
    dim_customer.customer_key,
    source.customer_pet_type,
    source.customer_pet_name,
    source.customer_pet_breed
FROM v_mock_data_clean source
JOIN dim_customer
    ON dim_customer.customer_hash = source.customer_hash
ON CONFLICT (pet_hash) DO NOTHING;

INSERT INTO dim_seller (
    seller_hash,
    source_seller_id,
    first_name,
    last_name,
    email,
    location_key
)
SELECT DISTINCT
    source.seller_hash,
    source.source_seller_id,
    source.seller_first_name,
    source.seller_last_name,
    source.seller_email,
    dim_location.location_key
FROM v_mock_data_clean source
LEFT JOIN dim_location
    ON dim_location.location_hash = source.seller_location_hash
ON CONFLICT (seller_hash) DO NOTHING;

INSERT INTO dim_store (
    store_hash,
    store_name,
    location_key,
    phone,
    email
)
SELECT DISTINCT
    source.store_hash,
    source.store_name,
    dim_location.location_key,
    source.store_phone,
    source.store_email
FROM v_mock_data_clean source
LEFT JOIN dim_location
    ON dim_location.location_hash = source.store_location_hash
ON CONFLICT (store_hash) DO NOTHING;

INSERT INTO dim_supplier (
    supplier_hash,
    supplier_name,
    contact_name,
    email,
    phone,
    location_key
)
SELECT DISTINCT
    source.supplier_hash,
    source.supplier_name,
    source.supplier_contact,
    source.supplier_email,
    source.supplier_phone,
    dim_location.location_key
FROM v_mock_data_clean source
LEFT JOIN dim_location
    ON dim_location.location_hash = source.supplier_location_hash
ON CONFLICT (supplier_hash) DO NOTHING;

INSERT INTO dim_product (
    product_hash,
    source_product_id,
    product_name,
    product_category_key,
    pet_category_key,
    brand_key,
    material_key,
    color_key,
    size_key,
    supplier_key,
    list_price,
    stock_quantity,
    product_weight,
    product_description,
    product_rating,
    product_reviews,
    release_date,
    expiry_date
)
SELECT DISTINCT
    source.product_hash,
    source.source_product_id,
    source.product_name,
    dim_product_category.product_category_key,
    dim_pet_category.pet_category_key,
    dim_brand.brand_key,
    dim_material.material_key,
    dim_color.color_key,
    dim_size.size_key,
    dim_supplier.supplier_key,
    source.product_price,
    source.product_quantity,
    source.product_weight,
    source.product_description,
    source.product_rating,
    source.product_reviews,
    source.product_release_date,
    source.product_expiry_date
FROM v_mock_data_clean source
LEFT JOIN dim_product_category
    ON dim_product_category.category_name = source.product_category
LEFT JOIN dim_pet_category
    ON dim_pet_category.category_name = source.pet_category
LEFT JOIN dim_brand
    ON dim_brand.brand_name = source.product_brand
LEFT JOIN dim_material
    ON dim_material.material_name = source.product_material
LEFT JOIN dim_color
    ON dim_color.color_name = source.product_color
LEFT JOIN dim_size
    ON dim_size.size_name = source.product_size
LEFT JOIN dim_supplier
    ON dim_supplier.supplier_hash = source.supplier_hash
ON CONFLICT (product_hash) DO NOTHING;

INSERT INTO fact_sales (
    source_row_id,
    source_file,
    source_sale_id,
    sale_date_key,
    customer_key,
    pet_key,
    seller_key,
    product_key,
    store_key,
    sale_quantity,
    sale_total_price,
    unit_price
)
SELECT
    source.mock_data_id,
    source.source_file,
    source.source_sale_id,
    source.sale_date,
    dim_customer.customer_key,
    dim_pet.pet_key,
    dim_seller.seller_key,
    dim_product.product_key,
    dim_store.store_key,
    source.sale_quantity,
    source.sale_total_price,
    source.product_price
FROM v_mock_data_clean source
JOIN dim_customer
    ON dim_customer.customer_hash = source.customer_hash
JOIN dim_pet
    ON dim_pet.pet_hash = source.pet_hash
JOIN dim_seller
    ON dim_seller.seller_hash = source.seller_hash
JOIN dim_product
    ON dim_product.product_hash = source.product_hash
JOIN dim_store
    ON dim_store.store_hash = source.store_hash
ON CONFLICT (source_row_id) DO NOTHING;
