# CeylonSavour

**Researcher:** Sandali Shela Nanayakkara

An AI-based culinary tourism recommender that suggests Sri Lankan dishes to tourists using personal taste profiles, dietary constraints, context, and location information.

## Research Objective

To design and evaluate an AI-based recommender system that suggests Sri Lankan dishes to tourists based on taste profiles, using data-driven user modelling and culinary datasets.

## Project Structure

- `data/raw` — original, unmodified datasets
- `data/processed` — cleaned and transformed datasets
- `notebooks` — exploratory analysis and experiments
- `src/recommender` — taste-profile and recommendation logic
- `src/api` — FastAPI backend
- `src/portal` — web or mobile frontend
- `evaluation` — metrics and experimental results
- `docs` — research and system documentation
- `thesis` — thesis chapters and supporting material
- `tests` — automated tests

## Environment Setup

```powershell
conda env create -f environment.yml
conda activate ceylon-savour
dvc pull