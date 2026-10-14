# Uses uv (https://docs.astral.sh/uv) for dependency management — uv sync creates/updates .venv; run commands via uv run, no manual activation.
DATA_ROOT ?= $(HOME)/Documents/data
REPO_NAME := $(notdir $(CURDIR))
DATA_DIR  ?= $(DATA_ROOT)/$(REPO_NAME)
JOURNAL_DIR ?= $(DATA_DIR)/journal

export DATA_DIR
export JOURNAL_DIR

BOUNDARY_POLY = osm/ho-chi-minh-city.poly
OSM_URL = https://download.geofabrik.de/asia/vietnam-latest.osm.pbf

DOTFILES_MK := $(HOME)/gitRepo/dotfiles/make/osm-country.mk

OSM_DIR := $(DATA_DIR)/osm
export OSM_DIR

.PHONY: country osm-country-fetch

ifneq ($(wildcard $(DOTFILES_MK)),)
include $(DOTFILES_MK)
else
COUNTRY_OSM_FILE ?= $(notdir $(OSM_URL))

country osm-country-fetch:
	@echo "error: '$@' needs evgeniyarbatov/dotfiles (private helper); not found at $(DOTFILES_MK)." >&2
	@echo "Fetch manually: download $(OSM_URL) into $(OSM_DIR)/$(COUNTRY_OSM_FILE), then retry." >&2
	@exit 1
endif

TERRAFORM_DIR = terraform

.DEFAULT_GOAL := help

# Entry point: analyze + reflect.
run: all

setup:
	@mkdir -p $(DATA_DIR)/raw $(DATA_DIR)/activities $(JOURNAL_DIR)
	@uv sync --dev

system-deps:
	@command -v osmconvert >/dev/null || brew install osmfilter

city: system-deps
	@osmconvert $(OSM_DIR)/$(COUNTRY_OSM_FILE) -B=$(BOUNDARY_POLY) -o=$(OSM_DIR)/city.osm.pbf
	@osmium cat --overwrite $(OSM_DIR)/city.osm.pbf -o $(OSM_DIR)/city.osm

# Enrichment only (GPX → DATA_DIR/activities). Idempotent; scripts skip existing fields.
analyze: setup
	@uv run python -m scripts.activity
	@uv run python -m scripts.weather_traffic
	@uv run python -m scripts.uniqueness
	@uv run python -m scripts.context
	@uv run python -m scripts.poi

# Full daily path: drop GPX in DATA_DIR/raw, then `make`.
reflect: analyze
	@uv run python -m scripts.describe

all: reflect

test: setup
	@uv run python -m pytest

deploy: test
	@cd $(TERRAFORM_DIR) && terraform init -input=false && terraform apply -auto-approve

lock:
	@uv lock

help:
	@echo "run          - analyze + reflect"
	@echo "make         - drop GPX in $(DATA_DIR)/raw, then this (analyze + reflect → $(JOURNAL_DIR))"
	@echo "analyze      - enrichment pipeline only"
	@echo "reflect      - analyze + journal reflection"
	@echo "setup        - uv sync --dev"
	@echo "system-deps  - brew install osmfilter (osmconvert) if missing"
	@echo "city         - build city OSM extract from country extract"
	@echo "test         - run pytest"
	@echo "deploy       - test + terraform apply"
	@echo "lock         - refresh uv.lock"

.PHONY: all setup system-deps city analyze reflect test deploy lock help
