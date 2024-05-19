with source as (
    select
        abs(invoice_id) as invoice_id
        , abs(parent_invoice_id) as parent_invoice_id
        , abs(transaction_id) as transaction_id
        , abs(organization_id) as organization_id
        , type as invoice_type
        , status as invoice_status
        , amount as invoice_amount_usd
        , currency as invoice_currency
        , payment_currency
        , payment_method
        , fx_rate
        , fx_rate_payment
        , created_at
    from {{ source('dbt_deel', 'invoices') }}
)

select * from source