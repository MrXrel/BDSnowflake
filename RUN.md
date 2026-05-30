# Запуск BDSnowflake

```bash
cd ~/labs/BDSnowflake
docker compose down -v --remove-orphans
docker compose up -d --wait
```

Проверка:

```bash
docker compose exec -T postgres psql -U postgres -d bigdata <<'SQL'
select count(*) as mock_data_rows from mock_data;
select count(*) as fact_sales_rows from fact_sales;
SQL
```

Ожидаемо:

```text
mock_data_rows = 10000
fact_sales_rows = 10000
```

Если нужно посмотреть логи:

```bash
docker compose logs postgres --tail=200
```
