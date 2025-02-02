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
        generated_at as artifact_generated_at,
        node.key as node_id,
        node.value:database::string as model_database,
        node.value:schema::string as model_schema,
        node.value:name::string as test_name,
        node.value:package_name::string as package_name,
        node.value:path::string as model_path_prep,
        node.value:checksum.checksum::string as checksum,
        node.value:config.materialized::string as model_materialization,

        replace(replace(replace(model_path_prep, 'bespoke_tests/', ''),
            'schema_test/', ''), 'data_test/', '') as model_path

    from manifests,
    lateral flatten(input => data:nodes) as node
    where node.value:resource_type = 'test'

),

surrogate_key as (

    select

        {{ dbt_utils.surrogate_key([
                'command_invocation_id',
                'node_id',
                'model_schema'])
            }} as manifest_test_id,

        *

    from flatten

)

select * from surrogate_key
