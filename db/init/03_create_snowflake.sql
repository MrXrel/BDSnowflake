CREATE OR REPLACE FUNCTION clean_text(value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
RETURN NULLIF(btrim(value), '');

CREATE OR REPLACE FUNCTION analytics_hash(VARIADIC parts text[])
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
RETURN md5(array_to_string(parts, E'\x1f', E'\x1e'));

CREATE TABLE IF NOT EXISTS dim_country (
    country_key bigserial PRIMARY KEY,
    country_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_location (
    location_key bigserial PRIMARY KEY,
    location_hash text NOT NULL UNIQUE,
    country_key bigint REFERENCES dim_country(country_key),
    address text,
    city text,
    state text,
    postal_code text
);

CREATE TABLE IF NOT EXISTS dim_product_category (
    product_category_key bigserial PRIMARY KEY,
    category_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_pet_category (
    pet_category_key bigserial PRIMARY KEY,
    category_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_brand (
    brand_key bigserial PRIMARY KEY,
    brand_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_material (
    material_key bigserial PRIMARY KEY,
    material_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_color (
    color_key bigserial PRIMARY KEY,
    color_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_size (
    size_key bigserial PRIMARY KEY,
    size_name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_date (
    date_key date PRIMARY KEY,
    year smallint NOT NULL,
    quarter smallint NOT NULL,
    month smallint NOT NULL,
    day_of_month smallint NOT NULL,
    day_of_week smallint NOT NULL,
    week_of_year smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key bigserial PRIMARY KEY,
    customer_hash text NOT NULL UNIQUE,
    source_customer_id integer,
    first_name text,
    last_name text,
    age integer,
    email text,
    location_key bigint REFERENCES dim_location(location_key)
);

CREATE TABLE IF NOT EXISTS dim_pet (
    pet_key bigserial PRIMARY KEY,
    pet_hash text NOT NULL UNIQUE,
    customer_key bigint NOT NULL REFERENCES dim_customer(customer_key),
    pet_type text,
    pet_name text,
    pet_breed text
);

CREATE TABLE IF NOT EXISTS dim_seller (
    seller_key bigserial PRIMARY KEY,
    seller_hash text NOT NULL UNIQUE,
    source_seller_id integer,
    first_name text,
    last_name text,
    email text,
    location_key bigint REFERENCES dim_location(location_key)
);

CREATE TABLE IF NOT EXISTS dim_store (
    store_key bigserial PRIMARY KEY,
    store_hash text NOT NULL UNIQUE,
    store_name text,
    location_key bigint REFERENCES dim_location(location_key),
    phone text,
    email text
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_key bigserial PRIMARY KEY,
    supplier_hash text NOT NULL UNIQUE,
    supplier_name text,
    contact_name text,
    email text,
    phone text,
    location_key bigint REFERENCES dim_location(location_key)
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_key bigserial PRIMARY KEY,
    product_hash text NOT NULL UNIQUE,
    source_product_id integer,
    product_name text,
    product_category_key bigint REFERENCES dim_product_category(product_category_key),
    pet_category_key bigint REFERENCES dim_pet_category(pet_category_key),
    brand_key bigint REFERENCES dim_brand(brand_key),
    material_key bigint REFERENCES dim_material(material_key),
    color_key bigint REFERENCES dim_color(color_key),
    size_key bigint REFERENCES dim_size(size_key),
    supplier_key bigint REFERENCES dim_supplier(supplier_key),
    list_price numeric(12, 2),
    stock_quantity integer,
    product_weight numeric(10, 2),
    product_description text,
    product_rating numeric(4, 2),
    product_reviews integer,
    release_date date,
    expiry_date date
);

CREATE TABLE IF NOT EXISTS fact_sales (
    sale_key bigserial PRIMARY KEY,
    source_row_id bigint NOT NULL UNIQUE REFERENCES mock_data(mock_data_id),
    source_file text NOT NULL,
    source_sale_id integer,
    sale_date_key date REFERENCES dim_date(date_key),
    customer_key bigint REFERENCES dim_customer(customer_key),
    pet_key bigint REFERENCES dim_pet(pet_key),
    seller_key bigint REFERENCES dim_seller(seller_key),
    product_key bigint REFERENCES dim_product(product_key),
    store_key bigint REFERENCES dim_store(store_key),
    sale_quantity integer,
    sale_total_price numeric(12, 2),
    unit_price numeric(12, 2)
);

CREATE OR REPLACE VIEW v_mock_data_clean AS
WITH cleaned AS (
    SELECT
        mock_data_id,
        source_file,
        clean_text(id)::integer AS source_sale_id,
        clean_text(customer_first_name) AS customer_first_name,
        clean_text(customer_last_name) AS customer_last_name,
        clean_text(customer_age)::integer AS customer_age,
        clean_text(customer_email) AS customer_email,
        clean_text(customer_country) AS customer_country,
        clean_text(customer_postal_code) AS customer_postal_code,
        clean_text(customer_pet_type) AS customer_pet_type,
        clean_text(customer_pet_name) AS customer_pet_name,
        clean_text(customer_pet_breed) AS customer_pet_breed,
        clean_text(seller_first_name) AS seller_first_name,
        clean_text(seller_last_name) AS seller_last_name,
        clean_text(seller_email) AS seller_email,
        clean_text(seller_country) AS seller_country,
        clean_text(seller_postal_code) AS seller_postal_code,
        clean_text(product_name) AS product_name,
        clean_text(product_category) AS product_category,
        clean_text(product_price)::numeric(12, 2) AS product_price,
        clean_text(product_quantity)::integer AS product_quantity,
        to_date(clean_text(sale_date), 'MM/DD/YYYY') AS sale_date,
        clean_text(sale_customer_id)::integer AS source_customer_id,
        clean_text(sale_seller_id)::integer AS source_seller_id,
        clean_text(sale_product_id)::integer AS source_product_id,
        clean_text(sale_quantity)::integer AS sale_quantity,
        clean_text(sale_total_price)::numeric(12, 2) AS sale_total_price,
        clean_text(store_name) AS store_name,
        clean_text(store_location) AS store_location,
        clean_text(store_city) AS store_city,
        clean_text(store_state) AS store_state,
        clean_text(store_country) AS store_country,
        clean_text(store_phone) AS store_phone,
        clean_text(store_email) AS store_email,
        clean_text(pet_category) AS pet_category,
        clean_text(product_weight)::numeric(10, 2) AS product_weight,
        clean_text(product_color) AS product_color,
        clean_text(product_size) AS product_size,
        clean_text(product_brand) AS product_brand,
        clean_text(product_material) AS product_material,
        clean_text(product_description) AS product_description,
        clean_text(product_rating)::numeric(4, 2) AS product_rating,
        clean_text(product_reviews)::integer AS product_reviews,
        to_date(clean_text(product_release_date), 'MM/DD/YYYY') AS product_release_date,
        to_date(clean_text(product_expiry_date), 'MM/DD/YYYY') AS product_expiry_date,
        clean_text(supplier_name) AS supplier_name,
        clean_text(supplier_contact) AS supplier_contact,
        clean_text(supplier_email) AS supplier_email,
        clean_text(supplier_phone) AS supplier_phone,
        clean_text(supplier_address) AS supplier_address,
        clean_text(supplier_city) AS supplier_city,
        clean_text(supplier_country) AS supplier_country
    FROM mock_data
),
base_hashes AS (
    SELECT
        *,
        analytics_hash(NULL::text, NULL::text, NULL::text, customer_postal_code, customer_country) AS customer_location_hash,
        analytics_hash(NULL::text, NULL::text, NULL::text, seller_postal_code, seller_country) AS seller_location_hash,
        analytics_hash(store_location, store_city, store_state, NULL::text, store_country) AS store_location_hash,
        analytics_hash(supplier_address, supplier_city, NULL::text, NULL::text, supplier_country) AS supplier_location_hash,
        analytics_hash(supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address, supplier_city, supplier_country) AS supplier_hash
    FROM cleaned
),
entity_hashes AS (
    SELECT
        *,
        analytics_hash(source_customer_id::text, customer_first_name, customer_last_name, customer_age::text, customer_email, customer_location_hash) AS customer_hash,
        analytics_hash(source_seller_id::text, seller_first_name, seller_last_name, seller_email, seller_location_hash) AS seller_hash,
        analytics_hash(store_name, store_location_hash, store_phone, store_email) AS store_hash
    FROM base_hashes
)
SELECT
    *,
    analytics_hash(customer_hash, customer_pet_type, customer_pet_name, customer_pet_breed) AS pet_hash,
    analytics_hash(
        source_product_id::text,
        product_name,
        product_category,
        product_price::text,
        product_quantity::text,
        pet_category,
        product_weight::text,
        product_color,
        product_size,
        product_brand,
        product_material,
        product_description,
        product_rating::text,
        product_reviews::text,
        product_release_date::text,
        product_expiry_date::text,
        supplier_hash
    ) AS product_hash
FROM entity_hashes;
