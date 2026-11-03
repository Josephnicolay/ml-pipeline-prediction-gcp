from kfp.v2.dsl import (
    Dataset,
    Input,
    Output,
    component
)

@component(
    packages_to_install=[
        "google-cloud-bigquery",
        "google-cloud-bigquery-storage",
        "pandas",
        "scikit-learn",
        "joblib",
        "db-dtypes",
        "pyarrow",
        "pandas-gbq",
        "google-cloud-storage",
        "pytz"
    ],
)
def prediction(
    project: str,
    features_table: Input[Dataset],
    output_table_id: str,
    output_table: Output[Dataset],
    path_model: str,
):
    from datetime import datetime
    from google.cloud import bigquery, storage
    import joblib
    import pandas_gbq
    import pandas as pd
    from pytz import timezone
    
    TZ = timezone('America/Bogota')

    def generate_datetime_created():
        return datetime.now(TZ).replace(tzinfo=None)

    client = bigquery.Client(project=project)
    storage_client = storage.Client(project=project)

    # user id de la sesión actual de bq
    user_id = client.query("SELECT SESSION_USER()").to_dataframe().iloc[0, 0]

    features_table_id = features_table.metadata.get("bq_table_id")

    query = f"SELECT * FROM `{features_table_id}`"
    df_features = client.query(query).to_dataframe()

    bucket_name, blob_name = path_model.replace("gs://", "").split("/", 1)
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename("/tmp/model.joblib")
    model = joblib.load("/tmp/model.joblib")

    predictions = model.predict(df_features)
    df_predictions = pd.DataFrame(
        {
            "prediction": predictions,
            "user_id": user_id,
            "datetime_created": generate_datetime_created()
        }
    )

    project_output = output_table_id.split(".")[0]
    pandas_gbq.to_gbq(
        df_predictions,
        destination_table=output_table_id,
        project_id=project_output,
        if_exists="replace"
    )
    output_table.uri = f"bq://{output_table_id}"
    output_table.metadata["bq_table_id"] = output_table_id
    output_table.metadata["rows"] = int(df_predictions.shape[0])
