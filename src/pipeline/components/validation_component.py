from kfp.v2.dsl import component
from typing import NamedTuple

@component(packages_to_install=["google-cloud-bigquery"])
def validate_data(
    table: str,
) -> NamedTuple(
    "Outputs",
    [
        ("condition", str)
    ],
):
    from google.cloud import bigquery

    client = bigquery.Client()

    try:
        client.get_table(table)
        condition = "true"
    except Exception as e:
        condition = "false"

    return (condition,)