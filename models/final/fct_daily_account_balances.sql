{{ config(
    materialized = 'incremental'
    , incremental_strategy = 'merge'
    , unique_key = ['organization_sk', 'snapshot_date']
    , partition_by = {'field': 'partition_date'}
    , incremental_predicates = [
      "DBT_INTERNAL_DEST.partition_date between date_trunc(current_date-30, month) and current_date-1"
    ]
)}}

with invoices as (
    select
        invoice_id
        , organization_id
        , invoice_status
        , invoice_amount_usd
        , created_at
    from {{ ref('stg_invoices') }}
    where invoice_status not in ('open', 'failed', 'cancelled', 'failed') -- Skipping unsuccessful/open payments
    {% if is_incremental() %}
        and cast(created_at as date) between date_trunc(current_date-30, month) and current_date-1
    {% endif %}
)

, organizations as (
    select
        organization_id
    from {{ ref('stg_organizations') }}
)

, dates as (
    select
        date_day
    from {{ ref('dim_dates') }}
    where date_day < current_date
    {% if is_incremental() %}
        and date_day between date_trunc(current_date-30, month) and current_date-1
    {% endif %}
)

, orgs_dates as (
    select
        organizations.organization_id
        , dates.date_day as snapshot_date
    from dates
    cross join organizations

)

, invoices_aggregated as (
    select
        organization_id
        , cast(created_at as date) as snapshot_date
        , sum(invoice_amount_usd) as daily_account_amount
    from invoices
    group by 1, 2
)

, final as (
    select
        {{ dbt_utils.generate_surrogate_key(['orgs_dates.organization_id']) }} as organization_sk
        , orgs_dates.snapshot_date
        , date_trunc(orgs_dates.snapshot_date, month) as partition_date
        , coalesce(invoices_aggregated.daily_account_amount, 0) as daily_account_amount
    from orgs_dates
    left join invoices_aggregated
        on orgs_dates.organization_id = invoices_aggregated.organization_id
        and orgs_dates.snapshot_date = invoices_aggregated.snapshot_date
)

select * from final