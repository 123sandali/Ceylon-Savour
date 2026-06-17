# Data Directory

## raw

Contains original datasets exactly as collected or downloaded. Raw data must not be manually modified.

## processed

Contains cleaned, normalized, transformed, merged, or feature-engineered datasets produced from the raw data.

## Data Versioning

Large datasets are tracked using DVC and stored in the configured remote storage.

Each dataset should include:

- source
- collection date
- licence or usage restrictions
- original schema
- cleaning steps
- missing-value handling
- known limitations
- generated features