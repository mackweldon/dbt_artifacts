{{
    config(
        materialized = 'incremental',
        unique_key = 'manifest_source_id'
    )
}}

with dbt_sources as (

    select * from {{ ref('stg_dbt_sources') }}

),

dbt_sources_incremental as (

    select * from dbt_sources

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
        where artifact_generated_at > (
            select max(artifact_generated_at)
            from {{ this }}
        )
    {% endif %}

)

select * from dbt_sources_incremental
