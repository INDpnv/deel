with source as (
    select
        abs(organization_id) as organization_id
        , first_payment_date
        , last_payment_date
        , abs(legal_entity_country_code) as legal_entity_country_code
        , count_total_contracts_active as total_active_contracts
        , created_date as created_datetime
    from {{ source('dbt_deel', 'organizations') }}
)

select * from source