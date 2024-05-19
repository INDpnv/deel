with organizations as (
    select
        organization_id
        , legal_entity_country_code
        , total_active_contracts
        , created_datetime
        , first_payment_date
        , last_payment_date
    from {{ ref('stg_organizations') }}
)

, final as (
    select
        {{ dbt_utils.generate_surrogate_key(['organization_id']) }} as organization_sk
        , organization_id as source_organization_id
        , legal_entity_country_code
        , total_active_contracts
        -- Assuming an org is inactive if created before 180 days and no payments done in the last 90 days
        , (coalesce(last_payment_date, '1970-01-01') < current_date - 90 and cast(created_datetime as date) < current_date -180 ) as is_inactive
        , created_datetime
    from organizations
)

select * from final


