OPENLANE_TAG ?= $(shell cat versions/openlane)
OPENLANE_BASE_IMAGE_NAME ?= efabless/openlane:$(OPENLANE_TAG)
OPENLANE_IMAGE_REPO ?= efabless/caravel_openlane
OPENLANE_IMAGE_NAME ?= $(OPENLANE_IMAGE_REPO):$(OPENLANE_TAG)

SKY130_REPO = https://github.com/google/skywater-pdk
SKY130_COMMIT = $(shell cat versions/sky130)

OPEN_PDKS_REPO = https://github.com/RTimothyEdwards/open_pdks
OPEN_PDKS_COMMIT = $(shell cat versions/open_pdks)

MAGIC_REPO = https://github.com/RTimothyEdwards/magic
MAGIC_COMMIT = $(shell cat versions/magic)

all: pdk
	id=$$(${ROOT} docker create openlane-pdk-build) ; \
		${ROOT} docker cp $$id:/build.tar.gz pdk.tar.gz ; \
		${ROOT} docker rm -v $$id
	docker build\
		--build-arg OPENLANE_BASE_IMAGE_NAME=$(OPENLANE_BASE_IMAGE_NAME)\
		-t $(OPENLANE_IMAGE_NAME)\
		-f integrate.Dockerfile\
		.

pdk: versions/magic
	docker build\
		--build-arg SKY130_REPO=$(SKY130_REPO)\
		--build-arg SKY130_COMMIT=$(SKY130_COMMIT)\
		--build-arg OPEN_PDKS_REPO=$(OPEN_PDKS_REPO)\
		--build-arg OPEN_PDKS_COMMIT=$(OPEN_PDKS_COMMIT)\
		--build-arg MAGIC_REPO=$(MAGIC_REPO)\
		--build-arg MAGIC_COMMIT=$(MAGIC_COMMIT)\
		--build-arg OPENLANE_BASE_IMAGE_NAME=$(OPENLANE_BASE_IMAGE_NAME)\
		-t openlane-pdk-build\
		-f build.Dockerfile\
		.

versions/magic: FORCE
	docker run --rm $(OPENLANE_BASE_IMAGE_NAME)\
		python3 /openlane/dependencies/tool.py -f commit magic > $@

FORCE:

.PHONY: ol_image_name
ol_image_name:
	@printf $(OPENLANE_IMAGE_NAME)

.PHONY: ol_repo_name
ol_repo_name:
	@printf $(OPENLANE_IMAGE_REPO)

	