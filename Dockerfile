# From: https://pdm.fming.dev/usage/advanced/#use-pdm-in-a-multi-stage-dockerfile

# build stage
FROM python:3.10-alpine AS angela-builder
ENV APP_NAME angela

# install PDM
RUN pip install -U pip setuptools wheel
RUN pip install pdm

# copy files
COPY pyproject.toml pdm.lock README.md /${APP_NAME}/
COPY src/ /${APP_NAME}/src

# install dependencies and project
WORKDIR /${APP_NAME}
RUN pdm install --prod --no-lock --no-editable


# run stage
FROM python:3.10-alpine AS angela
ENV APP_NAME angela

# retrieve packages from build stage
ENV PYTHONPATH=/${APP_NAME}/pkgs
COPY --from=angela-builder /${APP_NAME}/__pypackages__/3.10/lib /${APP_NAME}/pkgs

# set command/entrypoint, adapt to fit your needs
CMD python -m ${APP_NAME}.main