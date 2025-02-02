with run_results as (

    select * from {{ ref('fct_dbt_run_results') }}

),

model_executions as (

    select * from {{ ref('fct_dbt_model_executions') }}

),

latest_full as (

    select * from run_results
    where selected_models is null
        and was_full_refresh = false
    order by artifact_generated_at desc
    limit 1

),

joined as (

    select

        {{ dbt_utils.surrogate_key([
                'model_executions.command_invocation_id',
                'model_executions.node_id',
                'model_executions.model_schema'])
            }} as latest_model_id,

        model_executions.*

    from latest_full
    left join model_executions
        on model_executions.command_invocation_id = latest_full.command_invocation_id
        or model_executions.dbt_cloud_run_id = latest_full.dbt_cloud_run_id
        
)

select * from joined
