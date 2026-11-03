import os
from google.cloud import aiplatform


def require_env(var_name: str) -> str:
    value = os.environ.get(var_name)
    if not value:
        raise ValueError(f"Missing required environment variable: {var_name}")
    return value


def run_pipeline():

    project = require_env("PROJECT_ID")
    location = require_env("LOCATION")
    pipeline_path = require_env("PIPELINE_PATH")
    service_account = require_env("SERVICE_ACCOUNT")
    input_table_id = require_env("INPUT_TABLE_ID")
    features_table_id = require_env("FEATURES_TABLE_ID")
    output_table_id = require_env("OUTPUT_TABLE_ID")
    path_model = require_env("PATH_MODEL")

    blob_name = pipeline_path.split("/")[-1]
    display_name = blob_name.split(".")[0] if blob_name else "pipeline"
    
    aiplatform.init(project=project, location=location)

    job = aiplatform.PipelineJob(
        display_name=display_name,
        template_path=pipeline_path,
        enable_caching=False,
        project=project,
        location=location,
        parameter_values={
            "project": project,
            "input_table_id": input_table_id,
            "features_table_id": features_table_id,
            "output_table_id": output_table_id,
            "path_model": path_model,
        }
    )
    print('Submitting pipeline job...')
    job.submit(service_account=service_account)

if __name__ == "__main__":
    run_pipeline()
