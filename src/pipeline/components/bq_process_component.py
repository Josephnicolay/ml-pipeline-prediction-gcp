from kfp.v2.dsl import (
    Dataset,
    Output,
    component
)

@component(
    packages_to_install=[
        "google-cloud-bigquery",
        "google-cloud-bigquery-storage",
        "pandas",
        "pandas-gbq",
        "db-dtypes",
        "pyarrow"
    ],
)
def process_data(
    project: str,
    input_table_id: str,
    features_table_id: str,
    features_table: Output[Dataset],
):
    from google.cloud import bigquery
    import pandas_gbq

    FEATURES = {
        "MSSubClass",
        "MSZoning",
        "LotArea",
        "LotShape",
        "LandContour",
        "LotConfig",
        "Neighborhood",
        "OverallQual",
        "OverallCond",
        "YearRemodAdd",
        "RoofStyle",
        "Exterior1st",
        "ExterQual",
        "Foundation",
        "BsmtQual",
        "BsmtExposure",
        "BsmtFinType1",
        "HeatingQC",
        "CentralAir",
        "stFlrSF",
        "ndFlrSF",
        "GrLivArea",
        "BsmtFullBath",
        "FullBath",
        "HalfBath",
        "KitchenQual",
        "TotRmsAbvGrd",
        "Functional",
        "Fireplaces",
        "FireplaceQu",
        "GarageFinish",
        "GarageCars",
        "PavedDrive",
        "WoodDeckSF",
        "ScreenPorch",
        "SaleCondition"
    }

    client = bigquery.Client(project=project)

    query = f"SELECT * FROM `{input_table_id}`"
    df = client.query(query).to_dataframe()

    df = df[[col for col in df.columns if col in FEATURES]]
    df = df.dropna()
    df = df.reset_index(drop=True)

    project_features = features_table_id.split(".")[0]
    pandas_gbq.to_gbq(
        df,
        destination_table=features_table_id,
        project_id=project_features,
        if_exists="replace"
    )

    features_table.uri = f"bq://{features_table_id}"
    features_table.metadata["bq_table_id"] = features_table_id
    features_table.metadata["rows"] = int(df.shape[0])
    


    