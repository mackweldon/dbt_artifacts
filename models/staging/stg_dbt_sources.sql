with base as (

    select * from {{ ref('stg_dbt_artifacts') }}

),

manifests as (

    select * from base
    where artifact_type = 'manifest.json'

),

flatten as (

    select

        command_invocation_id,
        dbt_cloud_run_id,
        generated_at as artifact_generated_at,
        node.key as node_id,
        node.value:name::string as name,
        node.value:source_name::string as source_name,
        node.value:schema::string as source_schema,
        node.value:package_name::string as package_name,
        node.value:relation_name::string as relation_name_prep,
        node.value:path::string as source_path,

        case
            when relation_name_prep = 'funnel.FUNNEL__L0J2C68CVI_UUBY4HI7.FUNNEL_FB_GRANULAR'
                then 'funnel.FUNNEL__L0J2C68CVI_UUBY4HI7.FUNNEL'
            else relation_name_prep
        end as relation_name

    from manifests,
    lateral flatten(input => data:sources) as node
    where node.value:resource_type = 'source'

),

surrogate_key as (

    select

        {{ dbt_utils.surrogate_key([
                'command_invocation_id',
                'node_id'])
            }} as manifest_source_id,

        *

    from flatten

)

select * from surrogate_key
