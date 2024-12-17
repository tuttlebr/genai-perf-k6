#!/bin/bash
set -e

curl -s ${URL}/v1/health/ready | jq '.message'
echo

curl -s ${URL}/v1/models | jq
echo

genai-perf profile \
  -m ${MODEL} \
  --service-kind openai \
  --endpoint-type chat \
  --random-seed ${RANDOM_SEED} \
  --synthetic-input-tokens-mean ${INPUT_TOKENS_MEAN} \
  --synthetic-input-tokens-stddev ${INPUT_TOKENS_STDDEV} \
  --output-tokens-mean ${OUTPUT_TOKENS_MEAN} \
  --output-tokens-stddev ${OUTPUT_TOKENS_STDDEV} \
  --stability-percentage ${STABILITY_PERCENTAGE} \
  --measurement-interval ${MEASUREMENT_INTERVAL} \
  --num-prompts ${NUM_PROMPTS} \
  --tokenizer ${TOKENIZER} \
  --url ${URL} \
  --streaming \
  --concurrency ${CONCURRENCY} -- --max-threads=$(nproc)

# --extra-inputs ignore_eos:true
