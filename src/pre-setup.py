import os
from pathlib import Path

from google.cloud import bigquery

DATA_PATH = Path(__file__).resolve().parent.parent / "data"
INPUT_DATA = os.getenv("INPUT_DATA_FILE", "input_table.csv")


def require_env(var_name: str) -> str:
    value = os.getenv(var_name)
    if not value:
        raise ValueError(f"Missing required environment variable: {var_name}")
    return value


project_id = require_env("PROJECT_ID")
dataset_id = require_env("DATASET_ID")
table_id = require_env("TABLE_ID")

write_disposition_name = os.getenv("WRITE_DISPOSITION", "WRITE_TRUNCATE_DATA")
allowed_write_dispositions = {
    "WRITE_TRUNCATE",
    "WRITE_TRUNCATE_DATA",
    "WRITE_APPEND",
    "WRITE_EMPTY",
}
if write_disposition_name not in allowed_write_dispositions:
    raise ValueError(
        "Invalid WRITE_DISPOSITION. Use one of: "
        "WRITE_TRUNCATE, WRITE_TRUNCATE_DATA, WRITE_APPEND, WRITE_EMPTY"
    )
write_disposition = write_disposition_name

csv_file_path = DATA_PATH / INPUT_DATA
if not csv_file_path.exists():
    raise FileNotFoundError(f"CSV file not found: {csv_file_path}")

client = bigquery.Client(project=project_id)
table_ref = client.dataset(dataset_id).table(table_id)

job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,
    autodetect=False,
    write_disposition=write_disposition,
)

with open(csv_file_path, "rb") as source_file:
    load_job = client.load_table_from_file(source_file, table_ref, job_config=job_config)

print(f"Starting job {load_job.job_id} for {INPUT_DATA}")
load_job.result()
print(f"Job {load_job.job_id} finished for {INPUT_DATA}")

destination_table = client.get_table(table_ref)
print(f"Loaded {destination_table.num_rows} rows into {table_ref}.")
