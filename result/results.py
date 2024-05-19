from google.cloud import bigquery

client = bigquery.Client()

query = """
        with previous_amounts as
    (
      select 
        orgs.source_organization_id as organization_id
        , balances.snapshot_date
        , balances.daily_account_amount
        , lag(balances.daily_account_amount) over (partition by orgs.source_organization_id order by balances.snapshot_date) as previous_amount
      from `deel-take-home.dbt_deel.fct_daily_account_balances` as balances
      inner join `deel-take-home.dbt_deel.dim_organizations` as orgs
      on balances.organization_sk = orgs.organization_sk
    )
    , pct as (
      select * except(previous_amount)
      , coalesce(previous_amount, 0) as previous_amount 
      , case when coalesce(previous_amount, 0) = 0 and daily_account_amount = 0 then false
            when coalesce(previous_amount, 0) = 0 then true
            when daily_account_amount = 0 then true
            when abs(coalesce(previous_amount, 0) - daily_account_amount) / daily_account_amount > 0.5 then true
            else false end as pct_check
      from previous_amounts
      where snapshot_date = '2024-04-24'
    )

    select * except(pct_check) 
    from pct
    where pct_check
"""
rows = client.query_and_wait(query)  # Make an API request.

print("The query data:")
for row in rows:
    # Row values can be accessed by field name or index.
    print("day={}, organization_id={}, daily_account_amount={}. previous_amount={}".format(row["snapshot_date"], row["organization_id"], row["daily_account_amount"], row["previous_amount"]))