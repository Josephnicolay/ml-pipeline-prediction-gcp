import os
from google.cloud import storage
import kfp
from kfp.v2 import compiler, dsl

from google_cloud_pipeline_components.v1.vertex_notification_email import VertexNotificationEmailOp

from components.error_component import error
from components.validation_component import validate_data
from components.bq_process_component import process_data
from components.prediction_component import prediction

EMAIL = os.environ.get("EMAIL", "josephnicolay21@gmail.com")
GCS_BUCKET = os.environ.get("GCS_BUCKET")

PIPELINE_NAME = "house-price-prediction"
LOCAL_ARTIFACTS_DIR = os.environ.get("LOCAL_ARTIFACTS_DIR", "artifacts/pipelines")
PIPELINE_BLOB_PATH = f"pipelines/{PIPELINE_NAME}.json"


@kfp.dsl.pipeline(
    name=PIPELINE_NAME, 
    description="Pipeline for house price prediction",
    pipeline_root=f"gs://{GCS_BUCKET}/pipelines"
)
def main_pipeline(
    project: str,
    input_table_id: str,
    features_table_id: str,
    output_table_id: str,
    path_model: str,
):
    
    notify_email_task = VertexNotificationEmailOp(
        recipients=[EMAIL]
    )
    notify_email_task.set_display_name('Notification Email')
    
    with dsl.ExitHandler(notify_email_task, name="Execute pipeline prediction"):

        validate_tables_job = validate_data(
            table = input_table_id
        )
        validate_tables_job.set_display_name('Validate Data')

        with dsl.Condition(
            validate_tables_job.outputs['condition']=="false",
            name="no-execute",
        ):
            error(msg="Not able to validate input table.")


        with dsl.Condition(
            validate_tables_job.outputs['condition']=="true",
            name="execute",
        ):

            processOp = process_data(
                project=project,
                input_table_id=input_table_id,
                features_table_id=features_table_id
            )
            processOp.set_display_name("PROCESS_DATA")
            
  
            predictionOp = prediction(
                project=project,
                features_table=processOp.outputs['features_table'],
                output_table_id=output_table_id,
                path_model=path_model
            )
            predictionOp.set_display_name("MODEL_PREDICTION")


def compile_pipeline() -> str:
    os.makedirs(LOCAL_ARTIFACTS_DIR, exist_ok=True)
    local_package_path = os.path.join(LOCAL_ARTIFACTS_DIR, f"{PIPELINE_NAME}.json")

    compiler.Compiler().compile(
        pipeline_func=main_pipeline,
        package_path=local_package_path
    )

    return local_package_path


def upload_pipeline_spec(local_package_path: str) -> str:
    if not GCS_BUCKET:
        raise ValueError("GCS_BUCKET environment variable is required to upload the compiled pipeline.")

    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET)
    blob = bucket.blob(PIPELINE_BLOB_PATH)
    blob.upload_from_filename(local_package_path)

    return f"gs://{GCS_BUCKET}/{PIPELINE_BLOB_PATH}"


def compile_and_upload_pipeline() -> str:
    local_package_path = compile_pipeline()
    return upload_pipeline_spec(local_package_path)


if __name__ == "__main__":
    uploaded_uri = compile_and_upload_pipeline()
    print(f"Compiled pipeline uploaded to {uploaded_uri}")
